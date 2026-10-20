extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 g.reset_game();g.state="play";g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true
 var police=g.weapons.police_car
 assert(police.car!=null and police.door!=null and police.pickup.get_parent()==police.car,"Pistol is inside the actual parked police car")
 assert(not police.door_open and police.pickup.collision_layer==0 and not g.weapons.owned[0],"Closed car starts with an uncollected pistol")
 g.town.perform("weapon_pistol");assert(not g.weapons.owned[0],"Closed door prevents direct pickup")
 g.camera.global_position=police.car.to_global(Vector3(-1.6,1.4,-0.05));g.camera.look_at(police.door_area.global_position)
 await physics_frame;await physics_frame
 g.town.refresh_focus();assert(g.town.focus_action=="police_driver_door","Crosshair can reach the real driver's door outside the car collider")
 g.town.interact();await create_timer(0.8).timeout
 assert(police.can_take() and police.pickup.collision_layer==2,"Door opens before the gun becomes reachable")
 assert(police.cabin_light.visible,"Opening the door lights the fitted cabin")
 var view_start=police.car.to_global(Vector3(-1.12,1.20,0.02))
 var view_end=police.car.to_global(Vector3(-0.1,0.79,-0.43))
 for mesh in police.car.get_child(0).find_children("*","MeshInstance3D",true,false):
  if mesh==police.door or police.door.is_ancestor_of(mesh):continue
  var faces=mesh.mesh.get_faces();var ray_start=mesh.to_local(view_start);var ray_end=mesh.to_local(view_end)
  for i in range(0,faces.size(),3):
   assert(Geometry3D.segment_intersects_triangle(ray_start,ray_end,faces[i],faces[i+1],faces[i+2])==null,"No window backing or body panel remains across the open driver's doorway")
 # Painted hood and trunk use the same atlas colors as glass; they must stay opaque.
 for panel_z in [-1.4,1.5]:
  var panel_hit=false
  for mesh in police.car.get_child(0).find_children("*","MeshInstance3D",true,false):
   if police.door.is_ancestor_of(mesh):continue
   var a=mesh.to_local(police.car.to_global(Vector3(0,1.5,panel_z)))
   var b=mesh.to_local(police.car.to_global(Vector3(0,0.65,panel_z)))
   for surface in range(mesh.mesh.get_surface_count()):
    var material=mesh.get_active_material(surface)
    var vertices=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
    var indices=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX]
    var count=indices.size() if indices!=null and indices.size()>0 else vertices.size()
    for i in range(0,count,3):
     var triangle=[]
     for j in range(3):triangle.append(vertices[indices[i+j] if indices!=null and indices.size()>0 else i+j])
     if Geometry3D.segment_intersects_triangle(a,b,triangle[0],triangle[1],triangle[2])!=null:
      assert(material is StandardMaterial3D and material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,"Hood and trunk panels must remain opaque")
      panel_hit=true
  assert(panel_hit,"Original hood and trunk geometry must still cover the car")
 var model=police.pickup.get_child(1);var lowest=INF
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  var box=(police.car.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
  lowest=minf(lowest,box.position.y)
 assert(absf(lowest-0.536)<0.002,"Pistol lies on the seat after automatic world dressing")
 g.camera.global_position=police.car.to_global(Vector3(1.6,1.4,-0.05));g.camera.look_at(police.pickup.global_position)
 g.town.refresh_focus();assert(g.town.focus_action!="weapon_pistol","Cannot collect through the passenger side")
 g.camera.global_position=police.car.to_global(Vector3(-1.6,1.4,-0.05));g.camera.look_at(police.pickup.global_position)
 g.town.refresh_focus();assert(g.town.focus_action=="weapon_pistol","Aiming through the open driver's door reaches the seat")
 g.town.interact();assert(g.weapons.owned[0] and g.weapons.magazines[0]==3 and not police.pickup.visible,"Taking the gun removes it from the seat and grants only its three loaded rounds")
 g.town.perform("weapon_pistol");assert(g.weapons.magazines[0]==3,"Repeated pickup cannot duplicate ammo")
 g.reset_game();g.state="play";g.crash_site.has_backpack=true
 assert(not police.door_open and not g.weapons.owned[0] and police.pickup.visible and police.pickup.collision_layer==0,"New journey closes the door and restores the gun on the seat")
 assert(not police.cabin_light.visible,"Courtesy light resets with the closed door")
 police.interact();await create_timer(0.2).timeout;g.set_state("paused");await process_frame
 var angle=police.door.rotation.y;await create_timer(0.4).timeout
 assert(is_equal_approx(angle,police.door.rotation.y),"Door animation pauses in menus")
 g.set_state("play");await create_timer(0.8).timeout;assert(police.can_take(),"Door resumes after pause")
 assert("police car" in g.town.townspeople.words("ranger"),"Pat points to the new pistol location")
 print("PASS: original police car door, seated pistol, real aimed door and weapon interactions, closed/opposite-side gating, three rounds, deduplication, pause and reset")
 g.queue_free();await process_frame;quit()
