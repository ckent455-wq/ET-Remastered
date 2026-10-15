"""Export reduced copies of local interior models; never modify source .blend files."""
import bpy, json, math, re
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'interiors'
OUT.mkdir(parents=True,exist_ok=True)
REPORT=json.loads((ROOT/'tools'/'interior_asset_report.json').read_text())
SETTINGS={'shelf':('height',2.1,500),'lamp':('height',1.65,1000),'books':('width',0.9,1800),'curtain':('height',1.4,1000),'door':('height',2.7,1600),'box':('height',0.48,500),'teapot':('height',0.26,600),'sink':('width',0.92,1100)}
manifest=[]
for name,(axis,target,budget) in SETTINGS.items():
    source=REPORT[name]['source']
    bpy.ops.wm.open_mainfile(filepath=source,load_ui=False)
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    if name=='door':
        objects=[o for o in objects if o.name in ['door.001','door_decoration','door_inside_handle.003','lock.001','Cylinder']]
    bpy.ops.object.select_all(action='DESELECT')
    clones=[]
    rotation=Matrix.Rotation(math.pi/2,4,'Z') if name=='curtain' else Matrix.Identity(4)
    for original in objects:
        clone=original.copy()
        clone.data=original.data.copy()
        clone.parent=None
        clone.modifiers.clear()
        bpy.context.collection.objects.link(clone)
        clone.hide_viewport=False
        clone.hide_render=False
        clone.hide_set(False)
        if clone.data.shape_keys:
            clone.shape_key_clear()
        transform=rotation@original.matrix_world
        for vertex in clone.data.vertices:
            vertex.co=transform@vertex.co
        clone.matrix_world=Matrix.Identity(4)
        clones.append(clone)
    coords=[v.co for c in clones for v in c.data.vertices]
    low=Vector(tuple(min(v[i] for v in coords) for i in range(3)))
    high=Vector(tuple(max(v[i] for v in coords) for i in range(3)))
    factor=target/(high-low)[2 if axis=='height' else 0]
    origin=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
    total=sum(sum(len(p.vertices)-2 for p in c.data.polygons) for c in clones)
    # Keep small components readable; share a total budget among the meshes.
    cache={}
    for index,clone in enumerate(clones):
        for v in clone.data.vertices:
            v.co=(v.co-origin)*factor
        bpy.context.view_layer.objects.active=clone
        tris=sum(len(p.vertices)-2 for p in clone.data.polygons)
        allocation=max(48,int(budget*tris/max(1,total)))
        if tris>allocation:
            modifier=clone.modifiers.new('Retro simplification','DECIMATE')
            modifier.ratio=allocation/tris
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        if not clone.data.uv_layers:
            layer=clone.data.uv_layers.new()
            for poly in clone.data.polygons:
                normal=poly.normal
                axes=[i for i in range(3) if i!=max(range(3),key=lambda i:abs(normal[i]))]
                for li in poly.loop_indices:
                    v=clone.data.vertices[clone.data.loops[li].vertex_index].co
                    layer.data[li].uv=(v[axes[0]],v[axes[1]])
        for slot in clone.material_slots:
            old=slot.material
            old_name=old.name if old else 'Unpainted'
            key=(old_name,index%5 if name=='books' and 'cover' in old_name.lower() else 0)
            if key not in cache:
                mat=bpy.data.materials.new('retro_'+name+'_'+re.sub(r'[^a-zA-Z0-9]','_',old_name)+str(key[1]))
                mat.use_nodes=True
                shader=mat.node_tree.nodes.get('Principled BSDF')
                shader.inputs['Roughness'].default_value=1
                shader.inputs['Metallic'].default_value=0
                shader.inputs['Specular IOR Level'].default_value=0
                image=None
                for im in bpy.data.images:
                    lower=im.name.lower()
                    if any(token in lower for token in ['_col_','_color','_diffuse','_diff.','_diff_']):
                        image=im
                        break
                if image:
                    image.scale(256,256)
                    image.filepath_raw=str(OUT/(name+'_diffuse.png'))
                    image.file_format='PNG'
                    image.save()
                    tex=mat.node_tree.nodes.new('ShaderNodeTexImage')
                    tex.image=image
                    tex.interpolation='Closest'
                    mat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
                else:
                    color=tuple(old.diffuse_color) if old else (.45,.43,.38,1)
                    lower=old_name.lower()
                    if name=='books':
                        color=[(.22,.31,.28,1),(.35,.19,.15,1),(.24,.28,.36,1),(.42,.34,.20,1),(.32,.25,.23,1)][index%5] if 'cover' in lower else (.65,.60,.46,1)
                    elif 'black' in lower or 'insulator' in lower:
                        color=(.08,.09,.08,1)
                    elif 'bulb' in lower:
                        color=(.73,.67,.46,1)
                    elif name=='lamp':
                        color=(.50,.47,.34,1)
                    shader.inputs['Base Color'].default_value=color
                cache[key]=mat
            slot.material=cache[key]
    for clone in clones:
        clone.select_set(True)
    bpy.context.view_layer.objects.active=clones[0]
    if len(clones)>1:
        bpy.ops.object.join()
    merged=bpy.context.object
    merged.name=name
    merged.data.validate(clean_customdata=True)
    tris=sum(len(p.vertices)-2 for p in merged.data.polygons)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False)
    manifest.append({'asset':name,'source':source,'triangles':tris,'dimensions':[round(v,4) for v in ((high-low)*factor)],'texture_limit':256})
    print('EXPORTED',name,tris,'triangles',flush=True)
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
