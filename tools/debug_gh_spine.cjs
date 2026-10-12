const fs = require('fs');
const spine = require('./logic_vendor/spine/node_modules/@pixi-spine/runtime-3.8');
const base = require('./logic_vendor/spine/node_modules/@pixi-spine/base');
const rows = JSON.parse(fs.readFileSync('analysis_data/logic_index/spine_animations.json', 'utf8'));
const texts = JSON.parse(fs.readFileSync('analysis_data/logic_index/textassets.json', 'utf8'));
const row = rows.find(x => x.name === (process.argv[2] || 'Harrison_happy_begin.ani'));
const loader = {};
for (const kind of ['Region', 'Mesh', 'BoundingBox', 'Path', 'Point', 'Clipping'])
  loader[`new${kind}Attachment`] = (_skin, name) => new spine[`${kind}Attachment`](name);
const item = texts.find(x => x.sha256 === (process.argv[3] || row.candidate_skeletons[0]));
const parser = new spine.SkeletonBinary(loader);
const skeleton = parser.readSkeletonData(Uint8Array.from(fs.readFileSync(item.source)));
const original = spine.Skin.prototype.getAttachment;
spine.Skin.prototype.getAttachment = function(slot, name) {
  const result = original.call(this, slot, name);
  if (!result) throw new Error(JSON.stringify({ skin: this.name, slot, name,
    available: Object.keys(this.attachments[slot] || {}), strings: skeleton.binaryStrings.length,
    matching_slots: this.attachments.map((x, i) => x && x[name] ? i : null).filter(x => x !== null) }));
  return result;
};
const stream = new base.BinaryInput(Uint8Array.from(fs.readFileSync(row.source)), skeleton.binaryStrings);
try {
  const name = stream.readString();
  console.log(parser.readAnimation(stream, name, skeleton).duration);
} catch (e) { console.log(stream.index, String(e)); }
