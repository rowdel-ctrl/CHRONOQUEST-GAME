'use strict';
// Run with: node --test tools/levelgen/test
const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');

const { eras, rules, reach, peak, physics, enemyTop, footSpan } = require('../rules');
const { generateLevel } = require('../generate');
const { validate } = require('../validate');
const tmx = require('../tmx');

const LEVELS_DIR = path.join(__dirname, '..', '..', '..', 'assets', 'tiles', 'levels');
const clone = (o) => JSON.parse(JSON.stringify(o));

// Every level the generator is responsible for: all non-boss levels. (Pre-colonial 1
// started as a hand-built prototype and was replaced by a generated opener; the
// old map is kept as test/fixtures/hand_built_level.tmx.)
const targets = [];
for (const era of eras) {
  for (let n = 1; n < era.levelWeeks.length; n++) targets.push({ eraId: era.id, levelIndex: n });
}

const sample = () => generateLevel({ eraId: 'spanish', levelIndex: 3 }).level;

test('the physics model matches the protected jump numbers', () => {
  assert.ok(Math.abs(reach - 266.7) < 0.5, `reach ${reach}`);
  assert.strictEqual(peak, 128);
  assert.ok(rules.gapMax <= footSpan + reach * 0.9 + 1, 'gaps stay under 90% of the reach plus the foot span');
  assert.ok(rules.platformHeights[1] <= peak - 10, 'platforms are below the jump peak with room to land');
  assert.ok(rules.platformHeights[0] > enemyTop, 'a platform is above every enemy hit area');
});

test('there are 37 levels to generate', () => {
  assert.strictEqual(targets.length, 37);
});

test('every one of the 37 levels generates, validates and survives being written', () => {
  for (const t of targets) {
    const r = generateLevel(t); // throws if the written file fails validation
    assert.ok(r.validCount > 0, `${t.eraId} ${t.levelIndex}`);
  }
});

test('the same era and level always produce the same file', () => {
  const a = tmx.write(generateLevel({ eraId: 'ww2', levelIndex: 4 }).level);
  const b = tmx.write(generateLevel({ eraId: 'ww2', levelIndex: 4 }).level);
  assert.strictEqual(a, b);
});

test('different levels are different', () => {
  const a = tmx.write(generateLevel({ eraId: 'ww2', levelIndex: 2 }).level);
  const b = tmx.write(generateLevel({ eraId: 'ww2', levelIndex: 3 }).level);
  assert.notStrictEqual(a, b);
});

test('boss levels are refused', () => {
  assert.throws(() => generateLevel({ eraId: 'spanish', levelIndex: 5 }), /boss/);
});

test('Heavy enemies appear only in eras that have Heavy art', () => {
  for (const t of targets) {
    const era = eras.find((e) => e.id === t.eraId);
    const { level } = generateLevel(t);
    const heavies = level.enemies.filter((e) => e.behavior === 'heavy');
    if (era.heavy.length === 0) assert.strictEqual(heavies.length, 0, `${t.eraId} ${t.levelIndex}`);
    for (const h of heavies) assert.ok(era.heavy.includes(h.kind));
  }
});

test('era openers are the gentlest: no Heavy, short patrols, a lighter ramp', () => {
  for (const era of eras.slice(1)) {
    const { level } = generateLevel({ eraId: era.id, levelIndex: 1 });
    assert.strictEqual(level.enemies.filter((e) => e.behavior === 'heavy').length, 0);
    assert.ok(level.enemies.every((e) => e.patrol <= 100), `${era.id}: an opener enemy patrols over 100`);
  }
});

// Playtest: levels felt empty. Every section of every generated level now has a
// gap with a platform and an enemy; the extra elements in the middle sections
// are what make a level harder than the one before it.
test('every section of every generated level has a gap with a platform and an enemy', () => {
  for (const t of targets) {
    const { level } = generateLevel(t);
    for (let s = 0; s < rules.groups; s++) {
      const from = rules.safeStart + s * rules.groupWidth;
      const to = from + rules.groupWidth;
      const gaps = level.gaps.filter((g) => g.start >= from && g.start < to);
      const withPlatform = gaps.filter((g) => level.platforms.some((p) => p.x < g.end && p.x + p.width > g.start));
      const enemies = level.enemies.filter((e) => e.x >= from && e.x < to);
      assert.ok(withPlatform.length >= 1, `${t.eraId} ${t.levelIndex} section ${s + 1}: no gap with a platform`);
      assert.ok(enemies.length >= 1, `${t.eraId} ${t.levelIndex} section ${s + 1}: no enemy`);
    }
  }
});

test('a generated level has at least 10 gaps and 10 enemies', () => {
  for (const t of targets) {
    const { level } = generateLevel(t);
    assert.ok(level.gaps.length >= 10, `${t.eraId} ${t.levelIndex}: ${level.gaps.length} gaps`);
    assert.ok(level.enemies.length >= 10, `${t.eraId} ${t.levelIndex}: ${level.enemies.length} enemies`);
  }
});

test('difficulty rises across an era', () => {
  const era = eras.find((e) => e.id === 'pre-colonial');
  const obstacles = (n) => {
    const { level } = generateLevel({ eraId: era.id, levelIndex: n });
    return level.gaps.length + level.enemies.length;
  };
  assert.ok(obstacles(9) > obstacles(2), 'the last generated level should be harder than the first');
});

test('what is written reads back identically', () => {
  const level = sample();
  const back = tmx.read(tmx.write(level));
  assert.deepStrictEqual(back.gaps, level.gaps);
  assert.strictEqual(back.artifacts.length, 10);
  assert.strictEqual(back.gates.length, 1);
  assert.strictEqual(back.enemies.length, level.enemies.length);
  assert.deepStrictEqual(validate(back, { generated: true }), []);
});

test('the file has no double hyphen in its comment (illegal XML)', () => {
  const xml = tmx.write(sample());
  const comment = xml.match(/<!--([\s\S]*?)-->/)[1];
  assert.ok(!comment.includes('--'));
});

test('the writer refuses a gap that is not on the tile grid', () => {
  // This silently dropped ground columns once; it must now fail loudly.
  const bad = sample();
  bad.gaps[0] = { start: bad.gaps[0].start + 8, end: bad.gaps[0].end + 8 };
  assert.throws(() => tmx.write(bad), /tile grid/);
});

test('the validator accepts the hand-built reference level', () => {
  const xml = fs.readFileSync(path.join(__dirname, '..', '..', '..', 'test', 'fixtures', 'hand_built_level.tmx'), 'utf8');
  assert.deepStrictEqual(validate(tmx.read(xml), { generated: false }), []);
});

// The validator is only worth trusting if it can fail.
test('the validator catches each broken rule', () => {
  const has = (level, re) => validate(level, { generated: true }).some((p) => re.test(p));
  const good = sample();
  assert.deepStrictEqual(validate(good, { generated: true }), []);

  let b = clone(good); b.gaps[0].end = b.gaps[0].start + 336;
  assert.ok(has(b, /gap at/), 'a gap wider than the jump');

  b = clone(good); b.platforms[0].y = 660 - 130;
  assert.ok(has(b, /platform at .* above ground/), 'a platform too high');

  b = clone(good); b.platforms[0].x = 100;
  assert.ok(has(b, /not over a gap/), 'a platform over solid ground');

  b = clone(good); b.artifacts.pop();
  assert.ok(has(b, /9 artifacts/), 'a missing artifact');

  b = clone(good); b.artifacts[3].x = b.gates[0] + 100;
  assert.ok(has(b, /past the gate/), 'an artifact past the gate');

  b = clone(good); b.gates.push(5000);
  assert.ok(has(b, /2 gates/), 'a second gate');

  b = clone(good); b.enemies[0].x = b.gaps[0].start + 8;
  assert.ok(has(b, /patrols off its ground/), 'an enemy standing in a gap');

  b = clone(good); b.enemies[0].kind = 'tank';
  assert.ok(has(b, /not one of/), 'an enemy from another era');

  b = clone(good); b.enemies.push({ x: b.enemies[0].x + 50, kind: b.enemies[0].kind, behavior: 'walker', patrol: 60 });
  assert.ok(has(b, /apart/), 'two enemies too close');

  b = clone(good); b.enemies[0].x = b.artifacts[0].x - 60; b.enemies[0].patrol = 60;
  assert.ok(has(b, /of the artifact at/), 'a patrol beside an artifact');

  b = clone(good); b.coins.push({ x: b.gaps[0].start + 40, y: 620 });
  assert.ok(has(b, /coin at/), 'a coin over a gap');

  b = clone(good); b.props.level = 5;
  assert.ok(has(b, /boss/), 'a boss level');

  b = clone(good); b.gaps[0] = { start: b.gaps[0].start + 8, end: b.gaps[0].end + 8 };
  assert.ok(has(b, /tile-aligned/), 'a gap off the tile grid');

  // An enemy guarding a ledge: its patrol ends 40 short of the gap.
  b = clone(good);
  b.enemies.push({ x: b.gaps[0].start - 40 - physics.enemyWidth, kind: b.enemies[0].kind, behavior: 'walker', patrol: 0 });
  assert.ok(has(b, /of the gap at/), 'an enemy right at a ledge');

  // A section left bare.
  const from = rules.safeStart + 3 * rules.groupWidth;
  const to = from + rules.groupWidth;
  b = clone(good); b.enemies = b.enemies.filter((e) => e.x < from || e.x >= to);
  assert.ok(has(b, /section 4 has no enemy/), 'a section without an enemy');

  b = clone(good);
  b.gaps = b.gaps.filter((g) => g.start < from || g.start >= to);
  b.platforms = b.platforms.filter((p) => p.x < from || p.x >= to);
  assert.ok(has(b, /section 4 has no gap with a platform/), 'a section without a gap');

  // A platformless gap does not count as "a gap with a platform".
  b = clone(good);
  b.platforms = b.platforms.filter((p) => p.x < from || p.x >= to);
  assert.ok(has(b, /section 4 has no gap with a platform/), 'a section whose gap has no platform');
});

test('physics.json carries the number of artifacts the game expects', () => {
  assert.strictEqual(physics.artifactsPerLevel, 10);
});

// ── platform fights ──────────────────────────────────────────────────────────
const fightGaps = (level) => level.gaps.filter((g) => g.end - g.start > rules.gapMax);
const guardOf = (level, g) => {
  const p = level.platforms.find((q) => q.x < g.end && q.x + q.width > g.start);
  return { p, e: level.enemies.find((e) => e.y !== undefined && Math.abs(e.y - p.y) < 1 && e.x >= p.x && e.x < p.x + p.width) };
};

test('every generated level has a platform fight, and an opener has exactly one', () => {
  for (const t of targets) {
    const { level } = generateLevel(t);
    const n = fightGaps(level).length;
    assert.ok(n >= 1, `${t.eraId} ${t.levelIndex}: no platform fight`);
    if (t.levelIndex === 1) assert.strictEqual(n, 1, `${t.eraId} opener`);
    assert.ok(n <= 3, `${t.eraId} ${t.levelIndex}: ${n} fights`);
  }
});

test('a fight is a gap no jump can cross, with a wide platform and one walker on it', () => {
  for (const t of targets) {
    const { level } = generateLevel(t);
    for (const g of fightGaps(level)) {
      const w = g.end - g.start;
      assert.ok(rules.fightGaps.includes(w), `${t.eraId} ${t.levelIndex}: ${w}`);
      assert.ok(w - footSpan > reach, 'the platform is required');
      const { p, e } = guardOf(level, g);
      assert.ok(p.width >= rules.fightPlatformWidth);
      assert.ok(e, 'an enemy stands on the platform');
      assert.strictEqual(e.behavior, 'walker');
      assert.ok(e.y < physics.groundSurfaceY - 1, 'its feet are on the platform, above the ground');
      assert.ok(g.start >= rules.safeStart + rules.fightFirstSection * rules.groupWidth, 'not in the first two sections');
    }
  }
});

test('the written file keeps a platform enemy at the height of its platform', () => {
  const level = sample();
  const back = tmx.read(tmx.write(level));
  const onPlatform = back.enemies.filter((e) => e.y < physics.groundSurfaceY - 1);
  assert.strictEqual(onPlatform.length, fightGaps(level).length);
  for (const e of onPlatform) assert.ok(back.platforms.some((p) => Math.abs(p.y - e.y) < 1));
});

test('the gate fits on the map', () => {
  for (const t of targets) {
    const { level } = generateLevel(t);
    assert.ok(level.gates[0] + physics.gateWidth <= level.mapWidth, `${t.eraId} ${t.levelIndex}`);
  }
});

test('the validator catches each broken fight rule', () => {
  const has = (level, re) => validate(level, { generated: true }).some((p) => re.test(p));
  const good = sample();
  assert.deepStrictEqual(validate(good, { generated: true }), []);
  const g0 = fightGaps(good)[0];
  const { p, e } = guardOf(good, g0);

  let b = clone(good);
  b.enemies = b.enemies.filter((x) => !(x.y !== undefined && Math.abs(x.y - p.y) < 1 && x.x >= p.x && x.x < p.x + p.width));
  assert.ok(has(b, /has 0 enemies, expected 1/), 'a fight with no enemy');

  b = clone(good);
  const q = b.platforms.find((x) => x.x === p.x);
  q.width = 96;
  assert.ok(has(b, /under 240/), 'a platform too narrow');

  b = clone(good);
  const gg = fightGaps(b)[0];
  gg.end = gg.start + 336;
  assert.ok(has(b, /not a fight gap/), 'a gap that is neither a jump nor a listed fight width');

  b = clone(good);
  b.enemies.find((x) => x.x === e.x).patrol = 140;
  assert.ok(has(b, /patrols off its ground/), 'a patrol that leaves the platform');

  b = clone(good);
  b.enemies.find((x) => x.x === e.x).y = physics.groundSurfaceY - 40;
  assert.ok(has(b, /patrols off its ground/), 'an enemy at a height with no platform');

  b = clone(good);
  b.gates[0] = b.mapWidth - 40;
  assert.ok(has(b, /runs off the end of the map/), 'a gate past the end of the map');

  b = clone(good);
  b.gaps = b.gaps.filter((x) => x.end - x.start <= rules.gapMax);
  b.platforms = b.platforms.filter((x) => b.gaps.some((y) => x.x < y.end && x.x + x.width > y.start));
  b.enemies = b.enemies.filter((x) => x.y === undefined || x.y >= physics.groundSurfaceY - 1);
  assert.ok(has(b, /no platform fight/), 'a level with no fight');
});
