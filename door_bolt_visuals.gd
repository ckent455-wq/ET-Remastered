extends Node
## Cosmetic hardware is excluded from save trees and follows the actual door leaf.
var game
var built=false
var bolts=[]
var steel:StandardMaterial3D
var dark:StandardMaterial3D
func piece(parent:Node3D,p:Vector3,size:Vector3,material:Material)->MeshInstance3D:
 var mesh=MeshInstance3D.new();mesh.mesh=BoxMesh.new();mesh.mesh.size=size
 mesh.material_override=material;mesh.position=p;parent.add_child(mesh);return mesh
func add_bolt(leaf:Node3D,position:Vector3,receiver_parent:Node3D,receiver_position:Vector3,id:String,face:float):
 var mount=Node3D.new();mount.name="InsideDeadbolt";mount.set_meta("runtime_visual_only",true)
 leaf.add_child(mount);mount.position=position
 piece(mount,Vector3.ZERO,Vector3(.26,.18,.018),dark)
 for x in [-.10,.10]:
  for y in [-.06,.06]:piece(mount,Vector3(x,y,face*.014),Vector3(.018,.018,.009),steel)
 for x in [-.06,.07]:piece(mount,Vector3(x,0,face*.035),Vector3(.045,.075,.055),dark)
 var slider=Node3D.new();mount.add_child(slider)
 piece(slider,Vector3.ZERO,Vector3(.25,.035,.035),steel)
 piece(slider,Vector3(-.06,face*.025,face*.04),Vector3(.028,.065,.055),steel)
 var receiver=Node3D.new();receiver.name="DeadboltKeeper";receiver.set_meta("runtime_visual_only",true)
 receiver_parent.add_child(receiver);receiver.position=receiver_position
 piece(receiver,Vector3.ZERO,Vector3(.07,.14,.025),dark)
 piece(receiver,Vector3(0,0,face*.03),Vector3(.06,.065,.055),steel)
 slider.position.x=.12 if game.town.shelter_locks.get(id,false) else 0.0
 bolts.append({"id":id,"slider":slider,"mount":mount,"receiver":receiver})
func build():
 steel=StandardMaterial3D.new();steel.albedo_color=Color("9b9b90");steel.metallic=.75;steel.roughness=.44
 dark=StandardMaterial3D.new();dark.albedo_color=Color("46453e");dark.metallic=.6;dark.roughness=.65
 var town=game.town
 for id in town.doors:
  var door=town.doors[id]
  add_bolt(door.hinge,Vector3(1.62,1.13,-.105),door.hinge.get_parent(),Vector3(1.0,door.hinge.position.y+1.13,door.hinge.position.z-.105),id,-1.0)
 var hotel=game.hotel_upper
 for i in hotel.room_hinges.size():
  add_bolt(hotel.room_hinges[i],Vector3(1.16,1.12,.105),hotel.room_hinges[i].get_parent(),Vector3(.75,1.12,.105),"room_"+str(i),1.0)
 var church=town.streetscape.church
 if church.door_hinges.size()==2:
  add_bolt(church.door_hinges[0],Vector3(1.22,1.13,-.14),church.door_hinges[1],Vector3(-1.35,1.13,-.14),"chapel",-1.0)
 built=true
func _process(delta):
 if not built:
  if not game.surface_details.completed or not game.hotel_upper.ready_layout:return
  build()
 for bolt in bolts:
  var target=.12 if game.town.shelter_locks.get(bolt.id,false) else 0.0
  bolt.slider.position.x=move_toward(bolt.slider.position.x,target,delta*.65) if game.state=="play" else target
