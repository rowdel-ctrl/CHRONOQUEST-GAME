'use strict';
// Builds one candidate level: ten sections, each a challenge made of set pieces
// (pieces.js) followed by a flat rest area with the artifact. Everything is
// placed by construction inside the rules; validate.js and solve.js confirm it.
const { physics, rules, eras, eraNumber } = require('./rules');
const { plan } = require('./pieces');
const { OPENERS } = require('./openers');
const { ERA_THEME, TILE, surfaceY } = require('./terrain');

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

// The four acts across the 10 sections (Nintendo's introduce / develop / twist
// / conclude), and how intense each is before the era's difficulty scalar.
const actOf = (g) => (g < 2 ? 'introduce' : g < 6 ? 'develop' : g < 8 ? 'twist' : 'conclude');
const ACT_BASE = { introduce: 0.25, develop: 0.55, twist: 0.85, conclude: 0.35 };

// What kind of obstacle a piece is, for the ground left between two of them.
const KIND = {
  gap: 'pit', gapPlain: 'pit', fight: 'pit', bridge: 'pit', pillars: 'pit',
  mesa: 'wall', courtyard: 'wall', tower: 'wall', block: 'wall',
  hill: 'soft', bump: 'soft', ridge: 'soft', walker: 'lane', heavy: 'lane',
};

// How likely each big piece is, by act, then tilted by the era's landscape.
const BY_ACT = {
  introduce: { gap: 3, hill: 3, mesa: 2, bridge: 1, ridge: 1 },
  develop: { mesa: 3, courtyard: 2, pillars: 2, bridge: 2, hill: 2, tower: 1, ridge: 2 },
  twist: { courtyard: 3, pillars: 3, tower: 3, bridge: 3, mesa: 2, ridge: 2 },
  conclude: { hill: 3, gap: 2, mesa: 2, bridge: 1, pillars: 1, ridge: 1 },
};
// The small pieces that fill out a section around its big one.
const FILLERS = {
  introduce: ['gap', 'bump', 'block', 'hill', 'bump'],
  develop: ['gap', 'block', 'bump', 'hill', 'gap', 'block'],
  twist: ['gap', 'block', 'gapPlain', 'bump', 'gap', 'block'],
  conclude: ['gap', 'bump', 'hill', 'block', 'bump'],
};
const FLAVOR = {
  'pre-colonial': { hill: 2, bridge: 1.5, ridge: 1.5, courtyard: 0.3, tower: 0.3 },
  spanish: { mesa: 2, courtyard: 2, tower: 2, hill: 0.6 },
  nationalism: { hill: 1.5, bridge: 1.5, courtyard: 1 },
  american: { pillars: 2, bridge: 1.5, tower: 1, mesa: 1, ridge: 1.5 },
  ww2: { courtyard: 2.5, mesa: 1.5, tower: 1, hill: 0.7 },
  modern: { pillars: 2, bridge: 2, tower: 2, hill: 0.6 },
};

function weightedPick(ctx, weights) {
  const entries = Object.entries(weights).filter(([, w]) => w > 0);
  const total = entries.reduce((s, [, w]) => s + w, 0);
  let r = ctx.rng() * total;
  for (const [k, w] of entries) { r -= w; if (r <= 0) return k; }
  return entries[entries.length - 1][0];
}

// "hill+e" -> { type: 'hill', opts: { enemy: true } }
function parseSpec(ctx, spec) {
  const [type, flag] = spec.split('+');
  const opts = {};
  if (flag === 'e' || flag === 'h') {
    opts.enemy = true;
    if (type === 'bridge') { delete opts.enemy; opts.guard = true; }
    if (flag === 'h' && ctx.heavyKinds.length) opts.heavy = true;
  }
  if (type === 'ridge' && flag === 'h' && ctx.heavyKinds.length) opts.heavy = true;
  return { type, opts };
}

// ── the recipe for a section: which pieces, in priority order ───────────────
function randomSection(ctx, g, eff) {
  const act = actOf(g);
  const { rng } = ctx;
  const weights = { ...BY_ACT[act] };
  for (const [k, m] of Object.entries(FLAVOR[ctx.eraId] || {})) if (weights[k]) weights[k] *= m;
  // gentle levels keep off the hardest pieces
  if (ctx.d < 0.3) { delete weights.tower; if (weights.pillars) weights.pillars *= 0.5; }
  if (ctx.prevPrimary && weights[ctx.prevPrimary]) weights[ctx.prevPrimary] *= 0.15;

  const mid = act === 'develop' || act === 'twist';
  const heavyOk = mid && ctx.heavyKinds.length > 0 && ctx.d > 0.25;
  const heavyFlag = () => (heavyOk && rng() < 0.35 ? 'h' : 'e');

  const primary = ctx.fightSections.has(g) ? 'fight' : weightedPick(ctx, weights);
  ctx.prevPrimary = primary;

  const withEnemy = (type) => {
    if (type === 'hill') return rng() < 0.5 ? 'hill+e' : 'hill';
    if (type === 'mesa') return rng() < 0.7 ? 'mesa+' + heavyFlag() : 'mesa';
    if (type === 'courtyard') return 'courtyard+' + heavyFlag();
    if (type === 'tower') return rng() < 0.6 ? 'tower+' + heavyFlag() : 'tower';
    if (type === 'ridge') return 'ridge+' + heavyFlag();
    if (type === 'bridge') return act === 'twist' && eff > 0.5 && g >= rules.fightFirstSection ? 'bridge+e' : 'bridge';
    return type;
  };
  const list = [withEnemy(primary)];
  const hasEnemy = (s) => /^(fight|courtyard|ridge)/.test(s) || /\+[eh]$/.test(s);
  if (!hasEnemy(list[0])) list.push(mid && heavyOk && rng() < 0.35 ? 'heavy' : 'walker');

  // fillers: a few small pieces, tried in turn until the section is full
  const pool = [...FILLERS[act]];
  const want = 2 + (rng() < 0.5 ? 1 : 0);
  for (let i = 0; i < want && pool.length; i++) {
    list.push(pool.splice(Math.floor(rng() * pool.length), 1)[0]);
  }
  // Later levels crowd the section: another enemy, if there is room for one.
  if (act !== 'introduce' && rng() < 0.15 + 0.65 * ctx.d) {
    list.push(heavyOk && rng() < 0.4 ? 'heavy' : 'walker');
  }
  return list;
}

const minPadFor = (a, b) => {
  const ka = KIND[a] || 'lane', kb = KIND[b] || 'lane';
  if (ka === 'lane' || kb === 'lane' || (ka === 'soft' && kb === 'soft')) return [rules.padNearMin, rules.padNearMax];
  if (ka === 'soft' || kb === 'soft') return [160, 288];
  return [rules.padMin, rules.padMax];
};

// The ground's elevation under each section, in tiles: a landscape, not a strip.
// Every section is built as if on the base ground and then lifted by its
// elevation; the ramps between sections are walkable steps in the rest area.
// The first and last sit on the base, where the student starts and the gate is.
const PROFILES = [
  [0, 1, 2, 4, 3, 5, 4, 3, 1, 0],
  [0, 2, 3, 2, 4, 5, 5, 3, 2, 0],
  [0, 1, 3, 3, 2, 4, 5, 4, 2, 0],
  [0, 2, 1, 3, 5, 3, 4, 2, 3, 0],
  [0, 1, 2, 4, 4, 2, 5, 3, 1, 0],
  [0, 2, 4, 3, 2, 4, 5, 5, 3, 0],
];
const RAMP_RUN = 2; // tiles of ground per step of a ramp

function elevationProfile(ctx) {
  const pick = PROFILES[Math.floor(ctx.rng() * PROFILES.length)];
  // Gentler levels stay lower: an opener tops out at 3 tiles (72), a hard level at 5.
  const cap = ctx.opener ? 3 : 3 + Math.floor(2 * ctx.d + 0.001);
  const prof = pick.map((e) => Math.min(e, cap));
  // Spread the highest point over the middle sections, not the first and last.
  return prof;
}

// ── one section: its pieces, then a rest area with the artifact ─────────────
function buildGroup(ctx, g) {
  const { L, rng } = ctx;
  const start = rules.safeStart + g * rules.groupWidth;
  const restStart = start + rules.groupWidth - rules.restWidth;
  const before = { platforms: L.platforms.length, coins: L.coins.length, enemies: L.enemies.length, artifacts: L.artifacts.length };
  const avail = restStart - start;
  const act = actOf(g);
  const scale = ctx.opener ? 0.4 : 0.6 + 0.8 * ctx.d;
  const eff = clamp(ACT_BASE[act] * scale, 0, 1);

  const specs = ctx.opener ? OPENERS[ctx.eraId][g] : randomSection(ctx, g, eff);
  // Plan every piece (this fixes their sizes), most important first.
  const planned = specs.map((spec) => {
    const { type, opts } = parseSpec(ctx, spec);
    const p = plan(ctx, type, eff, opts);
    p.type = type;
    return p;
  });

  // Left to right: as written for an opener, shuffled for the rest.
  let order = planned.map((_, i) => i);
  if (!ctx.opener) {
    for (let i = order.length - 1; i > 0; i--) {
      const j = Math.floor(rng() * (i + 1));
      [order[i], order[j]] = [order[j], order[i]];
    }
  }
  // The room a sequence needs with the least ground between pieces.
  const needed = (idx) => {
    const seq = order.filter((i) => idx.has(i)).map((i) => planned[i]);
    let total = rules.padNearMin; // before the first
    let prev = 'rest';
    for (const p of seq) { total += minPadFor(prev, p.type)[0] + p.width; prev = p.type; }
    return total + rules.padNearMin; // after the last
  };
  // Keep the most important pieces that fit. A section must hold an enemy: when
  // the big piece has none of its own (a pit or pillars) and there is no room for
  // both it and the lane that follows it, the big piece gives way.
  const carriesEnemy = (p) => p.enemyXs !== undefined;
  const keepFrom = (skipFirst) => {
    const set = new Set();
    for (let i = skipFirst ? 1 : 0; i < planned.length; i++) {
      const trial = new Set(set).add(i);
      if (needed(trial) <= avail) set.add(i);
    }
    return set;
  };
  let kept = keepFrom(false);
  if (![...kept].some((i) => carriesEnemy(planned[i]))) kept = keepFrom(true);
  const seq = order.filter((i) => kept.has(i)).map((i) => planned[i]);

  // Spread the spare ground over the gaps between pieces.
  let slack = avail - needed(kept);
  const pads = [];
  let prev = 'rest';
  for (const p of seq) {
    const [lo, hi] = minPadFor(prev, p.type);
    const extra = Math.min(slack, Math.floor((rng() * (hi - lo)) / TILE) * TILE);
    slack -= extra;
    pads.push((prev === 'rest' ? rules.padNearMin : lo) + extra);
    prev = p.type;
  }

  const sig = [];
  let prevEnd = start;
  for (let k = 0; k < seq.length; k++) {
    const p = seq[k];
    // Back onto the tile grid: a walker's lane is not a whole number of tiles,
    // and terrain that is not tile-aligned silently loses columns.
    const cursor = Math.ceil((prevEnd + pads[k]) / TILE) * TILE;
    if (cursor + p.width + rules.padNearMin > restStart) continue;
    const xs = p.enemyXs ? p.enemyXs(cursor) : [];
    const spacing = p.fight ? rules.fightEnemySpacing : rules.enemySpacing;
    if (xs.length && xs[0] - ctx.lastEnemyX < spacing) continue;
    p.apply(L, cursor);
    if (xs.length) ctx.lastEnemyX = xs[xs.length - 1];
    L.pieces.push({ type: p.type, x: cursor, width: p.width, section: g });
    sig.push(p.type);
    prevEnd = cursor + p.width;
  }
  ctx.signatures.push(sig.join('>'));

  // Rest area: three coins on the ground, then the artifact in the middle.
  for (let i = 0; i < 3; i++) L.coins.push({ x: restStart + 100 + i * 40, y: 620 });
  L.artifacts.push({
    x: restStart + rules.restWidth / 2 - physics.artifactSize / 2,
    art: 'artifact_' + (((g + ctx.artOffset) % 5) + 1),
  });

  // Lift the whole section onto its elevation.
  const E = ctx.profile[g];
  const secEnd = start + rules.groupWidth;
  if (E > 0) {
    const lift = E * TILE;
    for (let c = start / TILE; c < restStart / TILE; c++) if (L.H[c] >= 0) L.H[c] += E;
    for (let i = before.platforms; i < L.platforms.length; i++) L.platforms[i].y -= lift;
    for (let i = before.coins; i < L.coins.length; i++) L.coins[i].y -= lift;
    for (let i = before.enemies; i < L.enemies.length; i++) L.enemies[i].y = (L.enemies[i].y ?? physics.groundSurfaceY) - lift;
  }
  for (let c = restStart / TILE; c < secEnd / TILE; c++) { L.H[c] = E; L.S[c] = 0; }
  for (let i = before.artifacts; i < L.artifacts.length; i++) L.artifacts[i].y = surfaceY(E);
  // The ramp down (or up) to the next section's elevation, at the end of the rest
  // area, one tile per two tiles of ground.
  const next = g + 1 < rules.groups ? ctx.profile[g + 1] : 0;
  const dir = Math.sign(next - E);
  for (let k = 1; k <= Math.abs(next - E); k++) {
    const c1 = secEnd / TILE - (Math.abs(next - E) - k + 1) * RAMP_RUN;
    for (let c = c1; c < c1 + RAMP_RUN; c++) { L.H[c] = E + dir * k; L.S[c] = 0; }
  }
}

// ── a whole candidate ───────────────────────────────────────────────────────
function buildLevel({ eraId, levelIndex, rng, seed }) {
  const era = eras.find((e) => e.id === eraId);
  const levelCount = era.levelWeeks.length;
  if (levelIndex >= levelCount) throw new Error('boss levels are not generated');
  const opener = levelIndex === 1;
  // Difficulty across the era's generated levels, 0 (easiest) to 1.
  const d = opener ? 0 : (levelIndex - 2) / Math.max(1, levelCount - 3);

  const mapWidth = Math.ceil(physics.lengthUnits / physics.tile) * physics.tile;
  const cols = mapWidth / physics.tile;
  const exitX = mapWidth - rules.exitMargin;
  const L = {
    H: new Int8Array(cols), // 0 everywhere: flat base ground until a piece changes it
    S: new Uint8Array(cols),
    C: new Uint8Array(cols), // rows of crates on top of a column
    platforms: [], coins: [], enemies: [], artifacts: [], gates: [exitX - 40], pieces: [],
    spawnX: physics.playerX, exitX, mapWidth, seed, opener, d, generated: true,
    props: { era: eraId, level: levelIndex, grade: era.grade, term: era.term, weeks: era.levelWeeks[levelIndex - 1].join(',') },
  };
  const heavyKinds = era.heavy;
  // Which sections hold a platform fight: one in an opener is written into its
  // recipe; in the other levels one to three, as the era gets harder. Never in
  // the first two sections.
  const pool = [];
  for (let s = rules.fightFirstSection; s < 8; s++) pool.push(s);
  for (let i = pool.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }
  const fightCount = opener ? 0 : 1 + (d > 0.34 ? 1 : 0) + (d > 0.67 ? 1 : 0);
  const ctx = {
    eraId, L, rng, opener, d,
    fightSections: new Set(pool.slice(0, fightCount)),
    walkerKinds: era.enemyTypes.filter((k) => !heavyKinds.includes(k)),
    heavyKinds,
    bare: ERA_THEME[eraId] === 'blue',
    lastEnemyX: -1e9,
    artOffset: Math.floor(rng() * 5),
    signatures: [],
    prevPrimary: null,
  };
  ctx.profile = elevationProfile(ctx);
  L.elevation = ctx.profile;
  for (let g = 0; g < rules.groups; g++) buildGroup(ctx, g);
  L.signatures = ctx.signatures;
  L.eraNumber = eraNumber(eraId);
  return L;
}

module.exports = { buildLevel, actOf, KIND };
