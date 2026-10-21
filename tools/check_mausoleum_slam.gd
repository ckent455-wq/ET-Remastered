extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.controller.set_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 g.cemetery_shadow.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 var c=g.town.cemetery;var b=g.hotel_basement
 c.unlocked=true;c.opened=true;c.door_hinge.rotation.y=PI/2;c.door_collision.set_deferred("disabled",true)
 g.player.global_position=c.crypt.to_global(Vector3(0,0.01,0))
 g.town.perform("cemetery_cellar_key");assert(g.town.inventory.chapel_key==0,"No key pickup from vault")
 var key=g.town.actions.cemetery_cellar_key.area
 assert(b.contains(key.global_position) and b.to_local(key.global_position).z> -5,"Key is at far tunnel chamber")
 g.town.perform("cemetery_coupler")
 assert(c.slam_triggered and c.slamming and not c.opened and g.town.inventory.antenna==1)
 assert("mausoleum" in g.saves.backend.blocked_reason(),"Cannot save halfway through slam")
 await create_timer(0.3).timeout
 assert(not c.slamming and is_zero_approx(c.door_hinge.rotation.y) and not c.door_collision.disabled)
 assert(c.slam_voice.playing and c.slam_voice.volume_db>=3,"Loud impact plays at door contact")
 b.interact("mausoleum_tunnel")
 assert(b.contains(g.player.global_position),"Tunnel remains accessible with front door slammed shut")
 b.interact("hotel_tunnel_return")
 c.interact_door();await create_timer(0.7).timeout
 assert(c.opened and c.unlocked,"Player can reopen door after scare")
 c.slam_shut();assert(c.opened,"Scare only happens once")
 b.interact("mausoleum_tunnel")
 g.town.perform("cemetery_cellar_key");assert(g.town.inventory.chapel_key==0,"Must traverse full tunnel")
 g.player.global_position=b.to_global(Vector3(-1.95,0.01,-0.8))
 g.camera.global_position=g.player.global_position+Vector3(0,1.6,0);g.camera.look_at(key.global_position)
 await physics_frame;await physics_frame
 g.camera.look_at(key.global_position);g.town.refresh_focus()
 assert(g.town.focus_action=="cemetery_cellar_key","Key target matches workbench model")
 g.town.interact();assert(g.town.inventory.chapel_key==1)
 g.reset_game();assert(not c.slam_triggered and not c.slamming and not c.opened and not c.slam_voice.playing)
 assert(not g.town.actions.cemetery_cellar_key.taken and key.visible)
 print("MAUSOLEUM SLAM AND TUNNEL KEY CHECK PASSED")
 g.queue_free();await process_frame;quit()
