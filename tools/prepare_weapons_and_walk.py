"""Adapt the locally downloaded weapons and rig existing humanoids for walking."""
import bpy, math, json, zipfile, tempfile, sys
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'weapons'
OUT.mkdir(exist_ok=True)
pack=Path(r'C:\Users\jkern\Downloads\3D_low_poly_guns_pack_2.zip')
report=[]
with tempfile.TemporaryDirectory(prefix='et_weapons_') as temp, zipfile.ZipFile(pack) as archive:
    (OUT/'LICENSE.txt').write_bytes(archive.read('3D_low_poly_guns_pack_2/LICENSE.txt'))
    for name,source,length in [('pistol','suppressed_covert_pistol',0.52),('rifle','semi_auto_service_rifle',0.95),('shotgun','over_under_shotgun',1.0)]:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        path=Path(temp)/(source+'.glb')
        path.write_bytes(archive.read('3D_low_poly_guns_pack_2/models/'+source+'.glb'))
        bpy.ops.import_scene.gltf(filepath=str(path))
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
        all_coords=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
        low=Vector(tuple(min(v[i] for v in all_coords) for i in range(3)))
        high=Vector(tuple(max(v[i] for v in all_coords) for i in range(3)))
        center=(low+high)/2
        scale=length/(high.x-low.x)
        rotation=Matrix.Rotation(math.pi/2,3,'Z')
        total=sum(len(o.data.loop_triangles) or sum(len(f.vertices)-2 for f in o.data.polygons) for o in meshes)
        for obj in meshes:
            coords=[obj.matrix_world@v.co for v in obj.data.vertices]
            obj.parent=None
            obj.matrix_world=Matrix.Identity(4)
            for v,co in zip(obj.data.vertices,coords): v.co=rotation@((co-center)*scale)
            dec=obj.modifiers.new('PS2 triangle budget','DECIMATE'); dec.ratio=min(1,2200/max(1,total));dec.use_collapse_triangulate=True
            bpy.context.view_layer.objects.active=obj
            bpy.ops.object.modifier_apply(modifier=dec.name)
            for face in obj.data.polygons: face.use_smooth=False
            for slot in obj.material_slots:
                material=slot.material
                if not material or not material.use_nodes: continue
                shader=next((n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
                if shader:
                    shader.inputs['Metallic'].default_value=0
                    shader.inputs['Roughness'].default_value=1
                    for key in ['Metallic','Roughness','Normal']:
                        for link in list(shader.inputs[key].links): material.node_tree.links.remove(link)
                for node in material.node_tree.nodes:
                    if node.type=='TEX_IMAGE' and node.image:
                        if max(node.image.size)>256: node.image.scale(256,256)
                        node.interpolation='Closest'
        bpy.ops.object.select_all(action='DESELECT')
        for obj in meshes: obj.select_set(True)
        bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False)
        tris=sum(sum(len(f.vertices)-2 for f in o.data.polygons) for o in meshes)
        report.append({'weapon':name,'source':source+'.glb','triangles':tris,'texture_limit':256,'license':'CC0 / Polyy'})
        print('WEAPON',name,tris,flush=True)
(OUT/'manifest.json').write_text(json.dumps(report,indent=2))
# Add a compact skeleton to each existing 402-triangle humanoid, retaining its atlas.
for name in ([] if '--guns-only' in sys.argv else ['ranger','nurse','mechanic']):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    path=ROOT/'assets'/'npcs'/(name+'.glb')
    bpy.ops.import_scene.gltf(filepath=str(path))
    if any(o.type=='ARMATURE' for o in bpy.context.scene.objects):
        print('WALK RIG already present',name,flush=True)
        continue
    obj=next(o for o in bpy.context.scene.objects if o.type=='MESH')
    # Make imported world coordinates local before skinning.
    coords=[obj.matrix_world@v.co for v in obj.data.vertices]
    obj.parent=None; obj.matrix_world=Matrix.Identity(4)
    for v,co in zip(obj.data.vertices,coords): v.co=co
    arm=bpy.data.armatures.new('TownWalker')
    rig=bpy.data.objects.new('TownWalker',arm);bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig;rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    specs=[('body',(0,0,.86),(0,0,1.5),None)]
    for side,x in [('L',.115),('R',-.115)]:
        specs += [('leg_'+side,(x,0,.86),(x,0,.44),'body'),('shin_'+side,(x,0,.44),(x,0,.08),'leg_'+side),('arm_'+side,(x*2,0,1.40),(x*2.5,0,.96),'body')]
    for bone_name,head,tail,parent in specs:
        bone=arm.edit_bones.new(bone_name);bone.head=head;bone.tail=tail
        if parent: bone.parent=arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    groups={n:obj.vertex_groups.new(name=n) for n,_,_,_ in specs}
    for vertex in obj.data.vertices:
        x,y,z=vertex.co;side='L' if x>=0 else 'R'
        group='body'
        if z<.86:
            group=('shin_' if z<.44 else 'leg_')+side
        elif abs(x)>.225 and z<1.46:
            group='arm_'+side
        groups[group].add([vertex.index],1,'REPLACE')
    modifier=obj.modifiers.new('Walk skin','ARMATURE');modifier.object=rig
    obj.parent=rig
    for frame in range(0,33,4):
        phase=frame/32*math.tau
        for side,sign in [('L',1),('R',-1)]:
            for part in ['leg','shin','arm']:
                bone=rig.pose.bones[part+'_'+side];bone.rotation_mode='XYZ'
                angle=math.sin(phase)*sign
                bone.rotation_euler.x=(angle*.36 if part=='leg' else max(0,-angle)*.42 if part=='shin' else -angle*.24)
                bone.keyframe_insert(data_path='rotation_euler',frame=frame)
    rig.animation_data.action.name='walk'
    bpy.context.scene.render.fps=30
    bpy.context.scene.frame_start=0;bpy.context.scene.frame_end=32;bpy.context.scene.frame_set(0)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);rig.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=True,export_frame_range=True,export_cameras=False,export_lights=False)
    print('WALK RIG',name,flush=True)
