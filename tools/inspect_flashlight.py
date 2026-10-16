import bpy,json
from pathlib import Path
from mathutils import Vector
source=Path(r'C:\Users\jkern\My project (2)\Assets\Flashlight\Misc\Flashlight.FBX')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(source))
for obj in bpy.data.objects:
 if obj.type!='MESH': continue
 coords=[obj.matrix_world@v.co for v in obj.data.vertices]
 low=[min(p[i] for p in coords) for i in range(3)]
 high=[max(p[i] for p in coords) for i in range(3)]
 print('FLASHLIGHT OBJECT',obj.name,'bounds',low,high,'triangles',sum(len(f.vertices)-2 for f in obj.data.polygons),'materials',[m.name for m in obj.data.materials],flush=True)
for image in bpy.data.images: print('IMAGE',image.name,image.filepath,list(image.size),flush=True)
