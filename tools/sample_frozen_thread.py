"""Read-only native stack sample of the unresponsive game; resumes its thread in finally."""
import ctypes as c,struct,sys
from ctypes import wintypes as w
k=c.WinDLL('kernel32',use_last_error=True)
p=c.WinDLL('psapi',use_last_error=True)
d=c.WinDLL('dbghelp',use_last_error=True)
k.OpenProcess.argtypes=[w.DWORD,w.BOOL,w.DWORD]; k.OpenProcess.restype=w.HANDLE
k.OpenThread.argtypes=[w.DWORD,w.BOOL,w.DWORD]; k.OpenThread.restype=w.HANDLE
k.SuspendThread.argtypes=[w.HANDLE];k.ResumeThread.argtypes=[w.HANDLE]
k.GetThreadContext.argtypes=[w.HANDLE,c.c_void_p]
k.ReadProcessMemory.argtypes=[w.HANDLE,c.c_void_p,c.c_void_p,c.c_size_t,c.c_void_p]
k.CloseHandle.argtypes=[w.HANDLE]
p.EnumProcessModulesEx.argtypes=[w.HANDLE,c.c_void_p,w.DWORD,c.c_void_p,w.DWORD]
p.GetModuleFileNameExW.argtypes=[w.HANDLE,w.HMODULE,w.LPWSTR,w.DWORD]
class ModuleInfo(c.Structure):
    _fields_=[('base',c.c_void_p),('size',w.DWORD),('entry',c.c_void_p)]
p.GetModuleInformation.argtypes=[w.HANDLE,w.HMODULE,c.c_void_p,w.DWORD]
if len(sys.argv)!=3:
    raise SystemExit('Usage: python tools/sample_frozen_thread.py PROCESS_ID THREAD_ID')
process=k.OpenProcess(0x410,False,int(sys.argv[1]))
thread=k.OpenThread(0x0002|0x0008|0x0040,False,int(sys.argv[2]))
assert process and thread, c.get_last_error()
modules=(w.HMODULE*1024)();needed=w.DWORD()
p.EnumProcessModulesEx(process,modules,c.sizeof(modules),c.byref(needed),3)
ranges=[]
for mod in modules[:needed.value//c.sizeof(w.HMODULE)]:
    info=ModuleInfo(); name=c.create_unicode_buffer(1024)
    p.GetModuleInformation(process,mod,c.byref(info),c.sizeof(info))
    p.GetModuleFileNameExW(process,mod,name,1024)
    ranges.append((info.base,info.base+info.size,name.value))
def identify(address):
    for low,high,path in ranges:
        if low<=address<high:
            return path.rsplit('\\',1)[-1]+'+0x%x'%(address-low)
    return hex(address)
d.SymInitializeW.argtypes=[w.HANDLE,w.LPCWSTR,w.BOOL]
d.SymInitializeW(process,None,True)
d.SymFunctionTableAccess64.argtypes=[w.HANDLE,c.c_ulonglong];d.SymFunctionTableAccess64.restype=c.c_void_p
d.SymGetModuleBase64.argtypes=[w.HANDLE,c.c_ulonglong];d.SymGetModuleBase64.restype=c.c_ulonglong
d.StackWalk64.argtypes=[w.DWORD,w.HANDLE,w.HANDLE,c.c_void_p,c.c_void_p,c.c_void_p,c.c_void_p,c.c_void_p,c.c_void_p]
context=c.create_string_buffer(1248)
aligned=(c.addressof(context)+15)&~15
c.memset(aligned,0,1232)
c.c_uint32.from_address(aligned+48).value=0x100003
k.SuspendThread(thread)
try:
    assert k.GetThreadContext(thread,aligned),c.get_last_error()
    rip=c.c_uint64.from_address(aligned+248).value
    rsp=c.c_uint64.from_address(aligned+152).value
    rbp=c.c_uint64.from_address(aligned+160).value
    print('CURRENT INSTRUCTION',identify(rip),flush=True)
    frame=c.create_string_buffer(1024)
    for offset,address in [(0,rip),(32,rbp),(48,rsp)]:
        struct.pack_into('<Q',frame,offset,address)
        struct.pack_into('<I',frame,offset+12,3)
    for i in range(24):
        success=d.StackWalk64(0x8664,process,thread,frame,aligned,None,c.cast(d.SymFunctionTableAccess64,c.c_void_p),c.cast(d.SymGetModuleBase64,c.c_void_p),None)
        if not success: break
        pc=struct.unpack_from('<Q',frame,0)[0]
        if not pc: break
        print(i,identify(pc),flush=True)
finally:
    k.ResumeThread(thread)
    k.CloseHandle(thread)
    k.CloseHandle(process)
