extends SceneTree
var g
func _initialize():call_deferred("run")
func snap(label):
 var camera_transform=g.camera.global_transform
 for i in 10:await process_frame;g.camera.global_transform=camera_transform
 g.hud.queue_redraw();g.hud.objectives.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("C:/Users/jkern/Documents/Codex/2026-10-16/go-x20/outputs/objective-"+label+".png")
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.set_process_input(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.story.clinic_rescue_done=true;g.town.reached_town=true;g.health=100;g.set_state("play");g.camera.make_current()
 g.player.global_position=Vector3(0,.02,-55);g.player.rotation=Vector3.ZERO;g.camera.look_at(Vector3(11.5,1.6,-59))
 g.knife.collect("workshop_knife");g.message="";g.flashlight.hide()
 var r=g.hud.objectives;r.set_process(false);r.reset();r.update_reminder(0)
 await snap("active")
 g.town.townspeople.conversation.greetings.mechanic=true;r.update_reminder(0)
 await snap("complete")
 r.update_reminder(2);r.update_reminder(.2);r.update_reminder(0)
 await snap("next")
 print("PASS: active, checked-off and next-objective renders saved")
 quit()
