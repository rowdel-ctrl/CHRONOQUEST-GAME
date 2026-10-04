'use strict';
// Hard rules. Mirrors test/game/level_lint_test.dart (which runs the same
// checks through the game's own loader), plus stricter rules that only apply to
// generated levels. Returns a list of problems; empty means the level is valid.
const { physics, rules, eras, reach, footSpan } = require('./rules');
const { groundSpans, isOverGround } = require('./tmx');

const ENEMY_INSET = (physics.enemyWidth * (1 - physics.footSpanFraction)) / 2; // 22.5
const DEFAULT_PATROL = 150;

function enemyRange(e) {
  return e.behavior === 'heavy' ? 0 : Number.isFinite(e.patrol) ? e.patrol : DEFAULT_PATROL;
}

// Same test as LoadedLevel.enemyStaysOnGround: the whole patrol corridor,
// measured by the enemy's centred foot span, must sit inside one ground span.
function enemyStaysOnGround(e, spans) {
  const r = enemyRange(e);
  const left = e.x - r + ENEMY_INSET;
  const right = e.x + r + physics.enemyWidth - ENEMY_INSET;
  return spans.some((s) => left >= s.start && right <= s.end);
}

// An enemy stands on a platform when its y (where its feet are) is above the
// ground. Same test as LoadedLevel.enemyStaysOnSupport: the corridor must sit
// inside the platform whose top is at that y.
const onPlatform = (e) => e.y !== undefined && e.y < physics.groundSurfaceY - 1;
function enemyStaysOnSupport(e, spans, platforms) {
  if (!onPlatform(e)) return enemyStaysOnGround(e, spans);
  const r = enemyRange(e);
  const left = e.x - r + ENEMY_INSET;
  const right = e.x + r + physics.enemyWidth - ENEMY_INSET;
  const centre = e.x + physics.enemyWidth / 2;
  const p = platforms.find((q) => Math.abs(q.y - e.y) < 1 && centre >= q.x && centre <= q.x + q.width);
  return !!p && left >= p.x && right <= p.x + p.width;
}

function validate(level, { generated = level.generated !== false } = {}) {
  const problems = [];
  const era = eras.find((e) => e.id === level.props.era);
  if (!era) return [`unknown era ${level.props.era}`];
  const spans = groundSpans(level);
  const heavy = new Set(era.heavy);

  // ── identity ──
  const n = era.levelWeeks.length;
  if (level.props.level < 1 || level.props.level > n) problems.push(`level ${level.props.level} is not in ${era.id}`);
  if (level.props.level === n) problems.push('boss levels are not generated');
  if (level.props.grade !== era.grade || level.props.term !== era.term) problems.push('grade or term does not match the registry');
  if (generated && level.props.weeks !== era.levelWeeks[level.props.level - 1]?.join(',')) problems.push('weeks do not match the registry');

  // ── start, end, length ──
  if (!isOverGround(spans, level.spawnX)) problems.push('spawn is not over ground');
  if (!isOverGround(spans, level.exitX)) problems.push('exit is not over ground');
  if (generated && (level.mapWidth < physics.lengthUnits - 100 || level.mapWidth > physics.lengthUnits + 100)) {
    problems.push(`map is ${level.mapWidth} wide, expected about ${physics.lengthUnits}`);
  }

  // ── gaps ──
  level.gaps.forEach((g, i) => {
    const w = g.end - g.start;
    if (g.start % physics.tile !== 0 || g.end % physics.tile !== 0) problems.push(`gap at ${g.start} is not tile-aligned`);
    const over = level.platforms.filter((p) => p.x < g.end && p.x + p.width > g.start);
    if (w > rules.gapMax) {
      // Wider than any jump: only a platform fight may be this wide.
      if (!rules.fightGaps.includes(w)) {
        problems.push(`gap at ${g.start} is ${w} wide, outside ${rules.gapMin}-${rules.gapMax} and not a fight gap (${rules.fightGaps.join(', ')})`);
      } else {
        if (w - footSpan <= reach) problems.push(`fight gap at ${g.start} can be jumped, so the platform is not required`);
        const p = over[0];
        if (over.length !== 1) problems.push(`fight gap at ${g.start} has ${over.length} platforms, expected 1`);
        else {
          if (p.width < rules.fightPlatformWidth) problems.push(`fight platform at ${p.x} is ${p.width} wide, under ${rules.fightPlatformWidth}`);
          const before = p.x - g.start, after = g.end - (p.x + p.width);
          if (before < 0 || after < 0 || before > rules.fightLedgeMax || after > rules.fightLedgeMax) {
            problems.push(`fight platform at ${p.x} is ${before} and ${after} from the ledges, outside 0-${rules.fightLedgeMax}`);
          }
          const guards = level.enemies.filter((e) => onPlatform(e) && Math.abs(e.y - p.y) < 1 && e.x >= p.x && e.x + physics.enemyWidth <= p.x + p.width);
          if (guards.length !== 1) problems.push(`fight platform at ${p.x} has ${guards.length} enemies, expected 1`);
          else if (guards[0].behavior === 'heavy') problems.push(`the enemy on the platform at ${p.x} is a heavy`);
        }
        if (generated && g.start < rules.safeStart + rules.fightFirstSection * rules.groupWidth) problems.push(`fight at ${g.start} is in the first sections`);
      }
    } else {
      if (w < rules.gapMin) problems.push(`gap at ${g.start} is ${w} wide, outside ${rules.gapMin}-${rules.gapMax}`);
      if (generated && over.length === 0 && w > rules.gapPlainMax) problems.push(`platformless gap at ${g.start} is ${w} wide, over ${rules.gapPlainMax}`);
      if (w - footSpan > reach) problems.push(`gap at ${g.start} is wider than a jump can carry the foot span across`);
    }
    if (generated && g.start < rules.safeStart) problems.push(`gap at ${g.start} is inside the safe start`);
  });
  for (let i = 1; i < spans.length - 1; i++) {
    const w = spans[i].end - spans[i].start;
    if (w < rules.minGroundBetweenGaps) problems.push(`only ${w} of ground between gaps near ${spans[i].start}`);
  }

  // ── the one end gate and the artifacts ──
  if (level.gates.length !== 1) problems.push(`${level.gates.length} gates, expected 1`);
  else if (level.gates[0] < level.exitX - physics.gateWidth) problems.push('the gate is not at the exit');
  else if (generated && level.gates[0] + physics.gateWidth > level.mapWidth) problems.push('the gate runs off the end of the map');
  if (level.artifacts.length !== physics.artifactsPerLevel) problems.push(`${level.artifacts.length} artifacts, expected ${physics.artifactsPerLevel}`);
  for (const a of level.artifacts) {
    if (!/^artifact_[1-5]$/.test(a.art || '')) problems.push(`artifact at ${a.x} has art ${a.art}`);
    if (level.gates.length && a.x >= level.gates[0]) problems.push(`artifact at ${a.x} is past the gate`);
    if (!isOverGround(spans, a.x + physics.artifactSize / 2)) problems.push(`artifact at ${a.x} is not over ground`);
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
    const h = physics.groundSurfaceY - p.y;
    if (h < rules.platformHeights[0] || h > rules.platformHeights[1]) problems.push(`platform at ${p.x} is ${h} above ground, outside ${rules.platformHeights.join('-')}`);
    if (p.width % physics.platformTile !== 0) problems.push(`platform at ${p.x} is ${p.width} wide, not a multiple of ${physics.platformTile}`);
    if (!level.gaps.some((g) => p.x < g.end && p.x + p.width > g.start)) problems.push(`platform at ${p.x} is not over a gap`);
  }

  // ── enemies ──
  const enemies = [...level.enemies].sort((a, b) => a.x - b.x);
  for (const e of enemies) {
    if (!era.enemyTypes.includes(e.kind)) problems.push(`enemy at ${e.x} is "${e.kind}", not one of ${era.enemyTypes}`);
    if (e.behavior !== (heavy.has(e.kind) ? 'heavy' : 'walker')) problems.push(`enemy "${e.kind}" at ${e.x} has behavior ${e.behavior}`);
    if (!enemyStaysOnSupport(e, spans, level.platforms)) problems.push(`enemy at ${e.x} patrols off its ground`);
    if (generated && e.x - enemyRange(e) < rules.safeStart) problems.push(`enemy at ${e.x} patrols into the safe start`);
  }
  const spacing = generated ? rules.enemySpacing : 400;
  for (let i = 1; i < enemies.length; i++) {
    const need = generated && (onPlatform(enemies[i]) || onPlatform(enemies[i - 1])) ? rules.fightEnemySpacing : spacing;
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
    }
    // An enemy that guards a ledge hits a student the moment they land. Keep its
    // whole patrol clear of every gap edge, so they can land and look first.
    for (const e of enemies) {
      if (onPlatform(e)) continue; // a platform fight is over the gap by design
      const r = enemyRange(e);
      const left = e.x - r;
      const right = e.x + r + physics.enemyWidth;
      for (const g of level.gaps) {
        const d = Math.max(g.start - right, left - g.end, 0);
        if (d < rules.enemyGapClearance) problems.push(`enemy at ${e.x} patrols within ${d} of the gap at ${g.start}`);
      }
    }
    if (!level.gaps.some((g) => g.end - g.start > rules.gapMax)) problems.push('the level has no platform fight');
    // Every section has a gap with a platform and an enemy.
    for (let s = 0; s < rules.groups; s++) {
      const from = rules.safeStart + s * rules.groupWidth;
      const to = from + rules.groupWidth;
      const hasGap = level.gaps.some(
        (g) => g.start >= from && g.start < to && level.platforms.some((p) => p.x < g.end && p.x + p.width > g.start)
      );
      if (!hasGap) problems.push(`section ${s + 1} has no gap with a platform`);
      if (!enemies.some((e) => e.x >= from && e.x < to)) problems.push(`section ${s + 1} has no enemy`);
    }
    for (const c of level.coins) {
      const cx = c.x + 21;
      const onGround = c.y === 620 && isOverGround(spans, cx);
      const onPlatform = level.platforms.some((p) => c.y === p.y - 40 && cx >= p.x && cx <= p.x + p.width);
      if (!onGround && !onPlatform) problems.push(`coin at (${c.x}, ${c.y}) is over a gap`);
    }
  }
  return problems;
}

module.exports = { validate, enemyStaysOnGround, enemyStaysOnSupport, enemyRange };
