'use strict';
// Plays a level to prove it can be finished. A breadth-first search over where
// the player can stand: from each spot they can walk either way, walk off an
// edge, or jump with the stick held one of five ways. Every landing is a new
// spot. The level passes when the end can be reached from the start AND from
// every spot reachable on the way (so nothing is a trap, a place you can reach
// but not leave).
//
// It uses the "careful" physics (a slower, lower jump than the real one), so a
// level that passes here has margin when a student plays it. With the real
// physics it can also hand back the exact frame-by-frame inputs of one winning
// run (see paths.js), which test/game/level_playthrough_test.dart replays through
// the game's own PlayerComponent.
const { World, step, resolveGround, careful, standingAt, W } = require('./sim');
const { TILE } = require('./terrain');

const QUANTUM = 8; // two spots closer than this on the same surface count as one
const JUMP_HOLDS = [1, 0.5, 0, -0.5, -1];
const MAX_FRAMES = 240; // a jump or fall that has not landed by 4 s is not coming back

const key = (x, top) => Math.round(x / QUANTUM) * 4096 + Math.round(top / 4);

const clone = (n) => standingAt(n.x, n.top);

// Plays frames until the player lands or falls. Returns the landing, or null.
function flyUntilLanded(world, s, h, phys, rec) {
  for (let i = 0; i < MAX_FRAMES; i++) {
    if (rec) rec.push([h, 0]);
    if (step(world, s, h, false, phys)) return null;
    if (s.ground) return s;
  }
  return null;
}

// One walking step: up to a quantum of ground, or off an edge.
//   -> { s, airborne } or null if the player fell
function walkStep(world, n, dir, phys, rec) {
  const s = clone(n);
  for (let i = 0; i < 12 && Math.abs(s.x - n.x) < QUANTUM; i++) {
    if (rec) rec.push([dir, 0]);
    if (step(world, s, dir, false, phys)) return null;
    if (!s.ground) return { s, airborne: true };
  }
  return { s, airborne: false };
}

// The edges out of a standing spot, each as { kind, h, run(rec) -> landing | null }.
function edgesFrom(world, n, canJump, phys) {
  const out = [];
  for (const dir of [1, -1]) {
    out.push({
      kind: 'walk', h: dir,
      run(rec) {
        const w = walkStep(world, n, dir, phys, rec);
        if (!w) return null;
        if (!w.airborne) return w.s.ground ? w.s : null;
        return flyUntilLanded(world, w.s, dir, phys, rec); // walked off an edge, still holding the stick
      },
    });
    out.push({
      kind: 'drop', h: dir,
      run(rec) {
        const w = walkStep(world, n, dir, phys, rec);
        if (!w || !w.airborne) return null;
        return flyUntilLanded(world, w.s, 0, phys, rec); // let go and drop straight down
      },
    });
  }
  if (canJump) {
    for (const h of JUMP_HOLDS) {
      out.push({
        kind: 'jump', h,
        run(rec) {
          const s = clone(n);
          if (rec) rec.push([h, 1]);
          if (step(world, s, h, true, phys)) return null;
          return s.ground ? s : flyUntilLanded(world, s, h, phys, rec);
        },
      });
    }
  }
  return out;
}

// Only worth trying jumps where something could be jumped: near a pit, a change
// of height, or a platform. Elsewhere a jump just lands on the same ground.
function interestingColumns(level) {
  const cols = level.H.length;
  const mark = new Uint8Array(cols);
  const reach = Math.ceil(420 / TILE);
  const spread = (c) => { for (let k = Math.max(0, c - reach); k <= Math.min(cols - 1, c + reach); k++) mark[k] = 1; };
  for (let c = 0; c < cols; c++) {
    const a = level.H[c], b = c + 1 < cols ? level.H[c + 1] : a;
    if (a < 0 || b < 0 || a !== b) spread(c);
  }
  for (const p of level.platforms) {
    for (let c = Math.floor(p.x / TILE); c <= Math.floor((p.x + p.width) / TILE); c++) spread(c);
  }
  return mark;
}

// A move that still works when it starts a few units either side. The game keeps
// positions as 32-bit floats and the simulator as doubles, so a long run drifts
// apart by a fraction of a unit; a run that lands on the very edge of a block
// would fall off the map on one and not the other. Runs saved for the game's
// own playthrough test only use moves with this much margin.
function robustRun(edge, n, world, phys, delta) {
  const ref = edge.run(null);
  if (!ref || !delta) return ref;
  for (const d of [-delta, -delta / 2, delta / 2, delta]) {
    const m = { x: n.x + d, top: n.top };
    const probe = standingAt(m.x, m.top);
    if (!resolveGround(world, probe) || Math.abs(probe.y + 120 - m.top) > 0.01) continue; // not standing there
    const again = edgesFrom(world, m, true, phys).find((q) => q.kind === edge.kind && q.h === edge.h);
    const land = again.run(null);
    if (!land || Math.abs(land.y - ref.y) > 1) return null;
  }
  return ref;
}

// A landing that holds only by a hair (the foot span just overlapping the edge of
// what it lands on) is a coin flip once the game's 32-bit floats drift from the
// simulator's doubles. With a margin, a landing must overlap its surface by at
// least that many units.
function landingHolds(world, land, margin) {
  if (!margin) return true;
  const top = land.y + 120;
  const left = land.x + 48 - 24, right = land.x + 48 + 24;
  let ok = false;
  const check = (b) => { if (Math.abs(b.top - top) < 1 && Math.min(right, b.end) - Math.max(left, b.start) >= margin) ok = true; };
  world.blocksOver(left, right, check);
  if (!ok) world.platformsOver(left, right, check);
  return ok;
}

function solve(level, { phys = careful, wantPath = false, margin = 0 } = {}) {
  const world = new World(level.H, level.platforms);
  const mark = interestingColumns(level);
  const goalX = (level.gates[0] ?? level.exitX) - 150;
  const startTop = world.blocks.find((b) => level.spawnX >= b.start && level.spawnX < b.end).top;
  const start = standingAt(level.spawnX, startTop);

  const nodes = new Map(); // key -> {x, top}
  const out = new Map(); // key -> [key]  (edges, for the trap check)
  const parent = wantPath ? new Map() : null;
  const goals = new Set();
  const queue = [];

  const add = (s, from, edge) => {
    const top = s.y + 120;
    const k = key(s.x, top);
    if (from !== null) {
      if (!out.has(from)) out.set(from, []);
      out.get(from).push(k);
    }
    if (nodes.has(k)) return;
    nodes.set(k, { x: s.x, top });
    if (wantPath) parent.set(k, { from, edge });
    if (s.x >= goalX) goals.add(k);
    queue.push(k);
  };
  add(start, null, null);

  for (let qi = 0; qi < queue.length; qi++) {
    const k = queue[qi];
    const n = nodes.get(k);
    const canJump = mark[Math.floor((n.x + W / 2) / TILE)] === 1;
    for (const e of edgesFrom(world, n, canJump, phys)) {
      const land = e.kind === 'walk' && margin === 0 ? e.run(null) : robustRun(e, n, world, phys, e.kind === 'walk' ? Math.min(margin, 3) : margin);
      if (land && landingHolds(world, land, margin)) add(land, k, e);
    }
  }

  // Nodes that can reach the end: walk the edges backwards from the goals.
  const back = new Map();
  for (const [from, tos] of out) for (const to of tos) {
    if (!back.has(to)) back.set(to, []);
    back.get(to).push(from);
  }
  const canFinish = new Set(goals);
  const stack = [...goals];
  while (stack.length) {
    const k = stack.pop();
    for (const p of back.get(k) || []) if (!canFinish.has(p)) { canFinish.add(p); stack.push(p); }
  }
  const traps = [];
  for (const [k, n] of nodes) if (!canFinish.has(k)) traps.push(n);

  const reachable = goals.size > 0;
  let frames = null;
  if (wantPath && reachable) {
    // The winning run: the chain of edges from the start to the first goal, each
    // replayed once more with its inputs recorded.
    const chain = [];
    let k = [...goals][0];
    while (parent.get(k).from !== null) { const p = parent.get(k); chain.push(p); k = p.from; }
    chain.reverse();
    frames = [];
    for (const link of chain) {
      const n = nodes.get(link.from);
      const canJump = true;
      const e = edgesFrom(world, n, canJump, phys).find((q) => q.kind === link.edge.kind && q.h === link.edge.h);
      e.run(frames);
    }
  }
  return { reachable, traps, nodes: nodes.size, frames, furthest: Math.max(...[...nodes.values()].map((n) => n.x)) };
}

// [[h, jump], ...] as [[h, jump, count], ...] for a run of identical frames.
function runLength(frames) {
  const out = [];
  for (const f of frames) {
    const last = out[out.length - 1];
    if (last && last[0] === f[0] && last[1] === f[1] && f[1] === 0) last[2]++;
    else out.push([f[0], f[1], 1]);
  }
  return out;
}

module.exports = { solve, runLength };
