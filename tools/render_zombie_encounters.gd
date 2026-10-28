extends SceneTree
var g
func _initialize():call_deferred("run")
func snap(label):
 for i in 8:await process_frame
 g.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("C:/Users/jkern/Documents/Codex/2026-10-16/go-x20/outputs/zombie-encounter-"+label+".png")
func frame_enemy(d):
 g.player.global_position=d.actor.global_position+Vector3(0,.02,3)
 g.player.global_position.y=maxf(g.player.global_position.y,g.town.streetscape.chapel_hill.terrain_height_at(g.player.global_position)+.03)
 g.player.rotation=Vector3.ZERO;g.camera.position=Vector3(0,g.STANDING_EYE,0)
 g.camera.look_at(d.actor.global_position+Vector3.UP*1.0);g.camera.make_current();g.flashlight.show();g.message=""
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.set_process_input(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.story.clinic_rescue_done=true;g.health=100;g.set_state("play")
 var e=g.enemies
 for data in e.creatures:data.actor.hide();data.actor.collision_layer=0
 for entry in [[0,"chapel"],[3,"workshop"],[6,"cemetery"]]:
  var d=e.creatures[entry[0]];e.reset_creature(d);d.actor.show();d.actor.collision_layer=1;d.actor.rotation=Vector3.ZERO;d.state="chase"
  d.animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
  e.play(d,"walk1");d.animation.seek(.7,true);d.animation.advance(0)
  frame_enemy(d);await snap(entry[1])
  if entry[0]==3:
   e.shoot(3,10000);d.animation.seek(d.animation.current_animation_length,true);d.animation.advance(0)
   g.camera.look_at(d.actor.global_position+Vector3.UP*.35);await snap("death")
  d.actor.hide();d.actor.collision_layer=0
 print("PASS: actual chapel, workshop, cemetery and death-pose renders saved")
 quit()


