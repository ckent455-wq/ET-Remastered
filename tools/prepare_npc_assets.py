"""Build three PS2-style NPC variants from the newly downloaded 402-triangle humanoid."""
import bpy,json,math
import numpy as np
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[1]
folder=Path(r'C:\Users\jkern\Downloads\Base Humanoid Mesh\Base Humanoid Mesh')
OUT=ROOT/'assets'/'npcs'
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(folder/'Humanoid.blend'),load_ui=False)
if bpy.context.mode!='OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')
source=bpy.data.objects['HumanoidBase_NotOverlapping']
coords=[source.matrix_world@v.co for v in source.data.vertices]
low=Vector(tuple(min(v[i] for v in coords) for i in range(3)))
high=Vector(tuple(max(v[i] for v in coords) for i in range(3)))
center=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
scale=1.78/(high.z-low.z)
variants=[('ranger',(.26,.34,.25),(.17,.21,.25)),('nurse',(.52,.61,.57),(.25,.31,.32)),('mechanic',(.44,.31,.22),(.20,.22,.22))]
report=[]
for name,jacket,trousers in variants:
    bpy.ops.object.select_all(action='DESELECT')
    mesh=source.data.copy()
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    for v,co in zip(mesh.vertices,coords):
        p=(co-center)*scale
        # Lower the entire A-pose arm, including wrist vertices below the elbow.
        if abs(p.x)>.21 and p.z>.88:
            side=1 if p.x>0 else -1
            shoulder=Vector((side*.19,0,1.43))
            p=shoulder+Matrix.Rotation(side*math.radians(43),3,'Y')@(p-shoulder)
        v.co=p
    # Recolor the supplied UV atlas while retaining its small face details.
    image=bpy.data.images.load(str(folder/'NonOverlapping.png'),check_existing=False)
    image.scale(256,256)
    pixels=np.array(image.pixels[:],dtype=np.float32).reshape(-1,4)
    rgb=pixels[:,:3].copy()
    r,g,b=rgb[:,0],rgb[:,1],rgb[:,2]
    masks=[((g>.7)&(r<.3)&(b<.3),(.16,.14,.12)),((r>.6)&(g>.7)&(b<.3),(.16,.14,.12)),((b>.55)&(r<.65)&(g<.5),jacket),((g>.6)&(b>.6)&(r<.4),jacket),((r>.8)&(b>.7)&(g>.25),jacket),((r>.8)&(b>.3)&(g<.3),trousers),((r>.8)&(g>.2)&(g<.65)&(b<.2),(.67,.46,.32))]
    for mask,color in masks:
        pixels[mask,:3]=color
    image.pixels.foreach_set(pixels.flatten())
    image.filepath_raw=str(OUT/(name+'_atlas.png'))
    image.file_format='PNG'
    image.save()
    mat=bpy.data.materials.new('npc_'+name)
    mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Roughness'].default_value=1
    shader.inputs['Metallic'].default_value=0
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image=image
    tex.interpolation='Closest'
    mat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
    mesh.materials.clear()
    mesh.materials.append(mat)
    for face in mesh.polygons:
        face.material_index=0
        face.use_smooth=False
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False)
    tris=sum(len(f.vertices)-2 for f in mesh.polygons)
    report.append({'variant':name,'source':str(folder/'Humanoid.blend'),'mesh':source.name,'triangles':tris,'texture_size':256,'pose':'arms lowered from source A-pose'})
    print('NPC',name,tris,'triangles',flush=True)
    bpy.data.objects.remove(obj,do_unlink=True)
(OUT/'manifest.json').write_text(json.dumps(report,indent=2))
