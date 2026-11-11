'use strict';
// Run with: node --test tools/levelgen/test
// The surprises (hoppers, throwers, the golden runner, ground pops, falling rocks): the
// ladder, the placement rules, that the in-place script is idempotent and agrees with the
// generator, and that the checker catches each unfair placement.
const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');

const { eras, eraNumber } = require('../rules');
const tmx = require('../tmx');
const { validate } = require('../validate');
const S = require('../surprises');
const { markText } = require('../mark_surprises');
const { generateLevel } = require('../generate');

const LEVELS_DIR = path.join(__dirname, '..', '..', '..', 'assets', 'tiles', 'levels');
const fileFor = (eraId, n) => path.join(LEVELS_DIR, `era${eraNumber(eraId)}_${n}.tmx`);
const lf = (s) => s.replace(/\r\n/g, '\n');
const targets = [];
for (const era of eras) for (let n = 1; n < era.levelWeeks.length; n++) targets.push({ eraId: era.id, n });

test('the ladder: hopper 4, ground pop 5, falling rock 6, thrower 7, golden runner 8', () => {
  assert.deepStrictEqual(S.LADDER, { hopper: 4, pop: 5, rock: 6, thrower: 7, golden: 8 });
  assert.deepStrictEqual(S.planFor(3), { hoppers: false, pops: 0, rocks: 0, throwers: false, golden: 0 });
  assert.strictEqual(S.planFor(4).hoppers, true);
  assert.strictEqual(S.planFor(4).pops, 0);
  assert.strictEqual(S.planFor(5).pops, 2);
  assert.strictEqual(S.planFor(5).rocks, 0);
  assert.strictEqual(S.planFor(6).rocks, 3);
  assert.strictEqual(S.planFor(6).throwers, false);
  assert.strictEqual(S.planFor(7).throwers, true);
  assert.strictEqual(S.planFor(7).golden, 0);
  assert.strictEqual(S.planFor(8).golden, 1);
  assert.strictEqual(S.planFor(9).golden, 1);
});

test('levels 1 to 3 and the boss rooms carry no surprise at all', () => {
  for (const t of targets.filter((q) => q.n <= 3)) {
    const level = tmx.read(fs.readFileSync(fileFor(t.eraId, t.n), 'utf8'));
    assert.strictEqual(level.surprises.length, 0, `${t.eraId} ${t.n}`);
    assert.ok(!level.enemies.some((e) => ['hopper', 'thrower', 'golden'].includes(e.behavior)), `${t.eraId} ${t.n}`);
  }
  for (const era of eras) {
    const text = fs.readFileSync(fileFor(era.id, era.levelWeeks.length), 'utf8');
    assert.ok(!/ground_pop|falling_rock|value="(hopper|thrower|golden)"/.test(text), `${era.id} boss`);
  }
});

test('every map on disk has its surprises, placed fairly, and still passes the whole validator (the solver too)', () => {
  for (const t of targets) {
    const level = tmx.read(fs.readFileSync(fileFor(t.eraId, t.n), 'utf8'));
    assert.deepStrictEqual(S.checkSurprises(level), [], `${t.eraId} ${t.n}`);
    assert.deepStrictEqual(validate(level, { generated: true }), [], `${t.eraId} ${t.n}`);
    if (t.n >= 5) assert.ok(level.surprises.some((s) => s.type === 'ground_pop'), `${t.eraId} ${t.n} has a ground pop`);
    if (t.n >= 6) assert.ok(level.surprises.some((s) => s.type === 'falling_rock'), `${t.eraId} ${t.n} has a falling rock`);
    if (t.n >= 4) assert.ok(level.enemies.some((e) => e.behavior === 'hopper'), `${t.eraId} ${t.n} has a hopper`);
  }
});

test('the maps hold what the era can: a thrower only where there is a heavy, the golden runner in the first era', () => {
  const kinds = (t, b) => tmx.read(fs.readFileSync(fileFor(t.eraId, t.n), 'utf8')).enemies.filter((e) => e.behavior === b);
  const throwers = targets.filter((t) => kinds(t, 'thrower').length);
  assert.ok(throwers.length >= 1);
  for (const t of throwers) {
    const heavy = eras.find((e) => e.id === t.eraId).heavy;
    assert.ok(t.n >= 7 && heavy.length > 0, `${t.eraId} ${t.n}`);
    for (const e of kinds(t, 'thrower')) assert.ok(heavy.includes(e.kind));
  }
  const golden = targets.filter((t) => kinds(t, 'golden').length);
  assert.ok(golden.length >= 1);
  for (const t of golden) {
    assert.ok(t.n >= 8, `${t.eraId} ${t.n}`);
    assert.strictEqual(kinds(t, 'golden').length, 1, 'at most one golden runner a level');
  }
});

test('the script is idempotent: a second run changes nothing', () => {
  for (const t of targets) {
    const text = fs.readFileSync(fileFor(t.eraId, t.n), 'utf8');
    const r = markText(text, t.eraId, t.n);
    assert.strictEqual(r.changed, false, `${t.eraId} ${t.n}`);
    assert.strictEqual(r.text, text);
  }
});

test('the script keeps line endings and objects it does not know', () => {
  const t = { eraId: 'pre-colonial', n: 6 };
  const text = lf(fs.readFileSync(fileFor(t.eraId, t.n), 'utf8'));
  // Take the surprises away, add an object of an unknown kind, and let the script put them back.
  const stripped = text.replace(/ {2}<object id="\d+" type="(ground_pop|falling_rock)"[^>]*\/>\n/g, '')
    .replace(/value="hopper"/g, 'value="walker"')
    .replace('  <object id="1"', '  <object id="900" type="portal" x="5000" y="600"/>\n  <object id="1"');
  const a = markText(stripped, t.eraId, t.n);
  assert.strictEqual(a.changed, true);
  assert.ok(a.text.includes('type="portal"'), 'the unknown object stays');
  assert.ok(/type="falling_rock"/.test(a.text) && /type="ground_pop"/.test(a.text));
  assert.ok(!a.text.includes('\r\n'));
  const crlf = markText(stripped.replace(/\n/g, '\r\n'), t.eraId, t.n);
  assert.strictEqual(crlf.text, a.text.replace(/\n/g, '\r\n'), 'the same with CRLF line endings');
  // Ids run 1, 2, 3 ... in file order and nextobjectid follows.
  const ids = [...a.text.matchAll(/<object id="(\d+)"/g)].map((m) => Number(m[1]));
  assert.deepStrictEqual(ids, ids.map((_, i) => i + 1));
  assert.match(a.text, new RegExp(`nextobjectid="${ids.length + 1}"`));
});

test('what the generator makes for a level is the text the script writes', () => {
  for (const t of [{ eraId: 'pre-colonial', n: 8 }, { eraId: 'ww2', n: 7 }, { eraId: 'spanish', n: 4 }]) {
    const onDisk = lf(fs.readFileSync(fileFor(t.eraId, t.n), 'utf8'));
    assert.strictEqual(tmx.write(generateLevel({ eraId: t.eraId, levelIndex: t.n }).level), onDisk, `${t.eraId} ${t.n}`);
  }
});

test('marking is a pure function of the level: the same level always gets the same surprises', () => {
  const read = () => tmx.read(fs.readFileSync(fileFor('pre-colonial', 9), 'utf8'));
  const a = read(), b = read();
  S.markSurprises(a, 'pre-colonial', 9);
  S.markSurprises(b, 'pre-colonial', 9);
  assert.deepStrictEqual(a.surprises, b.surprises);
  assert.deepStrictEqual(a.enemies.map((e) => e.behavior), b.enemies.map((e) => e.behavior));
  // Marking a level too early takes every mark off again.
  const c = read();
  const r = S.markSurprises(c, 'pre-colonial', 3);
  assert.deepStrictEqual(r, { hoppers: 0, golden: 0, throwers: 0, pops: 0, rocks: 0 });
  assert.strictEqual(c.surprises.length, 0);
  assert.ok(!c.enemies.some((e) => ['hopper', 'golden', 'thrower'].includes(e.behavior)));
});

test('a chaser is never made a hopper', () => {
  const level = tmx.read(fs.readFileSync(fileFor('spanish', 4), 'utf8'));
  const chasersBefore = level.enemies.filter((e) => e.behavior === 'chaser').length;
  assert.ok(chasersBefore > 0);
  S.markSurprises(level, 'spanish', 4);
  assert.strictEqual(level.enemies.filter((e) => e.behavior === 'chaser').length, chasersBefore);
});

test('the checker catches each unfair placement', () => {
  const base = () => tmx.read(fs.readFileSync(fileFor('pre-colonial', 9), 'utf8'));
  const has = (level, re) => S.checkSurprises(level).some((p) => re.test(p));
  assert.deepStrictEqual(S.checkSurprises(base()), []);

  let l = base();
  l.props.level = 3;
  assert.ok(has(l, /first allowed in level/), 'a surprise in level 3');

  l = base();
  l.surprises.push({ type: 'falling_rock', x: l.spawnX + 100, y: 660 });
  assert.ok(has(l, /within 400 of the start/));

  l = base();
  l.surprises.push({ type: 'falling_rock', x: l.gates[0] - 50, y: 660 });
  assert.ok(has(l, /within 400 of the gate/));

  l = base();
  l.surprises[0] = { ...l.surprises[0], y: l.surprises[0].y - 24 };
  assert.ok(has(l, /the ground there is/), 'a rock floating above the ground');

  l = base();
  const rock = l.surprises.find((s) => s.type === 'falling_rock');
  l.artifacts.push({ x: rock.x - 100, y: 660, art: 'artifact_1' });
  assert.ok(has(l, /from the artifact/), 'a rock by an artifact');

  l = base();
  l.platforms.push({ x: rock.x - 40, y: 540, width: 96 });
  assert.ok(has(l, /from the platform/), 'a rock by a platform landing');

  l = base();
  l.surprises.push({ type: 'falling_rock', x: rock.x + 100, y: rock.y });
  assert.ok(has(l, /apart/), 'two spots on one screen');

  l = base();
  l.surprises.push({ type: 'ground_pop', x: 0, y: 660 }, { type: 'ground_pop', x: 100000, y: 660 }, { type: 'ground_pop', x: 200000, y: 660 });
  assert.ok(has(l, /more than 3 ground pops/));

  l = base();
  l.enemies.filter((e) => e.kind === 'tribal_warrior').slice(0, 2).forEach((e) => { e.behavior = 'golden'; });
  assert.ok(has(l, /golden runners, at most 1/));

  l = base();
  l.enemies.find((e) => e.kind === 'tribal_warrior').behavior = 'thrower';
  assert.ok(has(l, /not a heavy/), 'a soldier cannot be the thrower');
  l = base();
  l.enemies.find((e) => e.kind === 'dark_spirit').behavior = 'hopper';
  assert.ok(has(l, /is a dark_spirit/), 'a chaser kind cannot hop');
});

test('the validator accepts the new behaviours and nothing else', () => {
  const level = tmx.read(fs.readFileSync(fileFor('ww2', 7), 'utf8'));
  assert.ok(level.enemies.some((e) => e.behavior === 'thrower'));
  assert.deepStrictEqual(validate(level, { generated: true, play: false }), []);
  const bad = tmx.read(fs.readFileSync(fileFor('ww2', 7), 'utf8'));
  bad.enemies[0].behavior = 'flying';
  assert.ok(validate(bad, { generated: true, play: false }).some((p) => /has behavior flying/.test(p)));
});
