import bpy
from pathlib import Path
from mathutils import Vector,Matrix
root=Path(__file__).resolve().parents[1]
source=Path(r'C:/Users/jkern/My project (2)/Assets/Flooded_Grounds/Content/Meshes/mBuildings/mChurches/Church1_End_A.fbx')
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(source),use_image_search=False)
o=next(o for o in bpy.context.scene.objects if o.type=='MESH');vs=[o.matrix_world@v.co for v in o.data.vertices];lo=Vector([min(v[i] for v in vs) for i in range(3)]);hi=Vector([max(v[i] for v in vs) for i in range(3)]);factor=10.1/(hi.x-lo.x);origin=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z));o.parent=None;o.matrix_world=Matrix.Identity(4)
for v,p in zip(o.data.vertices,vs):v.co=(p-origin)*factor
for y in [6,7,8,9,10,12]:
 a=[v.co for v in o.data.vertices if y<v.co.z<y+1];print('SLICE',y,[min(p[i] for p in a) for i in range(3)] if a else [],[max(p[i] for p in a) for i in range(3)] if a else [],flush=True)
# Clip the tower from the source facade, with its original UVs. The cut base
# is deliberately sunk below the new continuous roof rather than floating.
import bmesh
bm=bmesh.new();bm.from_mesh(o.data)
for point,normal in [((0,0,7.6),(0,0,1)),((-1.45,0,0),(1,0,0)),((1.45,0,0),(-1,0,0))]:
 bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=point,plane_no=normal,clear_inner=True,clear_outer=False)
# Cut the two tower halves against the sloping roof, rather than using a
# flat base which would protrude through the interior ceiling.
merged=bmesh.new()
for side in [-1,1]:
 half=bm.copy()
 bmesh.ops.bisect_plane(half,geom=list(half.verts)+list(half.edges)+list(half.faces),dist=.00001,plane_co=(0,0,0),plane_no=(side,0,0),clear_inner=True)
 bmesh.ops.bisect_plane(half,geom=list(half.verts)+list(half.edges)+list(half.faces),dist=.00001,plane_co=(0,0,8.55),plane_no=(side*2.8/5.4,0,1),clear_inner=True)
 tmp=bpy.data.meshes.new('Roof cut');half.to_mesh(tmp);half.free();merged.from_mesh(tmp);bpy.data.meshes.remove(tmp)
bm.free();bmesh.ops.remove_doubles(merged,verts=list(merged.verts),dist=.00001);merged.to_mesh(o.data);merged.free()
# Remove any loose cut geometry.
bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS');bm.to_mesh(o.data);bm.free()
mat=bpy.data.materials.new('Local church atlas');mat.use_nodes=True;bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=1;bs.inputs['Metallic'].default_value=0
im=bpy.data.images.load(str(root/'assets/church/front_BLD_Church1_A.png'));node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=im;mat.node_tree.links.new(node.outputs['Color'],bs.inputs['Base Color']);o.data.materials.clear();o.data.materials.append(mat)
for f in o.data.polygons:f.material_index=0;f.use_smooth=False
bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
bpy.ops.export_scene.gltf(filepath=str(root/'assets/church/bell_tower.glb'),export_format='GLB',use_selection=True,export_animations=False)
print('Tower triangles',sum(len(f.vertices)-2 for f in o.data.polygons),flush=True)
# The original atlas contains a consistent siding strip. Crop a repeating copy
# for the continuous shell instead of stretching the complete UV atlas.
src=bpy.data.images.load(str(root/'assets/church/front_BLD_Church1_A.png'),check_existing=False);w,h=src.size;pix=list(src.pixels);x0,x1=4,148;y0,y1=80,500
out=bpy.data.images.new('Source church siding',width=x1-x0,height=y1-y0);values=[]
for y in range(y0,y1):values.extend(pix[(y*w+x0)*4:(y*w+x1)*4])
out.pixels=values;out.scale(128,256);out.filepath_raw=str(root/'assets/church/siding.png');out.file_format='PNG';out.save()

import json
manifest=root/'assets/church/manifest.json'
data=json.loads(manifest.read_text())
data['active_assembly']={'assets':['bell_tower','door','pew','siding.png'],'shell':'One continuous shell with separate interior lining and roof; no overlapping full building modules.','tower':'Source facade clipped to roof slopes, preserving UVs.','door_prefab':'Flooded_Grounds/Prefabs/Buildings/Churches/Church1_Door_C.prefab','door_instances':'Two exactly fitted entrance leaves and one scaled cellar leaf.'}
manifest.write_text(json.dumps(data,indent=2))
