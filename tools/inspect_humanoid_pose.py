import bpy
from pathlib import Path
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath=r'C:\Users\jkern\Downloads\Base Humanoid Mesh\Base Humanoid Mesh\Humanoid.blend',load_ui=False)
if bpy.context.mode!='OBJECT': bpy.ops.object.mode_set(mode='OBJECT')
o=bpy.data.objects['HumanoidBase_NotOverlapping']
coords=[o.matrix_world@v.co for v in o.data.vertices]
low=Vector(tuple(min(v[i] for v in coords) for i in range(3)))
high=Vector(tuple(max(v[i] for v in coords) for i in range(3)))
center=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
for v in coords:
    p=(v-center)*1.78/(high.z-low.z)
    if p.x>.22:
        print('ARM',tuple(round(a,3) for a in p))
