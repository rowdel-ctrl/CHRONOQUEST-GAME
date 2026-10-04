'use strict';
// Builds one candidate level: the recipe (which elements go in which of the 10
// sections) and the chunks that realise each element. Everything is placed by
// construction inside the rules, then validate.js confirms it.
const { physics, rules, eras, eraNumber } = require('./rules');

const round16 = (v) => Math.round(v / 16) * 16;
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

// The four acts across the 10 sections (Nintendo's introduce / develop / twist
// / conclude), and how intense each is before the era's difficulty scalar.
const actOf = (g) => (g < 2 ? 'introduce' : g < 6 ? 'develop' : g < 8 ? 'twist' : 'conclude');
const ACT_BASE = { introduce: 0.25, develop: 0.55, twist: 0.85, conclude: 0.35 };

// ── elements: each plans its own size, then applies itself at an x ──────────
function gapWidth(ctx, eff, plain) {
  const jitter = ctx.rng() < 0.5 ? 0 : 16;
  const raw = round16(rules.gapMin + (rules.gapMax - rules.gapMin) * eff) + jitter;
  return clamp(raw, rules.gapMin, plain ? rules.gapPlainMax : rules.gapMax);
}

function planGap(ctx, eff, plain) {
  const G = gapWidth(ctx, eff, plain);
  const pw = rules.platformWidth;
  const [lowH, highH] = rules.platformHeights;
  const h = eff > 0.6 ? (ctx.rng() < 0.6 ? highH : lowH) : ctx.rng() < 0.5 ? lowH : highH;
  return {
    type: plain ? 'gapPlain' : 'gap',
    width: G,
    apply(L, x) {
      L.gaps.push({ start: x, end: x + G });
      if (!plain) {
        const px = x + Math.round((G - pw) / 2 / 8) * 8;
        const py = physics.groundSurfaceY - h;
        L.platforms.push({ x: px, y: py, width: pw });
        // A reward for the risky route: a coin on the platform (the paper's
        // "coin at the peak of a jump over a gap").
        L.coins.push({ x: px + 24, y: py - 40 });
      }
    },
  };
}

function patrolFor(eff) {
  return eff < 0.35 ? 60 : eff < 0.7 ? 100 : 150;
}

function planWalker(ctx, eff, cap) {
  // In a section that also holds a platform fight the patrol is capped, so the
  // section still fits.
  const patrol = cap ? Math.min(patrolFor(eff), 100) : patrolFor(eff);
  const kind = ctx.walkerKinds[Math.floor(ctx.rng() * ctx.walkerKinds.length)];
  return {
    type: 'walker',
    width: 2 * patrol + physics.enemyWidth + 120,
    apply(L, x) {
      L.enemies.push({ x: x + 60 + patrol, kind, behavior: 'walker', patrol });
    },
    enemyX: (x) => x + 60 + patrol,
  };
}

function planHeavy(ctx) {
  const kind = ctx.heavyKinds[Math.floor(ctx.rng() * ctx.heavyKinds.length)];
  return {
    type: 'heavy',
    width: physics.enemyWidth + 120,
    apply(L, x) {
      L.enemies.push({ x: x + 60, kind, behavior: 'heavy', patrol: 0 });
    },
    enemyX: (x) => x + 60,
  };
}

// A platform fight: a gap too wide to jump, a wide platform in the middle, and a
// walker patrolling the platform. Crossing means hitting the enemy from the air
// or landing beside it. Wider as the section gets harder.
function planFight(ctx, eff) {
  const W = rules.fightGaps[eff > 0.7 ? 2 : eff > 0.4 ? 1 : 0];
  const pw = rules.fightPlatformWidth;
  const [lowH, highH] = rules.platformHeights;
  const h = ctx.rng() < 0.5 ? lowH : highH;
  const kind = ctx.walkerKinds[Math.floor(ctx.rng() * ctx.walkerKinds.length)];
  const inset = (W - pw) / 2; // distance from each ledge to the platform
  const enemyOffset = inset + (pw - physics.enemyWidth) / 2; // centred on it
  return {
    type: 'fight',
    width: W,
    apply(L, x) {
      L.gaps.push({ start: x, end: x + W });
      const py = physics.groundSurfaceY - h;
      L.platforms.push({ x: x + inset, y: py, width: pw });
      L.enemies.push({ x: x + enemyOffset, y: py, kind, behavior: 'walker', patrol: rules.fightPatrol });
    },
    enemyX: (x) => x + enemyOffset,
  };
}

function plan(ctx, type, eff, cap) {
  if (type === 'gap') return planGap(ctx, eff, false);
  if (type === 'gapPlain') return planGap(ctx, eff, true);
  if (type === 'fight') return planFight(ctx, eff);
  if (type === 'walker') return planWalker(ctx, eff, cap);
  if (type === 'heavy') return planHeavy(ctx);
  throw new Error('unknown element ' + type);
}

// ── the recipe: which elements, per section ─────────────────────────────────
// Every section holds at least one gap with a platform and one enemy, in either
// order (playtest: levels felt empty with a hazard every other section). The
// middle sections, where the level develops and twists, can hold a third
// element, so the ramp comes from how many and how hard, not from leaving a
// section bare.
function elementsFor(ctx, g, eff) {
  const act = actOf(g);
  const { rng, opener } = ctx;
  const mid = act === 'develop' || act === 'twist';
  const enemy = () =>
    !opener && mid && ctx.heavyKinds.length > 0 && ctx.d > 0.25 && rng() < 0.35 ? 'heavy' : 'walker';

  const gapFirst = rng() < 0.5;
  let list = gapFirst ? ['gap', enemy()] : [enemy(), 'gap'];

  // A platform fight goes last, between the rest of the section and the
  // artifact. It is already a third element, so no sandwich on top of it.
  if (ctx.fightSections.has(g)) return [...list, 'fight'];

  // A third element, sandwiching the other kind: gap-enemy-gap or
  // enemy-gap-enemy. Openers take it less often, and it only goes in if it fits.
  const chance = (act === 'twist' ? 0.5 + 0.4 * ctx.d : 0.3 + 0.5 * ctx.d) * (opener ? 0.5 : 1);
  if (mid && rng() < chance) list = gapFirst ? ['gap', enemy(), 'gap'] : [enemy(), 'gap', enemy()];

  // The twist: now and then a gap with nothing to land on. Only when the
  // section has two gaps, so one of them still has its platform.
  if (act === 'twist' && list.filter((t) => t === 'gap').length >= 2 && rng() < 0.5) {
    list[list.lastIndexOf('gap')] = 'gapPlain';
  }
  return list;
}

// ── one section: a challenge segment, then a rest area with the artifact ────
function buildGroup(ctx, g) {
  const { L, rng } = ctx;
  const start = rules.safeStart + g * rules.groupWidth;
  const restStart = start + rules.groupWidth - rules.restWidth;
  const act = actOf(g);
  const scale = ctx.opener ? 0.4 : 0.6 + 0.8 * ctx.d;
  const eff = clamp(ACT_BASE[act] * scale, 0, 1);

  const isGap = (t) => t === 'gap' || t === 'gapPlain' || t === 'fight';
  const cap = ctx.fightSections.has(g);
  const padBetween = (a, b) => {
    // Two gaps need real ground between them; a gap and an enemy lane need
    // less, because the lane carries its own margin.
    const [lo, hi] = isGap(a) && isGap(b) ? [rules.padMin, rules.padMax] : [rules.padNearMin, rules.padNearMax];
    return lo + Math.floor((rng() * (hi - lo)) / 16) * 16;
  };

  const sig = [];
  let prevEnd = start;
  let prevType = 'rest'; // the previous section ends in ground (its rest area)
  for (const type of elementsFor(ctx, g, eff)) {
    const p = plan(ctx, type, eff, cap);
    // Measured from what was actually placed last, so an element that did not
    // fit never leaves two gaps closer than the ground rule allows.
    // Back onto the 16px tile grid: a walker's lane is not a whole number of
    // tiles, and a gap that is not tile-aligned silently loses columns.
    const cursor = Math.ceil((prevEnd + padBetween(prevType, type)) / 16) * 16;
    // Room to finish this element and still leave ground before the rest area.
    if (cursor + p.width + rules.padNearMin > restStart) continue;
    const spacing = type === 'fight' ? rules.fightEnemySpacing : rules.enemySpacing;
    if (p.enemyX && p.enemyX(cursor) - ctx.lastEnemyX < spacing) continue;
    p.apply(L, cursor);
    if (p.enemyX) ctx.lastEnemyX = p.enemyX(cursor);
    sig.push(type);
    prevEnd = cursor + p.width;
    prevType = type;
  }
  // In order, so gap-then-enemy and enemy-then-gap count as different rhythms.
  ctx.signatures.push(sig.join('>'));

  // Rest area: three coins on the ground, then the artifact in the middle.
  for (let i = 0; i < 3; i++) L.coins.push({ x: restStart + 100 + i * 40, y: 620 });
  L.artifacts.push({
    x: restStart + rules.restWidth / 2 - physics.artifactSize / 2,
    art: 'artifact_' + (((g + ctx.artOffset) % 5) + 1),
  });
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
  const exitX = mapWidth - rules.exitMargin;
  const L = {
    gaps: [], enemies: [], platforms: [], coins: [], artifacts: [], gates: [exitX - 40],
    spawnX: physics.playerX, exitX, mapWidth, seed, opener, d, generated: true,
    props: { era: eraId, level: levelIndex, grade: era.grade, term: era.term, weeks: era.levelWeeks[levelIndex - 1].join(',') },
  };
  const heavyKinds = era.heavy;
  // Which sections hold a platform fight: one in an opener (late), and one to
  // three in the other levels as the era gets harder. Never in the first two.
  const first = opener ? 5 : rules.fightFirstSection;
  const pool = [];
  for (let s = first; s < 8; s++) pool.push(s);
  for (let i = pool.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }
  const fightCount = opener ? 1 : 1 + (d > 0.34 ? 1 : 0) + (d > 0.67 ? 1 : 0);
  const ctx = {
    fightSections: new Set(pool.slice(0, fightCount)),
    L, rng, opener, d,
    walkerKinds: era.enemyTypes.filter((k) => !heavyKinds.includes(k)),
    heavyKinds,
    lastEnemyX: -1e9,
    artOffset: Math.floor(rng() * 5),
    signatures: [],
  };
  for (let g = 0; g < rules.groups; g++) buildGroup(ctx, g);
  L.signatures = ctx.signatures;
  L.eraNumber = eraNumber(eraId);
  return L;
}

module.exports = { buildLevel, actOf };
