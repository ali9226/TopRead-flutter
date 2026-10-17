#!/usr/bin/env python3
"""Rebuild Tile Quest's original, deterministic PCM sound effects.

Only synthesized oscillators and seeded, filtered noise are used. There are no
recordings, downloaded samples, or borrowed melodies. Run from any directory:
python3 tool/tile_quest/generate_audio.py
"""

import math
import random
import struct
import wave
from pathlib import Path

sample_rate = 22050
output_directory = Path(__file__).resolve().parents[2] / 'assets/audio/tile_quest'
tau = math.tau


def empty(seconds):
    return [0.0] * round(seconds * sample_rate)


def note(buffer, start, length, frequency, gain, *, decay=5.0, wood=False):
    """Damped partials with a short cosine attack make a soft mallet voice."""
    first = round(start * sample_rate)
    count = round(length * sample_rate)
    for index in range(count):
        at = first + index
        if at >= len(buffer):
            break
        t = index / sample_rate
        attack = min(1.0, t / .003)
        release = min(1.0, (count - index - 1) / (sample_rate * .014))
        envelope = math.sin(attack * math.pi / 2) ** 2
        envelope *= math.exp(-decay * t / length) * max(0.0, release)
        fundamental = math.sin(tau * frequency * t)
        if wood:
            voice = .72 * fundamental + .21 * math.sin(tau * frequency * 2.71 * t)
            voice += .07 * math.sin(tau * frequency * 5.33 * t)
        else:
            voice = .87 * fundamental + .10 * math.sin(tau * frequency * 2 * t)
            voice += .03 * math.sin(tau * frequency * 3 * t)
        buffer[at] += gain * envelope * voice


def breeze(buffer, start, length, gain, seed, *, flutter=0.0):
    """Band-limited breath with smooth ends; flutter suggests rotating cards."""
    rng = random.Random(seed)
    first = round(start * sample_rate)
    count = round(length * sample_rate)
    slow = 0.0
    fast = 0.0
    for index in range(count):
        at = first + index
        if at >= len(buffer):
            break
        t = index / sample_rate
        sample = rng.uniform(-1, 1)
        slow += .025 * (sample - slow)
        fast += .22 * (sample - fast)
        envelope = math.sin(math.pi * index / max(1, count - 1)) ** 2
        envelope *= 1 - flutter + flutter * (.5 + .5 * math.sin(tau * 7 * t))
        buffer[at] += (fast - slow) * gain * envelope


def bubble(buffer):
    count = round(.095 * sample_rate)
    phase = 0.0
    for index in range(count):
        t = index / sample_rate
        frequency = 310 + 1050 * (t / .095) ** 1.6
        phase += tau * frequency / sample_rate
        envelope = math.sin(math.pi * index / (count - 1)) ** 2
        buffer[index] += .32 * math.sin(phase) * envelope * math.exp(-18 * t)


def sounds():
    tap = empty(.11)
    note(tap, 0, .105, 490, .46, decay=7, wood=True)
    breeze(tap, .001, .025, .11, 17)

    match = empty(.56)
    bubble(match)
    for start, hz, gain in [(.065, 784, .25), (.165, 988, .28), (.27, 1175, .32)]:
        note(match, start, .28, hz, gain, decay=4)

    tool = empty(.26)
    breeze(tool, 0, .22, .28, 23)
    note(tool, .025, .10, 610, .29, decay=6, wood=True)
    note(tool, .105, .15, 815, .24, decay=5)

    entry = empty(1.04)
    breeze(entry, 0, .86, .34, 29, flutter=.14)
    for start, hz, gain in [(.12, 330, .10), (.31, 370, .11), (.49, 440, .12), (.65, 490, .12)]:
        note(entry, start, .12, hz, gain, decay=7, wood=True)
    note(entry, .73, .30, 1047, .23, decay=4)
    note(entry, .77, .25, 1568, .09, decay=5)

    # 聚拢、加速多圈搅动、减速归位，与 2100ms 动画同长；不循环短采样。
    shuffle = empty(2.10)
    breeze(shuffle, 0, 1.92, .34, 37, flutter=.42)
    for index, start in enumerate([.10, .31, .56, .76, .94, 1.11, 1.29, 1.48, 1.69]):
        note(shuffle, start, .10, 410 + (index % 5) * 47, .085, decay=6, wood=True)
        breeze(shuffle, start, .13, .21, 41 + index)
    note(shuffle, 1.82, .28, 1175, .21, decay=4)
    note(shuffle, 1.86, .24, 1568, .08, decay=5)

    won = empty(.84)
    for start, hz, gain in [(0, 659, .27), (.115, 784, .27), (.23, 988, .28), (.385, 1319, .31)]:
        note(won, start, .44, hz, gain, decay=3.5)

    lost = empty(.68)
    for start, hz, gain in [(0, 587, .23), (.15, 494, .21), (.30, 392, .18)]:
        note(lost, start, .37, hz, gain, decay=4.5)

    return {'tap': tap, 'match': match, 'tool': tool, 'entry': entry,
            'shuffle': shuffle, 'won': won, 'lost': lost}


def write_pcm(name, values):
    # Remove DC, reserve mixing headroom, and taper both ends to digital silence.
    dc = sum(values) / len(values)
    values = [value - dc for value in values]
    peak = max(abs(value) for value in values)
    gain = min(1.0, .56 / peak)
    fade = round(.006 * sample_rate)
    pcm = bytearray()
    for index, value in enumerate(values):
        edge = min(1.0, index / fade, (len(values) - 1 - index) / fade)
        value *= gain * math.sin(edge * math.pi / 2) ** 2
        pcm.extend(struct.pack('<h', round(value * 32767)))
    with wave.open(str(output_directory / f'{name}.wav'), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(sample_rate)
        output.writeframes(pcm)


if __name__ == '__main__':
    output_directory.mkdir(parents=True, exist_ok=True)
    for name, values in sounds().items():
        write_pcm(name, values)
    print(f'Generated {len(sounds())} original WAVs in {output_directory}')
