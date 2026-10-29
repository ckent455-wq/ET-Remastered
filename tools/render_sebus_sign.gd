extends SceneTree
var g
func _initialize():call_deferred("run")
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.set_process(false);g.set_process_input(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.health=100;g.set_state("play")
 var sign=g.town.streetscape.sebus.get_parent().get_node("SebusNeonSign")
 sign.set_process(false);sign.set_lit(true)
 for i in 3:
  g.player.global_position=[Vector3(1.5,.04,-79.5),Vector3(1.5,.04,-90.5),Vector3(3.5,2.65,-82.7)][i];g.player.rotation=Vector3.ZERO;g.camera.position=Vector3(0,g.STANDING_EYE,0);g.camera.look_at(sign.global_position+Vector3(0,-.15,0));g.camera.make_current();g.hud.hide();g.backpack.hide()
  for frame in 12:await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("C:/Users/jkern/Documents/Codex/2026-10-16/go-x20/outputs/sebus-neon-%d.png"%i)
 print("PASS: three Sebus neon sign views rendered");quit()
