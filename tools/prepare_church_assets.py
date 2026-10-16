import bpy,json,re
from pathlib import Path
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parents[1];BASE=Path(r'C:/Users/jkern/My project (2)/Assets/Flooded_Grounds/Content');OUT=ROOT/'assets/church';OUT.mkdir(parents=True,exist_ok=True)
recipes=[('pew','lo_Prop_ChurchBench_A.fbx',2.85,0,900,'PROP_SmallProps2_A.tif'),('door','Church1_Door_C.fbx',2.7,2,1000,'BLD_Doors1_A.tif'),('gothic_trim','Church1_Deco_Column_A.fbx',10.1,0,2000,'BLD_Church1_A.tif'),('front','Church1_End_A.fbx',10.1,0,6000,'BLD_Church1_A.tif'),('nave','Church1_Mid_A.fbx',10.1,0,3000,'BLD_Church1_A.tif'),('apse','Church1_End_B.fbx',10.1,0,4000,'BLD_Church1_A.tif')]
report=[]
for name,filename,target,axis,budget,tex in recipes:
 bpy.ops.wm.read_factory_settings(use_empty=True);src=next((BASE/'Meshes').rglob(filename));bpy.ops.import_scene.fbx(filepath=str(src),use_image_search=False)
 parts=[o for o in bpy.context.scene.objects if o.type=='MESH' and ('LOD' not in o.name or 'LOD1' in o.name)]
 world={o:[o.matrix_world@v.co for v in o.data.vertices] for o in parts};vs=[v for vv in world.values() for v in vv];lo=Vector([min(v[i] for v in vs) for i in range(3)]);hi=Vector([max(v[i] for v in vs) for i in range(3)]);factor=target/(hi-lo)[axis]
 origin=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
 mat=bpy.data.materials.new('church_source_atlas');mat.use_nodes=True;bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=1;bsdf.inputs['Metallic'].default_value=0;im=bpy.data.images.load(str(BASE/'Textures'/tex));im.scale(512 if name in ['front','nave','apse'] else 256,512 if name in ['front','nave','apse'] else 256);node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=im;node.interpolation='Closest';mat.node_tree.links.new(node.outputs['Color'],bsdf.inputs['Base Color'])
 total=sum(sum(len(f.vertices)-2 for f in o.data.polygons) for o in parts)
 for o in parts:
  o.parent=None;o.matrix_world=Matrix.Identity(4)
  for v,p in zip(o.data.vertices,world[o]):v.co=(p-origin)*factor
  # Widen the native facade opening to the existing 2.8m playable doorway.
  if name in ['front','apse']:
   import bmesh
   bm=bmesh.new();bm.from_mesh(o.data)
   remove=[f for f in bm.faces if (all(abs(v.co.x)<1.55 and v.co.z<3.05 for v in f.verts) if name=='front' else abs(f.calc_center_median().x)<4.6 and f.calc_center_median().z<7.0)]
   bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(o.data);bm.free()
  o.data.materials.clear();o.data.materials.append(mat)
  for f in o.data.polygons:f.use_smooth=False;f.material_index=0
  if total>budget:
   bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('PS2 budget','DECIMATE');mod.ratio=budget/total;bpy.ops.object.modifier_apply(modifier=mod.name)
 bpy.ops.object.select_all(action='DESELECT')
 for o in parts:o.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False)
 dims=(hi-lo)*factor;report.append({'asset':name,'source':str(src),'dimensions':[dims.x,dims.z,dims.y],'triangles':sum(sum(len(f.vertices)-2 for f in o.data.polygons) for o in parts)})
(OUT/'manifest.json').write_text(json.dumps({'package':'Flooded Grounds, local Unity assets','assets':report,'adaptation':'Original UVs and albedos, 256/512px atlas, matte flat shading, bounded triangle counts; source unchanged.'},indent=2))
