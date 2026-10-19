"""Exercise the shipped Windows updater against disposable portable installations."""
import ctypes, hashlib, json, subprocess, tempfile, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
HELPER=ROOT/'windows_update.ps1'
VERSION='9.8.7'
def digest(data):return hashlib.sha256(data).hexdigest()
def fixture(extra=None,bad_inner=False):
 base=Path(tempfile.mkdtemp(prefix="ffh updater's test \u00e9 "));target=base/'installed game';target.mkdir()
 (target/'FarFromHome.exe').write_bytes(b'old exe');(target/'FarFromHome.pck').write_bytes(b'old pck');(target/'README.md').write_bytes(b'old readme');(target/'my-save.txt').write_bytes(b'keep me')
 files={'FarFromHome.exe':b'new exe','FarFromHome.pck':b'new pck','README.md':b'new readme','LICENSES/Test.txt':b'license'}
 files['build-info.json']=json.dumps({'game':'Far From Home','version':VERSION,'platform':'Windows x86_64','sha256':{name:('0'*64 if bad_inner else digest(files[name])) for name in ['FarFromHome.exe','FarFromHome.pck']}}).encode()
 archive=base/'release.zip'
 with zipfile.ZipFile(archive,'w') as z:
  for name,data in files.items():z.writestr('FarFromHome-'+VERSION+'/'+name,data)
  if extra:z.writestr(*extra)
 plan={'archive':str(archive),'target':str(target),'version':VERSION,'sha256':digest(archive.read_bytes()),'size':archive.stat().st_size,'pid':2147483647}
 path=base/'plan.json';path.write_text(json.dumps(plan,ensure_ascii=False),encoding='utf-8');return base,target,path,plan

def run(path,*flags):
 result=subprocess.run(['powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',str(HELPER),'-Plan',str(path),'-NoLaunch',*flags],capture_output=True,text=True,timeout=35)
 assert (path.parent/'result.json').exists(),(result.stdout,result.stderr)
 report=json.loads((path.parent/'result.json').read_text(encoding='utf-8-sig'))
 return result,report

def unchanged(target):
 assert (target/'FarFromHome.exe').read_bytes()==b'old exe'
 assert (target/'FarFromHome.pck').read_bytes()==b'old pck'
 assert (target/'README.md').read_bytes()==b'old readme'
 assert (target/'my-save.txt').read_bytes()==b'keep me'

base,target,path,plan=fixture();r,report=run(path,'-ValidateOnly');assert r.returncode==0 and report['ok'],(r.stdout,r.stderr,report);unchanged(target)
r,report=run(path);assert r.returncode==0 and report['ok'],(r.stdout,r.stderr,report)
assert (target/'FarFromHome.exe').read_bytes()==b'new exe' and (target/'FarFromHome.pck').read_bytes()==b'new pck'
backup=next(target.glob('.ffh-update-backup-*'));assert (backup/'FarFromHome.exe').read_bytes()==b'old exe'
assert (target/'my-save.txt').read_bytes()==b'keep me'
print('PASS: validate-only, actual install, backup, unrelated files and spaced/apostrophe paths',flush=True)
for extra,bad_inner in [(('FarFromHome-'+VERSION+'/../escape.txt',b'escape'),False),(('FarFromHome-'+VERSION+'/FarFromHome.exe',b'duplicate'),False),(None,True)]:
 base,target,path,plan=fixture(extra,bad_inner);r,report=run(path);assert r.returncode!=0 and not report['ok'],(r.stdout,r.stderr,report);unchanged(target);assert not (base/'escape.txt').exists()
base,target,path,plan=fixture();plan['sha256']='0'*64;path.write_text(json.dumps(plan,ensure_ascii=False),encoding='utf-8');r,report=run(path);assert r.returncode!=0 and not report['ok'];unchanged(target)
print('PASS: traversal, duplicate entries, inner-file corruption and corrupt download rejected before installation',flush=True)
# Allow reading for the backup, but hold README against writes to force rollback
# after the EXE and PCK replacements have already happened.
base,target,path,plan=fixture()
create=ctypes.windll.kernel32.CreateFileW;create.argtypes=[ctypes.c_wchar_p,ctypes.c_uint32,ctypes.c_uint32,ctypes.c_void_p,ctypes.c_uint32,ctypes.c_uint32,ctypes.c_void_p];create.restype=ctypes.c_void_p
handle=create(str(target/'README.md'),0x80000000,1,None,3,0x80,None);assert handle not in [None,ctypes.c_void_p(-1).value]
try:r,report=run(path)
finally:ctypes.windll.kernel32.CloseHandle(ctypes.c_void_p(handle))
assert r.returncode!=0 and not report['ok'],(r.stdout,r.stderr,report);unchanged(target)
print('PASS: real mid-copy file-lock failure rolls back the replaced EXE and PCK',flush=True)
