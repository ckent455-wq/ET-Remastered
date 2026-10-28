extends SceneTree
var g
func _initialize():call_deferred("run")
func snap(label:String,feet:Vector3,target:Vector3):
 var h=g.hotel_upper;g.player.global_position=h.to_global(feet);g.player.rotation=Vector3.ZERO;g.camera.position=Vector3(0,g.STANDING_EYE,0);g.camera.look_at(h.to_global(target));g.camera.make_current();g.flashlight.show();g.hud.hide();g.backpack.hide()
 for i in 10:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("C:/Users/jkern/Documents/Codex/2026-10-16/go-x20/outputs/hotel-elevator-"+label+".png")
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.set_process(false);g.set_process_input(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 g.hotel_upper.set_physics_process(false);g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.health=100;g.set_state("play")
 await snap("lobby",Vector3(-2.25,.03,.5),Vector3(-4.3,1.45,-2.2))
 await snap("cab",Vector3(-4.3,.03,-2.9),Vector3(-4.0,1.55,-4.65))
 var h=g.hotel_upper;h.floor_index=1;h.cab.position.y=h.UPPER;h.sync_doors()
 await snap("landing",Vector3(-4.3,h.UPPER,-1.25),Vector3(.15,5.3,-1.25))
 await snap("corridor",Vector3(0,h.UPPER,-3.7),Vector3(0,5.3,3.8))
 h.room_open=[true,true,true]
 for i in 60:h._physics_process(1.0/60)
 await snap("room",Vector3(-3.35,h.UPPER,-.35),Vector3(-4.0,4.8,3.6))
 await snap("trim",Vector3(.45,h.UPPER,.85),Vector3(-2.8,3.95,-1.35))
 await snap("corner",Vector3(0,h.UPPER,-1.15),Vector3(-1.17,5.2,.25))
 print("PASS: hotel elevator visual previews saved");quit()
