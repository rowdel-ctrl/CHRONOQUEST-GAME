#!/usr/bin/env node
'use strict';
// Draws part of a level as a PNG, with the real tileset and sprites, the way the
// game draws it (ground tiles at 16 units, platforms at 24, sprites at their game
// sizes). For reviewing a level without running the game.
//
//   node tools/levelgen/render.js --level assets/tiles/levels/era1_3.tmx --x 8000 --out shot.png
//   node tools/levelgen/render.js --level ... --section 3        (one whole section, scaled to fit)
const fs = require('fs');
const path = require('path');
const { readPng, writePng } = require('./png');
const { physics, rules } = require('./rules');
const T = require('./terrain');
const tmx = require('./tmx');

const ASSETS = path.join(__dirname, '..', '..', 'assets');
const cache = new Map();
const sprite = (rel) => {
  if (!cache.has(rel)) cache.set(rel, readPng(path.join(ASSETS, rel)));
  return cache.get(rel);
};

// The body colour each era paints the inside of its ground (see recolor.js).
const { BODY } = require('./recolor');
const SKY = {
  'pre-colonial': [[96, 150, 110], [40, 80, 60]],
  spanish: [[170, 140, 90], [90, 70, 45]],
  nationalism: [[190, 165, 80], [100, 85, 40]],
  american: [[180, 170, 120], [100, 95, 65]],
  ww2: [[120, 140, 150], [55, 70, 80]],
  modern: [[100, 170, 180], [40, 85, 95]],
};

function recolored(era, body) {
  const key = 'tiles/ground_tileset.png#' + era + (body ? body.join() : 'orig');
  if (cache.has(key)) return cache.get(key);
  const src = sprite('tiles/ground_tileset.png');
  const out = { width: src.width, height: src.height, data: Buffer.from(src.data) };
  if (body) {
    for (let i = 0; i < out.data.length; i += 4) {
      if (out.data[i] === 39 && out.data[i + 1] === 32 && out.data[i + 2] === 52) {
        out.data[i] = body[0]; out.data[i + 1] = body[1]; out.data[i + 2] = body[2];
      }
    }
  }
  cache.set(key, out);
  return out;
}

class Canvas {
  constructor(w, h) { this.width = w; this.height = h; this.data = Buffer.alloc(w * h * 4); }
  fill(r, g, b, a = 255) { for (let i = 0; i < this.data.length; i += 4) { this.data[i] = r; this.data[i + 1] = g; this.data[i + 2] = b; this.data[i + 3] = a; } }
  rect(x, y, w, h, [r, g, b], a = 255) {
    for (let yy = Math.max(0, Math.round(y)); yy < Math.min(this.height, Math.round(y + h)); yy++) {
      for (let xx = Math.max(0, Math.round(x)); xx < Math.min(this.width, Math.round(x + w)); xx++) this.px(xx, yy, r, g, b, a);
    }
  }
  px(x, y, r, g, b, a) {
    const i = (y * this.width + x) * 4;
    if (a >= 255) { this.data[i] = r; this.data[i + 1] = g; this.data[i + 2] = b; this.data[i + 3] = 255; return; }
    const k = a / 255;
    this.data[i] = this.data[i] * (1 - k) + r * k;
    this.data[i + 1] = this.data[i + 1] * (1 - k) + g * k;
    this.data[i + 2] = this.data[i + 2] * (1 - k) + b * k;
    this.data[i + 3] = 255;
  }
  // Nearest-neighbour blit of a source rect into a destination rect.
  blit(src, sx, sy, sw, sh, dx, dy, dw, dh, flip = false) {
    for (let yy = 0; yy < dh; yy++) {
      const y = Math.round(dy) + yy;
      if (y < 0 || y >= this.height) continue;
      const v = Math.min(sh - 1, Math.floor((yy / dh) * sh));
      for (let xx = 0; xx < dw; xx++) {
        const x = Math.round(dx) + xx;
        if (x < 0 || x >= this.width) continue;
        let u = Math.min(sw - 1, Math.floor((xx / dw) * sw));
        if (flip) u = sw - 1 - u;
        const i = ((sy + v) * src.width + sx + u) * 4;
        const a = src.data[i + 3];
        if (a === 0) continue;
        this.px(x, y, src.data[i], src.data[i + 1], src.data[i + 2], a);
      }
    }
  }
}

const tileRect = (gid) => ({ sx: ((gid - 1) % 7) * 16, sy: Math.floor((gid - 1) / 7) * 16 });

function drawTile(cv, sheet, gid, dx, dy, size = T.TILE, h = size) {
  const { sx, sy } = tileRect(gid);
  if (gid === T.CRATE) {
    const c = T.CRATE_SRC; // a crate has a margin; draw only the box
    cv.blit(sheet, sx + c.x, sy + c.y, c.w, c.h, dx, dy, size, h);
    return;
  }
  cv.blit(sheet, sx, sy, 16, 16, dx, dy, size, h);
}


// One window of the level, x0..x0+width in world units, drawn at 1:1.
function renderWindow(level, x0, { width = 1280, height = 720, body = true } = {}) {
  const era = level.props.era;
  const cv = new Canvas(width, height);
  const [top, bot] = SKY[era] || SKY['pre-colonial'];
  for (let y = 0; y < height; y++) {
    const k = y / height;
    cv.rect(0, y, width, 1, top.map((v, i) => Math.round(v + (bot[i] - v) * k)));
  }
  const sheet = recolored(era, body ? BODY[era] : null);
  const theme = T.ERA_THEME[era];
  const cols = level.H.length;
  const grid = level.grid || T.autotile(level.H, level.S && level.S.length === cols ? level.S : null, theme);

  // water in the pits
  for (const p of T.pitsOf(level.H)) {
    const a = p.start - x0, b = p.end - x0;
    if (b < 0 || a > width) continue;
    cv.rect(a, 696, b - a, 24, [50, 138, 171], 235);
    for (let x = Math.max(0, Math.round(a)); x < Math.min(width, b); x += T.TILE) drawTile(cv, sheet, 37, x, 690, T.TILE, 16);
  }

  const c0 = Math.max(0, Math.floor(x0 / T.TILE));
  const c1 = Math.min(cols, Math.ceil((x0 + width) / T.TILE));
  const bodyRGB = BODY[era];
  for (let c = c0; c < c1; c++) {
    if (level.H[c] < 0) continue;
    const topY = T.surfaceY(level.H[c]);
    if (body) cv.rect(c * T.TILE - x0, topY + 4, T.TILE, height - topY, bodyRGB);
    for (let r = 0; r < T.ROWS; r++) {
      const gid = grid[r][c];
      if (gid) drawTile(cv, sheet, gid, c * T.TILE - x0, T.ORIGIN_Y + r * T.TILE);
    }
  }

  // platforms (24-unit tiles, as TilePlatformComponent draws them)
  const orig = recolored(era, body ? BODY[era] : null);
  for (const p of level.platforms) {
    const n = Math.round(p.width / 24);
    for (let i = 0; i < n; i++) {
      const gid = i === 0 ? 9 : i === n - 1 ? 10 : 2;
      drawTile(cv, orig, gid, p.x - x0 + i * 24, p.y, 24, 24);
      drawTile(cv, orig, i === 0 ? 11 : i === n - 1 ? 13 : 12, p.x - x0 + i * 24, p.y + 24, 24, 8);
    }
  }
  for (const c of level.coins) cv.blit(sprite('collectibles/coin.png'), 0, 0, 28, 28, c.x - x0, c.y, 42, 42);
  for (const a of level.artifacts) {
    cv.blit(sprite(`collectibles/${a.art}.png`), 0, 0, sprite(`collectibles/${a.art}.png`).width, sprite(`collectibles/${a.art}.png`).height, a.x - x0, 660 - 96, 72, 72);
  }
  for (const e of level.enemies) {
    const img = sprite(`enemies/${e.kind}_1.png`);
    const y = e.y ?? 660;
    cv.blit(img, 0, 0, img.width, img.height, e.x - x0, y - 108, 90, 108, true);
  }
  for (const g of level.gates) cv.rect(g - x0, 660 - 200, 144, 200, [70, 60, 50]);
  const pl = sprite('characters/rizal_walk_1.png');
  const px = level.spawnX - x0;
  if (px > -100 && px < width) cv.blit(pl, 0, 0, pl.width, pl.height, px, 660 - 120, 96, 120);
  return cv;
}

// A crop of a canvas, blown up with nearest-neighbour so pixels stay square.
function zoomed(cv, cx, cy, cw, ch, z) {
  const out = new Canvas(cw * z, ch * z);
  for (let y = 0; y < ch * z; y++) {
    for (let x = 0; x < cw * z; x++) {
      const i = ((cy + Math.floor(y / z)) * cv.width + cx + Math.floor(x / z)) * 4;
      const o = (y * out.width + x) * 4;
      out.data[o] = cv.data[i]; out.data[o + 1] = cv.data[i + 1]; out.data[o + 2] = cv.data[i + 2]; out.data[o + 3] = 255;
    }
  }
  return out;
}

// Four windows of a level in one image, each at half size (a 2x2 sheet), so a
// section can be judged at a glance. [xs] are world x of each window's left edge.
function sheet(level, xs) {
  const out = new Canvas(1280, 720);
  xs.slice(0, 4).forEach((x0, i) => {
    const cv = renderWindow(level, x0, { width: 1280 });
    const ox = (i % 2) * 640, oy = Math.floor(i / 2) * 360;
    for (let y = 0; y < 360; y++) {
      for (let x = 0; x < 640; x++) {
        let r = 0, g = 0, b = 0;
        for (let dy = 0; dy < 2; dy++) for (let dx = 0; dx < 2; dx++) {
          const k = ((y * 2 + dy) * cv.width + x * 2 + dx) * 4;
          r += cv.data[k]; g += cv.data[k + 1]; b += cv.data[k + 2];
        }
        const o = ((oy + y) * 1280 + ox + x) * 4;
        out.data[o] = r >> 2; out.data[o + 1] = g >> 2; out.data[o + 2] = b >> 2; out.data[o + 3] = 255;
      }
    }
    out.rect(ox, oy, 640, 2, [255, 255, 255], 120);
    out.rect(ox, oy, 2, 360, [255, 255, 255], 120);
  });
  return out;
}

function main(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i++) if (argv[i].startsWith('--')) args[argv[i].slice(2)] = argv[i + 1];
  const level = tmx.read(fs.readFileSync(args.level, 'utf8'));
  let x0 = Number(args.x || 0);
  if (args.section !== undefined) x0 = rules.safeStart + Number(args.section) * rules.groupWidth;
  if (args.sheet) {
    const xs = args.sheet.split(',').map((v) => (v.startsWith('s') ? rules.safeStart + Number(v.slice(1)) * rules.groupWidth : Number(v)));
    writePng(args.out || 'sheet.png', sheet(level, xs));
    console.log('wrote', args.out || 'sheet.png');
    return;
  }
  let cv = renderWindow(level, x0, { width: Number(args.w || 1280), body: args.body !== 'off' });
  if (args.zoom) cv = zoomed(cv, Number(args.cx || 0), Number(args.cy || 0), Number(args.cw || 400), Number(args.ch || 200), Number(args.zoom));
  writePng(args.out || 'shot.png', cv);
  console.log('wrote', args.out || 'shot.png', 'x', x0);
}

if (require.main === module) main(process.argv.slice(2));
module.exports = { sheet, renderWindow, Canvas, BODY, SKY, sprite, recolored, drawTile };
