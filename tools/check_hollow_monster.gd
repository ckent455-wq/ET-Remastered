extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	g.set_process(false);g.set_physics_process(false);g.controller.set_process(false)
	g.enemies.set_physics_process(false);g.weapons.set_physics_process(false);g.town.townspeople.set_physics_process(false)
	while not g.surface_details.completed:await process_frame
	g.clinic_rescue.set_process(false);g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.state="play"
	var e=g.enemies;var d=e.creatures[e.HOLLOW_INDEX];var cellar=g.town.streetscape.church.basement
	assert(e.creatures.size()==11 and cellar.contains(d.actor.global_position))
	assert(d.hp==168 and d.state=="chapel_wait")
	var bounds=g.surface_details.bounds_of(d.visual)
	assert(bounds.size.y>2.2 and bounds.size.y<2.4 and absf(bounds.position.y-cellar.global_position.y)<0.05)
	assert(bounds.end.y<cellar.global_position.y+3.3,"Head clears ceiling beams")
	for mesh in d.visual.find_children("*","MeshInstance3D",true,false):
		assert(mesh.layers==2,"Cellar monster responds to the flashlight, not outdoor lighting")
		for i in range(mesh.mesh.get_surface_count()):
			var m=mesh.get_active_material(i)
			assert(m.shading_mode==BaseMaterial3D.SHADING_MODE_PER_VERTEX and m.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS and m.roughness==1 and not m.emission_enabled)
			if m.albedo_texture:assert(maxi(m.albedo_texture.get_width(),m.albedo_texture.get_height())<=256)
	for clip in ["idle1","walk1","punch","death"]:assert(d.animation.has_animation(clip))
	var skeleton=d.visual.find_child("Skeleton3D",true,false) as Skeleton3D
	d.animation.play("idle1",0);d.animation.advance(0.4)
	for side in ["L","R"]:
		var hand=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("hand."+side)).origin)
		var shoulder=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("upper_arm."+side)).origin)
		assert(hand.y<shoulder.y-0.6,"Imported rest rotations keep arms hanging naturally")
	g.player.global_position=cellar.to_global(Vector3(0,0.02,1.5))
	await physics_frame;await physics_frame
	e.hollow_encounter.update(e,d,0.1);assert(d.state=="chapel_wait","Arrival on stairs does not immediately attack")
	g.player.global_position=cellar.to_global(Vector3(1.4,0.02,0.3))
	await physics_frame
	e.hollow_encounter.update(e,d,0.1);assert(d.state=="chase" and d.pursuing)
	var before=d.actor.global_position.distance_to(g.player.global_position)
	for i in range(75):
		e.pursuit.update(e,d,1.0/60);e.hollow_encounter.animate(d,1.0/60)
		await physics_frame
	assert(d.actor.global_position.distance_to(g.player.global_position)<before-0.8,"Walks out of hiding without sticking in scenery")
	g.player.global_position=d.actor.global_position+Vector3(0,0,1.0);g.health=100;g.invincible=0
	d.state="chase";d.cooldown=0
	for i in range(80):
		e.pursuit.update(e,d,1.0/60);e.hollow_encounter.animate(d,1.0/60)
		await physics_frame
	assert(g.health<100,"Melee attack actually damages the player")
	d.state="chase";e.play(d,"idle1");d.animation.advance(0.4)
	var boxes=preload("res://enemy_shot_hitboxes.gd").new(e)
	var head=boxes.head_center(d)
	var origin=head+Vector3(0,0,3.0)
	var hit=boxes.trace(origin,(head-origin).normalized(),8)
	assert(not hit.is_empty() and hit.collider==d.actor and hit.zone=="head","Animated head is shootable")
	g.weapons.enemy_hitboxes=boxes;g.weapons.owned[0]=true;g.weapons.equip(0);g.weapons.magazines[0]=8;g.weapons.delay=0;g.weapons.aiming=true
	g.player.global_position=d.actor.global_position+Vector3(0,0,3.0)
	g.camera.global_position=origin;g.camera.look_at(head)
	await physics_frame
	var hp=d.hp
	assert(g.weapons.fire() and d.hp==hp-36,"Real pistol headshot applies headshot damage")
	e.shoot(e.HOLLOW_INDEX,9999);e.hollow_encounter.animate(d,1.5)
	assert(d.state=="dead" and d.actor.collision_layer==0 and d.visual.rotation.x>1.4,"Death falls over and disables collision")
	g.story.repeater.shutdown_done=false;e._physics_process(121)
	assert(d.state=="chapel_wait" and d.hp==168 and absf(d.visual.rotation.x)<0.01,"Two-minute respawn resets the pose")
	var store=g.saves.backend
	var snapshot=store.capture();assert(store.valid(snapshot))
	e.shoot(e.HOLLOW_INDEX,50);snapshot=store.capture();store.apply(snapshot)
	assert(d.hp==118,"New monster health survives save restoration")
	var legacy=snapshot.duplicate(true);legacy.enemies.pop_back();legacy.roots.erase("hollow")
	assert(store.valid(legacy),"Previous saves without the new monster remain compatible")
	store.apply(legacy);assert(d.hp==168 and d.state=="chapel_wait")
	print("PASS: chapel Hollow placement, PS2 materials, reveal, pursuit, attack, real headshot, death, respawn, save round trip and old-save compatibility")
	g.queue_free();await process_frame;quit()
