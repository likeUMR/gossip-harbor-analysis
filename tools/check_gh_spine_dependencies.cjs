/* Check every available skeleton against original, unmodified animation references. */
const fs = require('fs');
const path = require('path');
const spine = require('./logic_vendor/spine/node_modules/@pixi-spine/runtime-3.8');
const base = require('./logic_vendor/spine/node_modules/@pixi-spine/base');
const dir = path.resolve(__dirname, '../analysis_data/logic_index');
const root = path.resolve(__dirname, '..');
const texts = JSON.parse(fs.readFileSync(path.join(dir,'textassets.json')));
const animations = JSON.parse(fs.readFileSync(path.join(dir,'spine_animations.json')));
const loader = {};
for (const kind of ['Region','Mesh','BoundingBox','Path','Point','Clipping'])
  loader[`new${kind}Attachment`] = (_skin,name) => new spine[`${kind}Attachment`](name);
const skeletons = texts.filter(x => x.name.endsWith('.skel')).map(item => {
  const parser = new spine.SkeletonBinary(loader);
  return {item,parser,data:parser.readSkeletonData(Uint8Array.from(fs.readFileSync(path.join(root,item.source))))};
});
function mismatch(wire, data) {
  for (const t of wire.timelines) {
    const table = {slot:data.slots, bone:data.bones, ik:data.ikConstraints,
      transform:data.transformConstraints, path:data.pathConstraints}[t.family];
    if (table && t.index >= table.length) return `${t.family}_index`;
    if (t.family === 'slot' && t.type === 0 && t.frames.some(f => f.string_ref > data.binaryStrings.length))
      return 'attachment_string_ref';
    if (t.family === 'deform') {
      const skin = data.skins[t.skin];
      if (!skin) return 'skin_index';
      const name = data.binaryStrings[t.attachment_ref - 1];
      const attachment = skin.getAttachment(t.slot,name);
      if (!name || !attachment || !attachment.vertices) return 'deform_attachment';
      const length = attachment.bones ? attachment.vertices.length / 3 * 2 : attachment.vertices.length;
      if (t.frames.some(f => !f.use_setup_vertices && f.start + f.values.length > length)) return 'deform_extent';
    }
  }
  if (wire.drawOrder.some(f => f.offsets.some(o => o.slot >= data.slots.length))) return 'draw_order_slot';
  if (!wire.event_interpretations.some(events => events.every(e => {
    const definition = data.events[e.event_ref];
    return definition && e.has_audio === (definition.audioPath != null);
  }))) return 'event_definition';
  return null;
}
const results = [];
for (const row of animations.filter(x => x.status !== 'decoded_complete')) {
  const wire = JSON.parse(fs.readFileSync(path.join(dir,'spine',row.sha256+'.wire.json')));
  const result = {name:row.name, sha256:row.sha256, skeletons_checked:skeletons.length,
    rejected:{}, candidates:[], fully_parsed:[]};
  for (const candidate of skeletons) {
    const reason = mismatch(wire,candidate.data);
    if (reason) { result.rejected[reason]=(result.rejected[reason]||0)+1; continue; }
    result.candidates.push(candidate.item.sha256);
    try {
      const stream = new base.BinaryInput(Uint8Array.from(fs.readFileSync(path.join(root,row.source))),candidate.data.binaryStrings);
      const name = stream.readString();
      candidate.parser.readAnimation(stream,name,candidate.data);
      if (stream.index !== stream.buffer.byteLength) throw Error('Trailing bytes');
      result.fully_parsed.push(candidate.item.sha256);
    } catch (e) {
      if (!result.parse_errors) result.parse_errors=[];
      result.parse_errors.push({skeleton:candidate.item.sha256,error:String(e)});
    }
  }
  result.status = result.fully_parsed.length ? 'structurally_compatible_requires_identity' : 'matching_dependency_absent_in_snapshot';
  results.push(result);
  if (results.length % 50 === 0) console.log('Exhaustive skeleton checks',results.length);
}
fs.writeFileSync(path.join(dir,'spine_dependency_checks.json'),JSON.stringify(results,null,2));
console.log(results.reduce((a,x)=>{a[x.status]=(a[x.status]||0)+1;return a;},{}));
