"""Original synthesized failed ignition cue; no third-party recording used."""
import array, math, random, wave
from pathlib import Path
rate=22050;duration=1.70;rng=random.Random(1983);samples=array.array('h')
for i in range(int(rate*duration)):
 t=i/rate
 speed=1.0-0.45*max(0,(t-1.28)/.42)
 crank=(math.sin(2*math.pi*8.5*t*speed)*.5+.5)**3
 motor=.37*math.sin(2*math.pi*89*t*speed)+.16*math.sin(2*math.pi*181*t*speed)+.09*math.sin(2*math.pi*357*t*speed)
 noise=rng.uniform(-1,1)*.17
 envelope=min(1,t/.02)*min(1,(duration-t)/.09)
 click=.36*math.exp(-t*150)*rng.uniform(-1,1)
 value=((motor+noise)*(.32+.68*crank)*envelope+click)*.8
 samples.append(int(max(-1,min(1,value))*32767))
path=Path(__file__).resolve().parents[1]/'assets/audio/engine_starter.wav'
with wave.open(str(path),'wb') as out:out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate);out.writeframes(samples.tobytes())
print('Generated',path.name)
