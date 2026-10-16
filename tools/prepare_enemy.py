import bpy,json,hashlib,tarfile
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parents[1]
stage=root/'builds/asset-source/creep'
if not list(stage.rglob('Creep_mesh_lod1.fbx')):
 package=next((Path.home()/'AppData/Roaming/Unity/Asset Store-5.x').rglob('Creep Horror Creature.unitypackage'))
 stage.mkdir(parents=True,exist_ok=True);(stage/'.gdignore').touch()
 with tarfile.open(package,'r:gz') as archive:
  for entry in archive.getmembers():
   if not entry.name.endswith('/pathname'):continue
   name=archive.extractfile(entry).read().decode(errors='replace').splitlines()[0].rstrip('\x00')
   if Path(name).suffix.lower() not in ['.fbx','.png']:continue
   destination=(stage/name).resolve();assert destination.is_relative_to(stage.resolve())
   destination.parent.mkdir(parents=True,exist_ok=True)
   destination.write_bytes(archive.extractfile(entry.name.rsplit('/',1)[0]+'/asset').read())
source=next(stage.rglob('Creep_mesh_lod1.fbx'));out=root/'assets/enemies';out.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(source))
arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');body=next(o for o in bpy.context.scene.objects if o.type=='MESH')
arm.animation_data.action=next(a for a in bpy.data.actions if 'Idle1_Action' in a.name);bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
evalbody=body.evaluated_get(bpy.context.evaluated_depsgraph_get());coords=[evalbody.matrix_world@v.co for v in evalbody.data.vertices];lo=Vector(tuple(min(v[i] for v in coords) for i in range(3)));hi=Vector(tuple(max(v[i] for v in coords) for i in range(3)))
parent=bpy.data.objects.new('CreepScale',None);bpy.context.collection.objects.link(parent)
for obj in [arm,body]:
 world=obj.matrix_world.copy();obj.parent=parent;obj.matrix_world=world
factor=2.1/(hi.z-lo.z);parent.scale=Vector((factor,)*3);parent.location=Vector((-(lo.x+hi.x)/2*factor,-(lo.y+hi.y)/2*factor,-lo.z*factor))
tex=next(source.parents[1].glob('Textures/tex/Creep_BaseColor.png'));im=bpy.data.images.load(str(tex));im.scale(256,256);im.filepath_raw=str(out/'creep_albedo.png');im.file_format='PNG';im.save()
mat=bpy.data.materials.new('Creep PS2 skin');mat.use_nodes=True;bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=1;bs.inputs['Metallic'].default_value=0;node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=im;node.interpolation='Closest';mat.node_tree.links.new(node.outputs['Color'],bs.inputs['Base Color']);body.data.materials.clear();body.data.materials.append(mat)
tri=sum(len(p.vertices)-2 for p in body.data.polygons)
if tri>3400:
 bpy.context.view_layer.objects.active=body;mod=body.modifiers.new('PS2 triangles','DECIMATE');mod.ratio=3400/tri;bpy.ops.object.modifier_apply(modifier=mod.name)
for face in body.data.polygons:face.use_smooth=False
for a in bpy.data.actions:a.name=a.name.split('|')[-1].replace('_Action','').lower();a.use_fake_user=True
arm.animation_data.action=None
for a in bpy.data.actions:
 a.id_root='OBJECT'
 track=arm.animation_data.nla_tracks.new();track.name=a.name;track.strips.new(a.name,1,a);track.mute=True
bpy.ops.export_scene.gltf(filepath=str(out/'creep.glb'),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_frame_range=False,export_cameras=False,export_lights=False)
report={'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'author':'Andrii Chykrii','pack':'Creep Horror Creature','triangles':sum(len(p.vertices)-2 for p in body.data.polygons),'texture_limit':256,'height':2.1,'actions':[a.name for a in bpy.data.actions],'adaptation':'Original skinned LOD1 mesh, UVs and animation clips; reduced triangles and albedo; source untouched.'};(out/'manifest.json').write_text(json.dumps(report,indent=2)+'\n');print('EXPORTED',report)
