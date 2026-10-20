extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 var w=g.hotel_window_figure;w.set_physics_process(false)
 var pane=w.get_node("LitRoomWindow").get_child(0).material_override
 assert(pane.emission_enabled and pane.emission_energy_multiplier>0,"Room is visibly lit behind silhouette")
 g.state="play";g.hud.hide();g.flashlight_model.hide();g.camera.current=true
 g.player.global_position=Vector3(-5,0.02,-36)
 g.camera.global_position=Vector3(-5,1.7,-36);g.camera.look_at(w.window_point)
 await physics_frame
 w._physics_process(0.6)
 assert(w.actor.visible and w.watched_time>0,"Figure visible from approach")
 g.state="pause";w._physics_process(5);assert(not w.vanished,"Pause preserves watcher")
 g.state="play"
 g.camera.global_position=Vector3(0,4,-41.85);g.camera.look_at(w.window_point)
 for i in range(6):await process_frame
 if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
 if not DisplayServer.get_name()=="headless":root.get_texture().get_image().save_png("res://../hotel-watcher-preview.png")
 g.player.global_position=Vector3(0,0.02,-41.85)
 g.camera.global_position=g.player.global_position+Vector3(0,1.7,0);g.camera.look_at(w.window_point)
 await physics_frame
 w._physics_process(0.1)
 assert(w.vanished and not w.actor.visible,"Approaching removes watcher")
 assert(pane.emission_energy_multiplier==0 and w.spill.light_energy==0,"Initial blackout")
 w._physics_process(0.10);assert(w.spill.light_energy>0,"Brief first flash")
 g.state="pause";w._physics_process(2);assert(w.flicker_time<0.11,"Flicker pauses")
 g.state="play"
 w._physics_process(0.10);assert(w.spill.light_energy==0)
 w._physics_process(0.10);assert(w.spill.light_energy>0,"Brief second flash")
 w._physics_process(0.20);assert(w.spill.light_energy==0 and pane.emission_energy_multiplier==0,"Stays dark")
 g.player.global_position=Vector3(-5,0.02,-36);w._physics_process(5)
 assert(w.vanished,"Does not reappear on retreat")
 w.reset();assert(w.actor.visible and not w.vanished and w.watched_time==0 and w.spill.light_energy>0)
 print("HOTEL WATCHER CHECK PASSED")
 g.queue_free();await process_frame;quit()
