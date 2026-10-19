extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	g.set_physics_process(false);g.enemies.set_physics_process(false);g.weapons.set_physics_process(false)
	g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
	var w=g.weapons;var e=g.enemies
	assert(w.collect(0))
	w.enemy_hitboxes=preload("res://enemy_shot_hitboxes.gd").new(e)
	var boxes=w.enemy_hitboxes
	for index in [0,e.HOUSE_INDEX,e.REAPER_INDEX]:
		var d=e.creatures[index]
		d.animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		for pose in ["idle1","walk1","punch"]:
			e.reset_creature(d)
			d.actor.position=Vector3(0,0.02,-57)
			d.actor.rotation=Vector3.ZERO
			d.actor.show();d.actor.collision_layer=1;d.state="chase"
			for shot in range(3):
				d.animation.play(d.clips[pose],0)
				d.animation.seek(d.animation.current_animation_length*0.5,true)
				if index==e.REAPER_INDEX:
					d.clip=pose;e.reaper_encounter.animate(e,d,0)
				var head:Vector3=boxes.head_center(d)
				g.player.position=Vector3(0,0.02,-49)
				g.camera.look_at(head)
				await physics_frame
				var ray=w.trace_shot(g.camera.global_position,(head-g.camera.global_position).normalized(),65)
				assert(not ray.is_empty() and ray.collider==d.actor,"Visible animated head has shootable volume")
				var hp=d.hp
				w.magazines[0]=8;w.delay=0;w.aiming=true
				assert(w.fire() and d.hp==maxf(0,hp-24),"Actual aimed headshot damages "+str(index)+" / "+pose)
			d.actor.hide();d.actor.collision_layer=0
	for gun in [1,2]:
		var target=e.creatures[e.REAPER_INDEX]
		e.reset_creature(target);target.actor.position=Vector3(0,0.02,-57)
		target.actor.show();target.actor.collision_layer=1;target.state="chase"
		target.animation.play(target.clips.idle1,0);target.animation.advance(0)
		target.clip="idle1";e.reaper_encounter.animate(e,target,0)
		g.camera.look_at(boxes.head_center(target))
		w.owned[gun]=true;w.equip(gun);w.magazines[gun]=w.LOADOUT[gun].clip;w.delay=0;w.aiming=true
		await physics_frame
		assert(w.fire() and target.hp<e.HEALTH,"Rifle and shotgun use the animated hitboxes too")
		target.actor.hide();target.actor.collision_layer=0
	w.equip(0)
	# Cover still wins the closest intersection; no shooting heads through walls.
	var d=e.creatures[e.REAPER_INDEX]
	e.reset_creature(d);d.actor.position=Vector3(0,0.02,-57);d.actor.show();d.actor.collision_layer=1;d.state="chase"
	d.animation.play(d.clips.idle1,0);d.animation.advance(0);d.clip="idle1";e.reaper_encounter.animate(e,d,0)
	var head:Vector3=boxes.head_center(d)
	var wall=g.town.box(g,Vector3(0,1.8,-53),Vector3(4,4,0.15),g.town.mats.wood)
	g.camera.look_at(head)
	await physics_frame;await physics_frame
	w.magazines[0]=8;w.delay=0;w.aiming=true
	var hp=d.hp
	assert(w.fire() and d.hp==hp,"Solid wall blocks headshot")
	wall.queue_free();await physics_frame;await physics_frame
	var empty=boxes.trace(g.camera.global_position,Vector3.UP,65)
	assert(empty.is_empty(),"Empty air around enemy is a miss")
	e.shoot(e.REAPER_INDEX,100)
	assert(boxes.trace(g.camera.global_position,(head-g.camera.global_position).normalized(),65).is_empty(),"Dead enemy has no bullet hitbox")
	g.reset_game()
	assert(e.creatures[e.REAPER_INDEX].state=="reaper_wait","Reset keeps hidden creatures unhittable")
	print("PASS: 27 real pistol headshots across three rigs and idle/walk/attack poses, damage, solid cover, misses, dead/hidden guards and reset")
	g.queue_free();await process_frame;quit()
