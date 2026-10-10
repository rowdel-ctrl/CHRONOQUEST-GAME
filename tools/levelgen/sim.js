'use strict';
// A port of the player's movement and ground contact (lib/game/components/
// player_component.dart and lib/game/game_collision.dart), so the generator can
// test a level by playing it. test/game/terrain_parity_test.dart runs the same
// scripted moves through the real PlayerComponent and checks the two agree.
//
// One step is one frame at 60 fps, which is also the longest step the game ever
// takes (ChronoGame.maxStepDt), so what is tested here is what is played.
const { physics } = require('./rules');
const { blocksOf, TILE } = require('./terrain');

const DT = 1 / 60;
const W = physics.playerWidth; // 96
const HEIGHT = 120; // the player's drawn height
const FOOT_HALF = (W * physics.footSpanFraction) / 2; // 24
const BAND = 28; // how far below a surface a foot still counts as landing on it
const STEP_UP = 12; // any rise bigger than this, one 24-unit tile included, is a wall: jump it
const FALL_Y = 770; // virtual height 720 + 50: below this the player has fallen

class World {
  constructor(H, platforms) {
    this.blocks = blocksOf(H); // {start, end, top}
    this.platforms = platforms.map((p) => ({ start: p.x, end: p.x + p.width, top: p.y }));
    // Index the platforms by 256-unit bucket so a step only looks at its neighbours.
    this.bucket = new Map();
    this.platforms.forEach((p, i) => {
      for (let b = Math.floor(p.start / 256); b <= Math.floor(p.end / 256); b++) {
        if (!this.bucket.has(b)) this.bucket.set(b, []);
        this.bucket.get(b).push(i);
      }
    });
    this.starts = this.blocks.map((b) => b.start);
  }

  // Blocks overlapping [left, right): found by bisection, then walked.
  blocksOver(left, right, fn) {
    const bl = this.blocks;
    let lo = 0, hi = bl.length;
    while (lo < hi) { const mid = (lo + hi) >> 1; if (bl[mid].end <= left) lo = mid + 1; else hi = mid; }
    for (let i = lo; i < bl.length && bl[i].start < right; i++) fn(bl[i]);
  }

  platformsOver(left, right, fn) {
    const seen = new Set();
    for (let b = Math.floor(left / 256); b <= Math.floor(right / 256); b++) {
      const list = this.bucket.get(b);
      if (!list) continue;
      for (const i of list) {
        if (seen.has(i)) continue;
        seen.add(i);
        const p = this.platforms[i];
        if (p.end > left && p.start < right) fn(p);
      }
    }
  }
}

// Solid sides: a block rising more than STEP_UP above the feet is a wall. The
// player is pushed back out of it, to the side they came from.
function resolveWalls(w, s, prevCentre) {
  const feet = s.y + HEIGHT;
  const centre = s.x + W / 2;
  const left = centre - FOOT_HALF, right = centre + FOOT_HALF;
  w.blocksOver(left, right, (b) => {
    // On the ground any rise over STEP_UP is a wall; in the air a landing that is
    // a little low (up to BAND) still snaps up onto the ledge instead of bouncing.
    if (!(feet > b.top + (s.ground ? STEP_UP : BAND))) return;
    if (!(right > b.start && left < b.end)) return;
    const prevLeft = prevCentre - FOOT_HALF, prevRight = prevCentre + FOOT_HALF;
    let toLeft;
    if (prevRight <= b.start) toLeft = true;
    else if (prevLeft >= b.end) toLeft = false;
    else toLeft = centre < (b.start + b.end) / 2;
    s.x = toLeft ? b.start - FOOT_HALF - W / 2 : b.end + FOOT_HALF - W / 2;
  });
}

// Lands on the highest ground the foot span is over and the feet are at, else on
// a platform (one-way: only while falling or resting).
function resolveGround(w, s) {
  const feet = s.y + HEIGHT;
  const centre = s.x + W / 2;
  const left = centre - FOOT_HALF, right = centre + FOOT_HALF;
  let best = null;
  w.blocksOver(left, right, (b) => {
    if (feet >= b.top && feet <= b.top + BAND && (best === null || b.top < best)) best = b.top;
  });
  if (best === null && s.vy >= 0) {
    w.platformsOver(left, right, (p) => {
      if (feet >= p.top && feet <= p.top + BAND && (best === null || p.top < best)) best = p.top;
    });
  }
  if (best === null) return false;
  s.y = best - HEIGHT;
  s.vy = 0;
  return true;
}

// One frame. h is the horizontal input (-1..1). Returns true when the player has
// fallen out of the level.
function step(w, s, h, jump, phys) {
  if (jump && s.ground) { s.vy = phys.jump; s.ground = false; }
  const prevCentre = s.x + W / 2;
  s.x += phys.speed * h * DT;
  if (s.x < 0) s.x = 0;
  resolveWalls(w, s, prevCentre);
  if (!s.ground) { s.vy += phys.gravity * DT; s.y += s.vy * DT; }
  s.ground = resolveGround(w, s);
  return s.y > FALL_Y;
}

const real = { speed: physics.forwardSpeed, jump: physics.jumpForce, gravity: physics.gravity };
// What the solver assumes of a student: a little slower and a little lower than
// the real thing, so a level that can be finished here has margin in play.
const careful = { speed: physics.forwardSpeed * 0.95, jump: physics.jumpForce * 0.95, gravity: physics.gravity };

const standingAt = (x, top) => ({ x, y: top - HEIGHT, vy: 0, ground: true });

module.exports = { World, step, resolveGround, resolveWalls, real, careful, standingAt, DT, W, HEIGHT, FOOT_HALF, BAND, STEP_UP, FALL_Y, TILE };
