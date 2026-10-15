import bpy,json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
out=root/'assets'/'town'
out.mkdir(parents=True,exist_ok=True)
sources={
'brick':('brick_4_8k.blend','brick_4_diff_8k.jpg'),
'wood':('wood_peeling_paint_weathered_8k.blend','wood_peeling_paint_weathered_diff_8k.jpg'),
'plaster':('plastered_wall_1k.blend','plastered_wall_diff_1k.jpg'),
'floor':('wood_floor_8k.blend','wood_floor_diff_8k.jpg'),
'roof':('roof_slates_03_1k.blend','roof_slates_03_diff_1k.jpg'),
'metal':('rusty_metal_sheet_1k.blend','rusty_metal_sheet_diff_1k.jpg')}
manifest={}
for name,(folder,file) in sources.items():
    source=Path(r'C:\Users\jkern\Downloads')/folder/'textures'/file
    image=bpy.data.images.load(str(source))
    image.scale(256,256)
    image.filepath_raw=str(out/(name+'.png'))
    image.file_format='PNG'
    image.save()
    manifest[name]=str(source)
(out/'sources.json').write_text(json.dumps(manifest,indent=2))
print('Prepared six local town textures at 256px',flush=True)
