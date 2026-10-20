extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.controller.set_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 g.state="play"
 var car=g.crash_site
 var eye=car.wreck.to_global(Vector3(0,1.6,3.25))
 await create_timer(0.1).timeout
 g.camera.global_position=eye;g.camera.look_at(car.tutorial_areas.crash_rear_hatch.global_position)
 g.town.refresh_focus();assert(g.town.focus_action=="crash_rear_hatch","Closed hatch reachable")
 g.town.interact();await create_timer(0.8).timeout
 assert(car.hatch_open and not car.door_open)
 for id in ["crash_backpack","crash_flashlight"]:
  var target=car.tutorial_areas[id]
  g.camera.global_position=eye;g.camera.look_at(target.global_position)
  await physics_frame
  g.camera.look_at(target.global_position);g.town.refresh_focus()
  print("TRUNK AIM ",id," -> ",g.town.focus_action)
  assert(g.town.focus_action==id,"Crosshair selects trunk gear")
  g.town.interact();await physics_frame
 assert(car.tutorial_complete() and not car.has_detour_sheet,"Detour sheet is optional")
 var paper=car.tutorial_areas.crash_record
 assert(paper.collision_layer==2 and car.detour_visual.visible)
 g.camera.global_position=eye;g.camera.look_at(paper.global_position)
 g.town.refresh_focus();assert(g.town.focus_action=="crash_record")
 g.town.interact();await physics_frame
 assert(car.has_detour_sheet and not car.detour_visual.visible)
 car.reset();await physics_frame
 assert(not car.hatch_open and not car.tutorial_complete())
 for id in ["crash_backpack","crash_flashlight","crash_record"]:assert(car.tutorial_areas[id].collision_layer==0)
 print("TRUNK PICKUPS CHECK PASSED")
 g.queue_free();await process_frame;quit()
