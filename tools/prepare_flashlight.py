"""Adapt the user's existing Unity flashlight FBX without changing its source."""
import bpy,json
from pathlib import Path
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/flashlight'
OUT.mkdir(parents=True,exist_ok=True)
source=Path(r'C:\Users\jkern\My project (2)\Assets\Flashlight\Misc\Flashlight.FBX')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(source))
obj=next(o for o in bpy.data.objects if o.type=='MESH')
coords=[obj.matrix_world@v.co for v in obj.data.vertices]
low=Vector(tuple(min(p[i] for p in coords) for i in range(3)))
high=Vector(tuple(max(p[i] for p in coords) for i in range(3)))
center=(low+high)/2
scale=0.34/(high.y-low.y)
for index,old in enumerate(obj.data.materials):
 ys=[(obj.matrix_world@obj.data.vertices[v].co).y for face in obj.data.polygons if face.material_index==index for v in face.vertices]
 print('MATERIAL',index,old.name,'Y range',min(ys),max(ys),flush=True)
obj.parent=None
obj.matrix_world=Matrix.Identity(4)
for vertex,p in zip(obj.data.vertices,coords): vertex.co=(p-center)*scale
for face in obj.data.polygons: face.use_smooth=False
image=bpy.data.images.load(str(source.parent/'Flashlight.fbm'/'LP_FlashLight_AL.png'),check_existing=False)
image.scale(256,256)
image.filepath_raw=str(OUT/'flashlight_albedo.png')
image.file_format='PNG'
image.save()
for index in range(len(obj.data.materials)):
 material=bpy.data.materials.new('FlashlightSurface%d'%index)
 material.use_nodes=True
 bsdf=material.node_tree.nodes.get('Principled BSDF')
 bsdf.inputs['Roughness'].default_value=0.86
 bsdf.inputs['Metallic'].default_value=0
 texture=material.node_tree.nodes.new('ShaderNodeTexImage')
 texture.image=image
 texture.interpolation='Closest'
 material.node_tree.links.new(texture.outputs['Color'],bsdf.inputs['Base Color'])
 obj.data.materials[index]=material
bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active=obj
bpy.ops.export_scene.gltf(filepath=str(OUT/'flashlight.glb'),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False)
triangles=sum(len(f.vertices)-2 for f in obj.data.polygons)
(OUT/'source.json').write_text(json.dumps({'source':str(source),'model':obj.name,'triangles':triangles,'texture_limit':256,'length_m':0.34,'muzzle_axis':'Godot -Z','adaptation':'centered original mesh, flat normals, original albedo reduced to 256 pixels, matte surfaces'},indent=2)+'\n')
print('FLASHLIGHT EXPORTED',triangles,'triangles',flush=True)
