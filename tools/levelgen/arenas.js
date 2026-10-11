#!/usr/bin/env node
'use strict';
// The six boss arenas: one fixed room per era, 76 tiles (1824 units) wide so a phone at the widest
// aspect the game allows (2.5:1, 1800 units) still sees only the arena. Each is described once, for
// its left half, and mirrored, so the two sides of the fight are fair.
//
//   node tools/levelgen/arenas.js              write assets/tiles/levels/era<N>_<boss>.tmx and the manifest
//   node tools/levelgen/arenas.js --check      only check them
//
// An arena has a start, a boss, a few `minion_spawn` spots and platforms, and no gate and no exit: the
// level ends when the boss is beaten. Two walls (7 tiles high, past a jump's 5.3 tiles) close the sides.
// Before a map is written the solver (solve.js) plays it: every platform, every minion spot and the
// ground around the boss must be reachable, and nothing may be a place you can reach but not leave.
const fs = require('fs');
const path = require('path');
const { physics, eras, eraNumber } = require('./rules');
const T = require('./terrain');
const tmx = require('./tmx');
const { solve } = require('./solve');
const { writeManifest } = require('./generate');

const COLS = 76;
const WALL = 7; // tiles; 168 units, over the 128-unit jump peak
const OUT = path.join(__dirname, '..', '..', 'assets', 'tiles', 'levels');

const tier = (n) => physics.groundSurfaceY - n * T.TILE; // top of a platform n tiles above the base ground

// Left half, 38 columns: runs of [columns, height]; -1 is a pit. Platforms as [col, columns, tiers up].
// startCol / minion columns are for the left half; the right half is the mirror image.
const SPECS = {
  // Bakunawa, on a shore: two tide pools, rocks to climb to a safe ledge.
  'pre-colonial': {
    left: [[2, WALL], [10, 0], [5, -1], [21, 0]],
    platforms: [[13, 3, 2], [21, 4, 3], [26, 4, 6]],
    startCol: 5, minions: [25, 32],
  },
  // The Governor in the courtyard of a fort: a bastion at each end with a balcony over it.
  spanish: {
    left: [[2, WALL], [7, 0], [2, 1], [6, 2], [2, 1], [19, 0]],
    platforms: [[12, 4, 6], [22, 4, 3], [27, 4, 6]],
    startCol: 5, minions: [26, 33],
  },
  // The plaza bowl: start on the high terrace and drop in.
  nationalism: {
    left: [[2, WALL], [8, 2], [4, 1], [24, 0]],
    platforms: [[3, 4, 5], [18, 4, 3], [24, 4, 6]],
    startCol: 5, minions: [21, 30],
  },
  // The trench line: sandbag mounds break the floor into short stretches.
  american: {
    left: [[2, WALL], [7, 0], [3, 1], [4, 0], [3, 1], [19, 0]],
    platforms: [[13, 4, 4], [21, 4, 7], [27, 4, 4]],
    startCol: 5, minions: [26, 33],
  },
  // The broken bridge: two gaps over water, a stepping stone in each.
  ww2: {
    left: [[2, WALL], [8, 0], [6, -1], [22, 0]],
    platforms: [[12, 2, 2], [18, 4, 4], [24, 4, 7]],
    startCol: 5, minions: [23, 31],
  },
  // The palace steps: a staircase up to a wide dais, the boss at the top.
  modern: {
    left: [[2, WALL], [9, 0], [4, 1], [5, 2], [18, 3]],
    platforms: [[12, 4, 5], [22, 4, 6]],
    startCol: 5, minions: [27, 33],
  },
};

function expand(runs) {
  return runs.reduce((a, [n, h]) => a.concat(Array(n).fill(h)), []);
}

const mirrorCol = (c) => COLS - 1 - c;

function buildArena(eraId) {
  const spec = SPECS[eraId];
  const left = expand(spec.left);
  if (left.length !== COLS / 2) throw new Error(`${eraId}: the left half has ${left.length} columns, not ${COLS / 2}`);
  const H = Int8Array.from([...left, ...[...left].reverse()]);

  const platforms = [];
  for (const [col, cols, tiers] of spec.platforms) {
    platforms.push({ x: col * T.TILE, y: tier(tiers), width: cols * T.TILE });
    platforms.push({ x: mirrorCol(col + cols - 1) * T.TILE, y: tier(tiers), width: cols * T.TILE });
  }
  platforms.sort((a, b) => a.x - b.x);

  const surface = (col) => T.surfaceY(H[col]);
  const centre = (col) => col * T.TILE + T.TILE / 2;
  const minions = [];
  for (const col of spec.minions) {
    minions.push({ x: centre(col), y: surface(col) }, { x: centre(mirrorCol(col)), y: surface(mirrorCol(col)) });
  }
  minions.sort((a, b) => a.x - b.x);

  const era = eras[eraNumber(eraId) - 1];
  const bossX = (COLS * T.TILE) / 2;
  return {
    props: { era: eraId, level: era.levelWeeks.length },
    H, S: null, C: null, grid: null,
    platforms, coins: [], artifacts: [], enemies: [], gates: [],
    spawnX: spec.startCol * T.TILE,
    exitX: COLS * T.TILE,
    seed: 0,
    arena: { boss: { x: bossX, y: surface(COLS / 2) }, minions },
  };
}

// ── checks ──────────────────────────────────────────────────────────────────

const standsOn = (spot, y, x0, x1) => Math.abs(spot.top - y) < 1 && spot.x + 48 >= x0 && spot.x + 48 <= x1;

function validateArena(level) {
  const problems = [];
  const { H, platforms } = level;
  const surface = (x) => T.surfaceY(H[Math.floor(x / T.TILE)]);

  if (H.length !== COLS) problems.push(`the map is ${H.length} columns, not ${COLS}`);
  for (const c of [0, 1, COLS - 2, COLS - 1]) if (H[c] !== WALL) problems.push(`column ${c} is not a wall`);
  if (H[Math.floor(level.spawnX / T.TILE)] < 0) problems.push('the start is over a pit');
  const boss = level.arena.boss;
  if (H[COLS / 2] < 0 || H[COLS / 2 - 1] < 0) problems.push('the boss would stand over a pit');
  // The boss stands on one height: its 5 columns are level.
  const bc = COLS / 2;
  for (let c = bc - 3; c <= bc + 2; c++) if (H[c] !== H[bc]) problems.push('the ground under the boss is not level');

  for (const m of level.arena.minions) {
    const c = Math.floor(m.x / T.TILE);
    // A minion paces 150 each way from where it stands; keep all of that on one height.
    for (let k = c - 7; k <= c + 7; k++) if (H[k] !== H[c]) problems.push(`the minion spot at ${m.x} does not have flat ground 7 tiles either side`);
  }
  for (const p of platforms) {
    const c0 = Math.floor(p.x / T.TILE), c1 = Math.floor((p.x + p.width - 1) / T.TILE);
    for (let c = c0; c <= c1; c++) {
      if (surface(c * T.TILE) - p.y < 24 + 24) problems.push(`the platform at ${p.x} is too low over the ground beside it (the player could not get under)`);
    }
  }

  const r = solve(level, { margin: 0 });
  if (r.traps.length) problems.push(`${r.traps.length} spots can be reached but not left, first at x ${Math.round(r.traps[0].x)}`);
  const spots = r.spots;
  for (const p of platforms) {
    if (!spots.some((s) => standsOn(s, p.y, p.x, p.x + p.width))) problems.push(`the platform at ${p.x}, ${p.y} cannot be reached`);
  }
  for (const m of level.arena.minions) {
    if (!spots.some((s) => standsOn(s, m.y, m.x - 100, m.x + 100))) problems.push(`the minion spot at ${m.x} cannot be reached`);
  }
  if (!spots.some((s) => standsOn(s, boss.y, boss.x - 400, boss.x + 400))) problems.push('the ground around the boss cannot be reached');
  // At least one ledge a student can stand on out of every enemy's reach.
  const safe = platforms.filter((p) => p.y <= physics.groundSurfaceY - 100 && spots.some((s) => standsOn(s, p.y, p.x, p.x + p.width)));
  if (safe.length < 2) problems.push('there is no ledge out of the minions\' reach on each side');
  return problems;
}

function fileFor(eraId) {
  const era = eras[eraNumber(eraId) - 1];
  return path.join(OUT, `era${eraNumber(eraId)}_${era.levelWeeks.length}.tmx`);
}

function main(argv) {
  const check = argv.includes('--check');
  let bad = 0;
  for (const era of eras) {
    const level = buildArena(era.id);
    const problems = validateArena(level);
    if (problems.length) {
      bad++;
      console.log(`${era.id}: ${problems.length} problem(s)\n  ${problems.join('\n  ')}`);
      continue;
    }
    // What is written must be what was checked: read the file text back and check that.
    const xml = tmx.write(level);
    const back = tmx.read(xml);
    if (back.H.join() !== level.H.join() || !back.arena || back.arena.minions.length !== level.arena.minions.length) {
      throw new Error(`${era.id}: the written map differs from the model`);
    }
    if (!check) fs.writeFileSync(fileFor(era.id), xml);
    console.log(`${era.id}: ok  ${path.basename(fileFor(era.id))}  platforms ${level.platforms.length}  minion spots ${level.arena.minions.length}`);
  }
  if (bad) process.exit(1);
  if (!check) console.log(`manifest: ${writeManifest(OUT)} generated levels`);
}

if (require.main === module) main(process.argv.slice(2));
module.exports = { SPECS, COLS, WALL, buildArena, validateArena, fileFor };
