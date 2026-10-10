'use strict';
// The set pieces a level is built from. Each planner decides its own size from
// the difficulty (eff, 0..1) and returns { type, width, apply(L, x), enemyXs(x) }.
// apply() paints terrain (L.H, L.S), platforms, enemies and coins at x, which is
// always on the 24-unit tile grid. Terrain widths are multiples of 24 too.
//
// Heights are in tiles (24 units); n tiles up is 660 - 24n. A student can jump
// up a rise of about 4 tiles (96), so a single hop is 4 or less and anything
// taller is built as a staircase of 2-tile steps.
const { physics, rules } = require('./rules');
const { TILE, surfaceY } = require('./terrain');

const SURFACE = physics.groundSurfaceY;
const pick = (ctx, list) => list[Math.floor(ctx.rng() * list.length)];
const chance = (ctx, p) => ctx.rng() < p;
const tiles = (n) => n * TILE;
const ceilTile = (v) => Math.ceil(v / TILE) * TILE;

// ── helpers ─────────────────────────────────────────────────────────────────
function fillCols(L, x0, x1, h, style = 0) {
  for (let c = x0 / TILE; c < x1 / TILE; c++) { L.H[c] = h; L.S[c] = style; }
}

function coin(L, x, y) {
  L.coins.push({ x: Math.round(x), y: Math.round(y) });
}
// A coin standing on a surface, the way the rest-area coins do (40 above it).
const coinOn = (L, x, top) => coin(L, x, top - 40);

function enemyOn(L, x, top, kind, behavior, patrol) {
  const e = { x: Math.round(x), kind, behavior, patrol };
  if (top < SURFACE - 1) e.y = top;
  L.enemies.push(e);
}

const ENEMY_W = physics.enemyWidth;
// Ground a patrolling enemy needs: its corridor plus clearance from the edges a
// student landing from a jump would come in over.
const needWidth = (patrol, margin) => 2 * patrol + ENEMY_W + 2 * margin;

const walkerKind = (ctx) => pick(ctx, ctx.walkerKinds);
const heavyKind = (ctx) => pick(ctx, ctx.heavyKinds);
const patrolFor = (eff) => (eff < 0.35 ? 60 : eff < 0.7 ? 100 : 150);

// An enemy standing in the middle of a top that is [x0, x1) wide; its patrol is
// trimmed to leave `margin` clear at each end.
function centredEnemy(L, ctx, x0, x1, top, eff, wantHeavy, margin = 160) {
  const heavy = wantHeavy && ctx.heavyKinds.length > 0;
  const room = Math.floor((x1 - x0 - ENEMY_W - 2 * margin) / 2 / 4) * 4;
  const patrol = heavy ? 0 : Math.max(0, Math.min(patrolFor(eff), room));
  const cx = (x0 + x1) / 2 - ENEMY_W / 2;
  if (heavy) enemyOn(L, cx, top, heavyKind(ctx), 'heavy', 0);
  else enemyOn(L, cx, top, walkerKind(ctx), 'walker', patrol);
  return cx;
}

// ── the simple pieces (flat ground) ─────────────────────────────────────────
function gapWidth(ctx, eff, plain) {
  const jitter = chance(ctx, 0.5) ? 0 : TILE;
  const raw = Math.round((rules.gapMin + (rules.gapMax - rules.gapMin) * eff) / TILE) * TILE + jitter;
  return Math.min(plain ? rules.gapPlainMax : rules.gapMax, Math.max(rules.gapMin, raw));
}

function planGap(ctx, eff, plain) {
  const G = gapWidth(ctx, eff, plain);
  const pw = rules.platformWidth;
  const [lowH, highH] = rules.platformHeights;
  const h = eff > 0.6 ? (chance(ctx, 0.6) ? highH : lowH) : chance(ctx, 0.5) ? lowH : highH;
  return {
    type: plain ? 'gapPlain' : 'gap',
    width: G,
    apply(L, x) {
      fillCols(L, x, x + G, -1);
      if (plain) return;
      const px = x + Math.round((G - pw) / 2 / 8) * 8;
      const py = SURFACE - h;
      L.platforms.push({ x: px, y: py, width: pw });
      coin(L, px + 24, py - 40);
    },
  };
}

function planWalker(ctx, eff, cap) {
  const patrol = cap ? Math.min(patrolFor(eff), 100) : patrolFor(eff);
  const kind = walkerKind(ctx);
  return {
    type: 'walker',
    width: 2 * patrol + ENEMY_W + 120,
    apply(L, x) { enemyOn(L, x + 60 + patrol, SURFACE, kind, 'walker', patrol); },
    enemyXs: (x) => [x + 60 + patrol],
  };
}

function planHeavy(ctx) {
  const kind = heavyKind(ctx);
  return {
    type: 'heavy',
    width: ENEMY_W + 120,
    apply(L, x) { enemyOn(L, x + 60, SURFACE, kind, 'heavy', 0); },
    enemyXs: (x) => [x + 60],
  };
}

// A gap too wide to jump, a wide platform in the middle, and a walker on it.
function planFight(ctx, eff) {
  const W = rules.fightGaps[eff > 0.7 ? 2 : eff > 0.4 ? 1 : 0];
  const pw = rules.fightPlatformWidth;
  const [lowH, highH] = rules.platformHeights;
  const h = chance(ctx, 0.5) ? lowH : highH;
  const kind = walkerKind(ctx);
  const inset = (W - pw) / 2;
  const enemyOffset = inset + (pw - ENEMY_W) / 2;
  return {
    type: 'fight',
    width: W,
    apply(L, x) {
      fillCols(L, x, x + W, -1);
      const py = SURFACE - h;
      L.platforms.push({ x: x + inset, y: py, width: pw });
      L.enemies.push({ x: x + enemyOffset, y: py, kind, behavior: 'walker', patrol: rules.fightPatrol });
    },
    enemyXs: (x) => [x + enemyOffset],
    fight: true,
  };
}

// ── hill: a walkable rise, one tile per step, with a flat top ───────────────
function planHill(ctx, eff, { enemy = false, heavy = false } = {}) {
  const n = 3 + Math.floor(ctx.rng() * 4); // 3..6 tiles tall: 72-144
  const upRun = pick(ctx, [2, 3]); // tiles of run per step
  const downRun = pick(ctx, [2, 3]);
  const patrol = heavy ? 0 : patrolFor(Math.min(eff, 0.6));
  const topWidth = ceilTile(enemy ? needWidth(patrol, 60) + 32 : tiles(pick(ctx, [8, 10, 12])));
  const width = tiles(n * upRun) + topWidth + tiles(n * downRun);
  return {
    type: 'hill',
    width,
    apply(L, x) {
      let cx = x;
      for (let i = 1; i <= n; i++) { fillCols(L, cx, cx + tiles(upRun), i, 0); cx += tiles(upRun); }
      const t0 = cx;
      fillCols(L, cx, cx + topWidth, n, 0);
      cx += topWidth;
      for (let i = n - 1; i >= 0; i--) { fillCols(L, cx, cx + tiles(downRun), i, 0); cx += tiles(downRun); }
      const top = surfaceY(n);
      for (let k = 0; k < 3; k++) coinOn(L, t0 + topWidth * (0.25 + 0.25 * k) - 21, top);
      if (enemy) centredEnemy(L, ctx, t0, t0 + topWidth, top, eff, heavy, 60);
    },
    enemyXs: (x) => (enemy ? [x + tiles(n * upRun) + topWidth / 2 - ENEMY_W / 2] : []),
  };
}

// ── mesa: a raised flat ground you jump up onto, then step or drop off ──────
function planMesa(ctx, eff, { enemy = false, heavy = false, bare = false } = {}) {
  // Tiles up: 3-8. Taller than 4 is climbed in two stages, so every hop is 4 or less.
  const total = pick(ctx, eff > 0.55 ? [4, 5, 6, 7, 8] : [3, 4, 5, 6]);
  const twoStage = total >= 5 || (total >= 3 && chance(ctx, 0.4));
  const first = twoStage ? Math.ceil(total / 2) : 0;
  const stageW = tiles(pick(ctx, [4, 5]));
  const patrol = heavy ? 0 : patrolFor(eff);
  const topWidth = ceilTile(enemy ? needWidth(patrol, 160) : tiles(pick(ctx, [8, 10, 12])));
  const stepDown = !enemy && total <= 4 && chance(ctx, 0.5);
  const downW = stepDown ? tiles(3) : 0;
  const width = (twoStage ? stageW : 0) + topWidth + downW;
  const style = bare ? 1 : 0;
  return {
    type: 'mesa',
    width,
    apply(L, x) {
      let cx = x;
      if (twoStage) { fillCols(L, cx, cx + stageW, first, style); cx += stageW; }
      const t0 = cx;
      fillCols(L, cx, cx + topWidth, total, style);
      cx += topWidth;
      if (stepDown) fillCols(L, cx, cx + downW, Math.floor(total / 2), style);
      const top = surfaceY(total);
      if (twoStage) coinOn(L, x + stageW / 2 - 21, surfaceY(first));
      for (let k = 0; k < 3; k++) coinOn(L, t0 + topWidth * (0.2 + 0.3 * k) - 21, top);
      if (enemy) centredEnemy(L, ctx, t0, t0 + topWidth, top, eff, heavy);
    },
    enemyXs: (x) => (enemy ? [x + (twoStage ? stageW : 0) + topWidth / 2 - ENEMY_W / 2] : []),
  };
}

// ── courtyard: climb a wall, drop into the yard, climb out the far side ─────
function planCourtyard(ctx, eff, { heavy = false, bare = true } = {}) {
  const hA = pick(ctx, eff > 0.5 ? [3, 4] : [2, 3]);
  const hB = Math.min(4, Math.max(2, hA + pick(ctx, [-1, 0, 1])));
  const topA = tiles(pick(ctx, [7, 8, 10]));
  const topB = tiles(pick(ctx, [7, 8]));
  const patrol = heavy ? 0 : patrolFor(eff);
  const yard = ceilTile(needWidth(patrol, 160));
  const width = topA + yard + topB;
  const style = bare ? 1 : 0;
  return {
    type: 'courtyard',
    width,
    apply(L, x) {
      fillCols(L, x, x + topA, hA, style);
      fillCols(L, x + topA + yard, x + width, hB, style);
      coinOn(L, x + topA / 2 - 21, surfaceY(hA));
      coinOn(L, x + topA + yard + topB / 2 - 21, surfaceY(hB));
      centredEnemy(L, ctx, x + topA, x + topA + yard, SURFACE, eff, heavy);
      for (let k = 0; k < 2; k++) coinOn(L, x + topA + yard * (0.3 + 0.4 * k) - 21, SURFACE);
    },
    enemyXs: (x) => [x + topA + yard / 2 - ENEMY_W / 2],
  };
}

// ── pillars: narrow towers of ground over water, each a jump from the last ──
function planPillars(ctx, eff, { bare = false } = {}) {
  const n = 3 + (eff > 0.5 ? 1 : 0) + (eff > 0.8 ? 1 : 0);
  const pw = tiles(eff > 0.6 ? 4 : 5);
  const style = bare ? 1 : 0;
  // heights wander within a tile or two of each other
  const hs = [];
  let h = 0;
  for (let i = 0; i < n; i++) {
    h = Math.max(0, Math.min(6, h + pick(ctx, [-2, -1, 1, 1, 2])));
    hs.push(h);
  }
  const gaps = [];
  for (let i = 0; i <= n; i++) {
    const prev = i === 0 ? 0 : hs[i - 1];
    const next = i === n ? 0 : hs[i];
    const delta = next - prev; // positive: the next ground is higher
    const base = 4 + Math.round(eff * 3); // tiles: 96..168
    const adj = delta > 0 ? -delta : Math.min(1, -delta);
    gaps.push(tiles(Math.max(4, Math.min(8, base + adj))));
  }
  const width = gaps.reduce((a, b) => a + b, 0) + n * pw;
  return {
    type: 'pillars',
    width,
    apply(L, x) {
      let cx = x;
      for (let i = 0; i < n; i++) {
        fillCols(L, cx, cx + gaps[i], -1);
        cx += gaps[i];
        fillCols(L, cx, cx + pw, hs[i], style);
        coinOn(L, cx + pw / 2 - 21, surfaceY(hs[i]));
        // a coin in the middle of the leap to the next pillar
        const nextH = i + 1 < n ? hs[i + 1] : 0;
        coin(L, cx + pw + gaps[i + 1] / 2 - 21, SURFACE - TILE * Math.max(hs[i], nextH) - 130);
        cx += pw;
      }
      fillCols(L, cx, cx + gaps[n], -1);
    },
  };
}

// ── bridge: a wide pit crossed on a row of floating platforms ───────────────
function planBridge(ctx, eff, { guard = false } = {}) {
  // A guarded bridge has the wide platform and so stays at three; the pit is kept
  // under 1152 either way.
  const k = guard ? 3 : 3 + (eff > 0.6 ? 1 : 0);
  const pw = rules.platformWidth;
  const ledge = pick(ctx, [96, 120]);
  const hop = tiles(5 + Math.round(eff * (k === 4 ? 2 : 3))); // 120..192, edge to edge
  const heights = [];
  for (let i = 0; i < k; i++) heights.push(pick(ctx, [64, 88, 104, 112]));
  heights[0] = Math.max(heights[0], 72);
  heights[k - 1] = Math.max(heights[k - 1], 72);
  const guardIdx = guard ? 1 : -1;
  const widths = Array.from({ length: k }, (_, i) => (i === guardIdx ? rules.fightPlatformWidth : pw));
  const pitW = ceilTile(2 * ledge + widths.reduce((a, b) => a + b, 0) + (k - 1) * hop);
  const kind = walkerKind(ctx);
  return {
    type: 'bridge',
    width: pitW,
    apply(L, x) {
      fillCols(L, x, x + pitW, -1);
      let px = x + ledge;
      for (let i = 0; i < k; i++) {
        const y = SURFACE - heights[i];
        L.platforms.push({ x: px, y, width: widths[i] });
        if (i === guardIdx) {
          L.enemies.push({ x: px + (widths[i] - ENEMY_W) / 2, y, kind, behavior: 'walker', patrol: rules.fightPatrol });
        } else coin(L, px + widths[i] / 2 - 21, y - 40);
        px += widths[i] + hop;
      }
    },
    enemyXs: (x) => (guard ? [x + ledge + widths[0] + hop + (rules.fightPlatformWidth - ENEMY_W) / 2] : []),
    fight: guard,
  };
}

// ── tower: a staircase up to a high platform of ground, then a drop ─────────
function planTower(ctx, eff, { enemy = false, heavy = false, bare = true } = {}) {
  const stairs = eff > 0.7 ? 5 : eff > 0.4 ? 4 : 3; // steps of 2 tiles (48): the top is 144-240 up
  const stepW = tiles(5);
  const patrol = heavy ? 0 : patrolFor(eff);
  const topWidth = ceilTile(enemy ? needWidth(patrol, 160) : tiles(12));
  const style = bare ? 1 : 0;
  const width = stairs * stepW + topWidth;
  return {
    type: 'tower',
    width,
    apply(L, x) {
      for (let i = 1; i <= stairs; i++) {
        fillCols(L, x + (i - 1) * stepW, x + i * stepW, 2 * i, style);
        coinOn(L, x + (i - 1) * stepW + stepW / 2 - 21, surfaceY(2 * i));
      }
      const t0 = x + stairs * stepW;
      fillCols(L, t0, t0 + topWidth, 2 * stairs, style);
      const top = surfaceY(2 * stairs);
      for (let k = 0; k < 3; k++) coinOn(L, t0 + topWidth * (0.2 + 0.3 * k) - 21, top);
      if (enemy) centredEnemy(L, ctx, t0, t0 + topWidth, top, eff, heavy);
    },
    enemyXs: (x) => (enemy ? [x + stairs * stepW + topWidth / 2 - ENEMY_W / 2] : []),
  };
}

// ── bump: a one-tile mound, walked up and over; a bit of landscape ──────────
function planBump(ctx, eff, { bare = false } = {}) {
  const w = tiles(pick(ctx, [6, 8, 10]));
  const style = bare ? 1 : 0;
  return {
    type: 'bump',
    width: w,
    apply(L, x) {
      fillCols(L, x, x + w, 1, style);
      coinOn(L, x + w / 2 - 21, surfaceY(1));
    },
  };
}

// ── block: a low wall to jump over, 2-3 tiles tall and a few wide ───────────
function planBlock(ctx, eff, { bare = true } = {}) {
  const h = pick(ctx, eff > 0.5 ? [2, 3] : [2]);
  const w = tiles(pick(ctx, [3, 4, 5]));
  const style = bare ? 1 : 0;
  return {
    type: 'block',
    width: w,
    apply(L, x) {
      fillCols(L, x, x + w, h, style);
      // A pile of crates: the top h rows of the block.
      for (let c = x / TILE; c < (x + w) / TILE; c++) L.C[c] = h;
      coin(L, x + w / 2 - 21, surfaceY(h) - 90);
    },
  };
}

// ── ridge: climb a gentle slope onto a long high road, with a pit and an
// enemy or two along it, then walk down the far side ──────────────────────
function planRidge(ctx, eff, { heavy = false } = {}) {
  const rise = pick(ctx, [2, 3]); // tiles the road is above the ground
  const run = tiles(3);
  const patrol = heavy ? 0 : patrolFor(Math.min(eff, 0.6));
  const lane = ceilTile(needWidth(patrol, 60) + 32);
  const G = pick(ctx, [8, 9, 10]) * TILE; // the pit in the road, 192-240
  const pw = rules.platformWidth;
  const hOver = pick(ctx, rules.platformHeights);
  const roadLead = tiles(3);
  const width = rise * run * 2 + roadLead + lane + tiles(5) + G + tiles(5) + lane + roadLead;
  return {
    type: 'ridge',
    width,
    apply(L, x) {
      let cx = x;
      for (let i = 1; i <= rise; i++) { fillCols(L, cx, cx + run, i, 0); cx += run; }
      const roadTop = surfaceY(rise);
      // the road, in three parts around the pit
      const a0 = cx;
      const aEnd = cx + roadLead + lane + tiles(5);
      fillCols(L, a0, aEnd, rise, 0);
      const pitStart = aEnd;
      fillCols(L, pitStart, pitStart + G, -1);
      const b0 = pitStart + G;
      const bEnd = b0 + tiles(5) + lane + roadLead;
      fillCols(L, b0, bEnd, rise, 0);
      const px = pitStart + Math.round((G - pw) / 2 / 8) * 8;
      L.platforms.push({ x: px, y: roadTop - hOver, width: pw });
      coin(L, px + 24, roadTop - hOver - 40);
      cx = bEnd;
      for (let i = rise - 1; i >= 0; i--) { fillCols(L, cx, cx + run, i, 0); cx += run; }
      // one enemy before the pit, a second after it (a heavy where the era has one)
      const e1 = a0 + roadLead + 30 + patrol;
      enemyOn(L, e1, roadTop, walkerKind(ctx), 'walker', patrol);
      const e2 = b0 + tiles(5) + 40 + patrol;
      if (heavy && ctx.heavyKinds.length) enemyOn(L, e2, roadTop, heavyKind(ctx), 'heavy', 0);
      else enemyOn(L, e2, roadTop, walkerKind(ctx), 'walker', patrol);
      for (let k = 0; k < 2; k++) coinOn(L, a0 + roadLead + lane * (0.2 + 0.5 * k) - 21, roadTop);
    },
    enemyXs: (x) => {
      const a0 = x + rise * run;
      const b0 = a0 + roadLead + lane + tiles(5) + G;
      return [a0 + roadLead + 30 + patrol, b0 + tiles(5) + 40 + patrol];
    },
  };
}

const PLANNERS = {
  gap: (ctx, eff) => planGap(ctx, eff, false),
  gapPlain: (ctx, eff) => planGap(ctx, eff, true),
  walker: (ctx, eff, o) => planWalker(ctx, eff, o && o.cap),
  heavy: (ctx) => planHeavy(ctx),
  fight: (ctx, eff) => planFight(ctx, eff),
  hill: (ctx, eff, o) => planHill(ctx, eff, o),
  mesa: (ctx, eff, o) => planMesa(ctx, eff, { bare: ctx.bare, ...o }),
  courtyard: (ctx, eff, o) => planCourtyard(ctx, eff, { bare: true, ...o }),
  pillars: (ctx, eff, o) => planPillars(ctx, eff, { bare: ctx.bare, ...o }),
  bridge: (ctx, eff, o) => planBridge(ctx, eff, o),
  tower: (ctx, eff, o) => planTower(ctx, eff, { bare: true, ...o }),
  bump: (ctx, eff, o) => planBump(ctx, eff, { bare: ctx.bare, ...o }),
  block: (ctx, eff, o) => planBlock(ctx, eff, { bare: true, ...o }),
  ridge: (ctx, eff, o) => planRidge(ctx, eff, o),
};

function plan(ctx, type, eff, opts) {
  const f = PLANNERS[type];
  if (!f) throw new Error('unknown piece ' + type);
  return f(ctx, eff, opts || {});
}

module.exports = { plan, PLANNERS, fillCols, ENEMY_W };
