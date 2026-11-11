'use strict';
// The surprises of the higher levels: which enemies hop, throw or glitter gold, and
// where a crack opens in the ground (`ground_pop`) or a rock falls (`falling_rock`).
// Shared by the generator (generate.js, validate.js) and the in-place script
// (mark_surprises.js), the way chasers.js is. Everything here is a pure function of the
// level: no randomness, so the same level always gets the same surprises.
//
// The ladder (first level of an era each kind may appear in; never in levels 1-3 or in
// a boss room) mirrors lib/core/surprise_constants.dart.
const { physics, eras } = require('./rules');
const T = require('./terrain');
const { hashString } = require('./rng');

const LADDER = { hopper: 4, pop: 5, rock: 6, thrower: 7, golden: 8 };
const FIRST_LEVEL = LADDER.hopper;

// Soldier-like walkers: they hop and one of them may be the golden runner. The modern
// era has no walker, so its cloud (forced to walk in the game) may hop too.
const SOLDIER_KINDS = new Set(['tribal_warrior', 'spanish_soldier', 'american_soldier', 'japanese_soldier']);
const HOPPER_KINDS = new Set([...SOLDIER_KINDS, 'misinfo_cloud']);

// How far, in units, surprises keep from things (see the placement rules in the task).
const FROM_START_OR_GATE = 400;
const FROM_HAZARD_EDGE = 150; // a pit edge or a rise/drop of two tiles or more
const FROM_PLATFORM = 150; // a platform's span, where a jump lands
const FROM_ARTIFACT = 300;
const FROM_ENEMY = 300; // an enemy's patrol range
const BETWEEN_SPOTS = 700; // two pops/rocks: at most two surprises fit on one screen
const SHADOW_HALF = 60; // the whole shadow stands on one block of ground
const ENEMY_WIDTH = physics.enemyWidth;
const MAX = { pop: 3, rock: 3, thrower: 2, golden: 1 };

// What each level holds (hoppers and throwers are marks on existing enemies; pops and
// rocks are new objects). Counts are for levels where the kind is allowed.
function planFor(levelIndex) {
  const L = levelIndex;
  return {
    hoppers: L >= LADDER.hopper,
    pops: L < LADDER.pop ? 0 : L === LADDER.pop ? 2 : 1,
    rocks: L < LADDER.rock ? 0 : L === LADDER.rock ? 3 : L === 7 ? 2 : L === 8 ? 1 : 2,
    throwers: L >= LADDER.thrower,
    golden: L >= LADDER.golden ? 1 : 0,
  };
}

const hasSurprises = (levelIndex) => levelIndex >= FIRST_LEVEL;
const isBoss = (eraId, levelIndex) => levelIndex >= eras.find((e) => e.id === eraId).levelWeeks.length;

// A hazard edge of a block: stepping off it, or landing beside it, is a real event.
function hazardEdges(block, H) {
  const lc = block.start / T.TILE - 1, rc = block.end / T.TILE;
  const hz = (n) => n === undefined || n < 0 || Math.abs(n - block.h) >= 2;
  return { left: hz(H[lc] === undefined ? -1 : H[lc]), right: hz(H[rc] === undefined ? -1 : H[rc]) };
}

const gateX = (level) => (level.gates && level.gates.length ? level.gates[0] : level.exitX);
const range = (e) => (e.behavior === 'heavy' || e.behavior === 'thrower' ? 0 : Number.isFinite(e.patrol) ? e.patrol : 150);
const feetY = (e) => e.y ?? physics.groundSurfaceY;

function supportBlock(e, blocks) {
  const centre = e.x + ENEMY_WIDTH / 2;
  return blocks.find((b) => Math.abs(b.top - feetY(e)) < 1 && centre >= b.start && centre <= b.end) || null;
}

// The x intervals a new ground pop or rock may not stand in.
function forbiddenZones(level, blocks, taken) {
  const z = [];
  z.push([-1e9, Math.max(level.spawnX + FROM_START_OR_GATE, 1500)]);
  z.push([gateX(level) - FROM_START_OR_GATE, 1e9]);
  for (const a of level.artifacts) z.push([a.x - FROM_ARTIFACT, a.x + physics.artifactSize + FROM_ARTIFACT]);
  for (const p of level.platforms) z.push([p.x - FROM_PLATFORM, p.x + p.width + FROM_PLATFORM]);
  for (const e of level.enemies) z.push([e.x - range(e) - FROM_ENEMY, e.x + range(e) + ENEMY_WIDTH + FROM_ENEMY]);
  for (const x of taken) z.push([x - BETWEEN_SPOTS, x + BETWEEN_SPOTS]);
  return z;
}

// The block a spot at world x stands on, or null if the spot is unfair: shadow not wholly
// on one block, or too near a hazard edge.
function spotBlock(x, blocks, H) {
  const b = blocks.find((q) => x >= q.start && x < q.end);
  if (!b) return null;
  if (x - SHADOW_HALF < b.start || x + SHADOW_HALF > b.end) return null;
  const hz = hazardEdges(b, H);
  if (hz.left && x - b.start < FROM_HAZARD_EDGE) return null;
  if (hz.right && b.end - x < FROM_HAZARD_EDGE) return null;
  return b;
}

// Picks `count` spots of one kind, spread along the level, nearest the evenly spaced
// targets (nudged a little by a hash of the level's name so every level differs).
function placeSpots(level, blocks, kind, count, taken, eraId, levelIndex) {
  const out = [];
  const lo = 1800, hi = level.exitX - 1800;
  for (let i = 0; i < count; i++) {
    const jitter = (hashString(`${eraId}:${levelIndex}:${kind}:${i}`) % 600) - 300;
    const target = lo + ((i + 0.5) * (hi - lo)) / count + jitter;
    const zones = forbiddenZones(level, blocks, taken);
    let best = null;
    for (let x = Math.ceil(lo / T.TILE) * T.TILE; x <= hi; x += T.TILE) {
      if (zones.some(([a, b]) => x > a && x < b)) continue;
      const b = spotBlock(x, blocks, level.H);
      if (!b) continue;
      const d = Math.abs(x - target);
      if (!best || d < best.d) best = { x, y: b.top, d };
    }
    if (!best) continue;
    taken.push(best.x);
    out.push({ type: kind === 'pop' ? 'ground_pop' : 'falling_rock', x: best.x, y: best.y });
  }
  return out;
}

// Marks the hoppers, the throwers and the golden runner among `level.enemies` and
// writes the ground pops and rocks to `level.surprises`. Idempotent: whatever marks the
// enemies carry now are recomputed from scratch (a chaser is never touched). Returns the
// counts.
function markSurprises(level, eraId, levelIndex) {
  const era = eras.find((e) => e.id === eraId);
  const heavyKinds = new Set(era.heavy);
  const blocks = T.blocksOf(level.H);
  const on = hasSurprises(levelIndex) && !isBoss(eraId, levelIndex);
  const plan = on ? planFor(levelIndex) : { hoppers: false, pops: 0, rocks: 0, throwers: false, golden: 0 };
  const gx = gateX(level);
  const roomy = (e) => e.x >= level.spawnX + FROM_START_OR_GATE && e.x + ENEMY_WIDTH <= gx - FROM_START_OR_GATE && supportBlock(e, blocks);

  // Walkers: every enemy of a hopping kind that is not a chaser, standing on a block.
  const walkers = level.enemies
    .filter((e) => HOPPER_KINDS.has(e.kind) && ['walker', 'hopper', 'golden'].includes(e.behavior) && roomy(e))
    .sort((a, b) => a.x - b.x);
  walkers.forEach((e) => { e.behavior = 'walker'; });
  const hoppers = [];
  // About every 4th walker (the 2nd, 6th ...); a level with a single walker hops it.
  if (plan.hoppers) walkers.forEach((e, n) => { if (n % 4 === 1 || walkers.length === 1) hoppers.push(e); });
  hoppers.forEach((e) => { e.behavior = 'hopper'; });
  // The golden runner: a soldier that is not a hopper, about 60% of the way along.
  const soldiers = walkers.filter((e) => SOLDIER_KINDS.has(e.kind) && e.behavior === 'walker');
  const golden = [];
  if (plan.golden && soldiers.length) {
    const pick = soldiers[Math.min(soldiers.length - 1, Math.floor(soldiers.length * 0.6))];
    pick.behavior = 'golden';
    golden.push(pick);
  }

  // Heavies: every second one (the 2nd, 4th ...), or the only one, throws.
  const heavies = level.enemies
    .filter((e) => heavyKinds.has(e.kind) && ['heavy', 'thrower'].includes(e.behavior) && roomy(e))
    .sort((a, b) => a.x - b.x);
  heavies.forEach((e) => { e.behavior = 'heavy'; });
  const throwers = [];
  if (plan.throwers) heavies.forEach((e, n) => { if (heavies.length === 1 ? n === 0 : n % 2 === 1) throwers.push(e); });
  throwers.forEach((e) => { e.behavior = 'thrower'; });

  // Cracks and rocks. A level that is not allowed any gets an empty list (and a stale
  // list from an earlier run goes).
  const taken = [];
  const pops = placeSpots(level, blocks, 'pop', plan.pops, taken, eraId, levelIndex);
  const rocks = placeSpots(level, blocks, 'rock', plan.rocks, taken, eraId, levelIndex);
  level.surprises = [...pops, ...rocks].sort((a, b) => a.x - b.x);
  return { hoppers: hoppers.length, golden: golden.length, throwers: throwers.length, pops: pops.length, rocks: rocks.length };
}

// The problems with a level's surprises (empty when fine); validate.js calls it.
function checkSurprises(level) {
  const problems = [];
  const eraId = level.props.era, L = level.props.level;
  const era = eras.find((e) => e.id === eraId);
  if (!era) return problems;
  const boss = isBoss(eraId, L) || !!level.arena;
  const H = level.H;
  const blocks = T.blocksOf(H);
  const spots = level.surprises || [];
  const kinds = (b) => level.enemies.filter((e) => e.behavior === b);
  const allowed = (what, first) => {
    if (boss) return `${what} in a boss room`;
    if (L < first) return `${what} in level ${L}, first allowed in level ${first}`;
    return null;
  };
  const note = (m) => m && problems.push(m);
  for (const e of kinds('hopper')) {
    note(allowed(`a hopper at ${e.x}`, LADDER.hopper));
    if (!HOPPER_KINDS.has(e.kind)) problems.push(`a hopper at ${e.x} is a ${e.kind}`);
  }
  for (const e of kinds('golden')) {
    note(allowed(`a golden runner at ${e.x}`, LADDER.golden));
    if (!SOLDIER_KINDS.has(e.kind)) problems.push(`the golden runner at ${e.x} is a ${e.kind}`);
  }
  for (const e of kinds('thrower')) {
    note(allowed(`a thrower at ${e.x}`, LADDER.thrower));
    if (!era.heavy.includes(e.kind)) problems.push(`the thrower at ${e.x} is a ${e.kind}, not a heavy`);
  }
  for (const s of spots) {
    if (!['ground_pop', 'falling_rock'].includes(s.type)) problems.push(`unknown surprise ${s.type}`);
    note(allowed(`a ${s.type} at ${s.x}`, s.type === 'ground_pop' ? LADDER.pop : LADDER.rock));
  }
  if (kinds('golden').length > MAX.golden) problems.push(`${kinds('golden').length} golden runners, at most ${MAX.golden}`);
  if (kinds('thrower').length > MAX.thrower) problems.push(`${kinds('thrower').length} throwers, at most ${MAX.thrower}`);
  if (spots.filter((s) => s.type === 'ground_pop').length > MAX.pop) problems.push(`more than ${MAX.pop} ground pops`);
  if (spots.filter((s) => s.type === 'falling_rock').length > MAX.rock) problems.push(`more than ${MAX.rock} falling rocks`);

  const gx = gateX(level);
  const marked = [...kinds('hopper'), ...kinds('golden'), ...kinds('thrower')].map((e) => ({ x: e.x + ENEMY_WIDTH / 2 }));
  for (const s of [...spots, ...marked]) {
    if (s.x < level.spawnX + FROM_START_OR_GATE) problems.push(`a surprise at ${s.x} is within ${FROM_START_OR_GATE} of the start`);
    if (s.x > gx - FROM_START_OR_GATE) problems.push(`a surprise at ${s.x} is within ${FROM_START_OR_GATE} of the gate`);
  }
  for (const s of spots) {
    const b = spotBlock(s.x, blocks, H);
    if (!b) problems.push(`the ${s.type} at ${s.x} is not on one block of ground, or is under ${FROM_HAZARD_EDGE} from a pit edge`);
    else if (Math.abs(b.top - s.y) > 1) problems.push(`the ${s.type} at ${s.x} is at y ${s.y}, the ground there is ${b.top}`);
    for (const a of level.artifacts) {
      if (s.x > a.x - FROM_ARTIFACT && s.x < a.x + physics.artifactSize + FROM_ARTIFACT) problems.push(`the ${s.type} at ${s.x} is under ${FROM_ARTIFACT} from the artifact at ${a.x}`);
    }
    for (const p of level.platforms) {
      if (s.x > p.x - FROM_PLATFORM && s.x < p.x + p.width + FROM_PLATFORM) problems.push(`the ${s.type} at ${s.x} is under ${FROM_PLATFORM} from the platform at ${p.x}`);
    }
    for (const e of level.enemies) {
      if (s.x > e.x - range(e) - FROM_ENEMY && s.x < e.x + range(e) + ENEMY_WIDTH + FROM_ENEMY) problems.push(`the ${s.type} at ${s.x} is under ${FROM_ENEMY} from the enemy at ${e.x}`);
    }
  }
  const xs = spots.map((s) => s.x).sort((a, b) => a - b);
  for (let i = 1; i < xs.length; i++) if (xs[i] - xs[i - 1] < BETWEEN_SPOTS) problems.push(`surprises at ${xs[i - 1]} and ${xs[i]} are under ${BETWEEN_SPOTS} apart`);
  return problems;
}

module.exports = {
  LADDER, FIRST_LEVEL, SOLDIER_KINDS, HOPPER_KINDS, MAX,
  FROM_START_OR_GATE, FROM_HAZARD_EDGE, FROM_PLATFORM, FROM_ARTIFACT, BETWEEN_SPOTS,
  planFor, hasSurprises, markSurprises, checkSurprises, hazardEdges,
};
