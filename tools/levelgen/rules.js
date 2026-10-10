'use strict';
// Shared constants for the level generator. The jump physics and era data are
// copies of the game's own values (data/*.json); test/game/levelgen_sync_test.dart
// fails if they drift from the Dart source.
const fs = require('fs');
const path = require('path');

const physics = JSON.parse(fs.readFileSync(path.join(__dirname, 'data', 'physics.json'), 'utf8'));
const eras = JSON.parse(fs.readFileSync(path.join(__dirname, 'data', 'eras.json'), 'utf8'));

// Ballistics from PlayerComponent: airtime on flat ground, how far a full-speed
// jump carries, and how high it peaks.
const airtime = (2 * Math.abs(physics.jumpForce)) / physics.gravity;
const reach = physics.forwardSpeed * airtime; // 267
const peak = (physics.jumpForce * physics.jumpForce) / (2 * physics.gravity); // 128

// How far up an enemy can touch: its drawn height is 108 and its hit area is the
// middle 85% of that, so it reaches 0.925 * 108 = 99.9 above the ground. A
// platform whose top is above this keeps a student standing on it out of reach.
const enemyTop = physics.enemyHeight * 0.925;
// A jump only has to carry the middle half of the sprite (the "feet") from the
// last ground it touches to the first, so a gap is crossable up to the reach
// plus that foot span (267 + 48 = 315). Gaps are kept to 90% of the reach plus
// the foot span (48 + 240 = 288), the same safety margin as before.
const footSpan = physics.footSpanFraction * physics.playerWidth;

const rules = {
  // Pits a student jumps in one go. The solver (solve.js) plays every level with
  // a slightly slower, lower jump than the real one and a pit up to 288 passes.
  gapMin: 192,
  gapMax: 288,
  gapPlainMax: 240, // without a platform to land on, keep it shorter
  minGroundBetweenGaps: 240,
  // Raised from 90-110 so a student on a platform is above every enemy's hit
  // area (99.9) with no special rule. 112 is under the game's verified ceiling
  // of jumpPeak - 15 = 113 (platform_layering_test). The jump is unchanged.
  platformHeights: [104, 112],
  platformWidth: 96,
  // Platform fights: a gap too wide to jump (the longest crossable gap is the
  // 267 reach plus the 48 foot span = 315), a wide platform in the middle, and a
  // walker patrolling it. The student has to hit the enemy from the air or land
  // beside it. The platform sits 80-112 from each ledge, well inside a jump.
  fightGaps: [360, 384, 408], // 15, 16 and 17 tiles of 24
  fightPlatformWidth: 240, // 10 tiles of 24
  fightPatrol: 36, // each way, so the enemy stays clear of both platform edges
  fightLedgeMax: 112, // furthest a platform edge may be from a ledge
  fightEnemySpacing: 400, // between a platform enemy and its neighbour; it is over a gap, so closer is fine
  fightFirstSection: 2, // none in sections 1 and 2 (0-based index of the first allowed)
  enemySpacing: 600, // generated levels; the Dart lint's floor is 400
  artifactClearance: 240,
  // Floor left past the exit marker. The gate stands 40 before the exit and is 144
  // wide, so its far edge is 104 past the exit and has to stay on the map.
  exitMargin: 120,
  safeStart: 1008, // nothing dangerous before this x (Mario 1-1: practise first); a multiple of the 24-unit tile
  groups: 10, // one per question
  groupWidth: 2304, // ~9 s at 250 u/s; 96 tiles
  restWidth: 576, // the artifact sits in the middle; 24 tiles
  padMin: 240, // ground between two gaps (never below minGroundBetweenGaps)
  padMax: 400,
  // Ground between a gap and an enemy lane. The lane has 60 of its own margin
  // inside it, so 112 here leaves an enemy at least 172 from a ledge: room to
  // land from a jump and look before the enemy is in reach.
  padNearMin: 112,
  padNearMax: 192,
  enemyGapClearance: 160, // an enemy's patrol stays at least this far from any hazard edge of its ground
  // ── terrain (v2) ──
  maxRiseTiles: 4, // the tallest step a student is asked to jump up: 96, under the jump's 128 peak
  stepTiles: 2, // the tallest single hop on a staircase: 48
  maxHeightTiles: 16, // the tallest ground anywhere: 384, a tower on a highland
  platformMinY: 300, // platforms never float higher than this (world y)
  generatorId: 'levelgen-v2',
};

function eraNumber(eraId) {
  const i = eras.findIndex((e) => e.id === eraId);
  if (i < 0) throw new Error('unknown era ' + eraId);
  return i + 1;
}

module.exports = { physics, eras, rules, reach, peak, airtime, enemyTop, footSpan, eraNumber };
