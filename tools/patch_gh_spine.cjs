/* Reapply the client-specific Spine reader after npm ci. */
const fs = require('fs');
const path = require('path');
const target = path.join(__dirname, 'logic_vendor/spine/node_modules/@pixi-spine/runtime-3.8/lib/core/SkeletonBinary.js');
const source = fs.readFileSync(target, 'utf8');
if (source.includes('GH 3.98.10: SkeletonBinary.ReadSkeletonData')) {
  console.log('GH Spine adapter already installed');
} else {
  const original = `    n = input.readInt(true);
    for (let i = 0; i < n; i++)
      skeletonData.animations.push(this.readAnimation(input, input.readString(), skeletonData));
    return skeletonData;`;
  const adapted = `    // GH 3.98.10: SkeletonBinary.ReadSkeletonData RVA 0x1927350 checks marker 153.
    const animationMarker = input.readUnsignedByte();
    if (animationMarker === 153) {
      n = input.readInt(true);
      skeletonData.lazyAnimationSource = input.readString();
      for (let i = 0; i < n; i++)
        skeletonData.animations.push({ name: input.readString(), duration: null, timelines: [], lazy: true });
    } else {
      input.index--;
      n = input.readInt(true);
      for (let i = 0; i < n; i++)
        skeletonData.animations.push(this.readAnimation(input, input.readString(), skeletonData));
    }
    skeletonData.binaryStrings = input.strings;
    return skeletonData;`;
  if (!source.includes(original)) throw new Error('Unexpected Spine runtime source; adapter requires version 4.0.6');
  fs.writeFileSync(target, source.replace(original, adapted), 'utf8');
  console.log('Installed GH Spine adapter');
}
