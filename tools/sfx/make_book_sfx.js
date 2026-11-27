#!/usr/bin/env node
'use strict';
// Writes the sounds of the era books, the chain break and the boss defeat, and the lobby
// music, into assets/sounds/. Like make_sfx.js nothing is recorded: it is all synthesised
// here, so it can be changed and carries no licence.
//
// Metal here means rings whose partials are NOT whole multiples of the pitch (1, 2.32,
// 4.25, 6.63, 9.38), which is what makes a struck link sound like iron and not like a flute.
// A link tapping another is a bandpassed tick plus a short bright ring; a heavy link or the
// lock body is a lower, longer ring.
// Run: node tools/sfx/make_book_sfx.js
const fs = require('fs');
const path = require('path');

const DIR = path.join(__dirname, '..', '..', 'assets', 'sounds');
let RATE = 32000;

// Same seed every run, so the files do not change when they are rebuilt.
let seed = 20261128;
const rand = () => {
  seed = (seed * 1664525 + 1013904223) >>> 0;
  return seed / 0x100000000;
};
const rnd = (a, b) => a + rand() * (b - a);

const buf = (sec, wrap = false) => {
  const b = new Float32Array(Math.round(RATE * sec));
  b.wrap = wrap;
  return b;
};

function mix(out, start, dur, fn) {
  const n0 = Math.round(start * RATE);
  const n = Math.round(dur * RATE);
  for (let k = 0; k < n; k++) {
    let j = n0 + k;
    if (j >= out.length) {
      if (!out.wrap) break;
      j %= out.length;
    }
    out[j] += fn(k / RATE);
  }
}

function wave(type, ph) {
  const p = ph - Math.floor(ph);
  if (type === 'saw') return 2 * p - 1;
  if (type === 'square') return p < 0.5 ? 1 : -1;
  if (type === 'tri') return 4 * Math.abs(p - 0.5) - 1;
  return Math.sin(2 * Math.PI * ph);
}

// A tone, optionally sweeping from f0 to f1, with an attack, an exponential decay (tau)
// and an optional own envelope.
function tone(out, o) {
  let ph = 0;
  mix(out, o.start || 0, o.dur, (t) => {
    const u = t / o.dur;
    const f = o.f1 === undefined ? o.f0 : o.f0 * Math.pow(o.f1 / o.f0, Math.pow(u, o.curve || 1));
    ph += f / RATE;
    let e = Math.min(1, t / (o.attack === undefined ? 0.004 : o.attack));
    if (o.tau) e *= Math.exp(-t / o.tau);
    if (o.env) e *= o.env(u, t);
    e *= Math.min(1, (o.dur - t) / (o.release === undefined ? 0.01 : o.release));
    return wave(o.type || 'sine', ph) * e * (o.gain === undefined ? 1 : o.gain);
  });
}

// Filtered noise: lp is the low-pass amount (0 to 1, a pair sweeps), hp removes the lows.
function noise(out, o) {
  let y = 0;
  let z = 0;
  mix(out, o.start || 0, o.dur, (t) => {
    const u = t / o.dur;
    const a = Array.isArray(o.lp) ? o.lp[0] + (o.lp[1] - o.lp[0]) * u : o.lp === undefined ? 1 : o.lp;
    y += a * (rand() * 2 - 1 - y);
    let v = y;
    if (o.hp) {
      z += o.hp * (y - z);
      v = y - z;
    }
    let e = Math.min(1, t / (o.attack === undefined ? 0.004 : o.attack));
    if (o.tau) e *= Math.exp(-t / o.tau);
    if (o.env) e *= o.env(u, t);
    e *= Math.min(1, (o.dur - t) / 0.01);
    return v * e * (o.gain === undefined ? 1 : o.gain);
  });
}

// Noise through a band-pass (a state-variable filter): a tick of a chosen colour.
function noiseBP(out, o) {
  const fc = Math.min(o.fc, RATE / 7);
  const f = 2 * Math.sin((Math.PI * fc) / RATE);
  const qd = 1 / o.q;
  let low = 0;
  let band = 0;
  mix(out, o.start || 0, o.dur, (t) => {
    const x = rand() * 2 - 1;
    low += f * band;
    const high = x - low - qd * band;
    band += f * high;
    return band * Math.exp(-t / o.tau) * o.gain * Math.min(1, t / 0.0008);
  });
}

const MR = [1, 2.32, 4.25, 6.63, 9.38];
// A struck metal ring: [n] partials, each decaying faster than the one before.
function metal(out, f, start, dur, gain, n = 5, jit = false) {
  MR.slice(0, n).forEach((r, i) => {
    const fr = f * r * (jit ? 1 + rnd(-0.02, 0.02) : 1);
    if (fr > RATE * 0.42) return;
    const d = dur / (1 + i * 0.8);
    tone(out, { start, dur: d, f0: fr, tau: d / 5, gain: gain / (1 + i * 0.7), attack: 0.001 });
  });
}

// A link tapping another link: a hard little tick plus a short bright ring.
function clink(out, when, vol) {
  noiseBP(out, { start: when, dur: 0.03, fc: rnd(2800, 4600), q: 6, tau: 0.006, gain: vol * 3 });
  metal(out, rnd(1500, 3400), when, 0.16, vol * 0.5, 3, true);
}

// A heavy link or the lock body: a lower, longer ring.
function clank(out, when, vol) {
  noiseBP(out, { start: when, dur: 0.06, fc: 2500, q: 3, tau: 0.012, gain: vol * 3 });
  metal(out, rnd(260, 460), when, 0.34, vol * 0.7, 5, true);
  noise(out, { start: when, dur: 0.05, lp: 0.3, hp: 0.04, tau: 0.01, gain: vol * 0.5 });
}

function write(name, out, peak = 0.85) {
  if (!out.wrap) {
    const tail = Math.round(RATE * 0.03);
    for (let i = 0; i < tail; i++) out[out.length - 1 - i] *= i / tail;
  }
  let max = 0;
  for (const v of out) max = Math.max(max, Math.abs(v));
  const scale = peak / (max || 1);
  const pcm = Buffer.alloc(out.length * 2);
  out.forEach((v, i) => pcm.writeInt16LE(Math.round(Math.max(-1, Math.min(1, v * scale)) * 32767), i * 2));
  const header = Buffer.alloc(44);
  header.write('RIFF', 0);
  header.writeUInt32LE(36 + pcm.length, 4);
  header.write('WAVEfmt ', 8);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20); // PCM
  header.writeUInt16LE(1, 22); // mono
  header.writeUInt32LE(RATE, 24);
  header.writeUInt32LE(RATE * 2, 28);
  header.writeUInt16LE(2, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36);
  header.writeUInt32LE(pcm.length, 40);
  fs.writeFileSync(path.join(DIR, name), Buffer.concat([header, pcm]));
  console.log(`${name}: ${((pcm.length + 44) / 1024) | 0} KB, ${(out.length / RATE).toFixed(2)}s`);
}

// ─── THE BOOKS ──────────────────────────────────────────────────────────────

// The shelf moves to the next book: a soft whoosh, a chain dragging, a small wooden thud.
{
  const o = buf(0.55);
  noise(o, { dur: 0.45, lp: [0.1, 0.45], hp: 0.03, attack: 0.08, tau: 0.25, gain: 0.35 });
  for (let i = 0; i < 5; i++) clink(o, 0.05 + i * 0.07 + rnd(0, 0.03), 0.07);
  tone(o, { start: 0.36, dur: 0.15, f0: 120, f1: 80, tau: 0.06, gain: 0.5 });
  write('book_slide.wav', o, 0.6);
}

// A book opens: a page rustle, a thud of the cover, a faint ring of the clasp.
{
  const o = buf(0.8);
  noise(o, { dur: 0.3, lp: [0.5, 0.9], hp: 0.2, attack: 0.05, tau: 0.12, gain: 0.3 });
  tone(o, { start: 0.22, dur: 0.14, f0: 110, f1: 60, tau: 0.05, gain: 0.8 });
  tone(o, { start: 0.05, dur: 0.5, f0: 220, f1: 330, tau: 0.2, gain: 0.08 });
  clink(o, 0.2, 0.06);
  write('book_open.wav', o, 0.65);
}

// A book closes: a short thud and a flick of paper.
{
  const o = buf(0.3);
  tone(o, { dur: 0.14, f0: 100, f1: 55, tau: 0.05, gain: 0.9 });
  noise(o, { dur: 0.12, lp: 0.6, hp: 0.2, tau: 0.04, gain: 0.25 });
  clink(o, 0.03, 0.08);
  write('book_close.wav', o, 0.6);
}

// A tap on a chained book: two heavy clanks and a quick rattle.
{
  const o = buf(0.6);
  clank(o, 0, 0.4);
  clank(o, 0.07, 0.28);
  for (let i = 0; i < 6; i++) clink(o, 0.1 + i * 0.045, 0.12);
  write('book_locked.wav', o, 0.7);
}

// ─── THE CHAIN BREAK ────────────────────────────────────────────────────────

// The charge, about 1.4 s: iron groaning under load, a ring that builds, links ticking
// faster and faster. It rises in volume and stops sharp, because the lock opens next.
{
  const o = buf(1.4);
  const build = (u) => 0.2 + 0.8 * u * u;
  tone(o, { dur: 1.35, f0: 70, f1: 125, type: 'saw', env: build, gain: 0.12 });
  tone(o, { dur: 1.35, f0: 140, f1: 250, type: 'square', env: build, gain: 0.035 });
  tone(o, { dur: 1.35, f0: 90, f1: 280, env: build, gain: 0.3 });
  noise(o, { dur: 1.35, lp: [0.05, 0.25], hp: 0.02, env: build, gain: 0.25 });
  [1250, 1870].forEach((f, k) => {
    tone(o, { start: k * 0.1, dur: 1.25, f0: f, env: build, gain: 0.05 });
    tone(o, { start: k * 0.1, dur: 1.25, f0: f * 2.32, env: build, gain: 0.025 });
  });
  for (let i = 0; i < 22; i++) clink(o, i * (0.1 - (0.065 * i) / 22), 0.05 + (0.09 * i) / 22);
  for (let i = 0; i < 4; i++) clank(o, 0.2 + i * 0.28, 0.07 + i * 0.025);
  tone(o, { start: 0.85, dur: 0.5, f0: 500, f1: 1800, env: (u) => u, gain: 0.1 });
  write('chain_strain.wav', o, 0.8);
}

// The padlock clicks open, a deep boom with a metal crash, then 26 links clink and fall,
// an anvil ring hangs in the air, and a burst of sparkles.
{
  const o = buf(2.7);
  clink(o, 0, 0.3);
  clink(o, 0.03, 0.22);
  noiseBP(o, { start: 0, dur: 0.04, fc: 3500, q: 5, tau: 0.01, gain: 0.9 });
  metal(o, 2600, 0.04, 0.45, 0.18);
  tone(o, { start: 0.1, dur: 1.0, f0: 75, f1: 24, tau: 0.35, gain: 1.0 });
  noise(o, { start: 0.1, dur: 0.8, lp: [0.4, 0.05], hp: 0.01, tau: 0.3, gain: 0.5 });
  for (let i = 0; i < 16; i++) clink(o, 0.1 + rnd(0, 0.16), 0.16);
  for (let i = 0; i < 5; i++) clank(o, 0.1 + rnd(0, 0.12), 0.2);
  metal(o, 880, 0.12, 1.6, 0.14);
  metal(o, 1320, 0.14, 1.3, 0.08);
  for (let i = 0; i < 26; i++) clink(o, 0.3 + Math.pow(i / 26, 1.25) * 1.0, 0.13 * (1 - i / 40));
  [0, 1, 2, 3].forEach((i) => clank(o, 0.35 + i * 0.22, 0.14));
  for (let i = 0; i < 10; i++) metal(o, 2400 + i * 190, 0.14 + i * 0.035, 0.25, 0.07, 3);
  write('chain_unlock.wav', o, 0.9);
}

// The book turns to its colour: a rising swell and a four-note bell chime.
{
  const o = buf(1.7);
  tone(o, { dur: 1.0, f0: 300, f1: 1400, env: (u) => Math.sin(Math.PI * u), gain: 0.12 });
  [523.25, 659.25, 783.99, 1046.5].forEach((f, i) => metal(o, f, 0.2 + i * 0.12, 1.0, 0.16));
  noise(o, { dur: 0.9, lp: [0.1, 0.5], hp: 0.04, env: (u) => Math.sin(Math.PI * u), gain: 0.1 });
  write('book_reveal.wav', o, 0.8);
}

// ─── THE BOSS DEFEAT ────────────────────────────────────────────────────────

// Pressure builds under the cracked boss: a rumble that climbs, a growl, crackling that
// gets faster. Rises in volume, ends sharp before the boom.
{
  const o = buf(1.7);
  const build = (u) => 0.15 + 0.85 * u * u;
  tone(o, { dur: 1.65, f0: 55, f1: 330, env: build, gain: 0.5 });
  noise(o, { dur: 1.65, lp: [0.03, 0.14], hp: 0.01, env: build, gain: 0.5 });
  tone(o, { dur: 1.65, f0: 220, f1: 1500, type: 'saw', env: build, gain: 0.05 });
  for (let i = 0; i < 28; i++) {
    const t = i * (0.09 - (0.06 * i) / 28);
    noiseBP(o, { start: t, dur: 0.05, fc: rnd(3000, 4600), q: 5, tau: 0.01, gain: 0.5 + (0.6 * i) / 28 });
    if (rand() < 0.5) tone(o, { start: t, dur: 0.05, f0: rnd(900, 1900), type: 'square', tau: 0.02, gain: 0.05 + (0.06 * i) / 28 });
  }
  write('boss_rumble.wav', o, 0.8);
}

// The boom: a deep sub drop, a roar of noise, a metal crash, a fall of debris.
{
  const o = buf(1.9);
  tone(o, { dur: 1.2, f0: 72, f1: 22, tau: 0.4, gain: 1.0 });
  noise(o, { dur: 1.1, lp: [0.5, 0.06], hp: 0.01, tau: 0.38, gain: 0.7 });
  tone(o, { dur: 0.35, f0: 1300, f1: 70, type: 'saw', tau: 0.12, gain: 0.12 });
  noise(o, { dur: 0.2, lp: 1, hp: 0.5, tau: 0.06, gain: 0.5 });
  for (let i = 0; i < 14; i++) clink(o, rnd(0, 0.16), 0.22);
  for (let i = 0; i < 5; i++) clank(o, rnd(0, 0.12), 0.24);
  metal(o, 150, 0.02, 1.4, 0.18, 4);
  write('boss_boom.wav', o, 0.95);
}

// Debris falling after the boom: small hard ticks, a few lower knocks.
{
  const o = buf(1.1);
  for (let i = 0; i < 22; i++) noiseBP(o, { start: Math.pow(rand(), 1.4) * 0.9, dur: 0.05, fc: rnd(1800, 4400), q: 3, tau: 0.012, gain: rnd(0.15, 0.5) });
  for (let i = 0; i < 4; i++) tone(o, { start: rnd(0.05, 0.8), dur: 0.08, f0: rnd(120, 220), tau: 0.03, gain: 0.3 });
  write('boss_clatter.wav', o, 0.6);
}

// The medal rises: a shimmer of bells climbing.
{
  const o = buf(1.2);
  [784, 988, 1175, 1568, 1976].forEach((f, i) => metal(o, f, i * 0.08, 0.5, 0.16, 4));
  tone(o, { dur: 0.9, f0: 400, f1: 1600, env: (u) => Math.sin(Math.PI * u), gain: 0.05 });
  write('boss_medal.wav', o, 0.7);
}

// The banner: a bright four-note chime.
{
  const o = buf(1.6);
  [523.25, 659.25, 783.99, 1046.5].forEach((f, i) => {
    metal(o, f, i * 0.13, 1.0, 0.2, 4);
    tone(o, { start: i * 0.13, dur: 0.5, f0: f * 2, tau: 0.12, gain: 0.05 });
  });
  write('boss_win.wav', o, 0.75);
}

// ─── THE LOBBY MUSIC ────────────────────────────────────────────────────────
// 8 bars at 92 BPM in D minor pentatonic, a loop that joins up with itself: a deep gong on
// the first beat, bell notes, a soft pad, a quiet wooden tick on the off-beats.
{
  RATE = 22050;
  const EIGHTH = 60 / 92 / 2;
  const BARS = 8;
  const o = buf(BARS * 8 * EIGHTH, true);
  const N = { Bb1: 58.27, C2: 65.41, D2: 73.42, F2: 87.31, G2: 98, A2: 110, Bb2: 116.54, C3: 130.81, D3: 146.83, E3: 164.81, F3: 174.61, G3: 196, A3: 220, C4: 261.63,
    D4: 293.66, F4: 349.23, G4: 392, A4: 440, C5: 523.25, D5: 587.33 };
  const bass = ['D2', 'Bb1', 'F2', 'C2', 'D2', 'Bb1', 'G2', 'A2'];
  const chords = [['D3', 'F3', 'A3'], ['Bb2', 'D3', 'F3'], ['F3', 'A3', 'C4'], ['C3', 'G3', 'D4'],
    ['D3', 'F3', 'A3'], ['Bb2', 'D3', 'F3'], ['G2', 'Bb2', 'D3'], ['A2', 'C3', 'E3']];
  const melA = ['D4', 0, 'F4', 0, 'A4', 0, 'G4', 'F4', 'F4', 0, 'A4', 0, 'C5', 0, 'A4', 'G4', 'A4', 0, 'G4', 0, 'F4', 0, 'D4', 0, 'F4', 'G4', 'A4', 0, 'G4', 0, 'F4', 0];
  const melB = ['A4', 0, 'C5', 0, 'D5', 0, 'C5', 'A4', 'G4', 0, 'A4', 0, 'F4', 0, 'G4', 0, 'F4', 0, 'D4', 0, 'F4', 0, 'G4', 'A4', 'C5', 0, 'A4', 0, 'G4', 0, 'D4', 0];
  const mel = melA.concat(melB);
  for (let bar = 0; bar < BARS; bar++) {
    const t0 = bar * 8 * EIGHTH;
    // The gong.
    tone(o, { start: t0, dur: 2.6, f0: N[bass[bar]] * 1.02, f1: N[bass[bar]], curve: 0.4, tau: 0.9, attack: 0.03, gain: 0.55 });
    tone(o, { start: t0, dur: 2.0, f0: N[bass[bar]] * 2.01, tau: 0.5, attack: 0.03, gain: 0.12 });
    // The pad.
    chords[bar].forEach((n) => {
      [1, 1.0016].forEach((d) => tone(o, { start: t0, dur: 8 * EIGHTH + 0.5, f0: N[n] * d, type: 'tri', attack: 0.5, release: 0.8, gain: 0.05 }));
    });
    // Off-beat wooden tick.
    for (let k = 1; k < 8; k += 2) noiseBP(o, { start: t0 + k * EIGHTH, dur: 0.05, fc: 1800, q: 5, tau: 0.014, gain: 0.18 });
    // Soft drum on beat 3.
    tone(o, { start: t0 + 4 * EIGHTH, dur: 0.2, f0: 110, f1: 62, tau: 0.07, gain: 0.3 });
  }
  for (let s = 0; s < BARS * 8; s++) {
    const m = mel[s];
    if (m) metal(o, N[m], s * EIGHTH, 0.9, 0.22, 3);
    const bar = Math.floor(s / 8);
    if (s % 2 === 1 && s % 8 !== 7) metal(o, N[chords[bar][s % 3]] * 2, s * EIGHTH, 0.5, 0.05, 2);
  }
  write('bgm_lobby.wav', o, 0.7);
}
