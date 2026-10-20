extends SceneTree
func _initialize():call_deferred("check")
func clear_capsule(g,point):
 var shape=CapsuleShape3D.new();shape.radius=0.3;shape.height=1.85
 var q=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform=Transform3D(Basis.IDENTITY,point+Vector3(0,0.96,0));q.collision_mask=1;q.exclude=[g.player.get_rid()]
 return g.get_world_3d().direct_space_state.intersect_shape(q,8).is_empty()
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 g.crash_site.wake_phase="";g.state="play"
 await create_timer(0.15).timeout
 var b=g.hotel_basement;var stacks=b.get_node("CellarCoffinStacks")
 assert(stacks.coffins.size()==9)
 for c in stacks.coffins:
  var bounds:AABB=c.transform*c.get_meta("local_bounds")
  assert(bounds.position.x> -4.38 and bounds.end.x<4.38 and bounds.position.z> -4.87 and bounds.end.z<4.87,"Coffins remain inside cellar walls")
  assert(bounds.position.y> -0.001 and bounds.end.y<2.8)
  for m in c.get_children():
   if m is MeshInstance3D:assert(m.layers==2 and m.material_override.albedo_texture!=null)
 for z in [-4.5,-3.0,-1.0,1.0,3.5]:assert(clear_capsule(g,b.to_global(Vector3(0,0.02,z))),"Clear central route to hotel door")
 for p in [Vector3(1,0.02,0.9),Vector3(1,0.02,-2.1),Vector3(0,0.02,-3.5)]:assert(clear_capsule(g,b.to_global(p)),"Wrapper route remains open")
 g.player.global_position=b.to_global(Vector3(-2.4,0.02,-3.2));g.camera.position=Vector3(0,g.STANDING_EYE,0)
 g.camera.look_at(g.town.actions.hotel_tunnel_note.area.global_position)
 await physics_frame
 g.town.refresh_focus();assert(g.town.focus_action=="hotel_tunnel_note","Ledger remains accessible")
 print("PASS: nine textured physical coffins, indoor bounds and light layers, clear player/door/Wrapper routes, reachable ledger")
 quit()
