#!/usr/bin/env node
// Makes every sound and piece of music in TATO! from code, so all audio is
// original and nothing is borrowed.
//
//   node tools/audio/make_audio.mjs            (needs Node 18+ and ffmpeg for .ogg)
//
// Sound effects and honks -> game/assets/audio/{sfx,voice}/<name>.ogg
// Music loops              -> game/assets/audio/music/<name>.ogg
//
// Everything is plain synthesis: sine / triangle / pulse / saw oscillators,
// filtered noise, simple envelopes. Music is written as scale degrees in a
// tiny tracker further down.

import { writeFileSync, mkdirSync, rmSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, '..', '..');
const OUT = join(ROOT, 'game', 'assets', 'audio');
const TMP = join(ROOT, 'build', 'audio_tmp');
const SR = 32000;

// ------------------------------------------------------------- utilities --
let seed = 12345;
function rnd() { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; }
const TAU = Math.PI * 2;
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const lerp = (a, b, t) => a + (b - a) * t;
const midi = (n) => 440 * Math.pow(2, (n - 69) / 12);

function buf(seconds) { return new Float32Array(Math.max(1, Math.round(seconds * SR))); }

// attack / hold / release envelope, 0..1 over the buffer
function env(i, n, attack = 0.01, release = 0.1, hold = 1) {
  const t = i / SR, total = n / SR;
  const a = Math.min(1, t / Math.max(attack, 1e-4));
  const r = Math.min(1, (total - t) / Math.max(release, 1e-4));
  return Math.max(0, Math.min(a, r)) * hold;
}

function osc(type, phase) {
  const p = phase - Math.floor(phase);
  switch (type) {
    case 'sine': return Math.sin(p * TAU);
    case 'tri': return 4 * Math.abs(p - 0.5) - 1;
    case 'saw': return 2 * p - 1;
    case 'square': return p < 0.5 ? 1 : -1;
    case 'pulse': return p < 0.22 ? 1 : -0.3;
    default: return Math.sin(p * TAU);
  }
}

// a tone whose pitch glides through the given frequencies
function tone(seconds, freqs, type = 'sine', vol = 0.5, attack = 0.005, release = 0.08, vibrato = 0, vibRate = 6) {
  const out = buf(seconds), n = out.length;
  let phase = 0;
  for (let i = 0; i < n; i++) {
    const t = i / (n - 1 || 1);
    const pos = t * (freqs.length - 1);
    const k = Math.min(freqs.length - 2, Math.floor(pos));
    let f = freqs.length === 1 ? freqs[0] : lerp(freqs[k], freqs[k + 1], pos - k);
    if (vibrato) f *= 1 + Math.sin(i / SR * TAU * vibRate) * vibrato;
    phase += f / SR;
    out[i] = osc(type, phase) * vol * env(i, n, attack, release);
  }
  return out;
}

function noise(seconds, vol = 0.4, attack = 0.002, release = 0.08, lowpass = 1, highpass = 0) {
  const out = buf(seconds), n = out.length;
  let lp = 0, hp = 0, prev = 0;
  for (let i = 0; i < n; i++) {
    const x = rnd() * 2 - 1;
    lp += (x - lp) * lowpass;
    hp = highpass ? (hp + lp - prev) * (1 - highpass) : lp;
    prev = lp;
    out[i] = (highpass ? hp : lp) * vol * env(i, n, attack, release);
  }
  return out;
}

function mix(...parts) {
  // parts: Float32Array or [Float32Array, offsetSeconds]
  let len = 0;
  const items = parts.map((p) => Array.isArray(p) ? p : [p, 0]);
  for (const [b, off] of items) len = Math.max(len, b.length + Math.round(off * SR));
  const out = new Float32Array(len);
  for (const [b, off] of items) {
    const o = Math.round(off * SR);
    for (let i = 0; i < b.length; i++) out[o + i] += b[i];
  }
  return out;
}

function lowpass(b, amount) { let y = 0; const o = new Float32Array(b.length); for (let i = 0; i < b.length; i++) { y += (b[i] - y) * amount; o[i] = y; } return o; }

function bandpass(b, freq, q = 4) {
  // simple state-variable band-pass
  const f = 2 * Math.sin(Math.PI * freq / SR), o = new Float32Array(b.length);
  let low = 0, band = 0;
  for (let i = 0; i < b.length; i++) {
    low += f * band;
    const high = b[i] - low - band / q;
    band += f * high;
    o[i] = band;
  }
  return o;
}

function gain(b, g) { const o = new Float32Array(b.length); for (let i = 0; i < b.length; i++) o[i] = b[i] * g; return o; }

function normalise(b, peak = 0.85) {
  let m = 0;
  for (let i = 0; i < b.length; i++) m = Math.max(m, Math.abs(b[i]));
  if (m < 1e-6) return b;
  const g = peak / m, o = new Float32Array(b.length);
  for (let i = 0; i < b.length; i++) o[i] = Math.tanh(b[i] * g * 1.1) / Math.tanh(1.1);
  return o;
}

function writeWav(path, samples) {
  const n = samples.length, data = Buffer.alloc(44 + n * 2);
  data.write('RIFF', 0); data.writeUInt32LE(36 + n * 2, 4); data.write('WAVE', 8);
  data.write('fmt ', 12); data.writeUInt32LE(16, 16); data.writeUInt16LE(1, 20); data.writeUInt16LE(1, 22);
  data.writeUInt32LE(SR, 24); data.writeUInt32LE(SR * 2, 28); data.writeUInt16LE(2, 32); data.writeUInt16LE(16, 34);
  data.write('data', 36); data.writeUInt32LE(n * 2, 40);
  for (let i = 0; i < n; i++) data.writeInt16LE(Math.round(clamp(samples[i], -1, 1) * 32767), 44 + i * 2);
  writeFileSync(path, data);
}

function save(kind, name, samples, quality = 4, peak = 0.85) {
  const wav = join(TMP, `${kind}_${name}.wav`);
  writeWav(wav, normalise(samples, peak));
  const dir = join(OUT, kind);
  mkdirSync(dir, { recursive: true });
  execFileSync('ffmpeg', ['-loglevel', 'error', '-y', '-i', wav, '-c:a', 'libvorbis', '-q:a', String(quality), '-ac', '1', join(dir, `${name}.ogg`)]);
}

// ------------------------------------------------------------- the honks --
// A gosling's honk: a nasal pulse with two formants, a quick rise then a
// droop. `shape` bends the pitch; `rough` adds breath.
function honk({ base = 560, len = 0.2, shape = [0.86, 1.12, 1.0, 0.8], rough = 0.06, vol = 0.6, wobble = 0 } = {}) {
  const raw = tone(len, shape.map((s) => s * base), 'pulse', 1, 0.008, 0.07, wobble, 18);
  const breath = noise(len, rough, 0.004, 0.06, 0.5);
  const voiced = mix(raw, breath);
  const out = mix(gain(bandpass(voiced, 1150, 3), 0.9), gain(bandpass(voiced, 2500, 4), 0.5), gain(lowpass(voiced, 0.25), 0.35));
  return gain(out, vol);
}

function makeVoices() {
  save('voice', 'honk', honk());
  save('voice', 'honk_happy', mix(honk({ base: 620, len: 0.13 }), [honk({ base: 700, len: 0.18, shape: [0.9, 1.15, 1.1, 0.95] }), 0.15]));
  save('voice', 'honk_hurt', honk({ base: 520, len: 0.34, shape: [1.2, 1.0, 0.8, 0.62], rough: 0.12 }));
  save('voice', 'honk_fire', mix(honk({ base: 500, len: 0.2, rough: 0.2 }), noise(0.22, 0.25, 0.01, 0.15, 0.35)));
  save('voice', 'honk_bubble', honk({ base: 640, len: 0.22, wobble: 0.08, shape: [0.9, 1.1, 1.2, 1.3] }));
  save('voice', 'honk_sticky', honk({ base: 470, len: 0.26, shape: [1.0, 0.95, 0.9, 0.84], rough: 0.03 }));
  save('voice', 'honk_melon', honk({ base: 430, len: 0.22, shape: [0.9, 1.05, 0.95, 0.8] }));
  save('voice', 'honk_ice', mix(honk({ base: 700, len: 0.16 }), tone(0.2, [2400, 3200], 'sine', 0.12, 0.002, 0.15)));
  save('voice', 'honk_pop', mix(honk({ base: 660, len: 0.1 }), [honk({ base: 760, len: 0.08 }), 0.1]));
  save('voice', 'honk_noodle', honk({ base: 520, len: 0.3, shape: [0.8, 1.0, 1.25, 1.4], wobble: 0.03 }));
  save('voice', 'honk_zing', honk({ base: 760, len: 0.14, shape: [1.0, 1.3, 1.2, 1.1] }));
  save('voice', 'honk_boom', mix(honk({ base: 380, len: 0.3, shape: [1.0, 1.05, 0.9, 0.7], rough: 0.1 }), tone(0.3, [110, 60], 'sine', 0.4, 0.004, 0.2)));
  save('voice', 'honk_puff', honk({ base: 600, len: 0.18, rough: 0.16, vol: 0.45 }));
  save('voice', 'honk_quiet', honk({ base: 540, len: 0.16, vol: 0.25, rough: 0.1 }));
}

// ------------------------------------------------------------ the effects --
function arp(notes, each = 0.07, type = 'tri', vol = 0.45, release = 0.12) {
  return mix(...notes.map((n, i) => [tone(each + release, [midi(n)], type, vol, 0.003, release), i * each]));
}

function makeEffects() {
  const s = (name, b, peak) => save('sfx', name, b, 4, peak);
  s('jump', tone(0.16, [300, 620], 'tri', 0.5, 0.004, 0.08));
  s('flap', mix(noise(0.1, 0.4, 0.01, 0.07, 0.25), tone(0.1, [520, 380], 'sine', 0.15)));
  s('land', mix(tone(0.1, [150, 70], 'sine', 0.6, 0.002, 0.08), noise(0.06, 0.2, 0.002, 0.05, 0.3)));
  s('step', noise(0.04, 0.3, 0.002, 0.03, 0.2), 0.5);
  s('slide', noise(0.3, 0.3, 0.02, 0.2, 0.15, 0.02));
  s('splash', mix(noise(0.3, 0.45, 0.005, 0.25, 0.3, 0.01), tone(0.2, [700, 250], 'sine', 0.2)));
  s('bonk', mix(tone(0.14, [260, 120], 'square', 0.4, 0.002, 0.1), noise(0.05, 0.3, 0.001, 0.04, 0.5)));
  s('coin', arp([88, 93], 0.05, 'square', 0.3, 0.14));
  s('coin_big', arp([84, 88, 91, 96], 0.06, 'square', 0.3, 0.2));
  s('heart', arp([76, 81, 84, 88], 0.07, 'sine', 0.5, 0.22));
  s('star', arp([79, 83, 86, 91, 95], 0.07, 'tri', 0.5, 0.3));
  s('note', arp([72, 76, 79, 84], 0.08, 'tri', 0.5, 0.25));
  s('key', arp([91, 86, 91], 0.06, 'square', 0.28, 0.2));
  s('unlock', mix(tone(0.08, [300], 'square', 0.3), [tone(0.2, [520, 780], 'tri', 0.4), 0.08]));
  s('pickup', arp([79, 86, 91], 0.05, 'tri', 0.45, 0.2));
  s('power_up', arp([60, 64, 67, 72, 76, 79], 0.055, 'square', 0.3, 0.25));
  s('blend', mix(arp([67, 71, 74, 79, 83], 0.05, 'tri', 0.45, 0.3), noise(0.3, 0.2, 0.01, 0.25, 0.4, 0.05)));
  s('recipe', arp([72, 76, 79, 84, 88, 91], 0.08, 'tri', 0.45, 0.35));
  s('checkpoint', mix(tone(0.5, [1318], 'sine', 0.5, 0.002, 0.45), tone(0.5, [1976], 'sine', 0.25, 0.002, 0.4), [tone(0.5, [1568], 'sine', 0.4, 0.002, 0.45), 0.16]));
  s('level_clear', arp([72, 76, 79, 84, 79, 84, 88, 91, 96], 0.1, 'square', 0.3, 0.4));
  s('crate_break', mix(noise(0.22, 0.6, 0.002, 0.2, 0.35), tone(0.1, [180, 90], 'square', 0.3)));
  s('block', mix(tone(0.08, [420, 300], 'square', 0.35), [tone(0.12, [840], 'tri', 0.3), 0.05]));
  s('button', mix(tone(0.05, [500], 'square', 0.3), [tone(0.08, [750], 'square', 0.3), 0.05]));
  s('lever', mix(tone(0.06, [200], 'square', 0.35), noise(0.05, 0.3, 0.001, 0.04, 0.4)));
  s('gate_open', mix(tone(0.5, [90, 160], 'saw', 0.3, 0.02, 0.2), noise(0.5, 0.2, 0.02, 0.3, 0.1)));
  s('gate_close', mix(tone(0.3, [160, 80], 'saw', 0.3, 0.01, 0.15), noise(0.1, 0.4, 0.001, 0.08, 0.3)));
  s('boing', tone(0.3, [220, 660, 440, 600, 520], 'sine', 0.55, 0.004, 0.15));
  s('pop', mix(tone(0.07, [900, 300], 'sine', 0.6, 0.001, 0.05), noise(0.03, 0.3, 0.001, 0.02, 0.8)));
  s('poof', mix(noise(0.25, 0.5, 0.004, 0.22, 0.18), tone(0.2, [500, 200], 'sine', 0.25)));
  s('stomp', mix(tone(0.1, [400, 150], 'tri', 0.6, 0.002, 0.07), noise(0.05, 0.3, 0.001, 0.04, 0.4)));
  s('enemy_hit', mix(tone(0.09, [520, 300], 'square', 0.35, 0.002, 0.06), noise(0.04, 0.25, 0.001, 0.03, 0.6)));
  s('enemy_shot', tone(0.12, [700, 420], 'square', 0.25, 0.002, 0.08));
  s('enemy_rush', mix(noise(0.25, 0.3, 0.02, 0.15, 0.2, 0.03), tone(0.25, [200, 380], 'saw', 0.15)));
  s('clink', mix(tone(0.12, [2200], 'tri', 0.35, 0.001, 0.1), tone(0.1, [3300], 'sine', 0.2, 0.001, 0.08)));
  s('thud', mix(tone(0.2, [110, 45], 'sine', 0.8, 0.002, 0.16), noise(0.08, 0.3, 0.001, 0.07, 0.2)));
  s('freeze', mix(tone(0.3, [1800, 2600, 3400], 'sine', 0.25, 0.003, 0.2), noise(0.2, 0.2, 0.002, 0.18, 1, 0.3)));
  s('melt', tone(0.4, [600, 200], 'sine', 0.35, 0.02, 0.3, 0.05, 9));
  s('squelch', mix(noise(0.16, 0.45, 0.01, 0.12, 0.12), tone(0.16, [240, 150, 260], 'sine', 0.3)));
  s('shot', tone(0.1, [800, 500], 'tri', 0.4, 0.002, 0.06));
  s('shot_fire', mix(noise(0.22, 0.45, 0.004, 0.18, 0.3), tone(0.16, [400, 180], 'saw', 0.25)));
  s('bubble_up', tone(0.2, [300, 900], 'sine', 0.45, 0.01, 0.08, 0.12, 22));
  s('whip', mix(noise(0.14, 0.45, 0.02, 0.05, 1, 0.2), tone(0.12, [400, 1400], 'sine', 0.2)));
  s('zap', mix(tone(0.2, [1400, 300, 1100, 250], 'saw', 0.35, 0.001, 0.08), noise(0.2, 0.3, 0.001, 0.15, 1, 0.3)));
  s('beam', mix(tone(0.3, [1300, 1100], 'saw', 0.3, 0.004, 0.2), tone(0.3, [2600, 2200], 'sine', 0.2, 0.004, 0.2)));
  s('dash', mix(noise(0.22, 0.5, 0.01, 0.18, 0.5, 0.05), tone(0.2, [300, 900], 'sine', 0.2)));
  s('shield', mix(tone(0.3, [392, 523], 'sine', 0.4, 0.02, 0.2), tone(0.3, [784], 'sine', 0.2, 0.02, 0.2)));
  s('throw', tone(0.14, [380, 700], 'sine', 0.4, 0.004, 0.08));
  s('splat', mix(noise(0.3, 0.6, 0.002, 0.26, 0.2), tone(0.2, [140, 60], 'sine', 0.6)));
  s('swoop', noise(0.35, 0.35, 0.1, 0.2, 0.3, 0.05));
  s('dig', noise(0.2, 0.45, 0.01, 0.16, 0.1));
  s('buzz', tone(0.3, [190, 210, 190], 'saw', 0.25, 0.02, 0.1, 0.05, 30));
  s('whistle', tone(0.6, [900, 1300, 1100], 'sine', 0.3, 0.05, 0.3, 0.02, 7));
  s('steam', noise(0.5, 0.35, 0.03, 0.4, 1, 0.4));
  s('appear', arp([84, 88, 91], 0.04, 'sine', 0.4, 0.15));
  s('alarm', mix(tone(0.12, [880], 'square', 0.3), [tone(0.12, [880], 'square', 0.3), 0.16]));
  s('deny', mix(tone(0.1, [220], 'square', 0.3), [tone(0.14, [165], 'square', 0.3), 0.1]));
  s('boss_warn', mix(tone(0.2, [196], 'saw', 0.3, 0.01, 0.1), [tone(0.25, [233], 'saw', 0.3, 0.01, 0.15), 0.2]));
  s('boss_down', mix(arp([60, 64, 67, 72, 76, 79, 84, 88], 0.09, 'square', 0.3, 0.4), noise(0.8, 0.25, 0.01, 0.7, 0.2)));
  s('charge', tone(0.8, [150, 500], 'saw', 0.25, 0.1, 0.05, 0.03, 12));
  s('boom', mix(tone(0.5, [120, 40], 'sine', 0.9, 0.002, 0.45), noise(0.4, 0.4, 0.002, 0.35, 0.15)));
  s('puff', noise(0.2, 0.35, 0.02, 0.16, 0.2));
  s('talk', tone(0.06, [500, 560], 'tri', 0.3));
  s('ui_move', tone(0.05, [660], 'tri', 0.3, 0.002, 0.04), 0.5);
  s('ui_select', arp([76, 83], 0.05, 'tri', 0.4, 0.1), 0.7);
  s('ui_open', arp([67, 72, 76], 0.04, 'tri', 0.4, 0.1), 0.7);
  s('ui_back', arp([76, 72], 0.05, 'tri', 0.4, 0.1), 0.7);
}

// --------------------------------------------------------------- the music --
const SCALES = {
  major: [0, 2, 4, 5, 7, 9, 11], minor: [0, 2, 3, 5, 7, 8, 10], dorian: [0, 2, 3, 5, 7, 9, 10],
  lydian: [0, 2, 4, 6, 7, 9, 11], mixo: [0, 2, 4, 5, 7, 9, 10], penta: [0, 2, 4, 7, 9, 12, 14],
};

function degree(root, scale, d) {
  const s = SCALES[scale], n = s.length;
  const oct = Math.floor(d / n), idx = ((d % n) + n) % n;
  return root + oct * 12 + s[idx];
}

const VOICES = {
  marimba: (f, len) => mix(tone(len, [f], 'sine', 0.5, 0.002, len * 0.9), gain(tone(Math.min(len, 0.08), [f * 4], 'sine', 0.18, 0.001, 0.06), 1)),
  pluck: (f, len) => lowpass(tone(len, [f], 'saw', 0.4, 0.002, len * 0.95), 0.25),
  lead: (f, len) => tone(len, [f], 'tri', 0.42, 0.012, Math.min(0.12, len * 0.5), 0.006, 5.5),
  flute: (f, len) => mix(tone(len, [f], 'sine', 0.42, 0.03, Math.min(0.14, len * 0.5), 0.008, 5), noise(len, 0.02, 0.02, 0.1, 0.4)),
  bell: (f, len) => mix(tone(len, [f], 'sine', 0.38, 0.002, len * 0.95), tone(len, [f * 2.76], 'sine', 0.1, 0.002, len * 0.7)),
  organ: (f, len) => mix(tone(len, [f], 'square', 0.16, 0.01, 0.06), tone(len, [f * 2], 'tri', 0.14, 0.01, 0.06)),
  bass: (f, len) => mix(tone(len, [f], 'tri', 0.5, 0.004, Math.min(0.1, len * 0.4)), tone(len, [f * 0.5], 'sine', 0.25, 0.004, 0.08)),
  pad: (f, len) => lowpass(mix(tone(len, [f * 0.996], 'saw', 0.14, 0.08, 0.2), tone(len, [f * 1.004], 'saw', 0.14, 0.08, 0.2)), 0.12),
};

function kick() { return tone(0.16, [150, 45], 'sine', 0.9, 0.001, 0.12); }
function snare() { return mix(noise(0.14, 0.4, 0.001, 0.12, 0.6, 0.05), tone(0.08, [240, 170], 'tri', 0.3, 0.001, 0.07)); }
function hat() { return noise(0.04, 0.16, 0.001, 0.035, 1, 0.5); }
function shaker() { return noise(0.06, 0.1, 0.01, 0.04, 1, 0.4); }
function tick() { return tone(0.03, [2000], 'tri', 0.18, 0.001, 0.025); }

// A tune is written per 8-bar section as scale degrees per eighth note:
// numbers play, "-" holds the last note, "." rests. Sections are joined by form.
function parseLine(line) { return line.trim().split(/\s+/); }

function track({ bpm, root, scale, form, sections, chords, lead = 'lead', comp = 'marimba', drums = 'light', swing = 0, bars = 8, waltz = false }) {
  const beat = 60 / bpm, eighth = beat / 2;
  const perBar = waltz ? 6 : 8;
  const parts = [];
  let t = 0;
  for (const name of form) {
    const sec = sections[name];
    const mel = parseLine(sec.mel);
    const prog = sec.chords || chords;
    // melody
    for (let i = 0; i < mel.length; i++) {
      const tok = mel[i];
      if (tok === '.' || tok === '-') continue;
      let len = 1;
      while (i + len < mel.length && mel[i + len] === '-') len++;
      const sw = (i % 2 === 1) ? swing * eighth : 0;
      const f = midi(degree(root + 12, scale, parseInt(tok, 10)));
      parts.push([VOICES[lead](f, Math.max(0.09, len * eighth * 0.95)), t + i * eighth + sw]);
    }
    // accompaniment and bass, one chord per bar
    for (let b = 0; b < bars; b++) {
      const ch = prog[b % prog.length];
      const bt = t + b * perBar * eighth;
      const tones = [ch, ch + 2, ch + 4];
      parts.push([gain(VOICES.bass(midi(degree(root - 12, scale, ch)), beat * 0.9), 0.9), bt]);
      if (!waltz) parts.push([gain(VOICES.bass(midi(degree(root - 12, scale, ch + 4)), beat * 0.9), 0.7), bt + beat * 2]);
      const pattern = waltz ? [null, 0, 1, null, 2, 1] : [0, null, 1, 2, null, 1, 2, 0];
      pattern.forEach((p, k) => {
        if (p === null) return;
        const sw = (k % 2 === 1) ? swing * eighth : 0;
        parts.push([gain(VOICES[comp](midi(degree(root, scale, tones[p])), eighth * 1.6), 0.5), bt + k * eighth + sw]);
      });
      if (sec.pad !== false) parts.push([gain(VOICES.pad(midi(degree(root, scale, ch)), perBar * eighth), 0.5), bt]);
      // drums
      for (let k = 0; k < perBar; k++) {
        const dt = bt + k * eighth + ((k % 2 === 1) ? swing * eighth : 0);
        if (drums === 'none') continue;
        if (waltz) {
          if (k === 0) parts.push([gain(kick(), 0.5), dt]);
          if (k === 2 || k === 4) parts.push([gain(tick(), 0.8), dt]);
          continue;
        }
        if (drums === 'clock') { parts.push([tick(), dt]); if (k === 0) parts.push([gain(kick(), 0.5), dt]); continue; }
        if (k === 0 || (k === 4 && drums !== 'light') || (k === 5 && drums === 'drive')) parts.push([gain(kick(), drums === 'light' ? 0.45 : 0.7), dt]);
        if ((k === 2 || k === 6) && drums !== 'light') parts.push([gain(snare(), 0.6), dt]);
        if (drums === 'light') { if (k % 2 === 1) parts.push([shaker(), dt]); } else parts.push([gain(hat(), k % 2 === 0 ? 1 : 0.6), dt]);
      }
    }
    t += bars * perBar * eighth;
  }
  // a short tail is folded back onto the start so the loop is seamless
  const body = mix(...parts);
  const loopLen = Math.round(t * SR);
  const out = new Float32Array(loopLen);
  for (let i = 0; i < body.length; i++) out[i % loopLen] += body[i];
  return out;
}

const TUNES = {
  title: { bpm: 112, root: 60, scale: 'major', lead: 'lead', comp: 'marimba', drums: 'beat', form: ['a', 'a', 'b', 'a'], chords: [0, 0, 3, 4, 0, 5, 3, 4],
    sections: {
      a: { mel: '4 . 4 5 7 - 5 4  2 . 2 4 5 - - .  3 . 3 5 7 - 9 7  8 - 7 5 4 - - .  4 . 4 5 7 - 5 4  9 - 7 9 7 - 5 .  3 5 7 5 3 - 2 .  1 - 2 3 4 - - .' },
      b: { chords: [3, 3, 0, 0, 3, 3, 4, 4], mel: '5 - 7 - 9 - 7 5  5 7 9 7 5 - - .  4 - 5 - 7 - 5 4  4 5 7 5 4 - - .  5 - 7 - 9 - 10 9  9 7 9 10 12 - - .  11 - 9 - 8 - 6 -  8 - 9 - 11 - - .' },
    } },
  hub: { bpm: 92, root: 65, scale: 'major', lead: 'flute', comp: 'pluck', drums: 'light', swing: 0.25, form: ['a', 'b'], chords: [0, 5, 3, 4],
    sections: {
      a: { mel: '4 - 5 4 2 - 0 -  2 - 4 2 0 - - .  3 - 4 3 1 - 0 -  1 - 2 - 4 - - .  4 - 5 4 2 - 0 -  5 - 7 5 4 - - .  3 4 5 3 2 - 1 -  0 - - - . . . .' },
      b: { mel: '7 - 5 - 4 - 5 -  4 - 2 - 0 - - .  5 - 4 - 3 - 4 -  2 - 1 - 2 - - .  7 - 5 - 4 - 5 -  9 - 7 - 5 - - .  4 5 7 5 4 - 2 -  0 - - - . . . .' },
    } },
  map: { bpm: 104, root: 62, scale: 'major', lead: 'bell', comp: 'pluck', drums: 'light', form: ['a'], chords: [0, 3, 4, 0, 5, 3, 4, 4],
    sections: { a: { mel: '0 2 4 - 2 4 5 -  4 2 0 - - . . .  3 5 7 - 5 7 8 -  7 5 4 - - . . .  5 4 2 - 4 2 0 -  3 2 0 - 2 0 -1 -  0 2 4 5 7 - 5 4  4 - - - . . . .' } } },
  story: { bpm: 76, root: 60, scale: 'lydian', lead: 'flute', comp: 'bell', drums: 'none', form: ['a'], chords: [0, 4, 3, 0, 5, 3, 1, 4],
    sections: { a: { mel: '4 - - - 7 - - -  6 - 4 - 2 - - -  3 - - - 5 - - -  4 - - - - - . .  5 - - - 9 - - -  7 - 5 - 4 - - -  3 - 4 - 5 - 6 -  4 - - - - - . .' } } },
  ending: { bpm: 84, root: 60, scale: 'major', lead: 'flute', comp: 'marimba', drums: 'light', form: ['a', 'b'], chords: [0, 4, 5, 3, 0, 4, 3, 4],
    sections: {
      a: { mel: '4 - 5 - 7 - - -  9 - 7 - 5 - - -  7 - 5 - 4 - 2 -  4 - - - - - . .  4 - 5 - 7 - - -  9 - 11 - 12 - - -  11 - 9 - 7 - 5 -  7 - - - - - . .' },
      b: { mel: '12 - 11 - 9 - 7 -  9 - - - 7 - - -  8 - 7 - 5 - 4 -  5 - - - - - . .  7 - 9 - 11 - 9 -  12 - - - 9 - - -  7 - 5 - 4 - 2 -  0 - - - - - . .' },
    } },
  world1: { bpm: 126, root: 60, scale: 'major', lead: 'lead', comp: 'marimba', drums: 'beat', form: ['a', 'a', 'b', 'a'], chords: [0, 3, 0, 4, 0, 3, 4, 0],
    sections: {
      a: { mel: '0 2 4 . 4 2 4 5  7 - 5 - 4 - . .  5 4 2 . 2 0 2 4  2 - - - . . . .  0 2 4 . 4 2 4 5  7 - 9 - 7 - . .  8 7 5 4 2 4 1 2  0 - - - . . . .' },
      b: { chords: [5, 5, 3, 3, 5, 5, 4, 4], mel: '7 . 7 9 7 5 4 .  5 . 5 7 5 4 2 .  4 . 4 5 4 2 0 .  2 - - - . . . .  7 . 7 9 7 5 4 .  9 . 9 11 9 7 5 .  6 - 5 - 4 - 2 -  4 - - - . . . .' },
    } },
  world2: { bpm: 118, root: 67, scale: 'mixo', lead: 'pluck', comp: 'pluck', drums: 'beat', swing: 0.3, form: ['a', 'a', 'b', 'a'], chords: [0, 0, 3, 0, 4, 3, 0, 4],
    sections: {
      a: { mel: '0 . 2 4 5 4 2 .  4 . 2 0 -1 - . .  3 . 5 7 8 7 5 .  4 - - - . . . .  0 . 2 4 5 4 2 .  7 . 5 4 2 - . .  4 5 4 2 0 2 -1 .  0 - - - . . . .' },
      b: { chords: [3, 3, 0, 0, 3, 3, 4, 4], mel: '7 - 5 7 8 - 7 5  7 - 5 4 2 - . .  4 - 2 4 5 - 4 2  4 - - - . . . .  7 - 5 7 8 - 7 5  9 - 7 5 7 - . .  8 7 5 4 5 4 2 1  2 - - - . . . .' },
    } },
  world3: { bpm: 132, root: 62, scale: 'major', lead: 'bell', comp: 'organ', drums: 'light', waltz: true, form: ['a', 'a', 'b', 'a'], chords: [0, 4, 0, 4, 3, 0, 4, 0],
    sections: {
      a: { mel: '4 - 5 7 - 5  4 - 2 0 - .  1 - 2 4 - 2  1 - - - . .  4 - 5 7 - 5  9 - 7 5 - .  6 - 4 2 - 1  0 - - - . .' },
      b: { chords: [5, 5, 3, 3, 1, 4, 0, 4], mel: '7 - 9 11 - 9  7 - 5 7 - .  5 - 7 9 - 7  5 - - - . .  3 - 5 8 - 5  4 - 6 8 - .  7 - 5 4 - 2  4 - - - . .' },
    } },
  world4: { bpm: 100, root: 64, scale: 'dorian', lead: 'bell', comp: 'bell', drums: 'light', form: ['a', 'b'], chords: [0, 3, 0, 4, 0, 3, 6, 0],
    sections: {
      a: { mel: '4 - . 7 - . 5 -  4 - 2 - 0 - . .  3 - . 5 - . 4 -  2 - - - . . . .  4 - . 7 - . 9 -  8 - 7 - 5 - . .  4 - 5 - 3 - 2 -  0 - - - . . . .' },
      b: { mel: '7 - 9 - 11 - 9 -  7 - - - 5 - . .  5 - 7 - 9 - 7 -  4 - - - . . . .  7 - 9 - 11 - 12 -  11 - 9 - 7 - . .  5 - 4 - 2 - 1 -  0 - - - . . . .' },
    } },
  world5: { bpm: 138, root: 65, scale: 'major', lead: 'flute', comp: 'pluck', drums: 'drive', form: ['a', 'a', 'b', 'a'], chords: [0, 4, 5, 3, 0, 4, 3, 4],
    sections: {
      a: { mel: '4 5 7 - 9 - 7 5  7 - 4 - 2 - . .  5 7 9 - 11 - 9 7  9 - - - . . . .  4 5 7 - 9 - 7 5  12 - 11 - 9 - . .  7 9 7 5 4 5 2 4  0 - - - . . . .' },
      b: { chords: [3, 3, 5, 5, 3, 3, 4, 4], mel: '8 - 7 5 7 - 5 3  5 - - - 3 - . .  9 - 7 5 7 - 9 7  5 - - - . . . .  8 - 7 5 7 - 5 3  10 - 9 7 9 - . .  8 7 5 7 6 5 4 6  7 - - - . . . .' },
    } },
  world6: { bpm: 116, root: 57, scale: 'minor', lead: 'organ', comp: 'pluck', drums: 'clock', form: ['a', 'a', 'b', 'a'], chords: [0, 5, 3, 4, 0, 5, 6, 4],
    sections: {
      a: { mel: '0 . 2 3 4 - 3 2  4 - 2 - 0 - . .  5 . 4 3 2 - 3 4  2 - - - . . . .  0 . 2 3 4 - 3 2  7 - 5 - 4 - . .  5 4 3 2 3 2 1 -1  0 - - - . . . .' },
      b: { chords: [3, 3, 6, 6, 5, 5, 4, 4], mel: '7 - 5 - 7 - 9 -  7 - - - 5 - . .  6 - 4 - 6 - 8 -  6 - - - . . . .  7 - 9 - 10 - 9 -  7 - 5 - 4 - . .  3 - 4 - 5 - 6 -  4 - - - . . . .' },
    } },
  boss: { bpm: 150, root: 57, scale: 'minor', lead: 'lead', comp: 'organ', drums: 'drive', form: ['a', 'b'], chords: [0, 0, 5, 4, 0, 0, 6, 4],
    sections: {
      a: { pad: false, mel: '0 0 . 0 3 . 2 0  0 0 . 0 4 . 3 2  5 5 . 5 7 . 5 4  4 - 3 - 2 - 1 -  0 0 . 0 3 . 2 0  0 0 . 0 7 . 5 4  6 6 . 6 8 . 6 5  4 - - - . . . .' },
      b: { pad: false, chords: [3, 3, 0, 0, 5, 5, 4, 4], mel: '7 - 5 7 8 - 7 5  7 - 5 3 5 - . .  4 - 2 4 5 - 4 2  4 - - - . . . .  9 - 7 9 10 - 9 7  9 - 7 5 7 - . .  8 7 5 4 5 4 3 1  2 - - - . . . .' },
    } },
};

function makeMusic() {
  for (const [name, spec] of Object.entries(TUNES)) {
    const audio = track(spec);
    save('music', name, audio, 3, 0.7);
    console.log(`music/${name}.ogg  ${(audio.length / SR).toFixed(1)} s`);
  }
}

// --------------------------------------------------------------------- run --
if (existsSync(TMP)) rmSync(TMP, { recursive: true, force: true });
mkdirSync(TMP, { recursive: true });
makeVoices();
makeEffects();
console.log('voices and effects written');
makeMusic();
rmSync(TMP, { recursive: true, force: true });
console.log('done');
