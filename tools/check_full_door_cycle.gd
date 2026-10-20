extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.controller.set_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 g.state="play";g.crash_site.has_backpack=true
 var t=g.town;t.inventory.station_key=1
 await create_timer(0.1).timeout
 for id in t.doors:
  var d=t.doors[id];var building=d.hinge.get_parent()
  for step in range(4):
   var local_z=5.8 if step in [0,3] else 4.2
   g.player.global_position=building.to_global(Vector3(0,0,local_z))
   g.camera.global_position=building.to_global(Vector3(0,1.65,local_z))
   await physics_frame
   g.camera.look_at(d.area.global_position)
   t.refresh_focus()
   assert(t.focus_action==id+"_door","Prompt reachable on step "+str(step)+" "+id)
   t.interact();await create_timer(0.6).timeout
   assert(d.open==(step in [0,2]),"Full enter-close-exit-close cycle: "+id)
  print("DOOR CYCLE PASSED ",id)
 print("FULL DOOR CYCLE CHECK PASSED")
 g.queue_free();await process_frame;quit()
