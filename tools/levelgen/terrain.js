'use strict';
// The terrain model. A level's ground is one height per 24-unit column:
//
//   H[c] = -1      a pit: no ground, the player falls (water at the bottom)
//   H[c] =  0      the base ground, whose surface is y = 660
//   H[c] =  n > 0  raised ground, n tiles (24 units each) above the base
//
// Everything else is derived from it: blocks (runs of equal height), pits, and
// the tile layer written to the .tmx, where each cell gets the right edge, cap
// or wall tile from the ground tileset so the map looks finished when opened
// in Tiled and the game only has to draw what the layer says.
const { physics } = require('./rules');

const TILE = physics.tile; // 24: the ground tiles are drawn at 1.5x, like the platforms, enemies and player
const ROWS = physics.mapRows; // 45
const BASE_ROW = physics.groundRow; // 41: the base surface is the top of this row
// Row 27 starts at y 648 on the 24 grid, but the base surface is 660, so the
// tile layer is drawn 12 units lower than rows * 24. Raised ground then lands on
// 660 - 24 * n exactly.
const ORIGIN_Y = physics.groundSurfaceY - BASE_ROW * TILE; // 4
const BASE_Y = physics.groundSurfaceY;

const surfaceY = (h) => BASE_Y - h * TILE;
const heightOfY = (y) => Math.round((BASE_Y - y) / TILE);

// ── derived geometry (x in world units) ─────────────────────────────────────
function blocksOf(H) {
  const out = [];
  let c0 = 0;
  for (let c = 1; c <= H.length; c++) {
    if (c === H.length || H[c] !== H[c0]) {
      if (H[c0] >= 0) out.push({ start: c0 * TILE, end: c * TILE, h: H[c0], top: surfaceY(H[c0]) });
      c0 = c;
    }
  }
  return out;
}

// Pits: runs of -1 that have ground on both sides (not the level's outer edge).
function pitsOf(H) {
  const out = [];
  let c0 = null;
  for (let c = 0; c <= H.length; c++) {
    const pit = c < H.length && H[c] < 0;
    if (pit && c0 === null) c0 = c;
    if (!pit && c0 !== null) {
      if (c0 > 0 && c < H.length) out.push({ start: c0 * TILE, end: c * TILE });
      c0 = null;
    }
  }
  return out;
}

// Runs of ground of any height: what lies between two pits.
function spansOf(H) {
  const out = [];
  let c0 = null;
  for (let c = 0; c <= H.length; c++) {
    const solid = c < H.length && H[c] >= 0;
    if (solid && c0 === null) c0 = c;
    if (!solid && c0 !== null) { out.push({ start: c0 * TILE, end: c * TILE }); c0 = null; }
  }
  return out;
}

// The ground height under x, or -1 over a pit.
function heightAt(H, x) {
  const c = Math.floor(x / TILE);
  return c < 0 || c >= H.length ? -1 : H[c];
}

const isOverGround = (H, x) => heightAt(H, x) >= 0;

// ── the tile sets ───────────────────────────────────────────────────────────
// 1-based GIDs into ground_tileset.png (7 columns x 8 rows, 16px tiles).
// Orange earth is rows 0-1, blue stone rows 2-3. Both share the plain fill (12).
const THEMES = {
  orange: {
    capMid: [2], capL: 9, capR: 10, capBoth: 7,
    bareMid: [5], bareL: 4, bareR: 6, bareBoth: 7,
    wallL: 11, wallR: 13, wallBoth: 14,
    fill: 12, speck: 8,
  },
  blue: {
    capMid: [16, 17], capL: 23, capR: 24, capBoth: 21,
    bareMid: [19], bareL: 18, bareR: 20, bareBoth: 21,
    wallL: 25, wallR: 27, wallBoth: 28,
    fill: 12, speck: 22,
  },
};

// Cheap deterministic hash so the variation (specks, which cap) never needs the
// level's random stream: the same terrain always draws the same tiles.
const mix = (a, b) => {
  let h = (a * 374761393 + b * 668265263) >>> 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177) >>> 0;
  return (h ^ (h >>> 16)) >>> 0;
};

// The crate tile: a 12x12 box with a margin round it, drawn cropped (see
// CRATE_SRC) so a pile of them is solid.
const CRATE = 30;
const CRATE_SRC = { x: 3, y: 2, w: 12, h: 12 };

// The tile layer, rows x cols of GIDs (0 = empty). S[c] = 1 gives a column a bare
// stone top instead of a grassy one; C[c] = n puts n rows of crates on top of it.
function autotile(H, S, themeName, C) {
  const T = THEMES[themeName];
  if (!T) throw new Error('unknown tile theme ' + themeName);
  const cols = H.length;
  const solid = (c, r) => c >= 0 && c < cols && H[c] >= 0 && r >= BASE_ROW - H[c];
  const rows = [];
  for (let r = 0; r < ROWS; r++) {
    const row = new Array(cols).fill(0);
    for (let c = 0; c < cols; c++) {
      if (!solid(c, r)) continue;
      if (C && C[c] > 0 && r < BASE_ROW - H[c] + C[c]) { row[c] = CRATE; continue; }
      const up = solid(c, r - 1);
      const left = solid(c - 1, r);
      const right = solid(c + 1, r);
      let gid;
      if (!up) {
        const bare = S && S[c] === 1;
        const mids = bare ? T.bareMid : T.capMid;
        if (!left && !right) gid = bare ? T.bareBoth : T.capBoth;
        else if (!left) gid = bare ? T.bareL : T.capL;
        else if (!right) gid = bare ? T.bareR : T.capR;
        else gid = mids[mix(c, r) % mids.length];
      } else if (!left && !right) gid = T.wallBoth;
      else if (!left) gid = T.wallL;
      else if (!right) gid = T.wallR;
      else gid = mix(c, r) % 7 === 0 ? T.speck : T.fill;
      row[c] = gid;
    }
    rows.push(row);
  }
  return rows;
}

// Which tile set an era uses: a deliberate alternation, so neighbouring eras look
// different (earth, stone, earth, stone ...).
const ERA_THEME = {
  'pre-colonial': 'orange',
  spanish: 'blue',
  nationalism: 'orange',
  american: 'blue',
  ww2: 'orange',
  modern: 'blue',
};

module.exports = {
  TILE, ROWS, BASE_ROW, ORIGIN_Y, BASE_Y, THEMES, ERA_THEME, CRATE, CRATE_SRC,
  surfaceY, heightOfY, blocksOf, pitsOf, spansOf, heightAt, isOverGround, autotile,
};
