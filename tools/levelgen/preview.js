#!/usr/bin/env node
'use strict';
// Contact sheet: one strip per level, so many levels can be reviewed at a glance
// without playing them.   node tools/levelgen/preview.js [--dir d] [--out file.html] [--era id]
const fs = require('fs');
const path = require('path');
const { physics, rules, eras } = require('./rules');
const T = require('./terrain');
const tmx = require('./tmx');

const SX = 0.04; // 25,000 units -> 1,000px
const VS = 0.3; // vertical scale: a 96-high mesa is 29px, a 288 tower 86px
const GY = 128; // the base ground surface, in svg y
const W = 1008;

const ACTS = [
  { name: 'Introduce', from: 0, to: 2 },
  { name: 'Develop', from: 2, to: 6 },
  { name: 'Twist', from: 6, to: 8 },
  { name: 'Conclude', from: 8, to: 10 },
];

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const fmt = (n) => n.toLocaleString('en-US');
const clock = (units) => {
  const s = Math.round(units / physics.forwardSpeed);
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
};

function strip(level) {
  const x = (v) => (v * SX).toFixed(1);
  const parts = [];
  const blocks = T.blocksOf(level.H);

  if (level.generated) {
    ACTS.forEach((a, i) => {
      const x0 = (rules.safeStart + a.from * rules.groupWidth) * SX;
      const x1 = (rules.safeStart + a.to * rules.groupWidth) * SX;
      parts.push(`<rect x="${x0.toFixed(1)}" y="0" width="${(x1 - x0).toFixed(1)}" height="13" class="act a${i}"/>`);
      parts.push(`<text x="${((x0 + x1) / 2).toFixed(1)}" y="9.5" class="actlabel" text-anchor="middle">${a.name}</text>`);
    });
    for (let g = 0; g <= rules.groups; g++) {
      parts.push(`<line x1="${x(rules.safeStart + g * rules.groupWidth)}" x2="${x(rules.safeStart + g * rules.groupWidth)}" y1="13" y2="${GY + 22}" class="tick"/>`);
    }
  }
  // pits: water
  for (const p of T.pitsOf(level.H)) {
    parts.push(`<rect x="${x(p.start)}" y="${GY}" width="${((p.end - p.start) * SX).toFixed(1)}" height="18" class="water"/>`);
  }
  // ground: one column of height per block
  for (const b of blocks) {
    const h = (physics.groundSurfaceY - b.top) * VS;
    parts.push(`<rect x="${x(b.start)}" y="${(GY - h).toFixed(1)}" width="${((b.end - b.start) * SX).toFixed(1)}" height="${(h + 18).toFixed(1)}" class="ground"/>`);
  }
  const surfaceAt = (px) => {
    const h = T.heightAt(level.H, px);
    return h >= 0 ? GY - (physics.groundSurfaceY - T.surfaceY(h)) * VS : GY;
  };
  for (const p of level.platforms) {
    parts.push(`<rect x="${x(p.x)}" y="${(GY - (physics.groundSurfaceY - p.y) * VS).toFixed(1)}" width="${Math.max(4, p.width * SX).toFixed(1)}" height="3" rx="1" class="platform"/>`);
  }
  for (const e of level.enemies) {
    const base = e.y !== undefined ? GY - (physics.groundSurfaceY - e.y) * VS : GY;
    const r = e.behavior === 'heavy' ? 0 : e.patrol;
    if (r > 0) parts.push(`<line x1="${x(e.x - r)}" x2="${x(e.x + r + physics.enemyWidth)}" y1="${(base - 2).toFixed(1)}" y2="${(base - 2).toFixed(1)}" class="patrol"/>`);
    parts.push(
      e.behavior === 'heavy'
        ? `<rect x="${(e.x * SX).toFixed(1)}" y="${(base - 9).toFixed(1)}" width="6" height="9" class="heavy"><title>${esc(e.kind)}</title></rect>`
        : `<circle cx="${((e.x + 45) * SX).toFixed(1)}" cy="${(base - 5).toFixed(1)}" r="3.2" class="walker"><title>${esc(e.kind)}, patrol ${e.patrol}</title></circle>`
    );
  }
  [...level.artifacts].sort((a, b) => a.x - b.x).forEach((a, i) => {
    const cx = (a.x + physics.artifactSize / 2) * SX;
    parts.push(`<circle cx="${cx.toFixed(1)}" cy="${GY - 150 * VS}" r="6.5" class="artifact"/>`);
    parts.push(`<text x="${cx.toFixed(1)}" y="${GY - 150 * VS + 3}" class="artnum" text-anchor="middle">${i + 1}</text>`);
  });
  for (const gx of level.gates) parts.push(`<rect x="${x(gx)}" y="${GY - 62 * VS * 2}" width="3" height="${62 * VS * 2}" class="gate"><title>end gate</title></rect>`);
  parts.push(`<path d="M${x(level.spawnX)} ${GY} v-16 l8 4 l-8 4" class="spawn"/>`);

  for (let sec = 0; sec <= 120; sec += 30) {
    const px = sec * physics.forwardSpeed * SX;
    if (px > level.mapWidth * SX + 1) break;
    parts.push(`<line x1="${px.toFixed(1)}" x2="${px.toFixed(1)}" y1="${GY + 18}" y2="${GY + 23}" class="rule"/>`);
    parts.push(`<text x="${px.toFixed(1)}" y="${GY + 33}" class="ruletext" text-anchor="${sec === 0 ? 'start' : 'middle'}">${Math.floor(sec / 60)}:${String(sec % 60).padStart(2, '0')}</text>`);
  }
  void surfaceAt;
  return `<svg viewBox="0 0 ${W} ${GY + 38}" width="${W}" role="img" aria-label="level layout">${parts.join('')}</svg>`;
}

function card(file, level) {
  const m = path.basename(file).match(/^era(\d+)_(\d+)\.tmx$/);
  const era = eras[Number(m[1]) - 1];
  const n = Number(m[2]);
  const count = era.levelWeeks.length;
  const opener = n === 1 && level.generated;
  const d = opener ? 0 : (n - 2) / Math.max(1, count - 3);
  const heavies = level.enemies.filter((e) => e.behavior === 'heavy').length;
  const blocks = T.blocksOf(level.H);
  const raised = blocks.filter((b) => b.h > 0).length;
  const tallest = Math.max(...blocks.map((b) => b.h)) * T.TILE;
  const pits = T.pitsOf(level.H).length;
  const tag = !level.generated ? 'hand-built prototype' : opener ? 'era opener' : `difficulty ${d.toFixed(2)}`;
  return `<section class="level">
  <h2>${esc(era.id)} ${n} <span class="tag">${tag}</span></h2>
  <ul class="stats">
    <li><b>${pits}</b> pits</li>
    <li><b>${raised}</b> raised blocks (tallest <b>${tallest}</b>)</li>
    <li><b>${level.enemies.length}</b> enemies${heavies ? ` (${heavies} heavy)` : ''}</li>
    <li><b>${level.platforms.length}</b> platforms</li>
    <li><b>${level.coins.length}</b> coins</li>
    <li><b>${fmt(level.mapWidth)}</b> units, about <b>${clock(level.exitX)}</b> of walking</li>
  </ul>
  <div class="scroll">${strip(level)}</div>
</section>`;
}

function build(dir, only) {
  const files = fs.readdirSync(dir).filter((f) => /^era\d+_\d+\.tmx$/.test(f)).sort((a, b) => {
    const [ea, la] = a.match(/\d+/g).map(Number);
    const [eb, lb] = b.match(/\d+/g).map(Number);
    return ea - eb || la - lb;
  });
  const cards = [];
  for (const f of files) {
    const level = tmx.read(fs.readFileSync(path.join(dir, f), 'utf8'));
    if (only && level.props.era !== only) continue;
    cards.push(card(f, level));
  }
  return cards.join('\n');
}

module.exports = { build, strip };

if (require.main === module) {
  const args = process.argv.slice(2);
  const get = (k) => { const i = args.indexOf('--' + k); return i >= 0 ? args[i + 1] : undefined; };
  const dir = get('dir') || path.join(__dirname, '..', '..', 'assets', 'tiles', 'levels');
  const out = get('out') || path.join(__dirname, 'level_drafts.html');
  const html = build(dir, get('era'));
  fs.writeFileSync(out, html);
  console.log(`wrote ${out} (${html.length} chars)`);
}
