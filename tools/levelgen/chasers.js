'use strict';
// Which soldiers chase. In the eras below, from level 3 on (never the boss room),
// every second soldier in the level, counted left to right (the 2nd, 4th, 6th...),
// is a chaser: its `behavior` property is "chaser" instead of "walker". The game
// reads that and gives the soldier the crouch-then-dash move.
// Shared by the generator (generate.js) and the in-place script (mark_chasers.js).

// The soldier `kind` of each era that has chaser soldiers, by era id.
const SOLDIER_KIND = { spanish: 'spanish_soldier', nationalism: 'spanish_soldier', ww2: 'japanese_soldier' };
const FIRST_LEVEL = 3;

const hasChasers = (eraId, levelIndex) => SOLDIER_KIND[eraId] !== undefined && levelIndex >= FIRST_LEVEL;

// Marks the chasers among `enemies` (any order of x is fine: they are counted
// left to right, ties in list order). Idempotent; returns how many soldiers are chasers.
function markChasers(enemies, eraId, levelIndex) {
  if (!hasChasers(eraId, levelIndex)) return 0;
  const soldiers = enemies.map((e, i) => ({ e, i })).filter(({ e }) => e.kind === SOLDIER_KIND[eraId])
    .sort((a, b) => a.e.x - b.e.x || a.i - b.i);
  let marked = 0;
  soldiers.forEach(({ e }, n) => {
    if (n % 2 === 1) { e.behavior = 'chaser'; marked++; }
  });
  return marked;
}

module.exports = { SOLDIER_KIND, FIRST_LEVEL, hasChasers, markChasers };
