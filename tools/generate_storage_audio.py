import math,random,struct,wave
from pathlib import Path
rng=random.Random(42)
samples=[]
low=0.0
for i in range(13230):
    t=i/22050
    noise=rng.uniform(-1,1)
    low+=.065*(noise-low)
    env=math.sin(math.pi*t/.6)**.7
    slide=low*.7*env+math.sin(math.tau*(125*t+16*t*t))*.035*env
    clunk=math.sin(math.tau*94*t)*math.exp(-t*60)*.26+math.sin(math.tau*83*(t-.48))*math.exp(-max(0,t-.48)*55)*.22*(t>.48)
    samples.append(struct.pack('<h',int(max(-1,min(1,slide+clunk))*32767)))
with wave.open(str(Path('assets/audio/drawer.wav')),'wb') as w:
    w.setparams((1,2,22050,0,'NONE','not compressed'))
    w.writeframes(b''.join(samples))
