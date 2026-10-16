"""Run with Blender's Python/audio decoder; keep the supplied M4A files unchanged."""
import aud,hashlib,json,wave
import numpy as np
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/audio/player';OUT.mkdir(parents=True,exist_ok=True)
files=['Voice 261016_153259.m4a','Voice 261016_153315.m4a','Voice 261016_153330.m4a'];rows=[]
for index,name in enumerate(files):
 src=Path.home()/'Downloads'/name;sound=aud.Sound(str(src));rate=float(sound.specs[0]);data=sound.data().mean(axis=1)
 # Trim only quiet lead/tail, retaining the natural intake and end of the grunt.
 window=max(1,int(rate*.015));energy=np.convolve(data.astype(np.float64)**2,np.ones(window)/window,mode='same');active=np.flatnonzero(energy>0.012**2)
 start=max(0,int(active[0])-int(rate*.06)) if len(active) else 0;end=min(len(data),int(active[-1])+int(rate*.12)+1) if len(active) else len(data)
 data=data[start:end];data=np.interp(np.arange(int(len(data)*22050/rate))*rate/22050,np.arange(len(data)),data)
 gain=.78/max(float(np.abs(data).max()),.001);data*=gain;fade=min(int(.008*22050),len(data)//2);data[:fade]*=np.linspace(0,1,fade);data[-fade:]*=np.linspace(1,0,fade);pcm=(np.clip(data,-1,1)*32767).astype('<i2')
 dst=OUT/('hurt_%d.wav'%index)
 with wave.open(str(dst),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(22050);w.writeframes(pcm.tobytes())
 rows.append({'asset':dst.name,'source':str(src),'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'seconds':len(data)/22050,'peak':round(float(np.abs(data).max()),4),'trim_seconds':[round(start/rate,3),round(end/rate,3)]})
 print('PREPARED',dst.name,'seconds',round(len(data)/22050,3),'peak',round(float(np.abs(data).max()),3),flush=True)
(OUT/'sources.json').write_text(json.dumps({'source':'Three user-supplied player hurt voice recordings','conversion':'Mono PCM16, 22050Hz, restrained peak normalization, quiet-edge trimming and 8ms edge fades. Original M4A files unchanged.','files':rows},indent=2))
