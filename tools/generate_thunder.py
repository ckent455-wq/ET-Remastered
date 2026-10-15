"""A soft, low-pass distant thunder roll with a slow attack and fading tail."""
import math
import random
import struct
import wave
from pathlib import Path

rate = 22050
duration = 7.5
rng = random.Random(217)
low = [0.0, 0.0]
samples = []
for i in range(int(rate * duration)):
    t = i / rate
    attack = min(1.0, t / 1.15)
    attack = attack * attack * (3 - 2 * attack)
    release = min(1.0, (duration - t) / 2.4)
    release = release * release * (3 - 2 * release)
    roll = .65 + .20 * math.sin(t * 2.7) + .15 * math.sin(t * 5.1 + 1)
    envelope = attack * release * roll * math.exp(-t * .14)
    shared = rng.uniform(-1, 1)
    for channel in range(2):
        noise = .82 * shared + .18 * rng.uniform(-1, 1)
        low[channel] += .024 * (noise - low[channel])
        rumble = low[channel] * 5.5
        rumble += .05 * math.sin(math.tau * 43 * t + channel * .15)
        samples.append(max(-1, min(1, rumble * envelope * .75)))
path = Path(__file__).resolve().parents[1] / 'assets' / 'audio' / 'thunder.wav'
with wave.open(str(path), 'wb') as output:
    output.setnchannels(2)
    output.setsampwidth(2)
    output.setframerate(rate)
    output.writeframes(struct.pack('<' + 'h' * len(samples), *(int(x * 32767) for x in samples)))
print('Thunder:', duration, 'seconds; peak', round(max(abs(x) for x in samples), 3))
