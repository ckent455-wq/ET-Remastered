"""Convert copies of the local RetroModelPack, retaining its geometry and UVs."""
import bpy, hashlib, json
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path.home()/'Downloads/RetroModelPack/Models'
OUT=ROOT/'assets/retro_props'
OUT.mkdir(parents=True,exist_ok=True)
ASSETS={'bucket':('Bucket',.32,'height'),'burner':('Burner',.42,'max'),'clock':('Clock',.32,'max'),'cutting_board':('CuttingBoard',.38,'max'),'entrance_mat':('EntranceMat',.95,'max'),'knife':('Knife',.28,'max'),'locker':('MetalLockerStorage',1.8,'height'),'plate':('Plate',.26,'max'),'scythe':('Scythe',1.7,'height'),'sheet_metal':('SheetMetal',1.2,'max'),'shovel':('Shovel',1.2,'height'),'slate':('Slate',.5,'max'),'table':('Tabel',.76,'height'),'tv':('Tv',.62,'max')}
report=[]
for asset,(folder,target,axis) in ASSETS.items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    src=SOURCE/folder/(folder+'.fbx')
    bpy.ops.import_scene.fbx(filepath=str(src))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    coords=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    lo=Vector(tuple(min(v[i] for v in coords) for i in range(3)))
    hi=Vector(tuple(max(v[i] for v in coords) for i in range(3)))
    size=hi-lo
    factor=target/(size.z if axis=='height' else max(size))
    offset=Vector((-(lo.x+hi.x)/2,-(lo.y+hi.y)/2,-lo.z))
    poses={o.name:o.matrix_world.copy() for o in meshes}
    for obj in meshes:
        world=poses[obj.name]
        obj.data=obj.data.copy()
        for v in obj.data.vertices:v.co=(world@v.co+offset)*factor
        obj.parent=None
        obj.matrix_world=Matrix.Identity(4)
        for face in obj.data.polygons:face.use_smooth=False
    for mat in bpy.data.materials:
        mat.use_nodes=True
        nodes=mat.node_tree.nodes
        bs=nodes.get('Principled BSDF')
        bs.inputs['Roughness'].default_value=1
        bs.inputs['Metallic'].default_value=0
        bs.inputs['Base Color'].default_value=(1,1,1,1)
        file=src.parent/('TabelFrame.png' if folder=='Tabel' and mat.name.endswith('.001') else folder+'.png')
        image=bpy.data.images.load(str(file),check_existing=True)
        if max(image.size)>256:
            ratio=256/max(image.size)
            image.scale(max(1,int(image.size[0]*ratio)),max(1,int(image.size[1]*ratio)))
        node=nodes.new('ShaderNodeTexImage')
        node.image=image
        node.interpolation='Closest'
        mat.node_tree.links.new(node.outputs['Color'],bs.inputs['Base Color'])
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes:obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(asset+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False)
    dims=size*factor
    row={'asset':asset,'source':str(src),'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'dimensions':[round(dims.x,5),round(dims.z,5),round(dims.y,5)],'triangles':sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)}
    report.append(row)
    print('EXPORTED RETRO',row,flush=True)
(OUT/'manifest.json').write_text(json.dumps({'pack':'User-supplied RetroModelPack','adaptation':'Native static meshes and UVs, grounded metric copies, flat matte shading, textures capped at 256px. Source unchanged.','assets':report},indent=2))
