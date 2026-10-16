import json,tarfile
from pathlib import Path
index=json.loads(Path('tools/apartment_package_index.json').read_text());out=Path('builds/asset-source/apartment-kit').resolve();count=0
out.mkdir(parents=True,exist_ok=True);(out/".gdignore").touch()
with tarfile.open(index['source'],'r:gz') as t:
 members={m.name:m for m in t.getmembers()}
 for row in index['assets']:
  name=row['path'];asset=members.get(row['entry']+'/asset')
  if not asset or Path(name).suffix.lower() not in ['.fbx','.png','.jpg','.tga','.mat','.prefab']:continue
  dest=(out/name).resolve()
  assert dest.is_relative_to(out)
  dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(t.extractfile(asset).read());count+=1
print('Extracted',count,'asset files to',out)
