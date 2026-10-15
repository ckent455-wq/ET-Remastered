"""Generate short original interaction cues; run after generate_audio.py if rebuilding."""
from pathlib import Path
import math, struct, wave
out=Path(__file__).resolve().parents[1]/'assets'/'audio'
rate=22050
for name,duration,notes in [('pickup',.35,[660,990]),('power',.65,[110,165,220]),('radio',1.2,[440,554,660,880])]:
    samples=[]
    segment=duration/len(notes)
    for i in range(int(rate*duration)):
        t=i/rate
        note=min(len(notes)-1,int(t/segment))
        u=t-note*segment
        env=min(1,u/.008)*math.exp(-u*12)*min(1,(duration-t)/.02)
        value=(math.sin(math.tau*notes[note]*u)+.15*math.sin(math.tau*notes[note]*2*u))*.25*env
        samples.append(struct.pack('<h',round(value*32767)))
    with wave.open(str(out/(name+'.wav')),'wb') as w:
        w.setparams((1,2,rate,0,'NONE','not compressed'))
        w.writeframes(b''.join(samples))
print('Generated pickup, power, and calibration cues')
