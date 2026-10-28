import math
import random
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1] / "assets" / "audio"
RATE = 22050
TAU = math.tau


def write_wav(name, samples, loop=False):
    peak = max((abs(value) for value in samples), default=1.0)
    scale = min(0.92 / peak, 1.0) if peak else 1.0
    path = ROOT / name
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, value * scale)) * 32767)) for value in samples))


def add_pluck(buffer, start, frequency, amplitude=0.12, duration=1.4, brightness=1.0):
    first = max(0, int(start * RATE))
    count = min(int(duration * RATE), len(buffer) - first)
    for offset in range(count):
        time = offset / RATE
        attack = 1.0 - math.exp(-time * 180.0)
        envelope = attack * math.exp(-time * (2.5 + (1.0 - brightness)))
        fundamental = math.sin(TAU * frequency * time)
        second = math.sin(TAU * frequency * 2.01 * time + 0.12) * 0.32
        third = math.sin(TAU * frequency * 3.97 * time + 0.4) * 0.10 * brightness
        buffer[first + offset] += amplitude * envelope * (fundamental + second + third)


def add_bell(buffer, start, frequency, amplitude=0.1, duration=2.4):
    first = max(0, int(start * RATE))
    count = min(int(duration * RATE), len(buffer) - first)
    for offset in range(count):
        time = offset / RATE
        envelope = math.exp(-time * 2.8)
        tone = math.sin(TAU * frequency * time)
        tone += 0.48 * math.sin(TAU * frequency * 2.72 * time + 0.18)
        tone += 0.17 * math.sin(TAU * frequency * 5.14 * time + 0.6)
        buffer[first + offset] += amplitude * envelope * tone


def add_drum(buffer, start, amplitude=0.08, duration=0.5, seed=1):
    first = max(0, int(start * RATE))
    count = min(int(duration * RATE), len(buffer) - first)
    rng = random.Random(seed)
    noise = [rng.uniform(-1.0, 1.0) for _ in range(count)]
    for offset in range(count):
        time = offset / RATE
        envelope = math.exp(-time * 12.0)
        low = math.sin(TAU * (78.0 - 28.0 * time) * time)
        tap = noise[offset] * math.exp(-time * 36.0) * 0.22
        buffer[first + offset] += amplitude * envelope * (low + tap)


def build_music():
    seconds = 32
    samples = [0.0] * (RATE * seconds)
    roots = [73.42, 82.41, 98.0, 82.41, 73.42, 110.0, 98.0, 82.41]
    melody = [
        [(0.0, 587.33), (0.75, 440.00), (1.50, 493.88), (2.50, 392.00), (3.25, 440.00)],
        [(0.25, 493.88), (1.00, 587.33), (2.00, 659.25), (3.00, 493.88)],
        [(0.0, 440.00), (1.25, 392.00), (2.0, 329.63), (3.0, 392.00)],
        [(0.5, 493.88), (1.25, 587.33), (2.5, 440.00), (3.25, 392.00)],
        [(0.0, 659.25), (0.75, 587.33), (1.75, 493.88), (2.5, 440.00), (3.5, 392.00)],
        [(0.25, 440.00), (1.25, 493.88), (2.0, 587.33), (3.0, 659.25)],
        [(0.0, 587.33), (1.0, 493.88), (2.0, 440.00), (3.25, 392.00)],
        [(0.5, 493.88), (1.5, 440.00), (2.25, 392.00), (3.0, 587.33)],
    ]

    for index, root in enumerate(roots):
        start = index * 4.0
        add_pluck(samples, start, root, 0.045, 3.9, 0.45)
        add_pluck(samples, start, root * 1.5, 0.027, 3.9, 0.35)
        add_pluck(samples, start, root * 2.0, 0.015, 3.9, 0.25)
        for beat, frequency in melody[index]:
            add_pluck(samples, start + beat, frequency, 0.105, 1.55, 0.9)
        if index % 2 == 0:
            add_bell(samples, start + 3.35, [587.33, 659.25, 783.99, 659.25][(index // 2) % 4], 0.034, 2.2)
        add_drum(samples, start + 0.05, 0.035, 0.48, index + 9)
        add_drum(samples, start + 2.05, 0.022, 0.42, index + 19)

    # Soft night air and a low, warm resonance under the plucked melody.
    for index in range(len(samples)):
        time = index / RATE
        samples[index] += 0.018 * math.sin(TAU * 55.0 * time)
        samples[index] += 0.012 * math.sin(TAU * 110.2 * time + 0.7)
        samples[index] += 0.006 * math.sin(TAU * 1760.0 * time) * (0.5 + 0.5 * math.sin(TAU * 0.13 * time))

    # Short matching fades avoid a click at the loop seam.
    fade = int(0.35 * RATE)
    for offset in range(fade):
        gain = offset / max(1, fade - 1)
        samples[offset] *= gain
        samples[len(samples) - 1 - offset] *= gain
    write_wav("kampung_misteri_bgm.wav", samples, loop=True)


def short_sound(duration, render):
    samples = [0.0] * int(RATE * duration)
    render(samples)
    return samples


def build_effects():
    ROOT.mkdir(parents=True, exist_ok=True)

    write_wav("ui_click.wav", short_sound(0.24, lambda b: (add_drum(b, 0.0, 0.10, 0.20, 31), add_bell(b, 0.025, 880.0, 0.035, 0.22))))
    write_wav("task_open.wav", short_sound(0.55, lambda b: (add_drum(b, 0.0, 0.09, 0.3, 42), add_bell(b, 0.07, 587.33, 0.07, 0.45))))
    write_wav("object_pickup.wav", short_sound(0.52, lambda b: (add_pluck(b, 0.0, 659.25, 0.10, 0.44, 1.0), add_bell(b, 0.06, 987.77, 0.055, 0.42))))
    write_wav("clue_found.wav", short_sound(1.15, lambda b: (add_bell(b, 0.0, 523.25, 0.065, 0.95), add_bell(b, 0.16, 659.25, 0.07, 0.90), add_bell(b, 0.34, 783.99, 0.075, 0.80))))
    write_wav("task_complete.wav", short_sound(1.75, lambda b: (add_drum(b, 0.0, 0.09, 0.50, 77), add_bell(b, 0.08, 587.33, 0.07, 1.5), add_bell(b, 0.28, 739.99, 0.08, 1.35), add_bell(b, 0.50, 880.0, 0.09, 1.2), add_bell(b, 0.72, 1174.66, 0.08, 0.95))))
    write_wav("drag_drop.wav", short_sound(0.38, lambda b: (add_drum(b, 0.10, 0.12, 0.27, 88), add_pluck(b, 0.0, 330.0, 0.035, 0.28, 0.25))))
    write_wav("timing_good.wav", short_sound(0.78, lambda b: (add_drum(b, 0.0, 0.11, 0.35, 91), add_bell(b, 0.06, 783.99, 0.09, 0.7))))
    write_wav("timing_miss.wav", short_sound(0.38, lambda b: (add_drum(b, 0.0, 0.10, 0.32, 101), add_pluck(b, 0.0, 164.81, 0.055, 0.34, 0.18))))


if __name__ == "__main__":
    ROOT.mkdir(parents=True, exist_ok=True)
    build_music()
    build_effects()
