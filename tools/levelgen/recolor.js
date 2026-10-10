#!/usr/bin/env node
'use strict';
// Writes one copy of the ground tileset per era, with the tileset's near-black
// fill (39,32,52) replaced by the era's earth colour. The caps, edges and walls
// keep their own art; only the void-black inside the ground changes, so the six
// eras read differently and the ground is not a black slab.
//
//   node tools/levelgen/recolor.js
//
// The game draws terrain and platforms from assets/tiles/ground_<era>.png.
const fs = require('fs');
const path = require('path');
const { readPng, writePng } = require('./png');
const { eras } = require('./rules');

const TILES = path.join(__dirname, '..', '..', 'assets', 'tiles');

// The inside of the ground, per era.
const BODY = {
  'pre-colonial': [0x5d, 0x4e, 0x37], // brown earth
  spanish: [0x6b, 0x72, 0x80], // slate stone
  nationalism: [0x7a, 0x5a, 0x3e], // clay
  american: [0x4f, 0x6b, 0x7a], // blue-grey
  ww2: [0x4a, 0x4a, 0x3a], // olive
  modern: [0x55, 0x58, 0x60], // concrete
};

function main() {
  const src = readPng(path.join(TILES, 'ground_tileset.png'));
  for (const era of eras) {
    const body = BODY[era.id];
    if (!body) throw new Error('no body colour for ' + era.id);
    const out = { width: src.width, height: src.height, data: Buffer.from(src.data) };
    for (let i = 0; i < out.data.length; i += 4) {
      if (out.data[i] === 39 && out.data[i + 1] === 32 && out.data[i + 2] === 52) {
        out.data[i] = body[0]; out.data[i + 1] = body[1]; out.data[i + 2] = body[2];
      }
    }
    const file = path.join(TILES, `ground_${era.id}.png`);
    writePng(file, out);
    console.log('wrote', path.basename(file));
  }
}

if (require.main === module) main();
module.exports = { BODY };
