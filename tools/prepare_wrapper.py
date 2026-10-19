"""Export the supplied baked FBX rig, without the rig-control widgets or lights."""
import bpy, hashlib, json
from pathlib import Path
from mathutils import Vector

root = Path(__file__).resolve().parents[1]
source = Path.home() / 'Downloads/TheWrapper V2/MonsterPSX.fbx'
out = root / 'assets/enemies/wrapper'
out.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(source))
arm = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
bodies = [o for o in bpy.context.scene.objects if o.type == 'MESH' and any(m.type == 'ARMATURE' for m in o.modifiers)]
assert bodies
for action in bpy.data.actions:
    action.name = action.name.split('|')[-1].lower().replace('.', '_')
arm.animation_data.action = bpy.data.actions['idle_watchful']
bpy.context.scene.frame_set(1)
bpy.context.view_layer.update()
coords = [o.matrix_world @ v.co for o in bodies for v in o.evaluated_get(bpy.context.evaluated_depsgraph_get()).data.vertices]
lo = Vector(tuple(min(v[i] for v in coords) for i in range(3)))
hi = Vector(tuple(max(v[i] for v in coords) for i in range(3)))
parent = bpy.data.objects.new('WrapperScale', None)
bpy.context.collection.objects.link(parent)
for obj in [arm] + bodies:
    if obj.parent == arm: continue
    world = obj.matrix_world.copy()
    obj.parent = parent
    obj.matrix_world = world
factor = 1.82 / (hi.z-lo.z)
parent.scale = Vector((factor,)*3)
parent.location = Vector((-(lo.x+hi.x)/2*factor, -(lo.y+hi.y)/2*factor, -lo.z*factor))
image = bpy.data.images.load(str(source.parent/'MonsterPSX_Diffuse.png'))
image.scale(256,256)
image.filepath_raw = str(out/'wrapper_albedo.png')
image.file_format = 'PNG'
image.save()
material = bpy.data.materials.new('Wrapper PSX skin')
material.use_nodes = True
bs = material.node_tree.nodes.get('Principled BSDF')
bs.inputs['Roughness'].default_value = 1
bs.inputs['Metallic'].default_value = 0
tex = material.node_tree.nodes.new('ShaderNodeTexImage')
tex.image = image
tex.interpolation = 'Closest'
material.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
for body in bodies:
    body.data.materials.clear()
    body.data.materials.append(material)
    for face in body.data.polygons: face.use_smooth = False
arm.animation_data.action = None
for track in list(arm.animation_data.nla_tracks): arm.animation_data.nla_tracks.remove(track)
for action in bpy.data.actions:
    action.use_fake_user = True
    track = arm.animation_data.nla_tracks.new()
    track.name = action.name
    track.strips.new(action.name,1,action)
    track.mute = True
bpy.ops.object.select_all(action='DESELECT')
for obj in [parent,arm]+bodies: obj.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=str(out/'wrapper.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_frame_range=False,export_cameras=False,export_lights=False)
report = {'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'height':1.82,'triangles':sum(len(p.vertices)-2 for b in bodies for p in b.data.polygons),'animations':[a.name for a in bpy.data.actions],'adaptation':'Original skinned mesh and baked clips, 256px supplied diffuse, flat matte PSX materials; controls/lights excluded. Source unchanged.'}
(out/'source.json').write_text(json.dumps(report,indent=2))
print('EXPORTED WRAPPER',report)
