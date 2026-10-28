extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process_input(false);g.controller.set_process(false)
 while not g.has_node("LocalZombiePreview"):await process_frame
 var p=g.get_node("LocalZombiePreview")
 for variant in 3:
  p.variant=variant;p.show_variant()
  for i in 20:await process_frame
  p.animation.advance(.5);g.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("C:/Users/jkern/Documents/Codex/2026-10-16/go-x20/outputs/zombie-preview-%d.png" % (variant+1))
 print("PASS: three in-game zombie preview renders saved")
 quit()
