"""Export the supplied baked FBX rig, without the rig-control widgets or lights."""
import bpy, hashlib, json
from pathlib import Path
from mathutils import Vector

root = Path(__file__).resolve().parents[1]
source = next((Path.home()/'Downloads').glob('THE STRAW REAPER*/*/*new.fbx'))
out = root / 'assets/enemies/reaper'
out.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(source))
arm = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
bodies = [o for o in bpy.context.scene.objects if o.type == 'MESH' and any(m.type == 'ARMATURE' for m in o.modifiers)]
assert bodies
actions = [a for a in bpy.data.actions if 'Scarecrow anim' not in a.name]
for index, action in enumerate(actions): action.name = 'motion_%d' % index
for action in list(bpy.data.actions):
    if action not in actions: bpy.data.actions.remove(action)
arm.animation_data.action = actions[0]
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
factor = 2.05 / (hi.z-lo.z)
parent.scale = Vector((factor,)*3)
parent.location = Vector((-(lo.x+hi.x)/2*factor, -(lo.y+hi.y)/2*factor, -lo.z*factor))
for mat in bpy.data.materials:
    if not mat.use_nodes: continue
    bs = mat.node_tree.nodes.get('Principled BSDF')
    if bs:
        bs.inputs['Roughness'].default_value=1
        bs.inputs['Metallic'].default_value=0
    for node in mat.node_tree.nodes:
        if node.type!='TEX_IMAGE' or not node.image: continue
        name=Path(node.image.filepath.replace('\\','/')).name
        file=source.parent/'texture'/name
        if not file.exists(): file=source.parent/'texture'/'teeth (2).png'
        image=bpy.data.images.load(str(file),check_existing=True)
        if max(image.size)>256:
            factor=256/max(image.size);image.scale(max(1,int(image.size[0]*factor)),max(1,int(image.size[1]*factor)))
        node.image=image
        node.interpolation='Closest'
for body in bodies:
    for face in body.data.polygons: face.use_smooth=False
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
bpy.ops.export_scene.gltf(filepath=str(out/'reaper.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_frame_range=False,export_cameras=False,export_lights=False)
report = {'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'height':2.05,'triangles':sum(len(p.vertices)-2 for b in bodies for p in b.data.polygons),'animations':[a.name for a in bpy.data.actions],'adaptation':'Original skinned body, scythe and teeth with nine usable supplied clips and reduced native textures. Unrelated malformed Scarecrow action excluded. Source unchanged.'}
(out/'source.json').write_text(json.dumps(report,indent=2))
print('EXPORTED REAPER',report)
