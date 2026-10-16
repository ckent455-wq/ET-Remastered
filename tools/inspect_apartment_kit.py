import bpy,json
from pathlib import Path
bpy.ops.wm.read_factory_settings(use_empty=True)
root=Path(r'C:/Users/jkern/Documents/et-remastered/builds/asset-source/apartment-kit/Assets/Brick Project Studio')
report={}
for name in ['Apt_Furniture_01.fbx','Apt_Furniture_02.fbx','Apt_Props_01.fbx','Apt_Props_02.fbx','Kitchen_01.fbx','Bathroom_Apt_01.fbx','BPS_Chair_01.fbx','BPS_Table.fbx','office chair.fbx']:
 source=next(root.rglob(name))
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.fbx(filepath=str(source),use_image_search=False)
 rows=[]
 for o in bpy.context.scene.objects:
  if o.type=='MESH':
   rows.append({'name':o.name,'dimensions':list(o.dimensions),'triangles':sum(len(p.vertices)-2 for p in o.data.polygons),'materials':[m.name if m else '' for m in o.data.materials]})
 report[name]={'source':str(source),'objects':rows}
 print(name,rows,flush=True)
Path(r'C:/Users/jkern/Documents/et-remastered/tools/apartment_mesh_report.json').write_text(json.dumps(report,indent=2))
