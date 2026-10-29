extends SceneTree
var g
func _initialize():call_deferred("run")
func walk(local:Vector3):
 var hotel=g.town.buildings.house;var target=hotel.to_global(local)
 for i in 240:
  await physics_frame
  var direction=target-g.player.global_position;direction.y=0
  if direction.length()<.12:return
  g.player.velocity=direction.normalized()*4+Vector3.DOWN*2;g.player.move_and_slide()
 assert(false,"Reception walking route blocked at "+str(hotel.to_local(g.player.global_position))+" toward "+str(local))
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.set_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.story.clinic_rescue_done=true;g.health=100;g.set_state("play")
 var hotel=g.town.buildings.house
 for id in ["hotel_reception_counter","hotel_reception_key_rack","hotel_reception_chair"]:assert(g.hotel_layout.added_furniture.has(id))
 g.player.global_position=hotel.to_global(Vector3(0,.04,3.3))
 for p in [Vector3(.6,0,2.4),Vector3(3.45,0,2.4)]:await walk(p)
 g.player.rotation=Vector3.ZERO;g.camera.position=Vector3(0,g.STANDING_EYE,0);g.camera.look_at(g.town.actions.house_note.area.global_position);g.camera.make_current();g.town.refresh_focus()
 assert(g.town.focus_action=="house_note","Existing letter remains accessible on the new counter")
 var bounds=g.surface_details.bounds_of(g.town.actions.house_note.area)
 print("LETTER BOUNDS ",bounds," AREA ",g.town.actions.house_note.area.position)
 assert(absf(bounds.position.y-1.1795)<.008,"Letter rests on the counter surface")
 g.hotel_staff.unlocked=true;g.hotel_staff.opened=true;g.hotel_staff.collision.set_deferred("disabled",true);g.hotel_staff._physics_process(1)
 for p in [Vector3(1.35,0,2.4),Vector3(1.35,0,-.25),Vector3(3.1,0,-.25),Vector3(1.35,0,-.25),Vector3(-.3,0,-.5),Vector3(-1.1625,0,-.6),Vector3(-1.1625,0,-2.7),Vector3(-.4,0,-3.5),Vector3(0,0,-2.6),Vector3(3.0,0,-2.6),Vector3(0,0,-2.6),Vector3(-1.1625,0,-2.6),Vector3(-1.1625,0,-.6),Vector3(0,0,-1.25),Vector3(-4.3,0,-1.25)]:await walk(p)
 var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved));g.saves.backend.apply(saved)
 assert(g.hotel_layout.added_furniture.has("hotel_reception_counter"))
 print("PASS: reception geometry, counter letter surface/focus, clerk aisle, kitchen/basement/elevator routes and save/load")
 quit()
