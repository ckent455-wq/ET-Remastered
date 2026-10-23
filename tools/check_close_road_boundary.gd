extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false)
 g.reset_game();g.crash_site.wake_phase="";g.state="play"
 await physics_frame;await physics_frame
 var boundary=g.forest_boundary.get_node("InvisibleSouthRoadLimit")
 assert(is_equal_approx(boundary.global_position.z,19.77))
 g.player.global_position=Vector3(0,0.01,18)
 assert(g.player.test_move(g.player.global_transform,Vector3(0,0,4)),"Close road boundary stops movement")
 assert(not g.player.test_move(g.player.global_transform,Vector3(0,0,-2)),"Townward movement stays open")
 var shot=g.weapons.trace_shot(Vector3(0,1.5,18),Vector3.BACK,4)
 assert(shot.is_empty(),"Bullets pass the boundary without floating marks")
 print("PASS: original road limit restored, townward movement clear, bullets ignore barrier")
 quit()
