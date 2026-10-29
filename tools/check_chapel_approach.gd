extends SceneTree
var g
func _initialize():call_deferred("run")
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.set_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.set_state("play")
 var church=g.find_child("BlackwoodChurch",true,false)
 assert(church!=null,"Chapel missing")
 church.toggle_doors()
 for frame in 60:await physics_frame
 for x in [28.2,29.0,29.8]:
  g.player.global_position=Vector3(x,9.06,-125.9)
  for frame in 150:
   await physics_frame
   g.player.velocity=Vector3(0,-1,-3.5);g.player.move_and_slide()
  assert(g.player.global_position.z < -134.4,"Approach blocked at %s"%g.player.global_position)
  assert(g.player.global_position.y>8.9,"Approach floor dropped")
 print("PASS: three walking lines clear from road through chapel doorway");quit()
