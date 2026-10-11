#!/usr/bin/env node
'use strict';
// Draws the six boss arenas as PNGs (the whole room, 1824 x 720 world units) from the same data
// arenas.js writes into the maps, with the real ground tileset, platforms and sprites, the way
// render.js draws a level. For reviewing an arena without running the game.
//
//   node tools/levelgen/arena_mock.js <out folder>
const fs = require('fs');
const path = require('path');
const { writePng } = require('./png');
const T = require('./terrain');
const { eras } = require('./rules');
const { renderWindow, sprite } = require('./render');
const { buildArena, COLS } = require('./arenas');

const BOSS = { 'pre-colonial': 'bakunawa', spanish: 'governor', nationalism: 'governor', american: 'general', ww2: 'commander', modern: 'corruption_boss' };
const MINION = { 'pre-colonial': 'tribal_warrior', spanish: 'spanish_soldier', nationalism: 'spanish_soldier', american: 'american_soldier', ww2: 'japanese_soldier', modern: 'corruption_figure' };

function draw(eraId) {
  const level = buildArena(eraId);
  const cv = renderWindow(level, 0, { width: COLS * T.TILE, height: 720 });

  // a minion on each spot, at its real size
  const img = sprite(`enemies/${MINION[eraId]}_1.png`);
  for (const m of level.arena.minions) cv.blit(img, 0, 0, img.width, img.height, m.x - 45, m.y - 108, 90, 108, true);

  // the boss, at its real size (120 x 140), standing where the map puts it
  const boss = sprite(`bosses/${BOSS[eraId]}_idle.png`);
  const b = level.arena.boss;
  cv.blit(boss, 0, 0, boss.width, boss.height, b.x - 60, b.y - 140, 120, 140);
  return { cv, level };
}

function main() {
  const out = process.argv[2] || 'arenas';
  fs.mkdirSync(out, { recursive: true });
  for (const era of eras) {
    writePng(path.join(out, `${era.id}.png`), draw(era.id).cv);
    console.log('wrote', `${era.id}.png`);
  }
}

if (require.main === module) main();
module.exports = { draw };
