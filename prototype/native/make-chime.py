"""Generate a short original two-note preview chime using only the standard library."""
import math
import struct
import sys
import wave

rate = 44100
duration = 0.62
samples = []
for i in range(int(rate * duration)):
    t = i / rate
    value = 0.0
    for onset, frequency, amplitude in [(0, 783.99, 0.28), (0.12, 1046.50, 0.21)]:
        age = t - onset
        if age >= 0:
            attack = min(1, age / 0.012)
            release = max(0, min(1, (duration - t) / 0.09))
            envelope = attack * math.exp(-age * 9) * release
            value += amplitude * envelope * (math.sin(2 * math.pi * frequency * age) + 0.12 * math.sin(4 * math.pi * frequency * age))
    samples.append(struct.pack('<h', int(max(-1, min(1, value)) * 32767)))
with wave.open(sys.argv[1], 'wb') as output:
    output.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
    output.writeframes(b''.join(samples))
