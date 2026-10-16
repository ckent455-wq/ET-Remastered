import bpy,json
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[1];STAGE=ROOT/'builds/asset-source/bullets-and-boxes';OUT=ROOT/'assets/ammo';report=[]
for name,source,width in [('pistol','9mm-box',.24),('rifle','556x45-box',.30),('shotgun','9mm-box',.26)]:
 bpy.ops.wm.open_mainfile(filepath=str(STAGE/'Bullets and boxes.blend'));o=bpy.data.objects[source];vs=[o.matrix_world@v.co for v in o.data.vertices];lo=Vector([min(v[i] for v in vs) for i in range(3)]);hi=Vector([max(v[i] for v in vs) for i in range(3)]);origin=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z));scale=width/(hi.x-lo.x);o.parent=None;o.matrix_world=Matrix.Identity(4)
 for v,p in zip(o.data.vertices,vs):
  v.co=(p-origin)*scale
  if name=='shotgun': v.co.y *= .18/((hi.y-lo.y)*scale)
 old=o.data.materials[0];im=next(n.image for n in old.node_tree.nodes if n.type=='TEX_IMAGE');im.scale(256,256)
 if name=='shotgun':
  im=bpy.data.images.load(str(Path.home()/'Downloads/cardboard_box_01_2k.blend/textures/cardboard_box_01_diff_2k.jpg'));im.scale(256,256)
 mat=bpy.data.materials.new(name+'_source_box');mat.use_nodes=True;bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=1;bs.inputs['Metallic'].default_value=0;node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=im;node.interpolation='Closest';mat.node_tree.links.new(node.outputs['Color'],bs.inputs['Base Color']);o.data.materials.clear();o.data.materials.append(mat)
 for f in o.data.polygons:f.material_index=0;f.use_smooth=False
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False)
 dims=(hi-lo)*scale
 if name=='shotgun': dims.y=.18
 report.append({'asset':name,'source_object':source,'dimensions':[dims.x,dims.z,dims.y],'triangles':sum(len(f.vertices)-2 for f in o.data.polygons)})
(OUT/'manifest.json').write_text(json.dumps({'source':str(Path.home()/'Downloads/Bullets and Boxes.zip'),'assets':report,'adaptation':'Original low-poly geometry and UVs; 256px matte albedos. Native 9mm and 5.56 cartons. Native closed carton repurposed with neutral cardboard and shotgun-shell labels. Source unchanged.'},indent=2))
