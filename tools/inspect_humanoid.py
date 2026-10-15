import bpy,json
from pathlib import Path
source=Path(r'C:\Users\jkern\Downloads\Base Humanoid Mesh\Base Humanoid Mesh\Humanoid.blend')
bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False)
for obj in bpy.context.scene.objects:
    if obj.type in ['MESH','ARMATURE']:
        print(json.dumps({'name':obj.name,'type':obj.type,'verts':len(obj.data.vertices) if obj.type=='MESH' else 0,'tris':sum(len(p.vertices)-2 for p in obj.data.polygons) if obj.type=='MESH' else 0,'dim':list(obj.dimensions),'modifiers':[(m.type,m.name) for m in obj.modifiers],'materials':[s.material.name if s.material else '' for s in obj.material_slots] if obj.type=='MESH' else [],'bones':[b.name for b in obj.data.bones] if obj.type=='ARMATURE' else []}),flush=True)
print('ACTIONS',[a.name for a in bpy.data.actions],flush=True)
