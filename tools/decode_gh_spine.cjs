/* Read Spine 3.8 structures without requiring textures or a rendering context. */
const fs = require('fs');
const path = require('path');
const spine = require('./logic_vendor/spine/node_modules/@pixi-spine/runtime-3.8');
const base = require('./logic_vendor/spine/node_modules/@pixi-spine/base');
const root = path.resolve(__dirname, '..');
const dataDir = path.join(root, 'analysis_data/logic_index');
const input = JSON.parse(fs.readFileSync(path.join(dataDir, 'textassets.json'), 'utf8'));
const occurrences = JSON.parse(fs.readFileSync(path.join(dataDir, 'textasset_occurrences.json'), 'utf8'));
const loader = {};
for (const kind of ['Region', 'Mesh', 'BoundingBox', 'Path', 'Point', 'Clipping']) {
  loader[`new${kind}Attachment`] = (_skin, name) => new spine[`${kind}Attachment`](name);
}
let lastInput;
let operations = 0;
const originalRead = base.BinaryInput.prototype.readByte;
base.BinaryInput.prototype.readByte = function () {
  if (++operations > 5000000) throw new Error('Spine parser operation limit exceeded');
  lastInput = this;
  return originalRead.call(this);
};
const originalInt = base.BinaryInput.prototype.readInt;
base.BinaryInput.prototype.readInt = function (positive) {
  const result = originalInt.call(this, positive);
  if (positive && result > this.buffer.byteLength) {
    throw new Error(`Unexpected Spine count/index ${result} at ${this.index}`);
  }
  return result;
};
function serializable(value, contextSignature = false) {
  const seen = new WeakMap();
  let next = 0;
  return JSON.stringify(value, (_key, item) => {
    if (_key === 'timelineIds') return undefined;
    if (contextSignature && (_key === 'id' || _key === 'lazyAnimationSource')) return undefined;
    if (!item || typeof item !== 'object') return item;
    if (ArrayBuffer.isView(item)) return Array.from(item);
    if (seen.has(item)) return { $ref: seen.get(item) };
    const id = next++;
    seen.set(item, id);
    if (Array.isArray(item)) return item;
    return { $id: id, ...item };
  });
}
const rows = [];
const lazySkeletons = [];
const bundleScope = value => value.toLowerCase().replace(/_[0-9a-f]{32}\.bundle$/, '');
const aliases = new Map();
for (const occurrence of occurrences) {
  const key = occurrence.payload_sha256;
  if (!aliases.has(key)) aliases.set(key, new Set());
  aliases.get(key).add(bundleScope(occurrence.container_path));
}
const animationScopes = new Set(input.filter(x => x.name.endsWith('.ani')).flatMap(x =>
  [...(aliases.get(x.sha256) || new Set([bundleScope(x.container)]))]));
for (const item of input) {
  if (!item.name.endsWith('.skel')) continue;
  const row = { name: item.name, sha256: item.sha256, source: item.source };
  try {
    operations = 0;
    if (rows.length === 0) console.log(`Reading first skeleton: ${item.name}`);
    const buffer = fs.readFileSync(path.join(root, item.source));
    const bytes = new Uint8Array(buffer.length);
    bytes.set(buffer);
    const parser = new spine.SkeletonBinary(loader);
    const skeleton = parser.readSkeletonData(bytes);
    if (rows.length === 0) console.log('First skeleton parsed');
    row.version = skeleton.version;
    row.bones = skeleton.bones.length;
    row.slots = skeleton.slots.length;
    row.animations = skeleton.animations.map(a => ({ name: a.name, duration: a.duration }));
    row.lazy_animation_source = skeleton.lazyAnimationSource;
    const scopes = aliases.get(item.sha256) || new Set([bundleScope(item.container)]);
    if (skeleton.lazyAnimationSource || [...scopes].some(x => animationScopes.has(x))) {
      lazySkeletons.push({ item, skeleton, parser, scopes });
    }
    row.events = skeleton.events.map(e => e.name);
    row.consumed_bytes = lastInput.index;
    row.bytes = bytes.length;
    row.status = row.consumed_bytes === row.bytes ? 'decoded_complete' : 'decoded_with_trailing_bytes';
    const destination = path.join(dataDir, 'spine', `${item.sha256}.json`);
    fs.mkdirSync(path.dirname(destination), { recursive: true });
    const metadata = {
      version: skeleton.version, hash: skeleton.hash,
      lazyAnimationSource: skeleton.lazyAnimationSource, binaryStrings: skeleton.binaryStrings,
      bones: skeleton.bones.map(b => ({ name: b.name, parent: b.parent?.name, length: b.length, x: b.x, y: b.y })),
      slots: skeleton.slots.map(s => ({ name: s.name, bone: s.boneData?.name, attachment: s.attachmentName })),
      skins: skeleton.skins.map(s => ({ name: s.name, slots: s.attachments.length })),
      events: skeleton.events,
      animations: skeleton.animations.map(a => ({ name: a.name, duration: a.duration,
        timelines: a.timelines.map(t => ({ type: t.constructor.name, frames: t.frames?.length, events: t.events })) })),
      export_scope: 'Parsed metadata and event timelines; original binary retains full geometry and frame data',
    };
    fs.writeFileSync(destination, serializable(metadata));
    const fullDestination = path.join(dataDir, 'spine', `${item.sha256}.full.json`);
    fs.writeFileSync(fullDestination, serializable(skeleton));
    row.full_decoded_path = path.relative(root, fullDestination).replaceAll('\\', '/');
    row.decoded_path = path.relative(root, destination).replaceAll('\\', '/');
  } catch (error) {
    row.status = 'failed';
    row.error = String(error);
  }
  rows.push(row);
  if (rows.length % 100 === 0) console.log(`Spine skeletons: ${rows.length}`);
}
fs.writeFileSync(path.join(dataDir, 'spine_skeletons.json'), JSON.stringify(rows, null, 2));
console.log(rows.reduce((counts, row) => {
  counts[row.status] = (counts[row.status] || 0) + 1;
  return counts;
}, {}));
const animationRows = [];
for (const item of input) {
  if (!item.name.endsWith('.ani')) continue;
  const row = { name: item.name, source: item.source, sha256: item.sha256 };
  const itemScopes = aliases.get(item.sha256) || new Set([bundleScope(item.container)]);
  const matches = lazySkeletons.filter(x => [...itemScopes].some(scope => x.scopes.has(scope)) ||
    (x.skeleton.lazyAnimationSource && item.container.toLowerCase().includes(
      x.skeleton.lazyAnimationSource.replaceAll('\\', '/').toLowerCase())));
  row.candidate_skeletons = matches.map(x => x.item.sha256);
  row.attempts = [];
  const decoded = [];
  const contextSignatures = [];
  for (const match of matches) {
    try {
      operations = 0;
      const buffer = fs.readFileSync(path.join(root, item.source));
      const bytes = new Uint8Array(buffer.length);
      bytes.set(buffer);
      const stream = new base.BinaryInput(bytes, match.skeleton.binaryStrings);
      const name = stream.readString();
      const animation = match.parser.readAnimation(stream, name, match.skeleton);
      if (stream.index !== bytes.length) throw new Error(`Trailing bytes: ${bytes.length - stream.index}`);
      decoded.push({ skeleton: match.item.sha256, name, duration: animation.duration,
        animation });
      contextSignatures.push(serializable(match.skeleton, true));
      row.attempts.push({ skeleton: match.item.sha256, status: 'complete' });
    } catch (error) {
      row.attempts.push({ skeleton: match.item.sha256, status: 'failed', error: String(error), stack: error.stack });
    }
  }
  const equivalent = decoded.length > 1 && new Set(contextSignatures).size === 1;
  row.status = decoded.length === 1 || equivalent ? 'decoded_complete' : decoded.length ? 'decoded_ambiguous' : 'failed';
  if (equivalent) row.context_evidence = 'All successful skeletons have identical decoded setup/geometry/events/string tables; only lazy source path and runtime-generated attachment IDs differ. All contexts retained.';
  if (decoded.length) {
    const destination = path.join(dataDir, 'spine', `${item.sha256}.animation.json`);
    fs.writeFileSync(destination, serializable(decoded));
    row.decoded_path = path.relative(root, destination).replaceAll('\\', '/');
  }
  animationRows.push(row);
}
fs.writeFileSync(path.join(dataDir, 'spine_animations.json'), JSON.stringify(animationRows, null, 2));
console.log('Separate animations:', animationRows.reduce((counts, row) => {
  counts[row.status] = (counts[row.status] || 0) + 1;
  return counts;
}, {}));
