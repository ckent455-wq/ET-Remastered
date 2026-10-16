import bpy,json
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'assets/lockbox'; OUT.mkdir(parents=True,exist_ok=True)
BASE=Path(r'C:/Users/jkern/My project (2)/Assets/HIVEMIND/HauntedFarmHouse/HDRP (Default)/Art')
report=[]
for name,src in [('body',BASE/'StaticMeshes/Props/Crates/SM_Crate_A_01.fbx'),('lid',BASE/'StaticMeshes/Props/Crates/SM_Crate_Lid_A_01.fbx'),('key',next((ROOT/'builds/asset-source/rust-key').rglob('rust_key.FBX')))]:
 bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.fbx(filepath=str(src),use_image_search=False)
 parts=[o for o in bpy.context.scene.objects if o.type=='MESH' and ('LOD1' in o.name if name!='key' else True)]
 world={o:[o.matrix_world@v.co for v in o.data.vertices] for o in parts}; vs=[v for a in world.values() for v in a]
 lo=Vector([min(v[i] for v in vs) for i in range(3)]); hi=Vector([max(v[i] for v in vs) for i in range(3)])
 print('BOUNDS',name,tuple(hi-lo),flush=True)
 # Imported FBX world coordinates are Z-up; preserve original UVs.
 factor=(.18/max(hi-lo)) if name=='key' else 1.5/.91096449
 origin=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
 for o in parts:
  names=[m.name for m in o.data.materials]; o.parent=None; o.matrix_world=Matrix.Identity(4)
  for v,p in zip(o.data.vertices,world[o]): v.co=(p-origin)*factor
  for f in o.data.polygons:f.use_smooth=False
  o.data.materials.clear()
  for matname in names or ['key']:
   mat=bpy.data.materials.new(matname);mat.use_nodes=True;bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=1;bsdf.inputs['Metallic'].default_value=0
   tex=next((ROOT/'builds/asset-source/rust-key').rglob('rust_key_Albedo.png')) if name=='key' else BASE/('Textures/Props/Other/T_CorrugatedMetalSheet_BaseColor.png' if 'Metal' in matname else 'Textures/House/T_WoodRough_basecolor.png')
   im=bpy.data.images.load(str(tex),check_existing=True);im.scale(256,256);node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=im;node.interpolation='Closest';mat.node_tree.links.new(node.outputs['Color'],bsdf.inputs['Base Color']);o.data.materials.append(mat)
  tris=sum(len(f.vertices)-2 for f in o.data.polygons)
  if tris>1600:
   bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('PS2','DECIMATE');mod.ratio=1600/tris;bpy.ops.object.modifier_apply(modifier=mod.name)
 bpy.ops.object.select_all(action='DESELECT')
 for o in parts:o.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False)
 dims=(hi-lo)*factor;report.append({'asset':name,'source':str(src),'dimensions':[dims.x,dims.z,dims.y]})
(OUT/'manifest.json').write_text(json.dumps({'assets':report,'adaptation':'Original local asset geometry and UVs; matte, flat shading, 256px albedos; originals unchanged.'},indent=2))
