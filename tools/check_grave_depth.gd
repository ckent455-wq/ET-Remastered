extends SceneTree
func _initialize():call_deferred("check")
func ray(g,a,b):
 var q=PhysicsRayQueryParameters3D.create(a,b,1,[g.player.get_rid()])
 return g.get_world_3d().direct_space_state.intersect_ray(q)
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.grave_dig.set_process(false);g.cemetery_shadow.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 g.crash_site.wake_phase="";g.state="play";g.crash_site.has_backpack=true
 var d=g.grave_dig
 await create_timer(0.15).timeout
 var before=ray(g,d.GRAVE+Vector3(0,2,0),d.GRAVE+Vector3(0,-2,0))
 assert(absf(before.position.y)<0.02,"Undug grave has a solid ground cap")
 g.town.inventory.shovel=1;g.town.focus_action="cemetery_disturbed_grave";g.player.global_position=d.GRAVE+Vector3(0,0,2)
 d.interact_grave();d.update_dig(3.2,true)
 await physics_frame
 var after=ray(g,d.GRAVE+Vector3(0,2,0),d.GRAVE+Vector3(0,-2,0))
 assert(after.position.y< -0.45,"Digging opens a real below-ground cavity")
 for id in ["cemetery_buried_ammo","cemetery_buried_note"]:
  g.player.global_position=d.GRAVE+Vector3(0,0.01,1.6)
  g.camera.position=Vector3(0,g.STANDING_EYE,0)
  g.camera.look_at(g.town.actions[id].area.global_position)
  await physics_frame
  g.town.refresh_focus()
  assert(g.town.focus_action==id,"Buried reward is reachable from the rim: "+id)
 g.player.global_position=d.GRAVE+Vector3(0,0.05,0);g.player.velocity=Vector3.ZERO
 for i in range(50):
  g._physics_process(1.0/60)
  await physics_frame
 assert(g.player.position.y< -0.4 and g.player.position.y> -0.8,"Player stands inside pit without terrain clamp")
 g.jump_queued=true
 var highest=-10.0
 for i in range(30):
  g._physics_process(1.0/60)
  highest=maxf(highest,g.player.position.y)
  await physics_frame
 assert(highest>0.1,"Jump clears the grave rim")
 g.reset_game();await physics_frame
 var restored=ray(g,d.GRAVE+Vector3(0,2,0),d.GRAVE+Vector3(0,-2,0))
 assert(absf(restored.position.y)<0.02 and not d.exposed.visible)
 print("PASS: real cavity, ground cap reset, coffin below ground, rewards reachable, player falls in and can jump above rim")
 quit()
