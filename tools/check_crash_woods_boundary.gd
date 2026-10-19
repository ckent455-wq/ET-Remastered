extends SceneTree
func _initialize():call_deferred("check")
func ray(g,a,b):
 var q=PhysicsRayQueryParameters3D.create(a,b,1)
 q.exclude=[g.player.get_rid()]
 return g.get_world_3d().direct_space_state.intersect_ray(q)
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false)
 await physics_frame
 for z in [16.0,0.0,-25.0]:
  var hit=ray(g,Vector3(-5,2,z),Vector3(-10,2,z))
  assert(not hit.is_empty() and hit.collider.name=="CrashWoodsRoadsideLimit")
 assert(ray(g,Vector3(0,2,16),Vector3(0,2,-30)).is_empty(),"Road stays open")
 assert(ray(g,Vector3(0,2,-12),Vector3(8,2,-12)).is_empty(),"Cemetery gate route stays open")
 var south=ray(g,Vector3(-12,2,18),Vector3(-12,2,22))
 assert(not south.is_empty() and south.collider.name=="CrashWoodsSouthReturn")
 var wall=g.forest_boundary.get_node("CrashWoodsRoadsideLimit")
 assert(wall.get_child_count()==1 and wall.get_child(0) is CollisionShape3D,"Boundary has no visible geometry")
 print("PASS: woods blocked behind shoulder, south return closed, road and cemetery access clear, invisible geometry")
 quit()
