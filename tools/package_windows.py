"""Package the Windows export with player instructions, credits and checksums."""
import hashlib
import json
import re
import shutil
import subprocess
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
version = re.search(r'config/version="([^"]+)"', (ROOT/'project.godot').read_text(encoding='utf-8')).group(1)
export = ROOT/'builds'/'windows'
package = ROOT/'builds'/f'FarFromHome-{version}'
package.mkdir(parents=True, exist_ok=True)
for source in export.iterdir():
    if source.is_file() and source.suffix.lower() in ['.exe', '.pck', '.dll']:
        shutil.copy2(source, package/source.name)
assert (package/'FarFromHome.exe').exists() and (package/'FarFromHome.pck').exists(), 'Export Windows first'
shutil.copy2(ROOT/'PLAYING.md', package/'README.md')
licenses = package/'LICENSES'
licenses.mkdir(exist_ok=True)
shutil.copy2(ROOT/'assets'/'OFL.txt', licenses/'Font-OFL.txt')
shutil.copy2(ROOT/'assets'/'high_voltage'/'LICENSE.txt', licenses/'PSX-Horror-Props-CC-BY-4.0.txt')
shutil.copy2(ROOT/'assets'/'weapons'/'LICENSE.txt', licenses/'Guns-CC0.txt')
for name in ['LICENSE.txt', 'COPYRIGHT.txt']:
    request = urllib.request.Request('https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/'+name, headers={'User-Agent':'FarFromHome-Release'})
    with urllib.request.urlopen(request, timeout=45) as response:
        (licenses/('Godot-'+name)).write_bytes(response.read())
credits = (ROOT/'README.md').read_text(encoding='utf-8').split('## Local assets', 1)[1].split('Validation:', 1)[0].strip()
(package/'CREDITS.md').write_text('# Far From Home - asset credits\n\nBuilt with Godot Engine 4.7.2. Engine, font and weapon licenses are in LICENSES.\n\n'+credits+'\n', encoding='utf-8')
commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
info = {'game':'Far From Home', 'version':version, 'platform':'Windows x86_64', 'engine':'Godot 4.7.2', 'source_commit':commit,
        'sha256':{name:hashlib.sha256((package/name).read_bytes()).hexdigest() for name in ['FarFromHome.exe','FarFromHome.pck']}}
(package/'build-info.json').write_text(json.dumps(info, indent=2)+'\n', encoding='utf-8')
dist = ROOT/'dist'
dist.mkdir(exist_ok=True)
archive = dist/f'FarFromHome-v{version}-Windows-x64.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as output:
    for path in sorted(package.rglob('*')):
        if path.is_file(): output.write(path, path.relative_to(package.parent).as_posix())
with zipfile.ZipFile(archive) as check:
    assert check.testzip() is None, 'Archive checksum failure'
checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
(dist/'SHA256SUMS.txt').write_text(checksum+'  '+archive.name+'\n')
print('PACKAGE', archive.name, archive.stat().st_size, 'bytes')
print('SOURCE COMMIT', commit)
print('SHA256', checksum)
