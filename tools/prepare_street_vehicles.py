"""Export five distinct low-poly street vehicles from the user's car pack."""
import bpy,json,math
from pathlib import Path
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/vehicles'
source=Path(r'C:\Users\jkern\Downloads\Blend\Blend\FreeCarPack.blend')
bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False)
report=[]
for name,filename,length in [('Classic Car_9','abandoned_classic',4.2),('N Van_10','abandoned_van',4.5),('Pick Up_11','abandoned_pickup',4.4),('Police Car N_4','abandoned_police',4.3),('N_Muscle Car_10','abandoned_muscle',4.1)]:
 car=bpy.data.objects[name]
 parts=[car]+[o for o in car.children_recursive if o.type=='MESH']
 world={o.name:[o.matrix_world@v.co for v in o.data.vertices] for o in parts}
 coords=[p for points in world.values() for p in points]
 low=Vector(tuple(min(p[i] for p in coords) for i in range(3)))
 high=Vector(tuple(max(p[i] for p in coords) for i in range(3)))
 center=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
 scale=length/(high.y-low.y)
 rotation=Matrix.Rotation(math.pi,3,'Z')
 for obj in parts:
  obj.parent=None
  obj.matrix_world=Matrix.Identity(4)
  for vertex,p in zip(obj.data.vertices,world[obj.name]): vertex.co=rotation@((p-center)*scale)
  for face in obj.data.polygons: face.use_smooth=False
  for slot in obj.material_slots:
   material=slot.material
   if not material or not material.use_nodes: continue
   for node in material.node_tree.nodes:
    if node.type=='BSDF_PRINCIPLED':
     node.inputs['Metallic'].default_value=0
     node.inputs['Roughness'].default_value=1
     node.inputs['Emission Strength'].default_value=0
    if node.type=='TEX_IMAGE' and node.image:
     if max(node.image.size)>256: node.image.scale(256,256)
     node.interpolation='Closest'
 bpy.ops.object.select_all(action='DESELECT')
 for obj in parts: obj.select_set(True)
 bpy.context.view_layer.objects.active=car
 bpy.ops.export_scene.gltf(filepath=str(OUT/(filename+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False)
 triangles=sum(sum(len(f.vertices)-2 for f in obj.data.polygons) for obj in parts)
 assert triangles<=4000
 report.append({'source':str(source),'model':name,'asset':filename+'.glb','triangles':triangles,'length_m':length,'texture_limit':256,'adaptation':'intact parked vehicle; centered, flat shaded, matte textures; original unchanged'})
(OUT/'street-vehicles.json').write_text(json.dumps(report,indent=2)+'\n')
print('STREET VEHICLES',json.dumps(report),flush=True)
