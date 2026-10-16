"""Export original Apartment Kit props as small, matte, textured Godot copies."""
import bpy,json,re,math,hashlib
from pathlib import Path
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parents[1];STAGE=ROOT/'builds/asset-source/apartment-kit';OUT=ROOT/'assets/apartment';OUT.mkdir(parents=True,exist_ok=True)
index=json.loads((ROOT/'tools/apartment_package_index.json').read_text());byguid={r['entry']:STAGE/r['path'] for r in index['assets']}
# name, source model, source root object (includes children), prefab, target long axis/value, budget
recipes=[
('sofa','Apt_Furniture_01.fbx','Sofa_Apt_01','Sofa_Apt_01.prefab','width',2.6,1800),
('chair','Apt_Furniture_01.fbx','Chair_Apt_01','Chair_Apt_01.prefab','height',0.92,800),
('coffee_table','Apt_Furniture_01.fbx','Coffee_Table_Apt_01','Coffee_Table_Apt_01.prefab','width',1.45,700),
('side_table','Apt_Furniture_01.fbx','Table_Side_Apt_01','Table_Side_Apt_01.prefab','height',0.68,600),
('bookcase','Apt_Furniture_01.fbx','Shelf_Apt_01','Shelf_Apt_01.prefab','height',2.1,900),
('floor_lamp','Apt_Furniture_01.fbx','Lamp_Floor_01','Lamp_Floor_01.prefab','height',1.65,400),
('desk','Apt_Furniture_01.fbx','ComputerTable_Apt_01','ComputerTable_Apt_01.prefab','height',0.88,1000),
('bed','Apt_Furniture_02.fbx','Bed_Apt_01','Bed_Apt_01_01.prefab','depth',2.2,2000),
('wardrobe','Apt_Furniture_02.fbx','Dresser Closet_01','Dresser Closet_01.prefab','height',2.15,700),
('dresser','Apt_Furniture_02.fbx','Dresser_Apt_01','Dresser_Apt_01.prefab','height',0.9,900),
('fridge','Kitchen_01.fbx','Fridge_01','Fridge_01.prefab','height',1.85,1800),
('stove','Kitchen_01.fbx','Stove_01','Stove_01.prefab','height',0.9,1600),
('counter','Kitchen_01.fbx','Cabinet_Base_DD_01','Cabinet_Base_DD_01.prefab','height',0.9,700),
('wall_cabinet','Kitchen_01.fbx','Cabinet_Wall_DD_02','Cabinet_Wall_DD_02.prefab','width',1.0,500),
('office_chair','office chair.fbx',None,'office chair.prefab','height',1.0,1100),
('dining_table','BPS_Table.fbx',None,'BPS_Table.prefab','height',0.78,300),
('monitor','Apt_Props_01.fbx','Monitor_Apt_01','Monitor_Apt_01.prefab','width',0.55,400),
('keyboard','Apt_Props_01.fbx','KeyBoard_Apt_01','KeyBoard_Apt_01.prefab','width',0.43,200),
('trash','Apt_Props_01.fbx','Trash_apt_01','Trash_apt_01.prefab','height',0.48,150),
('plate','Apt_Props_01.fbx','Plate_Apt_01','Plate_Apt_01.prefab','width',0.27,150),
('bowl','Apt_Props_01.fbx','Bowl_Apt_01','Bowl_Apt_01.prefab','width',0.23,300),
('coffee_maker','Apt_Props_01.fbx','CoffeeMaker_Apt_01','CoffeeMaker_Apt_01.prefab','height',0.34,1100),
('rug','Apt_Furniture_01.fbx','Carpet','Carpet_Apt_01.prefab','width',2.4,100),
('wall_art','Apt_Furniture_01.fbx','Canvas_Painting_01','Canvas_Painting_01.prefab','height',0.8,200),
]
material_cache={};image_cache={};report=[]
def prefab_materials(prefab):
 candidates=list(STAGE.rglob(prefab));result={}
 if not candidates:return result
 text=candidates[0].read_text(errors='replace');sections=re.split(r'^--- !u!',text,flags=re.M);names={}
 for section in sections:
  if section.startswith('1 '):
   ident=re.search(r'^1 &(-?\d+)',section);name=re.search(r'^  m_Name: (.+)$',section,re.M)
   if ident and name:names[ident[1]]=name[1].strip()
 for section in sections:
  if section.startswith('23 '):
   go=re.search(r'm_GameObject: \{fileID: (-?\d+)\}',section);materials=re.search(r'm_Materials:\n((?:  - .+\n)+)',section)
   if go and materials:result[names.get(go[1],'')]=re.findall(r'guid: ([a-f0-9]+)',materials[1])
 return result

def material(guid,object_name):
 key=guid or object_name.split('.')[0]
 if key in material_cache:return material_cache[key]
 src=byguid.get(guid);text=src.read_text(errors='replace') if src and src.exists() else ''
 tex=re.search(r'- _MainTex:\s*\n\s*m_Texture: \{[^}]*guid: ([a-f0-9]+)',text)
 if not tex:tex=re.search(r'- _BaseMap:\s*\n\s*m_Texture: \{[^}]*guid: ([a-f0-9]+)',text)
 color=re.search(r'- _Color: \{r: ([\d.e-]+), g: ([\d.e-]+), b: ([\d.e-]+), a: ([\d.e-]+)',text)
 mat=bpy.data.materials.new('apt_'+key[:24]);mat.use_nodes=True;bsdf=mat.node_tree.nodes.get('Principled BSDF')
 bsdf.inputs['Roughness'].default_value=1;bsdf.inputs['Metallic'].default_value=0;bsdf.inputs['Specular IOR Level'].default_value=0
 tint=tuple(float(v) for v in color.groups()) if color else (0.46,0.43,0.36,1)
 if not src:
  lower=object_name.lower();tint=(0.13,0.15,0.14,1) if any(s in lower for s in ['screen','wheel','stand','feet']) else (0.42,0.39,0.32,1)
 bsdf.inputs['Base Color'].default_value=tint
 if tex and tex[1] in byguid:
  im_path=byguid[tex[1]]
  if tex[1] not in image_cache:
   im=bpy.data.images.load(str(im_path),check_existing=False);im.scale(256,256);im.filepath_raw=str(OUT/(tex[1]+'.png'));im.file_format='PNG';im.save();image_cache[tex[1]]=im
  node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=image_cache[tex[1]];node.interpolation='Closest';mat.node_tree.links.new(node.outputs['Color'],bsdf.inputs['Base Color'])
  # Preserve source tiling when Unity supplies a repeating fabric/wood material.
  scale=re.search(r'- _MainTex:\s*\n\s*m_Texture:[^\n]*\n\s*m_Scale: \{x: ([\d.e-]+), y: ([\d.e-]+)\}',text)
  if scale and (float(scale[1])!=1 or float(scale[2])!=1):
   uv=mat.node_tree.nodes.new('ShaderNodeTexCoord');mapping=mat.node_tree.nodes.new('ShaderNodeVectorMath');mapping.operation='MULTIPLY';mapping.inputs[1].default_value=(float(scale[1]),float(scale[2]),1);mat.node_tree.links.new(uv.outputs['UV'],mapping.inputs[0]);mat.node_tree.links.new(mapping.outputs[0],node.inputs['Vector'])
 material_cache[key]=mat;return mat

bpy.ops.wm.read_factory_settings(use_empty=True)
for name,filename,root_name,prefab,axis,target,budget in recipes:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 source=next(STAGE.rglob(filename));bpy.ops.import_scene.fbx(filepath=str(source),use_image_search=False)
 obj=bpy.data.objects.get(root_name) if root_name else None
 parts=[o for o in ([obj]+list(obj.children_recursive) if obj else list(bpy.context.scene.objects)) if o and o.type=='MESH']
 if root_name and not obj:raise RuntimeError('Missing '+root_name)
 materials=prefab_materials(prefab)
 turn=Matrix.Identity(4)
 coords=[turn@o.matrix_world@v.co for o in parts for v in o.data.vertices];lo=Vector(tuple(min(v[i] for v in coords) for i in range(3)));hi=Vector(tuple(max(v[i] for v in coords) for i in range(3)))
 horizontal_axis='depth' if axis=='depth' else 'width'
 if (horizontal_axis=='width' and hi.x-lo.x<hi.y-lo.y) or (horizontal_axis=='depth' and hi.x-lo.x>hi.y-lo.y):turn=Matrix.Rotation(math.pi/2,4,'Z')@turn
 world={o:[turn@o.matrix_world@v.co for v in o.data.vertices] for o in parts};coords=[v for vs in world.values() for v in vs];lo=Vector(tuple(min(v[i] for v in coords) for i in range(3)));hi=Vector(tuple(max(v[i] for v in coords) for i in range(3)))
 factor=target/(hi-lo)[{'width':0,'depth':1,'height':2}[axis]];origin=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z));total=sum(sum(len(f.vertices)-2 for f in o.data.polygons) for o in parts)
 for o in parts:
  obj_name=o.name;o.parent=None;o.matrix_world=Matrix.Identity(4)
  for v,p in zip(o.data.vertices,world[o]):v.co=(p-origin)*factor
  for f in o.data.polygons:f.use_smooth=False
  guids=materials.get(obj_name,[]);o.data.materials.clear()
  o.data.materials.append(material(guids[0] if guids else '',obj_name))
  tris=sum(len(f.vertices)-2 for f in o.data.polygons);allocation=max(24,int(budget*tris/max(1,total)))
  if tris>allocation:
   bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('PS2 reduction','DECIMATE');mod.ratio=allocation/tris;bpy.ops.object.modifier_apply(modifier=mod.name)
 bpy.ops.object.select_all(action='DESELECT')
 for o in parts:o.select_set(True)
 bpy.context.view_layer.objects.active=parts[0]
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False)
 dims=(hi-lo)*factor;triangles=sum(sum(len(f.vertices)-2 for f in o.data.polygons) for o in parts)
 report.append({'asset':name,'source_model':str(source.relative_to(STAGE)),'source_object':root_name,'prefab':prefab,'dimensions':[dims.x,dims.z,dims.y],'triangles':triangles,'texture_limit':256})
 print('EXPORTED',name,'parts',len(parts),'triangles',triangles,'dimensions',tuple(dims),flush=True)
(OUT/'manifest.json').write_text(json.dumps({'package':index['source'],'package_sha256':hashlib.sha256(Path(index['source']).read_bytes()).hexdigest(),'assets':report,'adaptation':'Original furniture and UVs retained; flat shading, matte materials, 256-pixel source albedos, bounded triangle counts. Source package unchanged.'},indent=2)+'\n')
