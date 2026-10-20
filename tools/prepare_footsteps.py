"""Copy the supplied PSX footstep recordings without changing the originals."""
from pathlib import Path
import hashlib,json,shutil
root=Path(__file__).resolve().parents[1]
source=Path.home()/'Downloads/40 Free PSX Footsteps/40 Free PSX Footsteps'
target=root/'assets/audio/footsteps';target.mkdir(parents=True,exist_ok=True)
records=[]
for folder in sorted(source.iterdir()):
 if not folder.is_dir():continue
 for index,path in enumerate(sorted(folder.glob('*.ogg'))):
  name=f'{folder.name.lower()}_{index}.ogg';shutil.copy2(path,target/name)
  records.append({'file':name,'source':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
assert len(records)==40
(target/'sources.json').write_text(json.dumps(records,indent=2)+'\n')
(target/'CREDITS.txt').write_text("User-supplied 40 Free PSX Footsteps download. All 40 original OGG recordings retained unchanged. Source filenames and hashes are recorded in sources.json.\n")
print('Prepared',len(records),'original surface footstep clips')
