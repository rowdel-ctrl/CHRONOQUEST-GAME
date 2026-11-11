'use strict';
// Which artifact is golden. From level 2 on (never the first level, never the boss
// room, which has no artifacts), the artifact in the middle of the level, counted left
// to right, carries `golden="true"`. The game draws it gold, and a first-try right
// answer to it opens a portal to the bonus round. One per level.
// Shared by the generator (generate.js) and the in-place script (mark_golden.js).

const FIRST_LEVEL = 2;

// A non-boss level that has a golden artifact. `levelCount` is the number of levels
// of the era, the boss included, as in rules/eras.json's levelWeeks.length.
const hasGolden = (levelIndex, levelCount) => levelIndex >= FIRST_LEVEL && (levelCount == null || levelIndex < levelCount);

// Index, in x order, of the golden artifact among `count` artifacts: the middle one.
const goldenSlot = (count) => Math.floor(count / 2);

// Marks the middle artifact of `artifacts` golden and no other (any order of x is
// fine; ties in list order). Idempotent. Returns how many artifacts are golden.
function markGolden(artifacts, levelIndex, levelCount) {
  const sorted = artifacts.map((a, i) => ({ a, i })).sort((p, q) => p.a.x - q.a.x || p.i - q.i);
  const want = hasGolden(levelIndex, levelCount) && sorted.length ? goldenSlot(sorted.length) : -1;
  sorted.forEach(({ a }, n) => {
    if (n === want) a.golden = true;
    else delete a.golden;
  });
  return want >= 0 ? 1 : 0;
}

// What is wrong with the golden marks of a level, as sentences (empty when fine).
function goldenProblems(artifacts, levelIndex, levelCount) {
  const sorted = artifacts.map((a, i) => ({ a, i })).sort((p, q) => p.a.x - q.a.x || p.i - q.i);
  const have = sorted.map(({ a }, n) => (a.golden ? n : -1)).filter((n) => n >= 0);
  const want = hasGolden(levelIndex, levelCount) && sorted.length ? [goldenSlot(sorted.length)] : [];
  if (have.join() === want.join()) return [];
  return [`golden artifact at x-order ${have.join() || 'none'}, expected ${want.join() || 'none'}`];
}

module.exports = { FIRST_LEVEL, hasGolden, goldenSlot, markGolden, goldenProblems };
