extends RefCounted
## Static dressing stays outside the saved encounter hierarchy.
const PATH="res://assets/psx_house/"

static func surface_material(asset:String)->StandardMaterial3D:
 var model=load(PATH+asset+".glb").instantiate()
 var mesh=model.find_children("*","MeshInstance3D",true,false)[0]
 var mat=mesh.get_active_material(0).duplicate() as StandardMaterial3D
 mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
 mat.albedo_color=Color("a59f8c")
 mat.roughness=0.95
 model.free()
 return mat

static func prop(parent:Node3D,asset:String,p:Vector3,yaw=0.0,factor=1.0,solid=false):
 var model=load(PATH+asset+".glb").instantiate()
 model.name="Cellar_"+asset
 parent.add_child(model)
 model.position=p;model.rotation.y=yaw;model.scale=Vector3.ONE*factor
 var bounds=AABB();var first=true
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  var local_bounds=(model.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
  bounds=local_bounds if first else bounds.merge(local_bounds);first=false
  for i in range(mesh.mesh.get_surface_count()):
   var source=mesh.get_active_material(i)
   if source is StandardMaterial3D:
    var mat=source.duplicate()
    mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
    mat.albedo_color=Color("aaa18d");mat.roughness=0.96
    mesh.set_surface_override_material(i,mat)
 model.position.y-=bounds.position.y*factor
 if solid:
  var body=StaticBody3D.new();model.add_child(body)
  var col=CollisionShape3D.new();var shape=BoxShape3D.new()
  shape.size=bounds.size;col.shape=shape;col.position=bounds.get_center()
  body.add_child(col)
 return model

static func build(house,cellar:Node3D):
 var town=house.town
 var root=Node3D.new();root.name="AbandonedLaundryAndStorage";cellar.add_child(root)
 # Use the authored UVs of the modular panels rather than stretching a texture over boxes.
 for z in [-2.05,2.05]:
  for side in [-1,1]:
   var wall=prop(root,"wallBrick",Vector3(side*5.39,0,z),-side*PI/2)
   wall.scale=Vector3(1.025,0.75,1)
 for x in [-1.775,1.775]:
  var wall=prop(root,"wallBrick",Vector3(x,0,6.0),PI)
  wall.scale=Vector3(0.8875,0.75,1)
  for z in [-2.05,2.05]:
   var ceiling=prop(root,"ceilingConcrete",Vector3(x,2.985,z))
   ceiling.scale=Vector3(0.8875,1,1.025)
 # Masonry separates the rear storage bay while retaining a broad chase opening.
 var arch=prop(root,"archBrick",Vector3(0,0,-2.55))
 arch.scale=Vector3(1.775,0.75,1)
 for mesh in arch.find_children("*","MeshInstance3D",true,false):
  mesh.create_trimesh_collision()
  for col in mesh.find_children("*","CollisionShape3D",true,false):
   if col.shape is ConcavePolygonShape3D:col.shape.backface_collision=true
 # Stone flags meet at real seams; the original floor collider remains continuous.
 for x in [-1.775,1.775]:
  for z in [-2.05,2.05]:
   var tile=prop(root,"floorStone",Vector3(x,0.003,z))
   tile.scale=Vector3(0.8875,1,1.025)
 # Laundry corner: machines and utility storage follow the wall, never the chase lane.
 prop(root,"washingMachine",Vector3(-2.95,0,1.8),PI/2,1.0,true)
 prop(root,"bucket",Vector3(-2.55,0,0.85),0.24,0.85)
 prop(root,"broom",Vector3(-3.3,0,0.25),PI/2,0.92)
 prop(root,"shelves2",Vector3(3.05,0,-2.55),-PI/2,0.88,true)
 # Boxes are supported by shelves or a pallet instead of scattered evenly around the room.
 prop(root,"pallet",Vector3(-2.45,0,-2.2),0.08,0.9,true)
 prop(root,"box",Vector3(-2.7,0.157,-2.35),0.12,1.2)
 prop(root,"box2",Vector3(-2.1,0.157,-2.0),-0.22,0.8)
 prop(root,"box",Vector3(-2.68,0.613,-2.32),-0.06,0.8)
 prop(root,"trashBag",Vector3(-3.05,0,-0.8),0.4,0.65)
 # Tall shelf spacing comes directly from the pack's shelf model.
 prop(root,"paperBag",Vector3(3.03,0.5488,-2.95),0.2,0.7)
 prop(root,"scotch",Vector3(3.03,0.5488,-2.45),0,0.75)
 prop(root,"bucket",Vector3(3.03,0.5488,-1.85),0,0.65)
 prop(root,"ladder",Vector3(-3.05,0,3.0),0.65,1.0,true)
 prop(root,"radiator",Vector3(3.36,0,2.95),0,1.0)
 var leaning=prop(root,"pallet",Vector3(-2.45,0.20,-3.08),0.06,0.85)
 leaning.rotation.x=1.10
 # Reground tilted geometry after rotation so its lowest corner rests on the floor.
 var lowest=INF
 for mesh in leaning.find_children("*","MeshInstance3D",true,false):
  lowest=minf(lowest,((root.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()).position.y)
 leaning.position.y-=lowest
 prop(root,"ceilingLight",Vector3(-1.85,2.884,1.35),0,0.75)
 var glow=town.lamp(root,Vector3(-1.85,2.48,1.35),Color("b6ac8a"),0.32,3.5)
 glow.light_cull_mask=2
 # A displaced chair faces the breach, leaving the central approach and stairs clear.
 prop(root,"chair2",Vector3(2.65,0,1.65),-0.65,0.85,true)
 # Thin uneven puddles catch the flashlight without increasing ambient light.
 var water=town.color_material(Color("292e29"));water.roughness=0.24
 for p in [Vector3(-2.55,0.012,1.1),Vector3(-1.9,0.012,-2.9)]:
  var wet=house.game.mesh_at(root,house.game.cylinder(0.43,0.43,0.006,11),p,water)
  wet.scale.z=0.58
 return root
