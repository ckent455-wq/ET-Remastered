extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 g.crash_site.wake_phase="";g.state="play"
 await create_timer(0.15).timeout
 var e=g.enemies;var b=g.hotel_basement;var c=b.get_node("CellarCoffinStacks");c.set_process(false)
 var d=e.creatures[e.TUNNEL_INDICES[2]]
 assert(c.lid.get_child_count()==2 and not c.busted)
 assert(d.actor.global_position.distance_to(c.occupant_spawn())<0.01 and d.actor.collision_layer==0)
 g.player.global_position=b.to_global(Vector3(0,0.02,-6))
 await physics_frame
 var conceal=PhysicsRayQueryParameters3D.create(g.player.global_position+Vector3.UP,d.actor.global_position+Vector3.UP,1,[g.player.get_rid(),d.actor.get_rid()])
 var hit=g.get_world_3d().direct_space_state.intersect_ray(conceal)
 assert(not hit.is_empty() and hit.collider==c.upright,"Closed coffin conceals mummy")
 e._physics_process(0.1);assert(not c.busted and d.state=="tunnel_wait")
 g.player.global_position=b.to_global(Vector3(0,0.02,-3.3));var hp=g.health
 e._physics_process(0.01)
 assert(c.busted and d.state=="coffin_breakout" and c.crack.playing and c.sting.playing and g.health==hp)
 c._process(0.1);assert(c.lid.position!=c.lid_closed.origin)
 g.state="paused";var lid_transform=c.lid.transform;c._process(1);e._physics_process(1)
 assert(c.lid.transform==lid_transform and d.state=="coffin_breakout")
 g.state="play";assert(e.shoot(d.index,24))
 for i in range(55):
  e._physics_process(1.0/60);c._process(1.0/60)
  await physics_frame
 assert(d.actor.collision_layer==1 and d.actor.collision_mask==1,"Early shot cannot leave mummy without collision")
 assert(not c.lid.visible and c.burst_time==1)
 var start=d.actor.global_position
 for i in range(420):
  e._physics_process(1.0/60)
  await physics_frame
 assert(d.actor.global_position.distance_to(start)>1.0 and d.tunnel_waypoint>=2,"Mummy exits coffin and routes around workbench")
 e.shoot(d.index,100);e._physics_process(150);assert(d.state=="dead")
 g.reset_game()
 assert(not c.busted and c.lid.visible and c.lid.transform==c.lid_closed)
 assert(d.state=="tunnel_wait" and d.actor.collision_layer==0 and d.actor.position.is_equal_approx(d.spawn))
 print("PASS: concealed preplaced mummy, room trigger, crack/sting/roar, lid animation, safe windup, pause, shooting during reveal, physical exit path, death and full restart reset")
 quit()
