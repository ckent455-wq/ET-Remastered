import array,wave,json,hashlib
from pathlib import Path
base=Path.home()/'Downloads/Horror SFX Free/Horror SFX Free/Monsters & Ghosts';out=Path('assets/enemies');rows=[]
for name,filename in [('breath','Monster_breath.wav'),('growl','Monster_growl_1.wav'),('attack','Monster_grunt x2 (ghmmm).wav')]:
 src=base/filename
 with wave.open(str(src),'rb') as w:
  assert w.getsampwidth()==2;channels=w.getnchannels();rate=w.getframerate();raw=array.array('h',w.readframes(w.getnframes()))
 mono=[sum(raw[i:i+channels])/channels for i in range(0,len(raw),channels)];step=rate/22050;count=int(len(mono)/step);peak=max(max(abs(v) for v in mono),1);gain=min(1,23000/peak);samples=array.array('h')
 for i in range(count):
  a=min(int(i*step),len(mono)-1);b=min(a+1,len(mono)-1);v=mono[a]+(mono[b]-mono[a])*(i*step-a);fade=min(1,i/220,(count-i-1)/220);samples.append(int(v*gain*max(0,fade)))
 with wave.open(str(out/(name+'.wav')),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(22050);w.writeframes(samples.tobytes())
 rows.append({'asset':name+'.wav','source':str(src),'sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'seconds':count/22050,'conversion':'mono PCM16, 22050Hz, bounded peak and edge fades'})
(out/'audio-sources.json').write_text(json.dumps({'pack':'User-provided Horror SFX Free','files':rows},indent=2)+'\n')
print('Prepared creature breathing, growl and attack sounds')
