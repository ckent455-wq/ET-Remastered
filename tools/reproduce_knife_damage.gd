extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false);g.weapons.set_physics_process(false);g.knife.set_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 g.set_process(false)
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.state="play";g.crash_site.has_backpack=true;g.knife.collect()
 for data in g.enemies.creatures:data.actor.hide();data.actor.collision_layer=0
 var d=g.enemies.creatures[0];g.enemies.reset_creature(d);d.state="chase"
 g.player.rotation=Vector3.ZERO;g.player.global_position=Vector3(0,.02,-48);g.camera.position=Vector3(0,g.STANDING_EYE,0);g.camera.rotation=Vector3.ZERO
 g.weapons.enemy_hitboxes=preload("res://enemy_shot_hitboxes.gd").new(g.enemies)
 for distance in [0.9,1.3,1.5,1.7]:
  d.actor.global_position=Vector3(0,.02,-48-distance)
  await physics_frame;await physics_frame
  print("HEAD ",g.weapons.enemy_hitboxes.head_center(d)," EYE ",g.camera.global_position)
  for height in [0.0,0.2,0.4]:
   var ray=g.weapons.trace_shot(g.camera.global_position-Vector3.UP*height,Vector3.FORWARD,g.knife.REACH,g.knife.HIT_RADIUS)
   print("TRACE ",height," ",ray)
  print("STATE ",g.state," ",d.state," CAMERA ",g.camera.global_basis)
  var before=d.hp;g.knife.strike();print("NORMAL STAB distance=",distance," damage=",before-d.hp)
 quit()






