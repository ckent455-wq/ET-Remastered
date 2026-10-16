import array,wave,json,hashlib
from pathlib import Path
source=Path(r'C:/Users/jkern/My project (2)/Assets/living birds')
out=Path('assets/crow')
report={'source_root':str(source),'model':'models/crow.FBX','texture_limit':256,'animations':['watch','call','ruffle'],'sounds':[]}
for i in [1,2]:
 src=source/'sounds'/f'crow{i}.wav'
 with wave.open(str(src),'rb') as w:
  channels,rate,width=w.getnchannels(),w.getframerate(),w.getsampwidth()
  assert width==2
  data=array.array('h',w.readframes(w.getnframes()))
 mono=[sum(data[j:j+channels])/channels for j in range(0,len(data),channels)]
 step=rate/22050
 samples=array.array('h')
 for n in range(int(len(mono)/step)):
  pos=n*step;a=int(pos);b=min(a+1,len(mono)-1);v=mono[a]+(mono[b]-mono[a])*(pos-a)
  samples.append(int(max(-32768,min(32767,v))))
 with wave.open(str(out/f'crow_{i}.wav'),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(22050);w.writeframes(samples.tobytes())
 report['sounds'].append({'source':str(src),'sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'duration':len(samples)/22050})
print(report)
(out/'source.json').write_text(json.dumps(report,indent=2)+'\n')
