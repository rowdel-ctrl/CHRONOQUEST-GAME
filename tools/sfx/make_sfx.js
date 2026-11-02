#!/usr/bin/env node
'use strict';
// Writes the placeholder sound effects and the boss music into assets/sounds/.
// There is no recording behind any of them; they are synthesised here so they
// can be changed and so they carry no licence. To use a real sound instead, drop
// a recording over the file with the same name (wav or mp3 renamed is not enough:
// keep the extension the game asks for, see AudioService).
// Run: node tools/sfx/make_sfx.js
const fs = require('fs');
const path = require('path');

const RATE = 22050;
const DIR = path.join(__dirname, '..', '..', 'assets', 'sounds');

// Same seed every run, so the files do not change when they are rebuilt.
let seed = 20261102;
const rand = () => {
  seed = (seed * 1664525 + 1013904223) >>> 0;
  return seed / 0x100000000;
};

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

// A tone, optionally sweeping from f0 to f1, with an attack, an exponential
// decay (tau), an optional own envelope and an optional wobble in volume.
function tone(out, o) {
  let ph = 0;
  let amPh = 0;
  mix(out, o.start || 0, o.dur, (t) => {
    const u = t / o.dur;
    const f = o.f1 === undefined ? o.f0 : o.f0 * Math.pow(o.f1 / o.f0, Math.pow(u, o.curve || 1));
    ph += f / RATE;
    let e = Math.min(1, t / (o.attack === undefined ? 0.004 : o.attack));
    if (o.tau) e *= Math.exp(-t / o.tau);
    if (o.env) e *= o.env(u, t);
    if (o.am) {
      amPh += (o.am.from + (o.am.to - o.am.from) * u) / RATE;
      e *= 1 - o.am.depth * (0.5 + 0.5 * Math.sin(2 * Math.PI * amPh));
    }
    e *= Math.min(1, (o.dur - t) / (o.release === undefined ? 0.01 : o.release));
    return wave(o.type || 'sine', ph) * e * (o.gain === undefined ? 1 : o.gain);
  });
}

// Filtered noise: lp is the low-pass amount (0 to 1, a pair sweeps), hp removes
// the lows by subtracting a slower low-pass.
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

// A bell: a fundamental, an octave and a slightly sharp upper partial.
function bell(out, freq, start, decay, gain) {
  mix(out, start, decay * 5, (t) => {
    const attack = Math.min(1, t / 0.006);
    const v =
      Math.sin(2 * Math.PI * freq * t) * Math.exp(-t / decay) +
      0.35 * Math.sin(2 * Math.PI * freq * 2 * t) * Math.exp(-t / (decay * 0.6)) +
      0.12 * Math.sin(2 * Math.PI * freq * 3.01 * t) * Math.exp(-t / (decay * 0.3));
    return v * attack * gain;
  });
}

function lowpass(out, a) {
  let y = 0;
  for (let i = 0; i < out.length; i++) {
    y += a * (out[i] - y);
    out[i] = y;
  }
}

// Builds into its own buffer, low-passes it, and adds it to [out].
function layer(out, a, build) {
  const tmp = buf(out.length / RATE, out.wrap);
  build(tmp);
  lowpass(tmp, a);
  for (let i = 0; i < out.length; i++) out[i] += tmp[i];
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
  const file = path.join(DIR, name);
  fs.writeFileSync(file, Buffer.concat([header, pcm]));
  console.log(`${name}: ${((pcm.length + 44) / 1024) | 0} KB, ${(out.length / RATE).toFixed(2)}s`);
}

// ─── NORMAL LEVELS ─────────────────────────────────────────────────────────

// Landing after a jump: a soft thud.
{
  const o = buf(0.16);
  tone(o, { dur: 0.14, f0: 150, f1: 55, tau: 0.05 });
  noise(o, { dur: 0.06, lp: 0.15, tau: 0.02, gain: 0.3 });
  write('land.wav', o, 0.55);
}

// One footstep: a short low scuff.
{
  const o = buf(0.08);
  noise(o, { dur: 0.07, lp: 0.45, hp: 0.05, tau: 0.012 });
  tone(o, { dur: 0.06, f0: 110, tau: 0.02, gain: 0.3 });
  write('step.wav', o, 0.3);
}

// An artifact starts to glow as the student reaches it.
{
  const o = buf(0.9);
  bell(o, 783.99, 0, 0.16, 0.7);
  bell(o, 1174.7, 0.09, 0.2, 0.55);
  bell(o, 1568.0, 0.18, 0.28, 0.5);
  [2349, 3136, 2637].forEach((f, k) => bell(o, f, 0.3 + k * 0.1, 0.05, 0.1));
  write('artifact.wav', o, 0.8);
}

// The stone gate opens: a heavy rumble, grinding, and a thud as it stops.
{
  const o = buf(1.5);
  const swell = (u, t) => Math.min(1, t / 0.15) * (t < 1.05 ? 1 : Math.exp(-(t - 1.05) / 0.12));
  noise(o, { dur: 1.45, lp: 0.035, gain: 1.4, env: swell });
  tone(o, { dur: 1.45, f0: 48, gain: 0.7, env: swell, am: { from: 13, to: 17, depth: 0.45 } });
  tone(o, { dur: 1.45, f0: 61, gain: 0.35, env: swell });
  for (let k = 0; k < 11; k++) noise(o, { start: 0.1 + rand() * 0.9, dur: 0.05, lp: 0.6, tau: 0.01, gain: 0.45 });
  tone(o, { start: 1.1, dur: 0.3, f0: 95, f1: 38, tau: 0.1, gain: 1.1 });
  noise(o, { start: 1.1, dur: 0.15, lp: 0.2, tau: 0.04, gain: 0.7 });
  write('gate_rumble.wav', o, 0.9);
}

// Falling into the river: a splash and a few bubbles.
{
  const o = buf(0.8);
  noise(o, { dur: 0.5, lp: 0.5, hp: 0.03, attack: 0.005, tau: 0.12 });
  noise(o, { start: 0.05, dur: 0.5, lp: 0.2, tau: 0.25, gain: 0.5 });
  [0.18, 0.29, 0.4, 0.52, 0.6].forEach((s) => {
    const f = 400 + rand() * 300;
    tone(o, { start: s, dur: 0.08, f0: f, f1: f * 1.9, tau: 0.03, gain: 0.25 });
  });
  write('splash.wav', o, 0.85);
}

// A heart picked up: two warm notes.
{
  const o = buf(0.7);
  bell(o, 1318.5, 0, 0.12, 0.7);
  bell(o, 1760.0, 0.11, 0.22, 0.75);
  tone(o, { start: 0, dur: 0.4, f0: 440, tau: 0.12, gain: 0.2 });
  write('heart.wav', o, 0.8);
}

// The halfway flag: a short rising fanfare.
{
  const o = buf(1.1);
  [523.25, 659.25, 783.99].forEach((f, k) => tone(o, { start: k * 0.1, dur: 0.14, f0: f, type: 'tri', attack: 0.01, tau: 0.12, gain: 0.7 }));
  tone(o, { start: 0.3, dur: 0.7, f0: 1046.5, type: 'tri', attack: 0.01, tau: 0.3, gain: 0.7 });
  bell(o, 1046.5, 0.3, 0.3, 0.4);
  bell(o, 1568.0, 0.36, 0.3, 0.3);
  write('flag.wav', o, 0.8);
}

// The Shield turns a hit away: a bubble pops.
{
  const o = buf(0.3);
  tone(o, { dur: 0.15, f0: 1100, f1: 280, tau: 0.04 });
  noise(o, { dur: 0.05, lp: 0.6, hp: 0.02, tau: 0.015, gain: 0.5 });
  tone(o, { start: 0.02, dur: 0.06, f0: 500, f1: 900, tau: 0.03, gain: 0.3 });
  write('shield_pop.wav', o, 0.75);
}

// "+1 KAALAMAN!": three quick rising pings.
{
  const o = buf(0.55);
  bell(o, 880.0, 0, 0.07, 0.7);
  bell(o, 1108.7, 0.07, 0.07, 0.7);
  bell(o, 1318.5, 0.14, 0.15, 0.8);
  bell(o, 2637.0, 0.2, 0.06, 0.2);
  write('streak.wav', o, 0.7);
}

// A chaser notices the student: a short low growl.
{
  const o = buf(0.55);
  layer(o, 0.15, (t) => {
    tone(t, { dur: 0.5, f0: 95, f1: 62, type: 'saw', attack: 0.03, tau: 0.22, am: { from: 28, to: 28, depth: 0.5 } });
    noise(t, { dur: 0.4, lp: 0.2, tau: 0.15, gain: 0.25 });
  });
  write('chaser_notice.wav', o, 0.7);
}

// A heavy enemy winds up: a rising charge that stops short.
{
  const o = buf(0.65);
  const rise = (u) => 0.2 + 0.8 * u;
  layer(o, 0.2, (t) => {
    tone(t, { dur: 0.6, f0: 70, f1: 420, type: 'saw', attack: 0.02, env: rise, curve: 1.4 });
    noise(t, { dur: 0.6, lp: 0.3, env: rise, gain: 0.25 });
  });
  write('heavy_windup.wav', o, 0.7);
}

// The lunge: a quick whoosh.
{
  const o = buf(0.35);
  noise(o, { dur: 0.3, lp: [0.05, 0.5], hp: 0.02, attack: 0.05, tau: 0.1 });
  tone(o, { dur: 0.25, f0: 300, f1: 120, type: 'saw', attack: 0.02, tau: 0.08, gain: 0.15 });
  write('lunge.wav', o, 0.7);
}

// A menu button: a soft tap.
{
  const o = buf(0.07);
  tone(o, { dur: 0.06, f0: 1300, f1: 900, tau: 0.015 });
  write('tap.wav', o, 0.45);
}

// ─── BOSS ──────────────────────────────────────────────────────────────────

// The warning before a shockwave: a hum that rises and trembles faster, then
// cuts off as the wave is sent. The first warning lasts 1.0 s, the second 0.6 s.
function warning(name, sec) {
  const o = buf(sec + 0.05);
  const swell = (u) => 0.35 + 0.65 * u;
  layer(o, 0.13, (t) => {
    const am = { from: 6, to: 22, depth: 0.6 };
    tone(t, { dur: sec, f0: 60, f1: 150, type: 'saw', attack: 0.1, env: swell, curve: 1.3, am });
    tone(t, { dur: sec, f0: 61.5, f1: 153, type: 'saw', attack: 0.1, env: swell, curve: 1.3, am, gain: 0.8 });
    tone(t, { dur: sec, f0: 120, f1: 300, type: 'sine', attack: 0.1, env: swell, curve: 1.3, gain: 0.3 });
  });
  write(name, o, 0.8);
}
warning('boss_warning.wav', 1.0);
warning('boss_warning_short.wav', 0.6);

// The shockwave runs along the floor: a rumble with a whoosh on top.
{
  const o = buf(1.0);
  noise(o, { dur: 0.95, lp: [0.04, 0.02], attack: 0.05, tau: 0.35, gain: 1.2 });
  tone(o, { dur: 0.95, f0: 65, f1: 35, attack: 0.03, tau: 0.4, gain: 0.9 });
  noise(o, { dur: 0.6, lp: 0.3, hp: 0.05, attack: 0.15, tau: 0.2, gain: 0.35 });
  write('shockwave.wav', o, 0.9);
}

// A new boss phase: a deep hit, a dark drone and a sour stab.
{
  const o = buf(1.3);
  tone(o, { dur: 0.8, f0: 80, f1: 40, tau: 0.3, gain: 1 });
  noise(o, { dur: 0.3, lp: 0.1, tau: 0.12, gain: 0.7 });
  layer(o, 0.18, (t) => {
    tone(t, { dur: 1.2, f0: 55, type: 'saw', attack: 0.1, tau: 0.5, gain: 0.3 });
    tone(t, { dur: 1.2, f0: 82.4, type: 'saw', attack: 0.1, tau: 0.5, gain: 0.25 });
    tone(t, { dur: 0.7, f0: 220, type: 'saw', tau: 0.25, gain: 0.18 });
    tone(t, { dur: 0.7, f0: 233.1, type: 'saw', tau: 0.25, gain: 0.18 });
  });
  write('boss_phase.wav', o, 0.9);
}

// The boss is about to ask: a solemn gold chime.
{
  const o = buf(0.9);
  bell(o, 587.3, 0, 0.2, 0.7);
  bell(o, 880.0, 0.1, 0.25, 0.6);
  bell(o, 1174.7, 0.2, 0.4, 0.55);
  tone(o, { dur: 0.5, f0: 293.7, tau: 0.3, gain: 0.3 });
  write('boss_ask.wav', o, 0.75);
}

// The boss music: 8 bars at 120 BPM in A minor, a loop that joins up with itself.
{
  const BEAT = 0.5;
  const BARS = 8;
  const o = buf(BARS * 4 * BEAT, true);
  const note = (n) => 440 * Math.pow(2, (n - 69) / 12);
  const roots = [45, 45, 41, 43, 45, 45, 41, 40]; // A A F G A A F E
  const chords = [
    [57, 60, 64], [57, 60, 64], [53, 57, 60], [55, 59, 62],
    [57, 60, 64], [57, 60, 64], [53, 57, 60], [52, 56, 59],
  ];
  for (let bar = 0; bar < BARS; bar++) {
    const t0 = bar * 4 * BEAT;
    // Bass: eighth notes, jumping up an octave on the last one.
    layer(o, 0.16, (t) => {
      for (let e = 0; e < 8; e++) {
        const n = roots[bar] + (e === 7 ? 12 : 0);
        tone(t, { start: t0 + e * BEAT / 2, dur: BEAT / 2, f0: note(n), type: 'saw', attack: 0.005, tau: 0.16, gain: 0.55 });
      }
    });
    // Drums: kick on 1 and 3, snare on 2 and 4, hats on every eighth.
    [0, 2].forEach((b) => tone(o, { start: t0 + b * BEAT, dur: 0.2, f0: 125, f1: 45, tau: 0.09, gain: 0.9 }));
    if (bar % 2 === 1) tone(o, { start: t0 + 2.5 * BEAT, dur: 0.2, f0: 125, f1: 45, tau: 0.09, gain: 0.6 });
    [1, 3].forEach((b) => {
      noise(o, { start: t0 + b * BEAT, dur: 0.15, lp: 0.5, hp: 0.05, tau: 0.07, gain: 0.5 });
      tone(o, { start: t0 + b * BEAT, dur: 0.1, f0: 190, tau: 0.04, gain: 0.3 });
    });
    for (let e = 0; e < 8; e++) noise(o, { start: t0 + e * BEAT / 2, dur: 0.05, lp: 0.9, hp: 0.5, tau: 0.015, gain: e % 2 ? 0.28 : 0.16 });
    // Pad: the chord, held for the bar.
    layer(o, 0.3, (t) => {
      chords[bar].forEach((n) => tone(t, { start: t0, dur: 4 * BEAT + 0.2, f0: note(n), type: 'tri', attack: 0.25, release: 0.4, gain: 0.13 }));
    });
    // Lead: plucked chord tones, one per beat in the first half, per eighth in the second.
    const step = bar < 4 ? BEAT : BEAT / 2;
    const count = Math.round((4 * BEAT) / step);
    for (let k = 0; k < count; k++) {
      const n = chords[bar][[0, 1, 2, 1][k % 4]] + 12;
      tone(o, { start: t0 + k * step, dur: step * 1.6, f0: note(n), type: 'square', attack: 0.004, tau: 0.09, gain: bar < 4 ? 0.07 : 0.1 });
    }
  }
  lowpass(o, 0.55);
  write('bgm_boss.wav', o, 0.8);
}
