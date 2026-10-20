extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 g.reset_game();g.crash_site.wake_phase="";g.state="play"
 await physics_frame;await physics_frame
 var cellar=g.victorian_house.cellar
 var breach=cellar.get_node("BreachedCellarBurrow")
 assert(not breach.get_meta("player_accessible") and breach.has_node("DugEarthTunnel"),"Breach has real recessed tunnel geometry")
 var ray=PhysicsRayQueryParameters3D.create(cellar.to_global(Vector3(0,0.72,-3.8)),cellar.to_global(Vector3(0,0.72,-4.38)),1)
 assert(g.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"Foundation has an actual opening, not a black patch over the old wall")
 ray.to=cellar.to_global(Vector3(0,0.72,-5.8))
 var hit=g.get_world_3d().direct_space_state.intersect_ray(ray)
 assert(not hit.is_empty() and hit.collider.name=="CollapsedBurrowBlocker","Visible collapse seals the passage")
 for height in [g.STANDING_HEIGHT,g.CROUCH_HEIGHT]:
  g.player_collider.shape.height=height;g.player_collider.position.y=height/2
  g.player.global_position=cellar.to_global(Vector3(0,0.02,-3.2))
  await physics_frame
  assert(g.player.test_move(g.player.global_transform,cellar.global_basis*Vector3(0,0,-3)),"Neither standing nor crouching can pass through the collapsed tunnel")
 assert("already dead before the signal" in g.town.townspeople.conversation.answer("patients"),"Aubrey distinguishes reanimated dead from her transformed patients")
 assert("burial cloth" in g.town.townspeople.conversation.answer("house"),"Pat links the house breach to burial cloth")
 assert("coffins" in g.town.actions.hotel_tunnel_note.text.to_lower(),"Readable tunnel ledger establishes the dead's origin")
 assert("living residents" in g.story.RECORDS.workshop_record[1],"Workshop record no longer implies every monster was recently alive")
 g.town.perform("hotel_tunnel_note");assert(g.town.journal_entries.any(func(e):return e.id=="hotel_tunnel_note" and "AUBREY" in e.text),"New testimony is readable and journaled")
 print("PASS: actual broken foundation, recessed burrow, visible physical blockage, standing/crouch exclusion, reanimation lore and readable journal evidence")
 g.queue_free();await process_frame;quit()
