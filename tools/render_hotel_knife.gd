extends SceneTree
var g
func _initialize():call_deferred("run")
func snap(label):

 g.hud.queue_redraw()
 var camera_transform=g.camera.global_transform
 for i in range(8):
  await process_frame
  g.camera.global_transform=camera_transform
  if label=="hotel-pickup":
   for child in g.camera.get_children():
    if child is Node3D and not child is Light3D:child.hide()
 g.town.refresh_focus();g.hud.queue_redraw();await process_frame
 await RenderingServer.frame_post_draw
 var path="C:/Users/jkern/Documents/Codex/2026-10-16/go-x20/outputs/knife-"+label+".png"
 root.get_texture().get_image().save_png(path);print("RENDER ",path)
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.story.clinic_rescue_done=true;g.health=100;g.hurt_flash=0;g.set_state("play");g.flashlight.visible=true
 g.player.global_position=g.knife.source.global_position+Vector3(-0.25,-1.0,0.9)
 g.camera.global_position=g.knife.source.global_position+Vector3(0,0.8,0.03);g.camera.look_at(g.knife.source.global_position)
 g.town.refresh_focus();g.hud.queue_redraw()
 g.set_process_input(false);g.hud.hide();g.arm_visual.hide();g.set_process(false);g.weapons.set_physics_process(false);g.knife.set_process(false)
 await snap("hotel-pickup")
 g.hud.show();g.set_process(true);g.weapons.set_physics_process(true);g.knife.set_process(true)
 g.knife.collect();g.message=""
 g.camera.look_at(g.camera.global_position+Vector3(0,-0.05,-1))
 await snap("equipped")
 g.knife.set_process(false);g.knife.apply_pose(g.knife.HIT_TIME)
 await snap("stab")
 g.knife.apply_pose(-1);g.knife.set_process(true)
 g.set_state("backpack")
 var entries=g.backpack.pack(g.backpack.counts())
 for i in entries.size():
  if entries[i].id=="knife":g.backpack.selected=i
 g.backpack.queue_redraw()
 await snap("backpack")
 quit()








