'use strict';
// Hard rules. Mirrors test/game/level_lint_test.dart (which runs the structural
// checks through the game's own loader), plus the stricter rules that only apply
// to generated levels, plus the solver (solve.js), which plays the level.
// Returns a list of problems; empty means the level is valid.
const { physics, rules, eras } = require('./rules');
const T = require('./terrain');
const { solve } = require('./solve');

const ENEMY_INSET = (physics.enemyWidth * (1 - physics.footSpanFraction)) / 2; // 22.5
const DEFAULT_PATROL = 150;

function enemyRange(e) {
  return e.behavior === 'heavy' ? 0 : Number.isFinite(e.patrol) ? e.patrol : DEFAULT_PATROL;
}

const onRaised = (e) => e.y !== undefined && e.y < physics.groundSurfaceY - 1;

// What an enemy stands on: the block (ground of one height) or the platform whose
// top is at its feet, with its centre over it. Null if there is none.
function supportOf(e, blocks, platforms) {
  const y = e.y ?? physics.groundSurfaceY;
  const centre = e.x + physics.enemyWidth / 2;
  const b = blocks.find((q) => Math.abs(q.top - y) < 1 && centre >= q.start && centre <= q.end);
  if (b) return { kind: 'block', start: b.start, end: b.end, block: b };
  const p = platforms.find((q) => Math.abs(q.y - y) < 1 && centre >= q.x && centre <= q.x + q.width);
  if (p) return { kind: 'platform', start: p.x, end: p.x + p.width };
  return null;
}

// Same test as LoadedLevel.enemyStaysOnSupport: the whole patrol corridor,
// measured by the enemy's centred foot span, must sit inside what it stands on.
function enemyStaysOnSupport(e, blocks, platforms) {
  const s = supportOf(e, blocks, platforms);
  if (!s) return false;
  const r = enemyRange(e);
  const left = e.x - r + ENEMY_INSET;
  const right = e.x + r + physics.enemyWidth - ENEMY_INSET;
  return left >= s.start && right <= s.end;
}

// An edge of a block is a hazard if stepping off it, or landing beside it, is a
// real event: a pit or a rise or drop of two tiles or more. One-tile steps are
// just slopes.
function hazardEdges(block, H) {
  const lc = block.start / T.TILE - 1, rc = block.end / T.TILE;
  const hz = (n) => n === undefined || n < 0 || Math.abs(n - block.h) >= 2;
  return { left: hz(H[lc] === undefined ? -1 : H[lc]), right: hz(H[rc] === undefined ? -1 : H[rc]) };
}

function validate(level, { generated = level.generated !== false, play = true } = {}) {
  const problems = [];
  const era = eras.find((e) => e.id === level.props.era);
  if (!era) return [`unknown era ${level.props.era}`];
  const H = level.H;
  const blocks = T.blocksOf(H);
  const pits = T.pitsOf(H);
  const heavy = new Set(era.heavy);

  // ── identity ──
  const n = era.levelWeeks.length;
  if (level.props.level < 1 || level.props.level > n) problems.push(`level ${level.props.level} is not in ${era.id}`);
  if (level.props.level === n) problems.push('boss levels are not generated');
  if (level.props.grade !== era.grade || level.props.term !== era.term) problems.push('grade or term does not match the registry');
  if (generated && level.props.weeks !== era.levelWeeks[level.props.level - 1]?.join(',')) problems.push('weeks do not match the registry');

  // ── start, end, length ──
  if (!T.isOverGround(H, level.spawnX)) problems.push('spawn is not over ground');
  if (!T.isOverGround(H, level.exitX)) problems.push('exit is not over ground');
  if (generated && T.heightAt(H, level.spawnX) !== 0) problems.push('spawn is not on the base ground');
  if (generated && (level.mapWidth < physics.lengthUnits - 100 || level.mapWidth > physics.lengthUnits + 100)) {
    problems.push(`map is ${level.mapWidth} wide, expected about ${physics.lengthUnits}`);
  }

  // ── terrain ──
  for (let c = 0; c + 1 < H.length; c++) {
    if (H[c] >= 0 && H[c + 1] >= 0 && H[c + 1] - H[c] > rules.maxRiseTiles) {
      problems.push(`a rise of ${(H[c + 1] - H[c]) * T.TILE} at ${(c + 1) * T.TILE}, over ${rules.maxRiseTiles * T.TILE}`);
    }
    if (H[c] > rules.maxHeightTiles) problems.push(`ground at ${c * T.TILE} is ${H[c] * T.TILE} high, over ${rules.maxHeightTiles * T.TILE}`);
  }
  for (const b of blocks) {
    // A slope's steps are narrow on purpose; a sliver with a drop or a wall on both sides is not.
    const hz = hazardEdges(b, H);
    if (hz.left && hz.right && b.end - b.start < 3 * T.TILE && b.start > 0 && b.end < level.mapWidth) problems.push(`ground at ${b.start} is only ${b.end - b.start} wide`);
  }
  for (const g of pits) {
    const w = g.end - g.start;
    const over = level.platforms.filter((p) => p.x < g.end && p.x + p.width > g.start);
    if (w > rules.gapMax && over.length === 0) problems.push(`pit at ${g.start} is ${w} wide with no platform`);
    if (w < 4 * T.TILE) problems.push(`pit at ${g.start} is only ${w} wide`);
    if (generated && w > 1152) problems.push(`pit at ${g.start} is ${w} wide, over 1152`);
    if (generated && g.start < rules.safeStart) problems.push(`pit at ${g.start} is inside the safe start`);
    if (generated && over.length === 0 && w > rules.gapPlainMax) problems.push(`platformless pit at ${g.start} is ${w} wide, over ${rules.gapPlainMax}`);
  }
  if (generated) {
    for (const b of blocks) {
      if (b.h > 0 && b.start < rules.safeStart + 100) problems.push(`raised ground at ${b.start} is inside the safe start`);
    }
  }

  // ── the one end gate and the artifacts ──
  if (level.gates.length !== 1) problems.push(`${level.gates.length} gates, expected 1`);
  else if (level.gates[0] < level.exitX - physics.gateWidth) problems.push('the gate is not at the exit');
  else if (generated && level.gates[0] + physics.gateWidth > level.mapWidth) problems.push('the gate runs off the end of the map');
  if (level.artifacts.length !== physics.artifactsPerLevel) problems.push(`${level.artifacts.length} artifacts, expected ${physics.artifactsPerLevel}`);
  for (const a of level.artifacts) {
    if (!/^artifact_[1-5]$/.test(a.art || '')) problems.push(`artifact at ${a.x} has art ${a.art}`);
    if (level.gates.length && a.x >= level.gates[0]) problems.push(`artifact at ${a.x} is past the gate`);
    // An artifact stands on the ground under it, at that ground's height.
    const ah = T.heightAt(H, a.x + physics.artifactSize / 2);
    const ay = a.y ?? physics.groundSurfaceY;
    if (ah < 0 || Math.abs(T.surfaceY(ah) - ay) > 1) problems.push(`artifact at ${a.x} is not standing on the ground (y ${ay})`);
  }
  if (generated) {
    const xs = level.artifacts.map((a) => a.x).sort((a, b) => a - b);
    for (let i = 1; i < xs.length; i++) {
      if (xs[i] - xs[i - 1] < 1500) problems.push(`artifacts at ${xs[i - 1]} and ${xs[i]} are too close`);
    }
    if (xs.length && xs[0] < rules.safeStart) problems.push('the first artifact is inside the safe start');
  }

  // ── platforms ──
  for (const p of level.platforms) {
    if (p.width % physics.platformTile !== 0) problems.push(`platform at ${p.x} is ${p.width} wide, not a multiple of ${physics.platformTile}`);
    if (generated && (p.y < rules.platformMinY || physics.groundSurfaceY - p.y < 48)) problems.push(`platform at ${p.x} floats at y ${p.y}, outside the allowed band`);
    // Not inside the ground: every column under it is a pit or well below it.
    for (let x = p.x; x < p.x + p.width; x += T.TILE) {
      const h = T.heightAt(H, x);
      if (h >= 0 && T.surfaceY(h) < p.y + 32 + 56) { problems.push(`platform at ${p.x} sits in the ground at ${x}`); break; }
    }
  }

  // ── enemies ──
  const enemies = [...level.enemies].sort((a, b) => a.x - b.x);
  const supports = new Map();
  for (const e of enemies) {
    if (!era.enemyTypes.includes(e.kind)) problems.push(`enemy at ${e.x} is "${e.kind}", not one of ${era.enemyTypes}`);
    if (e.behavior !== (heavy.has(e.kind) ? 'heavy' : 'walker')) problems.push(`enemy "${e.kind}" at ${e.x} has behavior ${e.behavior}`);
    if (!enemyStaysOnSupport(e, blocks, level.platforms)) problems.push(`enemy at ${e.x} patrols off its ground`);
    else supports.set(e, supportOf(e, blocks, level.platforms));
    if (generated && e.x - enemyRange(e) < rules.safeStart) problems.push(`enemy at ${e.x} patrols into the safe start`);
  }
  const isPlatformEnemy = (e) => supports.get(e)?.kind === 'platform';
  const spacing = generated ? rules.enemySpacing : 400;
  for (let i = 1; i < enemies.length; i++) {
    const need = generated && (isPlatformEnemy(enemies[i]) || isPlatformEnemy(enemies[i - 1])) ? rules.fightEnemySpacing : spacing;
    if (enemies[i].x - enemies[i - 1].x < need) problems.push(`enemies at ${enemies[i - 1].x} and ${enemies[i].x} are under ${need} apart`);
  }

  // ── fairness and coins (generated levels only) ──
  if (generated) {
    for (const e of enemies) {
      const r = enemyRange(e);
      const left = e.x - r;
      const right = e.x + r + physics.enemyWidth;
      for (const a of level.artifacts) {
        const d = Math.max(left - (a.x + physics.artifactSize), a.x - right, 0);
        if (d < rules.artifactClearance) problems.push(`enemy at ${e.x} patrols within ${d} of the artifact at ${a.x}`);
      }
      // An enemy that guards a ledge hits a student the moment they land. Keep its
      // whole patrol clear of every hazard edge of the ground it stands on.
      const s = supports.get(e);
      if (s && s.kind === 'block') {
        const hz = hazardEdges(s.block, H);
        if (hz.left && left - s.start < rules.enemyGapClearance) problems.push(`enemy at ${e.x} patrols within ${left - s.start} of the left edge of its ground`);
        if (hz.right && s.end - right < rules.enemyGapClearance) problems.push(`enemy at ${e.x} patrols within ${s.end - right} of the right edge of its ground`);
      }
    }
    // A platform enemy (a fight) is never in the first two sections.
    for (const e of enemies) {
      if (isPlatformEnemy(e) && e.x < rules.safeStart + rules.fightFirstSection * rules.groupWidth) problems.push(`a platform fight at ${e.x} is in the first sections`);
      if (isPlatformEnemy(e) && e.behavior === 'heavy') problems.push(`the enemy on the platform at ${e.x} is a heavy`);
    }
    if (!enemies.some(isPlatformEnemy)) problems.push('the level has no platform fight');
    // Every section has something to do: an enemy, and some terrain to cross.
    for (let s = 0; s < rules.groups; s++) {
      const from = rules.safeStart + s * rules.groupWidth;
      const to = from + rules.groupWidth;
      if (!enemies.some((e) => e.x >= from && e.x < to)) problems.push(`section ${s + 1} has no enemy`);
      // Something to cross: a pit, or the ground changing height, within the section.
      const heights = new Set();
      for (let c = from / T.TILE; c < (to - rules.restWidth) / T.TILE; c++) heights.add(H[c]);
      const terrain = heights.size > 1;
      if (!terrain) problems.push(`section ${s + 1} has no terrain to cross`);
    }
    const share = (blocks.filter((b) => b.h > 0).reduce((s, b) => s + b.end - b.start, 0) + pits.reduce((s, p) => s + p.end - p.start, 0)) / level.mapWidth;
    if (share < 0.2) problems.push(`only ${Math.round(share * 100)}% of the level is raised ground or pits`);
    if (level.pieces) {
      const kinds = new Set(level.pieces.map((p) => p.type).filter((t) => !['walker', 'heavy'].includes(t)));
      if (kinds.size < 4) problems.push(`only ${kinds.size} kinds of set piece`);
    }
    for (const c of level.coins) {
      const h = T.heightAt(H, c.x + 21);
      // The coin is 42 tall; it may sit 2 into the ground the way the rest-area coins do.
      if (h >= 0 && c.y + 42 > T.surfaceY(h) + 4) problems.push(`coin at (${c.x}, ${c.y}) is inside the ground`);
      if (c.y < 100) problems.push(`coin at (${c.x}, ${c.y}) is off the top of the screen`);
    }
  }

  // ── the solver plays it ──
  if (play && problems.length === 0) {
    const r = solve(level);
    if (!r.reachable) problems.push(`the end cannot be reached (furthest ${Math.round(r.furthest)})`);
    else if (r.traps.length) problems.push(`${r.traps.length} places you can reach but not leave, first near ${Math.round(r.traps[0].x)}`);
  }
  return problems;
}

module.exports = { validate, enemyStaysOnSupport, supportOf, enemyRange, hazardEdges };
