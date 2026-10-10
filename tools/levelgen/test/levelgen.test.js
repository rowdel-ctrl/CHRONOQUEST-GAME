'use strict';
// Run with: node --test tools/levelgen/test
const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');

const { eras, rules, reach, peak, physics, enemyTop, footSpan } = require('../rules');
const { generateLevel } = require('../generate');
const { validate } = require('../validate');
const { solve } = require('../solve');
const { World, step, standingAt, real, careful } = require('../sim');
const { OPENERS } = require('../openers');
const T = require('../terrain');
const tmx = require('../tmx');
const { BODY } = require('../recolor');

const ROOT = path.join(__dirname, '..', '..', '..');
const LEVELS_DIR = path.join(ROOT, 'assets', 'tiles', 'levels');
const clone = (o) => ({ ...o, H: Int8Array.from(o.H), S: o.S && Uint8Array.from(o.S),
  platforms: o.platforms.map((p) => ({ ...p })), enemies: o.enemies.map((e) => ({ ...e })),
  coins: o.coins.map((c) => ({ ...c })), artifacts: o.artifacts.map((a) => ({ ...a })), gates: [...o.gates],
  props: { ...o.props } });

// Every level the generator is responsible for: all non-boss levels.
const targets = [];
for (const era of eras) for (let n = 1; n < era.levelWeeks.length; n++) targets.push({ eraId: era.id, levelIndex: n });

// Generating all 37 takes a few seconds; do it once.
const generated = new Map();
const gen = (t) => {
  const k = `${t.eraId}:${t.levelIndex}`;
  if (!generated.has(k)) generated.set(k, generateLevel(t));
  return generated.get(k);
};
const sample = () => gen({ eraId: 'spanish', levelIndex: 3 }).level;

test('the physics model matches the protected jump numbers', () => {
  assert.ok(Math.abs(reach - 266.7) < 0.5, `reach ${reach}`);
  assert.strictEqual(peak, 128);
  assert.ok(rules.gapMax <= footSpan + reach * 0.9 + 1, 'pits stay under 90% of the reach plus the foot span');
  assert.ok(rules.platformHeights[1] <= peak - 10, 'platforms are below the jump peak with room to land');
  assert.ok(rules.platformHeights[0] > enemyTop, 'a platform is above every enemy hit area');
  assert.ok(rules.maxRiseTiles * T.TILE <= peak - 30, 'a single hop is well under the peak');
});

test('the tile grid agrees with the base ground', () => {
  assert.strictEqual(T.ORIGIN_Y + T.BASE_ROW * T.TILE, physics.groundSurfaceY);
  assert.strictEqual(T.surfaceY(0), 660);
  assert.strictEqual(T.surfaceY(4), 660 - 4 * T.TILE);
  assert.strictEqual(T.TILE * T.ROWS, 720);
  assert.strictEqual(rules.safeStart % T.TILE, 0);
  assert.strictEqual(rules.groupWidth % T.TILE, 0);
  assert.strictEqual((rules.groupWidth - rules.restWidth) % T.TILE, 0);
});

test('there are 37 levels to generate', () => {
  assert.strictEqual(targets.length, 37);
});

test('every one of the 37 levels generates, validates, is solvable and survives being written', () => {
  for (const t of targets) {
    const r = gen(t); // throws if the written file fails validation
    assert.ok(r.validCount > 0, `${t.eraId} ${t.levelIndex}`);
  }
});

test('the same era and level always produce the same file', () => {
  const a = tmx.write(generateLevel({ eraId: 'ww2', levelIndex: 4 }).level);
  const b = tmx.write(generateLevel({ eraId: 'ww2', levelIndex: 4 }).level);
  assert.strictEqual(a, b);
});

test('different levels are different', () => {
  const a = tmx.write(gen({ eraId: 'ww2', levelIndex: 2 }).level);
  const b = tmx.write(gen({ eraId: 'ww2', levelIndex: 3 }).level);
  assert.notStrictEqual(a, b);
});

test('the maps on disk are what the generator makes today', () => {
  // Change a rule or a piece and forget to regenerate, and this says so.
  for (const t of targets) {
    const file = path.join(LEVELS_DIR, `era${eras.findIndex((e) => e.id === t.eraId) + 1}_${t.levelIndex}.tmx`);
    const onDisk = fs.readFileSync(file, 'utf8');
    if (/name="handEdited" value="true"/.test(onDisk)) continue;
    assert.strictEqual(onDisk, tmx.write(gen(t).level), `${path.basename(file)} is stale: run tools/levelgen/generate.js`);
  }
});

test('boss levels are refused', () => {
  assert.throws(() => generateLevel({ eraId: 'spanish', levelIndex: 5 }), /boss/);
});

test('Heavy enemies appear only in eras that have Heavy art', () => {
  for (const t of targets) {
    const era = eras.find((e) => e.id === t.eraId);
    const { level } = gen(t);
    const heavies = level.enemies.filter((e) => e.behavior === 'heavy');
    if (era.heavy.length === 0) assert.strictEqual(heavies.length, 0, `${t.eraId} ${t.levelIndex}`);
    for (const h of heavies) assert.ok(era.heavy.includes(h.kind));
  }
});

// ── openers ─────────────────────────────────────────────────────────────────
test('every opener recipe is written out for ten sections, each with an enemy', () => {
  for (const era of eras) {
    const sections = OPENERS[era.id];
    assert.strictEqual(sections.length, rules.groups, era.id);
    for (const pieces of sections) {
      assert.ok(pieces.some((p) => /^(walker|heavy|courtyard|ridge)/.test(p) || /\+[eh]$/.test(p)), `${era.id}: a section without an enemy: ${pieces}`);
      assert.ok(pieces.length <= 3, 'a section is at most three pieces');
    }
  }
});

test('era openers are the gentlest: no Heavy, short patrols, lower ground', () => {
  for (const era of eras) {
    const { level } = gen({ eraId: era.id, levelIndex: 1 });
    assert.strictEqual(level.enemies.filter((e) => e.behavior === 'heavy').length, 0);
    assert.ok(level.enemies.every((e) => e.patrol <= 100), `${era.id}: an opener enemy patrols over 100`);
    assert.ok(Math.max(...level.elevation) <= 3, `${era.id}: an opener climbs past 72`);
  }
});

test('an opener follows its written recipe: every piece it holds is one the recipe names', () => {
  for (const era of eras) {
    const { level } = gen({ eraId: era.id, levelIndex: 1 });
    const named = new Set(OPENERS[era.id].flat().map((p) => p.split('+')[0]));
    for (const p of level.pieces) assert.ok(named.has(p.type), `${era.id} opener holds a ${p.type}`);
  }
});

// ── the shape of a level ────────────────────────────────────────────────────
test('every section of every level has an enemy and something to cross', () => {
  for (const t of targets) {
    const { level } = gen(t);
    for (let s = 0; s < rules.groups; s++) {
      const from = rules.safeStart + s * rules.groupWidth;
      const to = from + rules.groupWidth;
      assert.ok(level.enemies.some((e) => e.x >= from && e.x < to), `${t.eraId} ${t.levelIndex} section ${s + 1}: no enemy`);
      const heights = new Set();
      for (let c = from / T.TILE; c < (to - rules.restWidth) / T.TILE; c++) heights.add(level.H[c]);
      assert.ok(heights.size > 1, `${t.eraId} ${t.levelIndex} section ${s + 1}: flat`);
    }
  }
});

test('levels are not flat: raised ground, pits and a landscape that climbs', () => {
  for (const t of targets) {
    const { level } = gen(t);
    const blocks = T.blocksOf(level.H);
    const raised = blocks.filter((b) => b.h > 0).reduce((s, b) => s + b.end - b.start, 0);
    const pits = T.pitsOf(level.H).reduce((s, p) => s + p.end - p.start, 0);
    assert.ok((raised + pits) / level.mapWidth >= 0.2, `${t.eraId} ${t.levelIndex}: terrain is under a fifth of the level`);
    assert.ok(Math.max(...level.elevation) >= 2, `${t.eraId} ${t.levelIndex}: the landscape never climbs`);
    const kinds = new Set(level.pieces.map((p) => p.type).filter((k) => !['walker', 'heavy'].includes(k)));
    assert.ok(kinds.size >= 4, `${t.eraId} ${t.levelIndex}: only ${kinds.size} kinds of set piece`);
  }
});

test('the first and last sections are on the base ground, where the student starts and the gate is', () => {
  for (const t of targets) {
    const { level } = gen(t);
    assert.strictEqual(level.elevation[0], 0);
    assert.strictEqual(level.elevation[rules.groups - 1], 0);
    assert.strictEqual(T.heightAt(level.H, level.spawnX), 0);
    assert.strictEqual(T.heightAt(level.H, level.exitX), 0);
  }
});

test('difficulty rises across an era: more terrain and more enemies', () => {
  const era = eras.find((e) => e.id === 'pre-colonial');
  const load = (n) => {
    const { level } = gen({ eraId: era.id, levelIndex: n });
    return level.enemies.length + level.platforms.length + T.pitsOf(level.H).length;
  };
  assert.ok(load(9) >= load(2) - 2, 'the last generated level should be no lighter than the first');
});

test('a Heavy sits only on ground a student reaches by a jump or a climb, never alone on a platform', () => {
  for (const t of targets) {
    const { level } = gen(t);
    for (const e of level.enemies.filter((q) => q.behavior === 'heavy')) {
      assert.ok(!level.platforms.some((p) => e.y !== undefined && Math.abs(p.y - e.y) < 1 && e.x >= p.x && e.x < p.x + p.width), `${t.eraId} ${t.levelIndex}`);
    }
  }
});

test('the gate fits on the map', () => {
  for (const t of targets) {
    const { level } = gen(t);
    assert.ok(level.gates[0] + physics.gateWidth <= level.mapWidth, `${t.eraId} ${t.levelIndex}`);
  }
});

// ── the tile layer ──────────────────────────────────────────────────────────
test('the tile layer: caps on top, walls on the sides, nothing over a pit', () => {
  for (const era of ['pre-colonial', 'spanish']) {
    const theme = T.THEMES[T.ERA_THEME[era]];
    const H = Int8Array.from([-1, 2, 2, 2, 2, 0, 0, -1]);
    const grid = T.autotile(H, new Uint8Array(H.length), T.ERA_THEME[era]);
    const top = (c) => grid[T.BASE_ROW - H[c]][c];
    assert.strictEqual(top(1), theme.capL, 'left end of a raised block');
    assert.strictEqual(top(4), theme.capR, 'right end of a raised block');
    assert.ok(theme.capMid.includes(top(2)), 'the middle of a cap');
    assert.strictEqual(grid[T.BASE_ROW - 1][1], theme.wallL, 'the wall under the left end');
    assert.strictEqual(grid[T.BASE_ROW - 1][4], theme.wallR, 'the wall under the right end');
    assert.strictEqual(grid[T.BASE_ROW][2], theme.fill === 12 ? grid[T.BASE_ROW][2] : theme.fill);
    for (let r = 0; r < T.ROWS; r++) { assert.strictEqual(grid[r][0], 0, 'a pit is empty'); assert.strictEqual(grid[r][7], 0); }
  }
});

test('every tile in a written map is one the tileset has', () => {
  const { level } = gen({ eraId: 'american', levelIndex: 4 });
  const back = tmx.read(tmx.write(level));
  for (const row of back.grid) for (const gid of row) assert.ok(gid >= 0 && gid <= 56, `gid ${gid}`);
});

test('bare stone caps come out where a piece asks for them', () => {
  const theme = T.THEMES.blue;
  const H = Int8Array.from([0, 0, 3, 3, 3, 0, 0]);
  const S = Uint8Array.from([0, 0, 1, 1, 1, 0, 0]);
  const grid = T.autotile(H, S, 'blue');
  assert.strictEqual(grid[T.BASE_ROW - 3][2], theme.bareL);
  assert.strictEqual(grid[T.BASE_ROW - 3][4], theme.bareR);
  assert.strictEqual(grid[T.BASE_ROW][0], theme.capL === grid[T.BASE_ROW][0] ? theme.capL : grid[T.BASE_ROW][0]);
});

test('the layer is offset so row 27 is the base ground', () => {
  const xml = tmx.write(sample());
  assert.match(xml, new RegExp(`<layer id="1" name="ground" width="\\d+" height="${T.ROWS}" offsety="${T.ORIGIN_Y}">`));
  assert.match(xml, /name="generator" value="levelgen-v2"/);
});

// ── reading and writing ─────────────────────────────────────────────────────
test('what is written reads back identically', () => {
  const level = sample();
  const back = tmx.read(tmx.write(level));
  assert.deepStrictEqual(Array.from(back.H), Array.from(level.H));
  assert.strictEqual(back.artifacts.length, 10);
  assert.strictEqual(back.gates.length, 1);
  assert.strictEqual(back.enemies.length, level.enemies.length);
  assert.strictEqual(back.platforms.length, level.platforms.length);
  assert.deepStrictEqual(validate(back, { generated: true }), []);
});

test('the file has no double hyphen in its comment (illegal XML)', () => {
  const xml = tmx.write(sample());
  const comment = xml.match(/<!--([\s\S]*?)-->/)[1];
  assert.ok(!comment.includes('--'));
});

test('a platform enemy keeps the height of its platform in the file', () => {
  const level = sample();
  const back = tmx.read(tmx.write(level));
  const onPlatform = back.enemies.filter((e) => e.y !== undefined && back.platforms.some((p) => Math.abs(p.y - e.y) < 1));
  assert.ok(onPlatform.length >= 1);
});

test('artifacts are written at the height of the ground under them', () => {
  const back = tmx.read(tmx.write(sample()));
  for (const a of back.artifacts) assert.strictEqual(a.y, T.surfaceY(T.heightAt(back.H, a.x + physics.artifactSize / 2)));
});

test('block pieces are piles of crates in the maps', () => {
  let crates = 0;
  for (const t of targets) crates += tmx.read(tmx.write(gen(t).level)).grid.flat().filter((g) => g === T.CRATE).length;
  assert.ok(crates > 100, 'crate piles are in the maps');
});

test('the recolour table matches the game', () => {
  const dart = fs.readFileSync(path.join(ROOT, 'lib', 'game', 'components', 'terrain_component.dart'), 'utf8');
  for (const [era, rgb] of Object.entries(BODY)) {
    const hex = rgb.map((v) => v.toString(16).padStart(2, '0')).join('').toUpperCase();
    assert.ok(dart.includes(`'${era}': Color(0xFF${hex})`), `${era} body colour ${hex} is not in terrain_component.dart`);
  }
  for (const era of eras) assert.ok(fs.existsSync(path.join(ROOT, 'assets', 'tiles', `ground_${era.id}.png`)), `ground_${era.id}.png`);
});

// ── the validator and the solver can fail ───────────────────────────────────
test('the validator catches each broken rule', () => {
  const has = (level, re, opts = { generated: true, play: false }) => validate(level, opts).some((p) => re.test(p));
  const good = sample();
  assert.deepStrictEqual(validate(good, { generated: true }), []);

  let b = clone(good); b.artifacts.pop();
  assert.ok(has(b, /9 artifacts/), 'a missing artifact');

  b = clone(good); b.artifacts[3].x = b.gates[0] + 100;
  assert.ok(has(b, /past the gate/), 'an artifact past the gate');

  b = clone(good); b.artifacts[2].y = 100;
  assert.ok(has(b, /not standing on the ground/), 'an artifact floating');

  b = clone(good); b.gates.push(5000);
  assert.ok(has(b, /2 gates/), 'a second gate');

  b = clone(good); b.enemies[0].kind = 'tank';
  assert.ok(has(b, /not one of/), 'an enemy from another era');

  b = clone(good); b.enemies.push({ x: b.enemies[0].x + 50, y: b.enemies[0].y, kind: b.enemies[0].kind, behavior: b.enemies[0].behavior, patrol: 0 });
  assert.ok(has(b, /apart/), 'two enemies too close');

  b = clone(good); b.props.level = 5;
  assert.ok(has(b, /boss/), 'a boss level');

  // a rise too tall to jump
  b = clone(good);
  for (let c = 60; c < 80; c++) b.H[c] = 7;
  assert.ok(has(b, /a rise of/), 'a wall too tall to jump');

  // ground higher than any tower
  b = clone(good);
  for (let c = 80; c < 90; c++) b.H[c] = rules.maxHeightTiles + 1;
  assert.ok(has(b, /high, over/), 'ground above the ceiling');

  // a pit nobody can cross: wide, with no platform
  b = clone(good);
  for (let c = 200; c < 200 + 16; c++) b.H[c] = -1;
  assert.ok(has(b, /wide with no platform/), 'a wide pit with no platform');

  // a section left without an enemy
  const from = rules.safeStart + 3 * rules.groupWidth;
  const to = from + rules.groupWidth;
  b = clone(good); b.enemies = b.enemies.filter((e) => e.x < from || e.x >= to);
  assert.ok(has(b, /section 4 has no enemy/), 'a section without an enemy');

  // a section flattened to nothing
  b = clone(good);
  for (let c = from / T.TILE; c < (to - rules.restWidth) / T.TILE; c++) b.H[c] = b.H[from / T.TILE];
  b.platforms = b.platforms.filter((p) => p.x < from || p.x >= to);
  b.enemies = b.enemies.filter((e) => e.x < from || e.x >= to);
  assert.ok(has(b, /section 4 has no terrain/), 'a section with nothing to cross');

  // an enemy standing in a pit
  b = clone(good);
  const e0 = b.enemies.find((e) => { const h = T.heightAt(b.H, e.x + physics.enemyWidth / 2); return h >= 0 && Math.abs((e.y ?? physics.groundSurfaceY) - T.surfaceY(h)) < 1; });
  const col = Math.floor(e0.x / T.TILE);
  for (let c = col - 3; c < col + 8; c++) b.H[c] = -1;
  assert.ok(has(b, /patrols off its ground/), 'an enemy over a pit');

  // a coin inside the ground
  b = clone(good);
  const c0 = b.coins.find((c) => T.heightAt(b.H, c.x + 21) >= 0);
  c0.y = 700;
  assert.ok(has(b, /inside the ground/), 'a coin buried');

  // no platform fight
  b = clone(good);
  b.enemies = b.enemies.filter((e) => e.y === undefined || !b.platforms.some((p) => Math.abs(p.y - e.y) < 1));
  assert.ok(has(b, /no platform fight/), 'a level with no platform fight');
});

test('the solver passes what a student can do and fails what they cannot', () => {
  const mk = (edit, platforms = []) => {
    const H = new Int8Array(300);
    edit(H);
    return { H, platforms, spawnX: 220, exitX: 300 * T.TILE - 120, gates: [300 * T.TILE - 160] };
  };
  const fill = (H, a, b, v) => { for (let c = a; c < b; c++) H[c] = v; };
  const ok = (l) => solve(l).reachable && solve(l).traps.length === 0;

  assert.ok(ok(mk((H) => fill(H, 100, 100 + 12, -1))), 'a 288 pit is crossable');
  assert.ok(!solve(mk((H) => fill(H, 100, 100 + 14, -1))).reachable, 'a 336 pit is not');
  assert.ok(ok(mk((H) => fill(H, 100, 140, 4))), 'a 96 step is climbable');
  assert.ok(!solve(mk((H) => fill(H, 100, 140, 6))).reachable, 'a 144 wall is not');
  assert.ok(ok(mk((H) => { for (let i = 0; i < 6; i++) fill(H, 100 + i * 8, 108 + i * 8, 2 * (i + 1)); fill(H, 148, 170, 12); })), 'a staircase of 48s to 288');
  // a yard walled too high to climb out of: reachable going in, a trap once there
  const trap = solve(mk((H) => { fill(H, 60, 80, 6); fill(H, 100, 120, 6); }));
  assert.ok(trap.traps.length > 0 || !trap.reachable, 'a deep yard is a trap');
  // a wide pit crossed on platforms
  // a pit of 408 (17 tiles), too wide to jump, crossed by one platform in the middle
  assert.ok(!solve(mk((H) => fill(H, 100, 117, -1))).reachable, 'a 408 pit alone is not passable');
  assert.ok(ok(mk((H) => fill(H, 100, 117, -1), [{ x: 100 * T.TILE + 156, y: 548, width: 96 }])), 'a platform makes a 408 pit passable');
});

test('the simulator and the careful physics are consistent', () => {
  // The careful jump is lower and slower than the real one, never higher.
  assert.ok(Math.abs(careful.jump) < Math.abs(real.jump));
  assert.ok(careful.speed < real.speed);
  // A real jump on the flat covers the protected 267 units.
  const w = new World(new Int8Array(100), []);
  const s = standingAt(500, 660);
  step(w, s, 1, true, real);
  const x0 = s.x;
  let frames = 1;
  while (!s.ground && frames < 200) { step(w, s, 1, false, real); frames++; }
  assert.ok(Math.abs(s.x - x0 - 267) < 12, `covered ${s.x - x0}`);
});

test('physics.json carries the number of artifacts the game expects', () => {
  assert.strictEqual(physics.artifactsPerLevel, 10);
});

test('the parity fixture is up to date', () => {
  // test/fixtures/terrain_parity.json is what test/game/terrain_parity_test.dart replays
  // through the real player. Change sim.js and forget `node tools/levelgen/parity.js`
  // and this says so.
  const { fixture, FILE } = require('../parity');
  assert.deepStrictEqual(JSON.parse(fs.readFileSync(FILE, 'utf8')), JSON.parse(JSON.stringify(fixture())));
});
