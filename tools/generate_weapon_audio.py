"""Small synthesized PS2-style shots and mechanical clicks; no external audio needed."""
import math
import random
import struct
import wave
from pathlib import Path

out = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
rng = random.Random(68)
rate = 22050
for name, duration, power in [('gun_pistol', .38, 1), ('gun_rifle', .48, 1.2),
                              ('gun_shotgun', .65, 1.5), ('gun_reload', 1.1, 0),
                              ('gun_empty', .13, 0)]:
    samples, smooth = [], 0
    for i in range(int(rate * duration)):
        t = i / rate
        noise = rng.uniform(-1, 1)
        smooth = .72 * smooth + .28 * noise
        if power:
            value = (noise * .55 + smooth * .6) * math.exp(-t * 22 / power)
            value += math.sin(math.tau * (80 * t - 17 * t * t)) * .4 * math.exp(-t * 11 / power)
            value += smooth * .18 * math.exp(-t * 6 / power)
        else:
            value = 0
            for start in ([.02, .24, .62, .9] if name == 'gun_reload' else [.005]):
                dt = t - start
                if dt >= 0:
                    value += (noise * .6 + math.sin(dt * math.tau * 1500) * .3) * math.exp(-dt * 110)
        samples.append(int(max(-1, min(1, value * .7)) * 32767))
    with wave.open(str(out / (name + '.wav')), 'wb') as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(rate)
        sound.writeframes(struct.pack('<' + 'h' * len(samples), *samples))
