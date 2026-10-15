"""Prepare local assets for the PS2-inspired forest. Run with Blender 4.2 --background --python."""
import bpy, bmesh, math, random, json, sys
from pathlib import Path
from mathutils import Vector
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'forest'
OUT.mkdir(parents=True,exist_ok=True)
DOWNLOADS=Path(r'C:\Users\jkern\Downloads')
report=[]
ground=bpy.data.images.load(str(ROOT/'assets'/'forest.jpg'))
ground.scale(256,256)
ground.filepath_raw=str(OUT/'ground_ps2.png')
ground.file_format='PNG'
ground.save()

def texture(folder, stem, alpha=None):
    files=list((folder/'textures').glob(stem+'_diff_*'))
    if not files:
        return None
    image=bpy.data.images.load(str(files[0]),check_existing=True)
    image.scale(256,256)
    rgba=np.array(image.pixels[:],dtype=np.float32).reshape(-1,4)
    if alpha:
        masks=list((folder/'textures').glob(alpha+'_alpha_*'))
        if masks:
            mask=bpy.data.images.load(str(masks[0]),check_existing=True)
            mask.scale(256,256)
            rgba[:,3]=np.array(mask.pixels[:],dtype=np.float32).reshape(-1,4)[:,0]
    image.pixels.foreach_set(rgba.flatten())
    image.filepath_raw=str(OUT/(stem+'.png'))
    image.file_format='PNG'
    image.save()
    return image

def simple_material(name,folder,stem,alpha=None):
    material=bpy.data.materials.new('retro_'+name)
    material.use_nodes=True
    nodes=material.node_tree.nodes
    shader=nodes.get('Principled BSDF')
    shader.inputs['Roughness'].default_value=1
    shader.inputs['Metallic'].default_value=0
    image=texture(folder,stem,alpha)
    if image:
        node=nodes.new('ShaderNodeTexImage')
        node.image=image
        node.interpolation='Closest'
        material.node_tree.links.new(node.outputs['Color'],shader.inputs['Base Color'])
        if alpha:
            material.node_tree.links.new(node.outputs['Alpha'],shader.inputs['Alpha'])
            material.surface_render_method='DITHERED'
            material.use_backface_culling=False
    return material

def export(obj,name,budget,folder,kind):
    # Work only on copies; never save changes to the source .blend.
    bpy.ops.object.select_all(action='DESELECT')
    clone=obj.copy()
    clone.data=obj.data.copy()
    bpy.context.collection.objects.link(clone)
    clone.select_set(True)
    bpy.context.view_layer.objects.active=clone
    clone.parent=None
    clone.location=Vector((0,0,0))
    clone.modifiers.clear()
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    mins=Vector((min(v.co.x for v in clone.data.vertices),min(v.co.y for v in clone.data.vertices),min(v.co.z for v in clone.data.vertices)))
    maxs=Vector((max(v.co.x for v in clone.data.vertices),max(v.co.y for v in clone.data.vertices),max(v.co.z for v in clone.data.vertices)))
    offset=Vector(((mins.x+maxs.x)/2,(mins.y+maxs.y)/2,mins.z))
    height=maxs.z-mins.z
    factor=(9.5 if kind=='pine' else 1.0)/max(height,.001)
    for v in clone.data.vertices:
        v.co=(v.co-offset)*factor
    if kind=='pine':
        # Needle geometry collapses into large shards when heavily decimated.
        # Keep the source woody structure; the game adds atlas-based foliage cards.
        needle_slots={i for i,s in enumerate(clone.material_slots) if s.material and 'twig' in s.material.name}
        bm=bmesh.new()
        bm.from_mesh(clone.data)
        bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.material_index in needle_slots],context='FACES')
        bm.to_mesh(clone.data)
        bm.free()
        budget=1400
    tris=sum(len(p.vertices)-2 for p in clone.data.polygons)
    if tris>budget:
        mod=clone.modifiers.new('PS2 polygon budget','DECIMATE')
        mod.ratio=budget/tris
        bpy.ops.object.modifier_apply(modifier=mod.name)
    old_slots=[slot.material.name if slot.material else '' for slot in clone.material_slots]
    for i,source_name in enumerate(old_slots):
        stem=source_name
        alpha=None
        if kind=='pine':
            if 'twig' in stem:
                stem='pine_tree_01_twig'
                alpha=stem
            elif 'trunk' not in stem:
                stem='pine_tree_01_bark'
        elif kind=='bush':
            stem='othonna_cerarioides'
            if 'leaves' in source_name:
                alpha=stem
        elif kind=='rock':
            stem='rock_surface'
        clone.material_slots[i].material=simple_material(source_name,folder,stem,alpha)
    for p in clone.data.polygons:
        p.use_smooth=False if kind=='rock' else True
    clone.name=name
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
    tris=sum(len(p.vertices)-2 for p in clone.data.polygons)
    report.append({'asset':name,'source':str(folder),'triangles':tris,'height':round(clone.dimensions.z,3),'texture_size':256})
    print('PREPARED',name,tris,flush=True)
    bpy.data.objects.remove(clone,do_unlink=True)

if '--rocks-only' not in sys.argv:
    folder=DOWNLOADS/'pine_tree_01_1k.blend'
    bpy.ops.wm.open_mainfile(filepath=str(folder/folder.name),load_ui=False)
    for letter in ['b','c']:
        export(bpy.data.objects[f'pine_tree_01_{letter}_LOD2'],'pine_'+letter,4200,folder,'pine')
    folder=DOWNLOADS/'othonna_cerarioides_2k.blend'
    bpy.ops.wm.open_mainfile(filepath=str(folder/folder.name),load_ui=False)
    for letter in ['e','f','g']:
        export(bpy.data.objects[f'othonna_cerarioides_{letter}_LOD3'],'bush_'+letter,750,folder,'bush')
else:
    report=[r for r in json.loads((OUT/'manifest.json').read_text()) if not r['asset'].startswith('rock')]
folder=DOWNLOADS/'rock_surface_1k.blend'
bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(23)
for i in range(3):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1)
    obj=bpy.context.object
    # Irregular faceted shapes use the local scanned rock diffuse texture.
    for v in obj.data.vertices:
        v.co*=random.uniform(.78,1.18)
        v.co.x*=1.25
        v.co.z*=.68
    obj.data.materials.append(simple_material('rock_surface',folder,'rock_surface'))
    # Spherical UV coordinates for the source rock texture.
    uv=obj.data.uv_layers.active or obj.data.uv_layers.new()
    for poly in obj.data.polygons:
        for li in poly.loop_indices:
            co=obj.data.vertices[obj.data.loops[li].vertex_index].co.normalized()
            uv.data[li].uv=(.5+math.atan2(co.y,co.x)/(2*math.pi),.5+math.asin(co.z)/math.pi)
    export(obj,'rock_'+str(i),320,folder,'rock')
    bpy.data.objects.remove(obj,do_unlink=True)
(OUT/'manifest.json').write_text(json.dumps(report,indent=2))
print('ASSET PREPARATION COMPLETE',flush=True)
