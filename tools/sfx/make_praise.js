#!/usr/bin/env node
'use strict';
// Writes assets/sounds/praise.wav, the cheer that plays after a correct answer:
// a rising bell arpeggio, a sparkling chord and a short crackle of applause.
// There is no recording behind it; it is synthesised here so it can be changed
// and so it carries no licence. Run: node tools/sfx/make_praise.js
const fs = require('fs');
const path = require('path');

const RATE = 22050;
const LENGTH = 1.25; // seconds
const out = new Float32Array(Math.round(RATE * LENGTH));

// Same seed every run, so the file does not change when it is rebuilt.
let seed = 20261006;
const rand = () => {
  seed = (seed * 1664525 + 1013904223) >>> 0;
  return seed / 0x100000000;
};

// A bell: a fundamental, an octave and a slightly sharp upper partial, each
// dying away at its own rate.
function bell(freq, start, decay, gain) {
  const n0 = Math.round(start * RATE);
  const n1 = Math.min(out.length, n0 + Math.round(RATE * decay * 5));
  for (let i = n0; i < n1; i++) {
    const t = (i - n0) / RATE;
    const attack = Math.min(1, t / 0.004);
    const v =
      Math.sin(2 * Math.PI * freq * t) * Math.exp(-t / decay) +
      0.45 * Math.sin(2 * Math.PI * freq * 2 * t) * Math.exp(-t / (decay * 0.6)) +
      0.2 * Math.sin(2 * Math.PI * freq * 3.01 * t) * Math.exp(-t / (decay * 0.3));
    out[i] += v * attack * gain;
  }
}

// Rising arpeggio, C5 E5 G5 C6.
[523.25, 659.25, 783.99, 1046.5].forEach((f, k) => bell(f, k * 0.085, 0.16, 0.5));

// The held chord on top: C6 E6 G6.
[1046.5, 1318.5, 1568.0].forEach((f) => bell(f, 0.36, 0.34, 0.3));

// Sparkles: quick high pings scattered over the end.
for (let k = 0; k < 9; k++) {
  const f = [2093, 2637, 3136, 3520][Math.floor(rand() * 4)];
  bell(f, 0.38 + rand() * 0.6, 0.06, 0.12 + rand() * 0.08);
}

// Applause: noise gated into claps, loud at first and thinning out.
let low = 0;
for (let i = Math.round(RATE * 0.32); i < out.length; i++) {
  const t = i / RATE - 0.32;
  const fade = Math.exp(-t / 0.35);
  const clap = Math.pow(Math.max(0, Math.sin(2 * Math.PI * 23 * t + 3 * Math.sin(2 * Math.PI * 7 * t))), 3);
  low += 0.5 * ((rand() * 2 - 1) - low); // a little low-pass: claps, not hiss
  out[i] += (rand() * 2 - 1 - low * 0.3) * clap * fade * 0.16;
}

// Fade the last 80 ms and normalise.
const tail = Math.round(RATE * 0.08);
for (let i = 0; i < tail; i++) out[out.length - 1 - i] *= i / tail;
let peak = 0;
for (const v of out) peak = Math.max(peak, Math.abs(v));
const scale = 0.85 / peak;

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

const file = path.join(__dirname, '..', '..', 'assets', 'sounds', 'praise.wav');
fs.writeFileSync(file, Buffer.concat([header, pcm]));
console.log(`${file}: ${(pcm.length + 44) / 1024 | 0} KB, ${LENGTH}s`);
