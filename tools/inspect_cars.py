import bpy
import json
from pathlib import Path
bpy.ops.wm.open_mainfile(filepath=r'C:\Users\jkern\Downloads\Blend\Blend\FreeCarPack.blend', load_ui=False)
report = []
for obj in bpy.data.objects:
    if obj.type == 'MESH':
        report.append({'name': obj.name, 'parent': obj.parent.name if obj.parent else '', 'location': list(obj.location), 'dimensions': list(obj.dimensions), 'polygons': len(obj.data.polygons), 'materials': [m.name for m in obj.data.materials if m], 'collections': [c.name for c in obj.users_collection]})
path = Path(__file__).resolve().parent / 'car_asset_report.json'
path.write_text(json.dumps(report, indent=2))
print(json.dumps(report), flush=True)
