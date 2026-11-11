'use strict';
// Run with: node --test tools/levelgen/test/golden.test.js
// The golden artifact: one per level from level 2 on, the middle one, never in a
// boss room or the first level; the generator writes it and the marking script keeps it.
const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');

const { eras, eraNumber } = require('../rules');
const { markGolden, goldenProblems, hasGolden, goldenSlot, FIRST_LEVEL } = require('../golden');
const { markText } = require('../mark_golden');
const { generateLevel } = require('../generate');
const tmx = require('../tmx');

const LEVELS_DIR = path.join(__dirname, '..', '..', '..', 'assets', 'tiles', 'levels');
const fileFor = (era, n) => path.join(LEVELS_DIR, `era${eraNumber(era.id)}_${n}.tmx`);
const art = (xs) => xs.map((x) => ({ x, y: 660, art: 'artifact_1' }));

test('golden starts at level 2 and never reaches a boss level', () => {
  assert.strictEqual(FIRST_LEVEL, 2);
  assert.strictEqual(hasGolden(1, 10), false);
  assert.strictEqual(hasGolden(2, 10), true);
  assert.strictEqual(hasGolden(9, 10), true);
  assert.strictEqual(hasGolden(10, 10), false, 'level 10 of 10 is the boss');
  assert.strictEqual(hasGolden(4, 5), true);
  assert.strictEqual(hasGolden(5, 5), false);
});

test('the middle artifact in x order is golden, and only it, whatever order the list is in', () => {
  const a = art([900, 100, 500, 300, 700, 1100, 1300, 1500, 1700, 1900]);
  assert.strictEqual(markGolden(a, 3, 10), 1);
  const golden = a.filter((o) => o.golden);
  assert.strictEqual(golden.length, 1);
  const sorted = [...a].sort((p, q) => p.x - q.x);
  assert.strictEqual(sorted[goldenSlot(10)], golden[0]);
  assert.strictEqual(golden[0].x, 1100, 'the 6th of 10 from the left');
});

test('marking is idempotent and clears stray marks', () => {
  const a = art([100, 200, 300, 400, 500]);
  a[0].golden = true;
  a[4].golden = true;
  markGolden(a, 2, 8);
  const once = JSON.stringify(a);
  markGolden(a, 2, 8);
  assert.strictEqual(JSON.stringify(a), once);
  assert.deepStrictEqual(a.filter((o) => o.golden).map((o) => o.x), [300]);
});

test('level 1 and a boss level get no golden artifact', () => {
  const first = art([100, 200, 300]);
  first[1].golden = true;
  assert.strictEqual(markGolden(first, 1, 10), 0);
  assert.ok(first.every((o) => !o.golden));
  const boss = art([100, 200, 300]);
  assert.strictEqual(markGolden(boss, 10, 10), 0);
  assert.deepStrictEqual(goldenProblems(boss, 10, 10), []);
});

test('goldenProblems names a missing, a doubled and a misplaced mark', () => {
  const a = art([100, 200, 300, 400, 500]);
  assert.strictEqual(goldenProblems(a, 3, 8).length, 1, 'missing');
  markGolden(a, 3, 8);
  assert.deepStrictEqual(goldenProblems(a, 3, 8), []);
  a[0].golden = true;
  assert.strictEqual(goldenProblems(a, 3, 8).length, 1, 'doubled');
  a.forEach((o) => delete o.golden);
  a[4].golden = true;
  assert.strictEqual(goldenProblems(a, 3, 8).length, 1, 'misplaced');
});

test('the maps on disk carry exactly one golden artifact from level 2 on, the middle one', () => {
  let golden = 0;
  for (const era of eras) {
    const count = era.levelWeeks.length;
    for (let n = 1; n < count; n++) {
      const xml = fs.readFileSync(fileFor(era, n), 'utf8');
      const level = tmx.read(xml.replace(/\r\n/g, '\n'));
      assert.deepStrictEqual(goldenProblems(level.artifacts, n, count), [], `${era.id} ${n}`);
      golden += level.artifacts.filter((a) => a.golden).length;
    }
  }
  assert.strictEqual(golden, 31, '37 non-boss levels minus the 6 first levels');
});

test('a boss room has no artifacts and so no golden one', () => {
  for (const era of eras) {
    const xml = fs.readFileSync(fileFor(era, era.levelWeeks.length), 'utf8');
    assert.ok(!/name="golden"/.test(xml), era.id);
  }
});

test('mark_golden changes nothing on a map that is already marked, and keeps its line endings', () => {
  for (const [era, n] of [[eras[0], 4], [eras[1], 2], [eras[4], 6]]) {
    const text = fs.readFileSync(fileFor(era, n), 'utf8');
    const r = markText(text, n, era.levelWeeks.length);
    assert.strictEqual(r.text, text, `${era.id} ${n} is already marked`);
    assert.strictEqual(r.golden, 1);
  }
});

test('mark_golden adds the one missing mark and removes a stray one, only touching that line', () => {
  const era = eras[0];
  const text = fs.readFileSync(fileFor(era, 3), 'utf8');
  const eol = text.includes('\r\n') ? '\r\n' : '\n';
  const line = new RegExp(`${eol}[ \\t]*<property name="golden"[^>]*/>`);
  const bare = text.replace(line, '');
  assert.notStrictEqual(bare, text);
  const added = markText(bare, 3, era.levelWeeks.length);
  assert.strictEqual(added.text, text, 'the mark goes back exactly where it was');
  // Move the mark to the first artifact: it is taken off there and put back.
  const moved = bare.replace(/(<property name="art" value="[^"]*"\/>)/, `$1${eol}    <property name="golden" type="bool" value="true"/>`);
  assert.strictEqual(markText(moved, 3, era.levelWeeks.length).text, text);
});

test('the generator writes the golden artifact, and the file reads back with it', () => {
  const { level } = generateLevel({ eraId: 'spanish', levelIndex: 3 });
  assert.strictEqual(level.artifacts.filter((a) => a.golden).length, 1);
  const xml = tmx.write(level);
  assert.strictEqual((xml.match(/name="golden"/g) || []).length, 1);
  const back = tmx.read(xml);
  assert.deepStrictEqual(goldenProblems(back.artifacts, 3, 5), []);
  // The same level on disk has the golden artifact at the same x.
  const disk = tmx.read(fs.readFileSync(fileFor(eras[1], 3), 'utf8').replace(/\r\n/g, '\n'));
  assert.strictEqual(disk.artifacts.find((a) => a.golden).x, back.artifacts.find((a) => a.golden).x);
});

test('the generator gives the first level no golden artifact', () => {
  const { level } = generateLevel({ eraId: 'ww2', levelIndex: 1 });
  assert.strictEqual(level.artifacts.filter((a) => a.golden).length, 0);
  assert.ok(!/name="golden"/.test(tmx.write(level)));
});
