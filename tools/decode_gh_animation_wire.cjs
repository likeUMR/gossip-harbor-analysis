/* Preserve encoded timelines without inventing a missing skeleton or mesh baseline. */
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const dir = path.join(root, 'analysis_data/logic_index');
const texts = JSON.parse(fs.readFileSync(path.join(dir, 'textassets.json')));
function decode(buffer) {
  let p = 0;
  const need = n => { if (p + n > buffer.length) throw Error(`Truncated at ${p}`); };
  const byte = () => { need(1); return buffer[p++]; };
  const bool = () => { const v = byte(); if (v > 1) throw Error('Invalid bool'); return !!v; };
  const int = () => { let v = 0; for (let s = 0; s < 35; s += 7) {
    const b = byte(); v += (b & 127) * 2 ** s; if (!(b & 128)) return v;
  } throw Error('Invalid varint'); };
  const count = () => { const n = int(); if (n > buffer.length) throw Error('Invalid count'); return n; };
  const float = () => { need(4); const v = buffer.readFloatBE(p); p += 4;
    if (!Number.isFinite(v)) throw Error('Invalid float'); return v; };
  const color = () => { need(4); const v = buffer.readUInt32BE(p); p += 4; return v; };
  const string = () => { const n = count(); if (!n) return null; need(n - 1);
    const v = buffer.subarray(p, p + n - 1).toString('utf8'); p += n - 1; return v; };
  const curve = () => { const type = byte(); if (type > 2) throw Error('Invalid curve');
    return type === 2 ? { type, controls: [float(), float(), float(), float()] } : { type }; };
  const timelines = [];
  const frames = (n, read, curves) => Array.from({length:n}, (_, i) => {
    const value = read(); if (curves && i + 1 < n) value.curve = curve(); return value;
  });
  const name = string();
  for (const family of ['slot', 'bone']) for (let i = 0, n = count(); i < n; i++) {
    const index = count();
    for (let j = 0, m = count(); j < m; j++) {
      const type = byte(), nframes = count();
      if (type > (family === 'slot' ? 2 : 3)) throw Error('Invalid timeline');
      const values = frames(nframes, () => {
        const time = float();
        if (family === 'slot') return type === 0 ? {time, string_ref:int()} :
          {time, colors: Array.from({length:type}, color)};
        return {time, values:Array.from({length:type === 0 ? 1 : 2}, float)};
      }, family !== 'slot' || type !== 0);
      timelines.push({family, index, type, frames:values});
    }
  }
  for (const family of ['ik', 'transform']) for (let i = 0, n = count(); i < n; i++) {
    const index = count(), nframes = count();
    timelines.push({family, index, frames:frames(nframes, () => family === 'ik' ?
      {time:float(), mix:float(), softness:float(), bend:byte(), compress:bool(), stretch:bool()} :
      {time:float(), values:[float(),float(),float(),float()]}, true)});
  }
  for (let i = 0, n = count(); i < n; i++) {
    const index = count();
    for (let j = 0, m = count(); j < m; j++) {
      const type = byte(), nframes = count(); if (type > 2) throw Error('Invalid path type');
      timelines.push({family:'path', index, type, frames:frames(nframes, () =>
        ({time:float(), values:Array.from({length:type === 2 ? 2 : 1}, float)}), true)});
    }
  }
  for (let i = 0, n = count(); i < n; i++) {
    const skin = count();
    for (let j = 0, m = count(); j < m; j++) {
      const slot = count();
      for (let k = 0, a = count(); k < a; k++) {
        const attachment_ref = int(), nframes = count();
        timelines.push({family:'deform', skin, slot, attachment_ref,
          frames:frames(nframes, () => { const time = float(), length = count();
            if (!length) return {time, use_setup_vertices:true};
            const start = count(); return {time, start, values:Array.from({length}, float)};
          }, true)});
      }
    }
  }
  const drawOrder = frames(count(), () => ({time:float(), offsets:Array.from({length:count()}, () =>
    ({slot:count(), offset:int()}))}), false);
  const eventCount = count();
  // Audio presence belongs to the skeleton event definition. Keep each exact-consumption alternative.
  const events = [];
  function eventBranch(index, history) {
    if (index === eventCount) { if (p === buffer.length) events.push(history); return; }
    const time = float(), event_ref = count(), encodedInt = int(), value = {
      time, event_ref, int_value:(encodedInt >>> 1) ^ -(encodedInt & 1), float_value:float()};
    value.string_value = bool() ? string() : {from_skeleton:true};
    const next = p;
    try { eventBranch(index + 1, [...history, {...value, has_audio:false}]); } catch (_) {}
    p = next;
    try { const volume = float(), balance = float();
      eventBranch(index + 1, [...history, {...value, has_audio:true, volume, balance}]); } catch (_) {}
    p = next;
  }
  eventBranch(0, []);
  if (!events.length) throw Error(`No complete event interpretation at ${p}/${buffer.length}`);
  return {name, timelines, drawOrder, event_interpretations:events, bytes:buffer.length,
    consumed_bytes:buffer.length, scope:'Encoded timeline data only. String IDs, setup vertices, bones and event defaults require the original matching skeleton.'};
}
const rows = [];
function encode(value, events) {
  const parts = [];
  const byte = n => parts.push(Buffer.from([n]));
  const int = n => { n >>>= 0; while (n > 127) { byte((n & 127) | 128); n >>>= 7; } byte(n); };
  const float = n => { const b = Buffer.alloc(4); b.writeFloatBE(n); parts.push(b); };
  const color = n => { const b = Buffer.alloc(4); b.writeUInt32BE(n); parts.push(b); };
  const string = s => { if (s == null) return int(0); const b = Buffer.from(s); int(b.length + 1); parts.push(b); };
  const curve = c => { byte(c.type); if (c.controls) c.controls.forEach(float); };
  const framed = (frames, write, curves) => frames.forEach((f,i) => { write(f); if (curves && i + 1 < frames.length) curve(f.curve); });
  string(value.name);
  for (const family of ['slot','bone','ik','transform','path']) {
    const rows = value.timelines.filter(t => t.family === family), groups = [];
    for (const row of rows) {
      const last = groups.at(-1);
      if (last && last.index === row.index && ['slot','bone','path'].includes(family)) last.rows.push(row);
      else groups.push({index:row.index,rows:[row]});
    }
    int(groups.length);
    for (const group of groups) {
      int(group.index);
      if (['slot','bone','path'].includes(family)) int(group.rows.length);
      for (const row of group.rows) {
        if (['slot','bone','path'].includes(family)) byte(row.type);
        int(row.frames.length);
        framed(row.frames, f => {
          float(f.time);
          if (family === 'slot') { if (row.type === 0) int(f.string_ref); else f.colors.forEach(color); }
          else if (family === 'ik') { float(f.mix); float(f.softness); byte(f.bend); byte(+f.compress); byte(+f.stretch); }
          else f.values.forEach(float);
        }, family !== 'slot' || row.type !== 0);
      }
    }
  }
  const skins = [];
  for (const row of value.timelines.filter(t => t.family === 'deform')) {
    let skin = skins.at(-1);
    if (!skin || skin.index !== row.skin) { skin = {index:row.skin,slots:[]}; skins.push(skin); }
    let slot = skin.slots.at(-1);
    if (!slot || slot.index !== row.slot) { slot = {index:row.slot,rows:[]}; skin.slots.push(slot); }
    slot.rows.push(row);
  }
  int(skins.length);
  for (const skin of skins) {
    int(skin.index); int(skin.slots.length);
    for (const slot of skin.slots) {
      int(slot.index); int(slot.rows.length);
      for (const row of slot.rows) {
        int(row.attachment_ref); int(row.frames.length);
        framed(row.frames, f => { float(f.time); int(f.use_setup_vertices ? 0 : f.values.length);
          if (!f.use_setup_vertices) { int(f.start); f.values.forEach(float); } },true);
      }
    }
  }
  int(value.drawOrder.length);
  for (const f of value.drawOrder) { float(f.time); int(f.offsets.length); for (const o of f.offsets) { int(o.slot); int(o.offset); } }
  int(events.length);
  for (const e of events) {
    float(e.time); int(e.event_ref); int((e.int_value << 1) ^ (e.int_value >> 31)); float(e.float_value);
    const explicit = typeof e.string_value !== 'object' || e.string_value === null;
    byte(+explicit); if (explicit) string(e.string_value);
    if (e.has_audio) { float(e.volume); float(e.balance); }
  }
  return Buffer.concat(parts);
}
for (const item of texts.filter(x => x.name.endsWith('.ani'))) {
  const row = {name:item.name, sha256:item.sha256, source:item.source};
  try {
    const original = fs.readFileSync(path.join(root, item.source));
    const value = decode(original);
    if (!value.event_interpretations.every(events => encode(value,events).equals(original)))
      throw Error('Wire re-encoding differs from original bytes');
    value.roundtrip_bytes_equal = true;
    const target = path.join(dir, 'spine', item.sha256 + '.wire.json');
    fs.writeFileSync(target, JSON.stringify(value));
    Object.assign(row, {status:'wire_decoded', decoded_path:path.relative(root,target).replaceAll('\\','/'),
      bytes:value.bytes, roundtrip_bytes_equal:true, event_interpretations:value.event_interpretations.length});
  } catch (e) { Object.assign(row, {status:'failed', error:String(e)}); }
  rows.push(row);
}
fs.writeFileSync(path.join(dir, 'spine_animation_wire.json'), JSON.stringify(rows,null,2));
console.log(rows.reduce((a,x) => { a[x.status]=(a[x.status]||0)+1; return a; },{}));
