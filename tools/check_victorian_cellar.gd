extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 while not g.surface_details.completed:await process_frame
 g.set_physics_process(false);g.enemies.set_physics_process(false)
 g.crash_site.wake_phase="";g.state="play"
 var cellar=g.victorian_house.cellar
 var dressing=cellar.get_node("AbandonedLaundryAndStorage")
 assert(dressing.get_node("Cellar_archBrick").find_children("*","StaticBody3D",true,false).size()>0,"Masonry opening has real collision")
 g.player.global_position=cellar.to_global(Vector3(0,0.02,1.2))
 g.player.velocity=Vector3.ZERO
 await physics_frame;await physics_frame
 assert(not g.player.test_move(g.player.global_transform,cellar.global_basis*Vector3(0,0,-3.6)),"Standing player can pass beneath the arch to the breach")
 g.fog_atmosphere.update_fog(1)
 assert(g.camera.environment==g.fog_atmosphere.cellar_environment,"Victorian cellar uses indoor darkness")
 assert(not g.camera.environment.fog_enabled,"Outdoor fog cannot wash out the cellar")
 for x in [-2.7,2.7]:
  var ray=PhysicsRayQueryParameters3D.create(cellar.to_global(Vector3(x,1,0.2)),cellar.to_global(Vector3(x,1,-1)),1)
  assert(not g.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"Side masonry creates separate storage bays")
 print("PASS: modular cellar bays, open central chase route, solid side walls and indoor darkness")
 g.queue_free();await process_frame;quit()
