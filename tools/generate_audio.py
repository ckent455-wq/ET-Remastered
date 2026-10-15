"""Generate original, deterministic forest sound effects using Python's standard library."""
from pathlib import Path
import math, random, struct, wave
OUT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
RATE = 22050
TAU = math.tau

def write(name, duration, synth, seed=14):
    rng = random.Random(seed)
    values = [synth(i / RATE, rng) for i in range(round(duration * RATE))]
    peak = max(max(abs(v) for v in values), .001)
    gain = min(1, .88 / peak)
    data = b''.join(struct.pack('<h', round(max(-1,min(1,v*gain))*32767)) for v in values)
    with wave.open(str(OUT / (name+'.wav')), 'wb') as wav:
        wav.setparams((1,2,RATE,0,'NONE','not compressed'))
        wav.writeframes(data)

def ambience(kind):
    low = mid = 0.0
    def sample(t, rng):
        nonlocal low, mid
        noise = rng.uniform(-1,1)
        low += .022*(noise-low)
        mid += .25*(noise-mid)
        # Periodic gust envelope; crossfaded at the loop boundary below.
        gust = .55+.22*math.sin(TAU*t/12)+.13*math.sin(TAU*t/4+1)
        edge = min(1,t/.4,(12-t)/.4)
        if kind=='wind':
            return low*2.1*gust*max(0,edge)
        rustle = .5+.5*math.sin(TAU*t/1.5+math.sin(TAU*t/4))
        return (noise-mid)*.20*gust*rustle*max(0,edge)
    return sample

write('wind',12,ambience('wind'))
write('leaves',12,ambience('leaves'),30)
for variant in range(5):
    low = [0.0]
    def step(t,rng,v=variant):
        noise = rng.uniform(-1,1)
        low[0] += .12*(noise-low[0])
        impact = math.sin(TAU*(78+v*5)*t)*math.exp(-t*38)*.40
        crunch = (noise*.16+low[0]*.85)*math.exp(-t*14)
        grains = sum(math.exp(-((t-c)/.013)**2) for c in (.035,.08+v*.006,.14))
        return (impact+crunch+noise*grains*.09)*min(1,t/.004)*min(1,(.40-t)/.02)
    write(f'step_{variant}',.40,step,90+variant)

def drone(t,rng):
    envelope = .72+.16*math.sin(TAU*t/2)+.09*math.sin(TAU*t/3)
    return (math.sin(TAU*55*t)*.22+math.sin(TAU*56*t)*.15+math.sin(TAU*82*t)*.10+math.sin(TAU*110*t)*.05)*envelope
write('drone',6,drone)

def owl(t,rng):
    signal=0
    for start,length,pitch in ((.12,.28,410),(.65,.65,365),(1.65,.28,400),(2.15,.70,350)):
        u=t-start
        if 0<u<length:
            env=math.sin(math.pi*u/length)**1.4
            phase=TAU*(pitch*u-14*u*u+1.4*math.sin(TAU*u*3))
            signal += env*(math.sin(phase)*.37+math.sin(2*phase)*.05+rng.uniform(-.015,.015))
    return signal
write('owl',3.2,owl)

def bird(t,rng):
    result=0
    for start in (.1,.35,.62,1.3,1.56):
        u=t-start
        if 0<u<.19:
            phase=TAU*(1700*u+1600*u*u+5*math.sin(TAU*u*19))
            result+=math.sin(math.pi*u/.19)**2*(math.sin(phase)*.21+math.sin(phase*2)*.025)
    return result
write('night_bird',2.2,bird)

def chirr(t,rng):
    env=math.sin(math.pi*t/1.8)**2
    pulses=max(0,math.sin(TAU*22*t))**3
    return math.sin(TAU*3300*t)*pulses*env*.18
write('insects',1.8,chirr)
with wave.open(str(OUT/'flashlight.wav'),'rb') as src:
    print('Local flashlight:',src.getnchannels(),'channels,',src.getframerate(),'Hz,',round(src.getnframes()/src.getframerate(),2),'seconds')
for path in sorted(OUT.glob('*.wav')):
    with wave.open(str(path),'rb') as wav:
        print(path.name,round(wav.getnframes()/wav.getframerate(),2),'seconds')
