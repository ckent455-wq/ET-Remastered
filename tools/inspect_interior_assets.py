import bpy,json
from pathlib import Path
root=Path(r'C:\Users\jkern')
models=root/'Documents'/'assets'/'models'
sources={}
for name,pattern in [('shelf','wall-book-shelf*'),('lamp','floor-lamp*'),('books','books_*'),('curtain','ribbon-curtain-c*'),('door','wooden-door*')]:
    sources[name]=next(next(models.glob(pattern)).glob('*.blend'))
for name,folder in [('box','cardboard_box_01_2k.blend'),('teapot','TeapotSilver001'),('sink','Sink003')]:
    sources[name]=next((root/'Downloads'/folder).glob('*.blend'))
report={}
for name,path in sources.items():
    bpy.ops.wm.open_mainfile(filepath=str(path),load_ui=False)
    objects=[]
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH':
            objects.append({'name':obj.name,'verts':len(obj.data.vertices),'tris':sum(len(p.vertices)-2 for p in obj.data.polygons),'dimensions':[round(v,3) for v in obj.dimensions],'location':[round(v,3) for v in obj.location],'materials':[slot.material.name if slot.material else '' for slot in obj.material_slots]})
    images=[{'name':im.name,'path':im.filepath,'size':list(im.size),'packed':bool(im.packed_file)} for im in bpy.data.images if im.source=='FILE']
    report[name]={'source':str(path),'objects':objects,'images':images}
    print('INSPECTED',name, len(objects),'meshes',sum(o['tris'] for o in objects),'tris',flush=True)
Path(r'C:\Users\jkern\Documents\et-remastered\tools\interior_asset_report.json').write_text(json.dumps(report,indent=2))
