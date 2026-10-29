extends SceneTree
var g
func _initialize():call_deferred("run")
func snap(label:String,feet:Vector3,target:Vector3):
 var hotel=g.town.buildings.house;g.player.global_position=hotel.to_global(feet);g.player.rotation=Vector3.ZERO;g.camera.position=Vector3(0,g.STANDING_EYE,0);g.camera.look_at(hotel.to_global(target));g.camera.make_current();g.flashlight.show();g.hud.hide();g.backpack.hide()
 for i in 8:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("C:/Users/jkern/Documents/Codex/2026-10-16/go-x20/outputs/hotel-reception-"+label+".png")
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.set_process(false);g.set_process_input(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.health=100;g.set_state("play")
 await snap("lobby",Vector3(.25,.04,3.6),Vector3(3.7,1.35,.1))
 await snap("desk",Vector3(3.7,.04,2.8),Vector3(3.7,1.50,-.6))
 await snap("details",Vector3(3.2,.04,2.3),Vector3(3.7,1.17,1.05))
 await snap("staff",Vector3(0,.04,2.6),Vector3(-.65,1.4,-1.6))
 await snap("staff-trim",Vector3(-3.25,.04,.15),Vector3(.1,.85,-1.6))
 print("PASS: hotel reception previews saved");quit()
