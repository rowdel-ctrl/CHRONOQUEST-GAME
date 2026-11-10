#!/usr/bin/env node
'use strict';
// The six boss arenas: one fixed room per era, 76 tiles (1824 units) wide so a phone at the widest
// aspect the game allows (2.5:1, 1800 units) still sees only the arena. Each is described once, for
// its left half, and mirrored, so the two sides of the fight are fair.
//
//   node tools/levelgen/arenas.js              write assets/tiles/levels/era<N>_<boss>.tmx and the manifest
//   node tools/levelgen/arenas.js --check      only check them
//
// Every arena has the same plan ("towers and a stage"), dressed in the era's own obstacle:
//   * a STAGE in the exact middle for the boss: ground 2 tiers (48) above the base, with a top 14 tiles
//     wide (the boss paces 100 each side of its place and is 120 wide) and a one-tile step down each side;
//   * on each side a TOWER of two platforms: P1 about 104 above the ground beside it (a plain jump), P2
//     another 104 above P1, too high to reach from the ground, so you climb via P1;
//   * `minion_spawn` spots on the ground in front of the towers, two a side, never on a platform;
//   * `scroll_spot` objects, one on top of each P2: the question scroll appears there (x is the platform's
//     centre, y its top surface, written like a `minion_spawn`);
//   * a start, no gate and no exit: the level ends when the boss is beaten. Two walls (7 tiles high, past a
//     jump's 5.3 tiles) close the sides.
// Before a map is written the solver (solve.js) plays it: every platform, every minion spot, every scroll
// spot and the ground around the boss must be reachable, no scroll spot may be reachable from the ground in
// a single jump, and nothing may be a place you can reach but not leave.
const fs = require('fs');
const path = require('path');
const { physics, rules, eras, eraNumber } = require('./rules');
const T = require('./terrain');
const tmx = require('./tmx');
const { solve } = require('./solve');
const { real } = require('./sim');
const { writeManifest } = require('./generate');

const COLS = 76;
const WALL = 7; // tiles; 168 units, over the 128-unit jump peak
const STAGE_TIERS = 2; // the boss stands this many tiles (24 units each) above the base ground
const STAGE_HALF = 7; // columns of stage top each side of the middle: 14 in all (336 units)
const STAGE_MIN_TOP = 14; // the narrowest stage top allowed, in columns
const TOWER_COLS = 5; // every tower platform is 5 tiles wide
const TOWER_STEP = 104; // P1 over the ground, P2 over P1: rules.platformHeights[0], out of every minion's reach
const MINION_SPACING = 4; // columns between the two minion spots of a side
const OUT = path.join(__dirname, '..', '..', 'assets', 'tiles', 'levels');

// Left half, 38 columns. `left` gives columns 0 to 29 as runs of [columns, height]; -1 is a pit. The last
// 8 columns are the stage and are added by buildArena: one step (STAGE_TIERS - 1) and STAGE_HALF columns of
// top. `towers` are the first columns of P1 and P2 (P2 sits nearer the stage). `startCol` and `minions`
// are columns of the left half; the right half is the mirror image.
//
// The obstacle of each era sits in columns 8 to 12 so the ground from column 13 to the stage is flat: a
// minion paces 150 (6 tiles) each way and stays on one height, so its spot needs 6 flat columns either
// side (columns 19 and 23 are the first and last that have them).
const SPECS = {
  // Bakunawa, on a shore: a tide pool by each wall.
  'pre-colonial': {
    left: [[2, WALL], [6, 0], [5, -1], [17, 0]],
    towers: [18, 25], startCol: 5, minions: [19, 23],
  },
  // The Governor in the courtyard of a fort: a bastion at each end.
  spanish: {
    left: [[2, WALL], [6, 0], [1, 1], [3, 2], [1, 1], [17, 0]],
    towers: [18, 25], startCol: 5, minions: [19, 23],
  },
  // The plaza bowl: start on the high terrace and drop in.
  nationalism: {
    left: [[2, WALL], [8, 2], [3, 1], [17, 0]],
    towers: [18, 25], startCol: 5, minions: [19, 23],
  },
  // The trench line: a sandbag mound with a trench behind it.
  american: {
    left: [[2, WALL], [6, 0], [2, 1], [2, 0], [1, 1], [17, 0]],
    towers: [18, 25], startCol: 5, minions: [19, 23],
  },
  // The broken bridge: a gap over water and the stump of the bridge beyond it.
  ww2: {
    left: [[2, WALL], [6, 0], [4, -1], [1, 1], [17, 0]],
    towers: [18, 25], startCol: 5, minions: [19, 23],
  },
  // The palace steps: a short staircase up, then down to the courtyard.
  modern: {
    left: [[2, WALL], [6, 0], [2, 1], [3, 2], [17, 0]],
    towers: [18, 25], startCol: 5, minions: [19, 23],
  },
};

function expand(runs) {
  return runs.reduce((a, [n, h]) => a.concat(Array(n).fill(h)), []);
}

const mirrorCol = (c) => COLS - 1 - c;

function buildArena(eraId) {
  const spec = SPECS[eraId];
  const left = expand(spec.left);
  const stageCols = 1 + STAGE_HALF;
  if (left.length !== COLS / 2 - stageCols) throw new Error(`${eraId}: the left half has ${left.length} columns before the stage, not ${COLS / 2 - stageCols}`);
  left.push(STAGE_TIERS - 1, ...Array(STAGE_HALF).fill(STAGE_TIERS));
  const H = Int8Array.from([...left, ...[...left].reverse()]);

  // A platform is out of every minion's reach: a student standing on it is above the
  // 99.9 a minion's hit area reaches from the highest ground beside it (playtest 2026-10-26:
  // 'some platforms still reach you without jumping'; tiers 2 to 4 are 48 to 96 up). Anything
  // lower is lifted to 104 above that ground, the same height the generated levels use.
  const platformY = (col, cols, tiers) => {
    let top = Infinity;
    for (let c = Math.max(0, col - 4); c <= Math.min(COLS - 1, col + cols + 3); c++) top = Math.min(top, T.surfaceY(H[c]));
    return Math.min(tier(tiers), top - rules.platformHeights[0]);
  };
  const tier = (n) => physics.groundSurfaceY - n * T.TILE; // top of a platform n tiles above the base ground

  // The tower: P1 over the ground beside it, P2 a step above P1 (never lower than the platform rule).
  const [c1, c2] = spec.towers;
  const y1 = platformY(c1, TOWER_COLS, 0);
  const y2 = Math.min(y1 - TOWER_STEP, platformY(c2, TOWER_COLS, 0));
  const platforms = [];
  const scrolls = [];
  for (const [col, y] of [[c1, y1], [c2, y2]]) {
    platforms.push({ x: col * T.TILE, y, width: TOWER_COLS * T.TILE });
    platforms.push({ x: mirrorCol(col + TOWER_COLS - 1) * T.TILE, y, width: TOWER_COLS * T.TILE });
  }
  for (const p of platforms) if (p.y === y2) scrolls.push({ x: p.x + p.width / 2, y: p.y });
  platforms.sort((a, b) => a.x - b.x);
  scrolls.sort((a, b) => a.x - b.x);

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
    arena: { boss: { x: bossX, y: surface(COLS / 2) }, minions, scrolls },
  };
}

// ── checks ──────────────────────────────────────────────────────────────────

const standsOn = (spot, y, x0, x1) => Math.abs(spot.top - y) < 1 && spot.x + 48 >= x0 && spot.x + 48 <= x1;
const onPlatform = (o, p) => Math.abs(o.y - p.y) < 1 && o.x >= p.x && o.x <= p.x + p.width;

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

  // The stage: the boss's ground is a wide top, at least 2 tiers above the base ground.
  let l = bc - 1, r = bc;
  while (l > 0 && H[l - 1] === H[bc]) l--;
  while (r < COLS - 1 && H[r + 1] === H[bc]) r++;
  const top = r - l + 1;
  if (top < STAGE_MIN_TOP) problems.push(`the stage top is ${top} tiles wide, under ${STAGE_MIN_TOP} (the boss would walk off it)`);
  if (H[bc] < STAGE_TIERS) problems.push(`the stage is ${H[bc]} tiles high, under ${STAGE_TIERS}`);
  if (Math.abs(boss.y - T.surfaceY(H[bc])) > 1) problems.push('the boss is not on the stage surface');

  const minions = level.arena.minions;
  for (const m of minions) {
    const c = Math.floor(m.x / T.TILE);
    // A minion paces 150 each way from where it stands; keep all of that on one height.
    for (let k = c - 6; k <= c + 6; k++) if (H[k] !== H[c]) problems.push(`the minion spot at ${m.x} does not have flat ground 6 tiles either side`);
    if (Math.abs(m.y - surface(m.x)) > 1) problems.push(`the minion spot at ${m.x} is not on the ground`);
    if (platforms.some((p) => onPlatform(m, p))) problems.push(`the minion spot at ${m.x} is on a platform`);
  }
  for (const p of platforms) {
    const c0 = Math.floor(p.x / T.TILE), c1 = Math.floor((p.x + p.width - 1) / T.TILE);
    for (let c = c0; c <= c1; c++) {
      if (surface(c * T.TILE) - p.y < 24 + 24) problems.push(`the platform at ${p.x} is too low over the ground beside it (the player could not get under)`);
    }
  }

  const r0 = solve(level, { margin: 0 });
  if (r0.traps.length) problems.push(`${r0.traps.length} spots can be reached but not left, first at x ${Math.round(r0.traps[0].x)}`);
  const spots = r0.spots;
  for (const p of platforms) {
    if (!spots.some((s) => standsOn(s, p.y, p.x, p.x + p.width))) problems.push(`the platform at ${p.x}, ${p.y} cannot be reached`);
  }
  for (const m of minions) {
    if (!spots.some((s) => standsOn(s, m.y, m.x - 100, m.x + 100))) problems.push(`the minion spot at ${m.x} cannot be reached`);
  }
  if (!spots.some((s) => standsOn(s, boss.y, boss.x - 400, boss.x + 400))) problems.push('the ground around the boss cannot be reached');

  // The scroll spots: on a platform top, reachable, and not in one jump from the ground (the real jump,
  // a little higher than the one the solver assumes, played with only that platform on the map).
  const scrolls = level.arena.scrolls || [];
  if (scrolls.length < 2) problems.push(`there are ${scrolls.length} scroll spots, not one on each side`);
  for (const s of scrolls) {
    const p = platforms.find((q) => onPlatform(s, q));
    if (!p) { problems.push(`the scroll spot at ${s.x}, ${s.y} is not on a platform top`); continue; }
    if (!spots.some((q) => standsOn(q, p.y, p.x, p.x + p.width))) { problems.push(`the scroll spot at ${s.x} cannot be reached`); continue; }
    const alone = solve({ ...level, platforms: [p] }, { phys: real, margin: 0 });
    if (alone.spots.some((q) => standsOn(q, p.y, p.x, p.x + p.width))) problems.push(`the scroll spot at ${s.x} can be reached from the ground in one jump`);
  }

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
    if (back.H.join() !== level.H.join() || !back.arena || back.arena.minions.length !== level.arena.minions.length ||
        JSON.stringify(back.arena.scrolls) !== JSON.stringify(level.arena.scrolls)) {
      throw new Error(`${era.id}: the written map differs from the model`);
    }
    if (!check) fs.writeFileSync(fileFor(era.id), xml);
    console.log(`${era.id}: ok  ${path.basename(fileFor(era.id))}  platforms ${level.platforms.length}  minion spots ${level.arena.minions.length}  scroll spots ${level.arena.scrolls.length}`);
  }
  if (bad) process.exit(1);
  if (!check) console.log(`manifest: ${writeManifest(OUT)} generated levels`);
}

if (require.main === module) main(process.argv.slice(2));
module.exports = { SPECS, COLS, WALL, STAGE_MIN_TOP, buildArena, validateArena, fileFor };
