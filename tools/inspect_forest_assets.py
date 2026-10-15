import bpy,json
from pathlib import Path
root=Path(r'C:\Users\jkern\Downloads')
report={}
for name in ['pine_tree_01_1k.blend','fir_sapling_medium_2k.blend','othonna_cerarioides_2k.blend']:
    bpy.ops.wm.open_mainfile(filepath=str(root/name/name),load_ui=False)
    rows=[]
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH' and (obj.dimensions.z>2 or ('othonna' in name and 'LOD3' in obj.name)):
            rows.append({'name':obj.name,'tris':sum(len(p.vertices)-2 for p in obj.data.polygons),'height':round(obj.dimensions.z,2),'materials':[s.material.name if s.material else '' for s in obj.material_slots]})
    report[name]=rows
Path(r'C:\Users\jkern\Documents\et-remastered\tools\asset_report.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report),flush=True)
