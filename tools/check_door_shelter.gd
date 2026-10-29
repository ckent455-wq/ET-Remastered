extends SceneTree
var g
func _initialize():call_deferred("run")
func require(condition:bool,message:String):
 if not condition:
  push_error(message);quit(1)
  assert(condition,message)
func focus_clinic(inside:bool):
 var town=g.town
 g.player.global_position=town.buildings.clinic.to_global(Vector3(0,.04,3.7 if inside else 6.3))
 g.player.rotation=Vector3.ZERO;g.camera.position=Vector3(0,g.STANDING_EYE,0)
 g.camera.look_at(town.actions.clinic_door.area.global_position);g.camera.make_current()
 for i in 3:await physics_frame
 town.refresh_focus()
 require(town.focus_action=="clinic_door","Test camera must face clinic door")
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.set_process_input(false)
 g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 g.reset_game();g.crash_site.leave_seat_for_testing();g.crash_site.wake_phase="";g.set_state("play")
 var town=g.town;var e=g.enemies;var d=e.creatures[0];var original_spawn:Vector3=d.spawn
 await focus_clinic(false)
 town.door_locks.toggle(town)
 require(not town.shelter_locks.get("clinic",false),"Cannot lock from outside")
 town.set_building_door("clinic",true,false,true)
 await focus_clinic(true)
 town.door_locks.toggle(town)
 require(town.shelter_locks.get("clinic",false) and not town.doors.clinic.open,"Inside lock closes and bolts door")
 require(not town.set_building_door("clinic",true,false,false,true),"Monster cannot open bolted door")
 require(not town.set_building_door("clinic",true),"NPC cannot open bolted door")
 town.perform("clinic_door")
 require(not town.doors.clinic.open,"E cannot bypass the bolt")
 d.actor.global_position=town.buildings.clinic.to_global(Vector3(0,.04,6.25))
 d.state="chase";d.pursuing=true;d.target=g.player.global_position;d.hidden_time=0.0
 for i in 3:await physics_frame
 require(not e.pursuit.visible(e,d),"Closed door blocks monster sight")
 for i in 8:
  e.door_encounter.update(e,d,1.0)
 require(not town.doors.clinic.open,"Repeated pounding cannot break inside lock")
 var hp:float=d.hp
 d.hidden_time=19.5;e.pursuit.update(e,d,.6)
 require(d.state=="returning_home" and not d.pursuing,"Hidden player is forgotten after twenty seconds")
 require(d.hp==hp,"Forgetting never heals or respawns a monster")
 require(d.actor.global_position.distance_to(e.to_global(original_spawn))>5,"Return does not teleport to spawn")
 for i in 45:await physics_frame
 await focus_clinic(true)
 town.door_locks.toggle(town)
 require(not town.shelter_locks.get("clinic",false),"Inside lock can be released")
 d.state="chase";d.pursuing=true;d.actor.global_position=town.buildings.clinic.to_global(Vector3(0,.04,6.25))
 e.door_encounter.clear_attempt(d)
 for i in 8:
  e.door_encounter.update(e,d,1.0)
 require(town.doors.clinic.open,"Unlocked closed door can be forced by monster")
 for i in 3:await physics_frame
 d.state="chase";d.hidden_time=19.5;e.pursuit.update(e,d,.1)
 require(d.hidden_time==0.0 and d.pursuing,"Seeing player resets hiding countdown")
 # Walk a short outdoor route home, rather than teleporting or resuming pursuit.
 d.actor.global_position=town.buildings.clinic.to_global(Vector3(0,.04,7.0))
 d.spawn=e.to_local(town.buildings.clinic.to_global(Vector3(0,.04,10.0)))
 e.pursuit.forget(e,d)
 g.player.global_position=Vector3(100,0,100)
 var start_distance:float=d.actor.global_position.distance_to(e.to_global(d.spawn))
 for i in 600:
  await physics_frame
  e.pursuit.update(e,d,1.0/60.0)
  if d.state=="guarding_spawn":break
 require(d.actor.global_position.distance_to(e.to_global(d.spawn))<start_distance-1.5,"Monster walks back toward its spawn")
 require(d.state=="guarding_spawn" and not d.pursuing,"Arriving home waits at spawn")
 await focus_clinic(false)
 d.actor.global_position=town.buildings.clinic.to_global(Vector3(0,.04,7.5))
 e.pursuit.update(e,d,.1)
 require(d.pursuing and d.state in ["chase","attack"],"Returned monster reacquires visible player")
 d.spawn=original_spawn
 var room=town.actions.hotel_room_0
 var room_frame:Node3D=g.hotel_upper.room_hinges[0].get_parent()
 g.player.global_position=room_frame.to_global(Vector3(0,.04,1.0))
 require(town.door_locks.inside(town,room),"Guest-room lock recognizes room side")
 g.player.global_position=room_frame.to_global(Vector3(0,.04,-1.0))
 require(not town.door_locks.inside(town,room),"Guest-room corridor cannot operate inside bolt")
 g.set_state("play")
 d.actor.global_position=room_frame.to_global(Vector3(0,.04,-1.2))
 d.state="chase";d.pursuing=true;d.special_effort=0.0;d.special_door=""
 town.shelter_locks["room_0"]=true
 g.hotel_upper.room_open[0]=false
 for i in 6:e.pursuit.special_door(e,d,room_frame.to_global(Vector3(0,.04,1.2)),1.0)
 require(not g.hotel_upper.room_open[0],"Locked guest room blocks monster entry")
 town.shelter_locks["room_0"]=false
 for i in 6:e.pursuit.special_door(e,d,room_frame.to_global(Vector3(0,.04,1.2)),1.0)
 require(g.hotel_upper.room_open[0],"Monster forces unlocked guest-room door")
 town.set_building_door("clinic",false,false,true)
 g.hotel_upper.room_open[0]=false
 g.hotel_upper.room_colliders[0].set_deferred("disabled",false)
 town.shelter_locks={"clinic":true,"chapel":true,"room_0":true}
 var snapshot=g.saves.backend.capture()
 require(snapshot.town.shelter_locks.clinic,"Save captures inside locks")
 require(g.saves.backend.valid(snapshot),"New save validates")
 g.saves.backend.apply(snapshot)
 require(town.shelter_locks.get("clinic",false),"Loading restores inside locks")
 require(not town.doors.clinic.open,"Loaded locked door remains closed")
 snapshot.town.erase("shelter_locks")
 require(g.saves.backend.valid(snapshot),"Older save without lock data validates")
 g.saves.backend.apply(snapshot)
 require(town.shelter_locks.is_empty(),"Older saves start with inside bolts released")
 print("PASS: inside-only locks, close-and-lock, player/NPC/monster barriers, unlocked forced entry, hiding timeout, physical return, reacquisition and save compatibility")
 quit()
