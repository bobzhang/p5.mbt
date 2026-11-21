"""Narration, music and sound effects for the film, timed by the MoonBit story.

    python3 p5_demos/agents/tools/audio.py

Reads the timeline from `moon run p5_demos/agents/cues` (story/story.mbt), so every
whoosh lands on its camera move and every line fits its slot. Writes:

    assets/soundtrack.wav             the full mix
    output/made-in-moonbit.srt        subtitles

The voice is macOS `say` (Samantha); everything else is synthesized here.
"""
import array
import json
import math
import os
import subprocess
import tempfile
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # the demo
REPO = os.path.dirname(os.path.dirname(ROOT))  # the p5.mbt workspace
RATE = 24000
VOICE = os.environ.get("VOICE", "Samantha")


def cues():
    out = subprocess.run(["moon", "run", "p5_demos/agents/cues", "--target", "js"], cwd=REPO,
                         check=True, capture_output=True, text=True).stdout
    return json.loads([l for l in out.splitlines() if l.startswith("{")][-1])


C = cues()
TOTAL = C["total"]
EV = C["events"]
N = int(TOTAL * RATE) + RATE
music = array.array("f", bytes(4 * N))
sfx = array.array("f", bytes(4 * N))
voice = array.array("f", bytes(4 * N))


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


class Rng:
    def __init__(self, seed):
        self.x = seed * 2654435761 % 2147483648 or 1

    def __call__(self):
        self.x = (1103515245 * self.x + 12345) % 2147483648
        return self.x / 1073741824 - 1


def add(buf, i, v):
    if 0 <= i < len(buf):
        buf[i] += v


# ---------------------------------------------------------------- instruments

def tone(buf, start, dur, midi, amp, bright=0.0, attack=0.004, decay=4.0):
    f = hz(midi)
    i0 = int(start * RATE)
    w = 2 * math.pi * f / RATE
    for j in range(int((dur + 2.0 / decay) * RATE)):
        t = j / RATE
        env = min(1.0, t / attack) * math.exp(-decay * t)
        if env < 2e-4:
            break
        ph = w * j
        add(buf, i0 + j, amp * env * (math.sin(ph) + bright * (0.5 * math.sin(2 * ph) + 0.3 * math.sin(3 * ph))))


def pad(buf, start, dur, chord, amp, fade=0.8):
    i0 = int(start * RATE)
    ws = [2 * math.pi * hz(m) * d / RATE for m in chord for d in (0.996, 1.004)]
    for j in range(int(dur * RATE)):
        t = j / RATE
        env = min(1.0, t / fade, (dur - t) / fade)
        if env > 0:
            add(buf, i0 + j, amp * env * sum(math.sin(w * j) for w in ws) / len(ws))


def kick(buf, start, amp=0.5):
    i0 = int(start * RATE)
    ph = 0.0
    for j in range(int(0.3 * RATE)):
        t = j / RATE
        f = 45 + 90 * math.exp(-t * 30)
        ph += 2 * math.pi * f / RATE
        add(buf, i0 + j, amp * math.sin(ph) * math.exp(-t * 11))


def hat(buf, start, amp, seed):
    i0 = int(start * RATE)
    r = Rng(seed)
    prev = 0.0
    for j in range(int(0.05 * RATE)):
        x = r()
        hp = x - prev
        prev = x
        add(buf, i0 + j, amp * hp * math.exp(-j / (0.01 * RATE)))


def whoosh(buf, start, dur, amp, seed, peak=0.5, lo=0.02, hi=0.35, tremolo=0.0):
    """Filtered noise whose brightness and loudness swell to `peak`."""
    i0 = int(start * RATE)
    r = Rng(seed)
    y = 0.0
    n = int(dur * RATE)
    for j in range(n):
        u = j / n
        shape = math.sin(math.pi * min(1, u / (2 * peak) if u < peak else 0.5 + (u - peak) / (2 * (1 - peak))))
        a = lo + (hi - lo) * shape
        y += a * (r() - y)
        trem = 1 - tremolo * (0.5 + 0.5 * math.sin(2 * math.pi * 9 * u * dur))
        add(buf, i0 + j, amp * shape * trem * y * 3)


def sweep(buf, start, dur, f0, f1, amp):
    i0 = int(start * RATE)
    ph = 0.0
    n = int(dur * RATE)
    for j in range(n):
        u = j / n
        f = f0 * (f1 / f0) ** u
        ph += 2 * math.pi * f / RATE
        add(buf, i0 + j, amp * math.sin(ph) * math.sin(math.pi * u))


def click(buf, start, amp, seed, length=0.012):
    i0 = int(start * RATE)
    r = Rng(seed)
    prev = 0.0
    for j in range(int(length * RATE)):
        prev = 0.5 * prev + 0.5 * r()
        add(buf, i0 + j, amp * prev * math.exp(-j / (0.003 * RATE)))


def blip(buf, start, dur, midi, amp):
    i0 = int(start * RATE)
    f = hz(midi)
    for j in range(int(dur * RATE)):
        sq = 1.0 if math.sin(2 * math.pi * f * j / RATE) > 0 else -1.0
        add(buf, i0 + j, amp * sq * (1 - j / (dur * RATE)))


# ------------------------------------------------------------------- narration

def say(text, rate):
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "v.wav")
        subprocess.run(["say", "-v", VOICE, "-r", str(int(rate)), "--file-format=WAVE",
                        f"--data-format=LEI16@{RATE}", "-o", path, text], check=True)
        with wave.open(path, "rb") as w:
            pcm = array.array("h", w.readframes(w.getnframes()))
    # trim the silence `say` leaves around the words
    thr = 300
    a = next((i for i, v in enumerate(pcm) if abs(v) > thr), 0)
    b = len(pcm) - next((i for i, v in enumerate(reversed(pcm)) if abs(v) > thr), 0)
    return pcm[max(0, a - 240):min(len(pcm), b + 240)]


voiced = []
srt = []
for n, line in enumerate(C["lines"]):
    slot = line["end"] - line["start"]
    rate = 172
    pcm = say(line["text"], rate)
    dur = len(pcm) / RATE
    tries = 0
    while dur > slot and tries < 4:
        rate = min(290, rate * dur / slot * 1.02)
        pcm = say(line["text"], rate)
        dur = len(pcm) / RATE
        tries += 1
    peak = max(abs(v) for v in pcm) or 1
    i0 = int(line["start"] * RATE)
    for j, v in enumerate(pcm):
        add(voice, i0 + j, 0.9 * v / peak)
    voiced.append((line["start"], line["start"] + dur))
    print(f"line {n}: {dur:4.2f}s in a {slot:4.2f}s slot at {rate:.0f} wpm  {line['text']}", flush=True)

    def ts(x):
        ms = int(round(x * 1000))
        return f"{ms // 3600000:02d}:{ms // 60000 % 60:02d}:{ms // 1000 % 60:02d},{ms % 1000:03d}"
    srt.append(f"{n + 1}\n{ts(line['start'])} --> {ts(line['start'] + dur + 0.2)}\n{line['zh']}\n")


def phrase_time(i, phrase):
    l = C["lines"][i]
    at = l["text"].find(phrase)
    return l["start"] + (l["end"] - l["start"]) * max(at, 0) / len(l["text"])


# ----------------------------------------------------------------------- music
TN = 2048
SAW = [sum(math.sin(2 * math.pi * k * i / TN) / k for k in range(1, 11)) / 1.6 for i in range(TN)]
SOFT = [math.sin(2 * math.pi * i / TN) + 0.25 * math.sin(4 * math.pi * i / TN) for i in range(TN)]


def voice_(buf, start, dur, midi, amp, table=SAW, attack=0.6, release=1.0, cutoff=0.06,
           detune=(0.996, 1.004), vib=0.0):
    """A sustained, filtered oscillator: strings, pads, brass."""
    i0 = int(start * RATE)
    n = int((dur + release) * RATE)
    f = hz(midi)
    for d in detune:
        inc = f * d * TN / RATE
        ph = 0.0
        y = 0.0
        g = amp / len(detune)
        for j in range(n):
            t = j / RATE
            env = min(1.0, t / attack) if t < dur else max(0.0, 1 - (t - dur) / release)
            if env <= 0:
                continue
            step = inc * (1 + vib * math.sin(2 * math.pi * 5.2 * t)) if vib else inc
            ph = (ph + step) % TN
            y += cutoff * (table[int(ph)] - y)
            k = i0 + j
            if k < len(buf):
                buf[k] += g * env * y


def chord(buf, start, dur, notes, amp, **kw):
    for m in notes:
        voice_(buf, start, dur, m, amp / len(notes) * 2, **kw)


def piano(buf, start, midi, amp, decay=1.6):
    tone(buf, start, 1.0, midi, amp, bright=0.3, attack=0.003, decay=decay)
    tone(buf, start, 1.0, midi + 12, amp * 0.18, attack=0.003, decay=decay * 2)


def boom(buf, start, amp=0.5):
    sweep(buf, start, 1.2, 90, 32, amp)
    whoosh(buf, start, 0.9, amp * 0.5, int(start * 100), peak=0.05, hi=0.08)


def riser(buf, start, dur, amp):
    whoosh(buf, start, dur, amp, int(start * 10) + 3, peak=0.97, lo=0.01, hi=0.5)
    sweep(buf, start, dur, 110, 880, amp * 0.25)


shots = C["shots"]
ML_, TL_, FL_ = C["moon_line"], C["tagline_line"], C["finale_line"]
t_title, t_ov, t_ai, t_conv, t_born, t_moon, t_tag, t_fin = (
    EV[k] for k in ("title", "overview", "ai", "converge", "born", "moon", "tagline", "finale"))
first = shots[0]["start"]

# cold open: a low drone and a lonely piano; a boom under the title; a rise
chord(music, 0.0, first - 0.3, [33, 40, 45], 0.16, table=SOFT, attack=2.5, release=1.0, cutoff=0.05)
for k, m in enumerate([69, 72, 76, 74, 72, 69, 64]):
    piano(music, 0.9 + k * 1.0, m, 0.05)
boom(music, t_title, 0.45)
chord(music, t_title, first - t_title, [57, 60, 64, 69], 0.10, attack=1.5, release=0.5, cutoff=0.04, vib=0.003)
riser(music, first - 2.0, 2.0, 0.10)

# the six chapters: strings, a ticking clock, a piano arpeggio, a slowly
# growing pulse. Two chords per chapter.
BEAT = 60 / 90
prog = [[45, 57, 60, 64], [41, 57, 60, 65], [48, 55, 60, 64], [43, 55, 59, 62],
        [45, 57, 60, 64], [41, 57, 60, 65], [38, 57, 62, 65], [40, 56, 59, 64],
        [45, 57, 60, 64], [41, 57, 60, 65], [48, 55, 60, 64], [40, 56, 59, 64]]
for k, s_ in enumerate(shots):
    st = s_["start"]
    end = shots[k + 1]["start"] if k + 1 < len(shots) else t_ov
    boom(music, st, 0.30 + 0.03 * k)
    half = (end - st) / 2
    for h_ in range(2):
        c = prog[(2 * k + h_) % len(prog)]
        t0 = st + h_ * half
        chord(music, t0, half, c[1:], 0.09 + 0.01 * k, attack=0.7, release=0.6, cutoff=0.05, vib=0.003)
        voice_(music, t0, half, c[0] - 12, 0.10, table=SOFT, attack=0.05, release=0.3, cutoff=0.2, detune=(1.0,))
        b = 0
        t = t0
        notes = c[1:] + [c[1] + 12, c[2] + 12]
        while t < t0 + half - 0.01:
            piano(music, t, notes[[0, 1, 2, 3, 4, 3, 2, 1][b % 8]] + 12, 0.028 + 0.004 * k, decay=3.0)
            if b % 2 == 0:
                click(music, t, 0.10, 4000 + int(t * 100), length=0.02)  # the clock
                if k >= 2 and b % 4 == 0:
                    kick(music, t, 0.10 + 0.04 * k)
            b += 1
            t += BEAT / 2

# the big picture: no beat, everything opens up
boom(music, t_ov, 0.5)
chord(music, t_ov, 3.6, [41, 53, 57, 60, 64], 0.20, attack=1.2, release=1.0, cutoff=0.045, vib=0.004)
chord(music, t_ov + 3.6, t_ai - t_ov - 3.6, [36, 52, 55, 60, 67], 0.20, attack=1.0, release=0.8, cutoff=0.045, vib=0.004)
chord(music, t_ov, t_ai - t_ov, [69, 72, 76], 0.06, table=SOFT, attack=2.0, release=1.0, cutoff=0.1, vib=0.006)
for k, m in enumerate([76, 79, 84, 83, 79, 76, 72]):
    piano(music, t_ov + 0.8 + k * 0.9, m, 0.04, decay=1.2)

# the age of agents: an ostinato that tightens, a rise, a breath, the braam
t = t_ai
k = 0
while t < t_born - 0.35:
    c = [50, 53, 57, 62] if t < t_conv else [52, 56, 59, 64]
    level = (t - t_ai) / (t_born - t_ai)
    voice_(music, t, BEAT / 4 * 0.9, c[k % 4] + 12, 0.05 + 0.05 * level, attack=0.005, release=0.05, cutoff=0.15, detune=(1.0,))
    if k % 4 == 0:
        kick(music, t, 0.20 + 0.25 * level)
    k += 1
    t += BEAT / 4 * (1 - 0.25 * level)
chord(music, t_ai, t_conv - t_ai, [38, 50, 53, 57], 0.14, attack=0.8, release=0.3, cutoff=0.05)
chord(music, t_conv, t_born - t_conv - 0.3, [40, 52, 56, 59], 0.18, attack=0.5, release=0.1, cutoff=0.06)
riser(music, t_conv - 0.6, t_born - t_conv + 0.3, 0.16)
chord(music, t_born, 3.0, [33, 40, 45, 52, 57], 0.36, attack=0.02, release=2.0, cutoff=0.05)  # braam
boom(music, t_born, 0.7)

# MoonBit: A major, hopeful and moving
BEAT2 = 0.6
mprog = [[45, 57, 61, 64], [40, 56, 59, 64], [42, 57, 61, 66], [38, 57, 62, 66]]
t = t_moon
b = 0
while t < t_tag - 0.01:
    c = mprog[int((t - t_moon) / (BEAT2 * 4)) % 4]
    if b % 4 == 0:
        chord(music, t, BEAT2 * 4, c[1:], 0.10, attack=0.3, release=0.4, cutoff=0.06, vib=0.003)
        voice_(music, t, BEAT2 * 4, c[0] - 12, 0.12, table=SOFT, attack=0.02, release=0.2, cutoff=0.2, detune=(1.0,))
    kick(music, t, 0.28)
    hat(music, t + BEAT2 / 2, 0.07, 700 + b)
    notes = c[1:] + [c[1] + 12]
    piano(music, t, notes[b % 4] + 12, 0.035, decay=2.5)
    piano(music, t + BEAT2 / 2, notes[(b + 2) % 4] + 12, 0.025, decay=2.5)
    b += 1
    t += BEAT2

# the refrain: Unix had C, the GPU had CUDA, the age of agents has MoonBit
rows = [phrase_time(TL_, w_) - 0.2 for w_ in ("Unix", "GPU", "agents")]
chord(music, t_tag, rows[2] - t_tag, [45, 57, 60, 64], 0.10, table=SOFT, attack=0.6, release=0.4, cutoff=0.06)
for k, at in enumerate(rows[:2]):
    boom(music, at, 0.30)
    piano(music, at, [69, 72][k], 0.06, decay=1.2)
boom(music, rows[2], 0.65)
chord(music, rows[2], t_fin - rows[2] + 0.6, [33, 45, 57, 61, 64, 69], 0.32, attack=0.05, release=1.2, cutoff=0.05, vib=0.003)
piano(music, rows[2] + 0.5, 81, 0.05)
piano(music, rows[2] + 1.2, 85, 0.04)

# finale: the moon assembles; a resolving piano line over a warm pad
chord(music, t_fin, TOTAL - t_fin + 1, [45, 57, 61, 64, 68], 0.18, table=SOFT, attack=1.2, release=0.2, cutoff=0.06, vib=0.004)
for k, m in enumerate([76, 73, 69, 71, 73, 76, 81]):
    piano(music, t_fin + 0.5 + k * 0.55, m, 0.045, decay=1.4)
made = phrase_time(FL_, "made")
for m in [69, 73, 76, 81, 85]:
    tone(music, made - 0.2, 3.0, m, 0.03, bright=0.2, decay=0.7)

# --------------------------------------------------------------- sound effects
for k, s_ in enumerate(shots):
    st, tr, style = s_["start"], s_["trans"], s_["style"]
    if style == "ignite":
        whoosh(sfx, st - 0.3, 1.6, 0.14, 1, peak=0.3)
        sweep(sfx, st, 1.2, 1200, 2400, 0.02)
    elif style in ("swoop", "swing"):
        whoosh(sfx, st - 0.05, tr + 0.3, 0.24, k)
    elif style == "spin":
        whoosh(sfx, st - 0.05, tr + 0.3, 0.24, k, tremolo=0.6)
    elif style == "whip":
        whoosh(sfx, st - 0.03, tr + 0.12, 0.30, k, peak=0.45, hi=0.6)
    elif style == "flip":
        click(sfx, st + 0.02, 0.35, k)
        whoosh(sfx, st, tr, 0.12, k, hi=0.7)
        click(sfx, st + tr * 0.5, 0.28, k + 7)
    elif style == "dive":
        sweep(sfx, st, tr / 2, 700, 90, 0.10)
        whoosh(sfx, st, tr / 2 + 0.05, 0.24, k, peak=0.95)
        kick(sfx, st + tr / 2, 0.35)
        whoosh(sfx, st + tr / 2, tr / 2 + 0.2, 0.12, k + 3, peak=0.1)
    elif style == "glitch":
        r = Rng(k)
        for q in range(16):
            blip(sfx, st + q * tr / 16, tr / 20, 60 + int((r() + 1) * 18), 0.035)
    elif style == "iris":
        tone(sfx, st, 0.6, 84, 0.05, decay=3)
        whoosh(sfx, st, tr + 0.1, 0.08, k)
    elif style == "ink":
        whoosh(sfx, st, tr + 0.4, 0.10, k, peak=0.6, lo=0.01, hi=0.12)
        for q in range(7):
            tone(sfx, st + q * tr / 7, 0.6, [76, 79, 83, 86, 88, 91, 95][q], 0.018, decay=3)
    elif style == "leak":
        whoosh(sfx, st, tr, 0.12, k, peak=0.5, lo=0.01, hi=0.15)
        chord(sfx, st, tr * 0.8, [69, 73, 76, 81], 0.05, table=SOFT, attack=tr * 0.4, release=0.6, cutoff=0.1)
    elif style == "dissolve":
        r = Rng(k)
        for q in range(28):
            tone(sfx, st + q * tr / 28, 0.04, 84 + int((r() + 1) * 6), 0.02, decay=40)
    # keys while the code types, then the MoonBit panel opens
    arrive = st + tr
    end = shots[k + 1]["start"] if k + 1 < len(shots) else t_ov
    t0 = arrive - 0.15
    stop = t0 + min(2.6, max(0.35, (end - t0) * 0.8))
    tt, q = t0, 0
    while tt < stop:
        click(sfx, tt, 0.06, 1000 * k + q)
        q += 1
        tt += 0.05 + 0.02 * ((q * 7919) % 11) / 11
    link = arrive + 2.6
    whoosh(sfx, link, 0.5, 0.08, 900 + k, peak=0.3, hi=0.4)
    tone(sfx, link + 0.1, 0.4, 88, 0.03, decay=5)
    tone(sfx, link + 0.18, 0.4, 93, 0.025, decay=5)

whoosh(sfx, t_ov - 0.1, 2.4, 0.18, 77, peak=0.8, hi=0.2)
r = Rng(99)
t = t_ai
while t < t_born - 0.3:
    blip(sfx, t, 0.02, 84 + int((r() + 1) * 8), 0.010 + 0.012 * (t - t_ai) / (t_born - t_ai))
    t += 0.03 + 0.03 * (r() + 1) / 2
whoosh(sfx, t_born + 0.05, t_moon - t_born + 0.2, 0.16, 56, peak=0.3)
# MoonBit's code, its test, the agent loop and the four promises
t0 = t_moon - 0.15
tt, q = t0, 0
while tt < t0 + 2.6:
    click(sfx, tt, 0.06, 5000 + q)
    q += 1
    tt += 0.05 + 0.02 * ((q * 7919) % 11) / 11
ok = t_moon + 2.6 + 0.8
tone(sfx, ok, 0.5, 84, 0.04, decay=4)
tone(sfx, ok + 0.1, 0.6, 88, 0.04, decay=4)
t = t_moon + 0.4
while t < t_tag:
    tone(sfx, t, 0.03, 96, 0.006, decay=60)
    t += 1.1 / 4
for n_, phrase in enumerate(["Designed for AI", "Safe", "Verifiable", "Fast to compile"]):
    at = phrase_time(ML_, phrase) - 0.1
    tone(sfx, at, 0.25, 79 + n_ * 2, 0.04, decay=8)
    click(sfx, at, 0.15, 300 + n_)
r = Rng(7)
t = t_fin
while t < t_fin + 2.4:
    tone(sfx, t, 0.05, 86 + int((r() + 1) * 7), 0.010, decay=30)
    t += 0.02
whoosh(sfx, t_fin, 2.0, 0.10, 88, peak=0.6, hi=0.25)

# ------------------------------------------------------------------------ mix
duck = array.array("f", bytes(4 * N))
for a, b_ in voiced:
    for j in range(int((a - 0.15) * RATE), int((b_ + 0.25) * RATE)):
        if 0 <= j < N:
            duck[j] = 1.0
level = 0.0
for j in range(N):  # smooth the ducking so the music breathes rather than jumps
    target = duck[j]
    level += (target - level) * (0.0009 if target > level else 0.00025)
    duck[j] = level

mpeak = max(abs(v) for v in music) or 1
out = array.array("h")
for j in range(int(TOTAL * RATE)):
    t = j / RATE
    m = music[j] / mpeak * 0.55 * (1 - 0.5 * duck[j])
    v = math.tanh(1.1 * (m + 0.9 * sfx[j]) + 0.85 * voice[j])
    fade = min(1.0, (TOTAL - t) / 0.4, t / 0.05)
    out.append(int(max(-1, min(1, v * fade)) * 30000))

os.makedirs(os.path.join(ROOT, "assets"), exist_ok=True)
with wave.open(os.path.join(ROOT, "assets", "soundtrack.wav"), "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(RATE)
    w.writeframes(out.tobytes())
os.makedirs(os.path.join(ROOT, "output"), exist_ok=True)
with open(os.path.join(ROOT, "output", "made-in-moonbit.srt"), "w") as f:
    f.write("\n".join(srt))
print(f"assets/soundtrack.wav: {TOTAL:.1f} s; output/made-in-moonbit.srt")
