"""Package a Godot Windows export with credits, licenses, and checksums."""
import argparse,hashlib,json,re,shutil,subprocess,urllib.request,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
ENGINE='4.7.2'
p=argparse.ArgumentParser()
p.add_argument('--export-dir',type=Path,default=ROOT/'builds/windows')
p.add_argument('--output-dir',type=Path,default=ROOT/'dist')
args=p.parse_args()
version=re.search(r'config/version="([^"]+)"',(ROOT/'project.godot').read_text(encoding='utf-8')).group(1)
package=args.export_dir.resolve()
assert (package/'FarFromHome.exe').exists() and (package/'FarFromHome.pck').exists(),'Export Windows first'
shutil.copy2(ROOT/'PLAYING.md',package/'README.md')
shutil.copy2(ROOT/'RELEASE_NOTES.md',package/'RELEASE_NOTES.md')
licenses=package/'LICENSES';licenses.mkdir(exist_ok=True)
shutil.copy2(ROOT/'assets/OFL.txt',licenses/'Font-OFL.txt')
shutil.copy2(ROOT/'assets/weapons/LICENSE.txt',licenses/'Guns-CC0.txt')
shutil.copy2(ROOT/'assets/supplies/SOURCES.md',licenses/'Supplies-Sources.md')
for name in ['LICENSE.txt','COPYRIGHT.txt']:
 request=urllib.request.Request('https://raw.githubusercontent.com/godotengine/godot/'+ENGINE+'-stable/'+name,headers={'User-Agent':'FarFromHome-Release'})
 with urllib.request.urlopen(request,timeout=45) as response:(licenses/('Godot-'+name)).write_bytes(response.read())
readme=(ROOT/'README.md').read_text(encoding='utf-8',errors='replace')
credits=readme.split('## Local assets',1)[-1].split('Validation:',1)[0].strip()
(package/'CREDITS.md').write_text('# Far From Home - asset credits\n\nBuilt with Godot '+ENGINE+'.\n\n'+credits+'\n\n'+(ROOT/'assets/supplies/SOURCES.md').read_text(encoding='utf-8'),encoding='utf-8')
try:commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True,stderr=subprocess.DEVNULL).strip()
except (OSError,subprocess.CalledProcessError):commit='unknown'
info={'game':'Far From Home','version':version,'platform':'Windows x86_64','engine':ENGINE,'source_commit':commit,'sha256':{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in package.iterdir() if f.suffix.lower() in ['.exe','.pck','.dll']}}
(package/'build-info.json').write_text(json.dumps(info,indent=2)+'\n',encoding='utf-8')
args.output_dir.mkdir(parents=True,exist_ok=True)
archive=args.output_dir/f'FarFromHome-v{version}-Windows-x64.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as output:
 for file in sorted(package.rglob('*')):
  if file.is_file():output.write(file,Path(f'FarFromHome-{version}')/file.relative_to(package))
with zipfile.ZipFile(archive) as check:assert check.testzip() is None
checksum=hashlib.sha256(archive.read_bytes()).hexdigest()
(args.output_dir/'SHA256SUMS.txt').write_text(checksum+'  '+archive.name+'\n',encoding='utf-8')
print('PACKAGE',archive,archive.stat().st_size)
print('SOURCE COMMIT',commit)
