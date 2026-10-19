extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.crash_site.wake_phase=""
	game.state="play"
	var e=game.enemies
	assert(e.creatures.size()>=6,"Existing creatures plus separate cellar encounter")
	for i in [e.HOUSE_INDEX,e.CELLAR_INDEX]:
		var d=e.creatures[i]
		assert(d.visual.scene_file_path=="res://assets/enemies/wrapper/wrapper.glb","Both house creatures use the new model")
		for clip in ["idle1","walk1","punch","roar"]: assert(d.clips.has(clip),"Original clips mapped to combat")
	for i in range(4): assert(e.creatures[i].visual.scene_file_path=="res://assets/enemies/creep.glb","Other encounters keep their creature")
	var data=e.creatures[e.CELLAR_INDEX]
	var cellar=game.victorian_house.cellar
	game.player.global_position=game.victorian_house.to_global(Vector3(0,0.24,0))
	e._physics_process(0.1)
	assert(data.state=="cellar_wait","Ground floor cannot trigger cellar encounter")
	game.player.global_position=cellar.to_global(Vector3(0,0.01,0.8))
	e._physics_process(0.1)
	assert(data.state=="cellar_wait","Exit landing gives breathing room")
	game.player.global_position=cellar.to_global(Vector3(0,0.01,-0.2))
	await physics_frame
	await physics_frame
	game.health=100
	game.invincible=0
	e._physics_process(0.01)
	assert(data.state=="cellar_rush" and game.health==100,"Separate ambush without instant damage")
	var start:Vector3=data.actor.global_position
	game.state="journal"
	for i in range(5): e._physics_process(0.1)
	assert(data.actor.global_position==start,"Journal pauses encounter")
	game.state="play"
	for i in range(240):
		e._physics_process(1.0/60)
		await physics_frame
	assert(data.actor.global_position.distance_to(start)>1,"Basement creature physically pursues")
	assert(game.health<100,"Basement creature reaches and attacks player")
	assert(absf(cellar.to_local(data.actor.global_position).y)<0.1,"Creature stays on basement floor")
	game.victorian_house.leave_cellar()
	var hp=game.health
	for i in range(30):
		e._physics_process(1.0/60)
		await physics_frame
	assert(game.health==hp and game.victorian_house.cellar_contains(data.actor.global_position),"Escape portal leaves creature behind")
	for i in [e.HOUSE_INDEX,e.CELLAR_INDEX]:
		assert(e.shoot(i,100),"House creatures take normal combat damage")
	for i in range(60): e._physics_process(1.0/60)
	for i in [e.HOUSE_INDEX,e.CELLAR_INDEX]:
		var d=e.creatures[i]
		assert(d.state=="dead" and d.actor.collision_layer==0 and absf(d.visual.rotation.x)>1.4,"Dead model falls and stops blocking")
	e._physics_process(150)
	assert(e.creatures[e.HOUSE_INDEX].state=="dead" and data.state=="dead","House encounters do not respawn")
	game.reset_game()
	assert(e.creatures[e.HOUSE_INDEX].state=="house_wait" and data.state=="cellar_wait" and data.hp==60 and data.visual.rotation==Vector3.ZERO,"New journey restores both encounters")
	print("PASS: two Wrapper models, original animated combat, independent floor triggers, actual basement pursuit and attack, pause, safe escape, death and reset")
	game.queue_free()
	await process_frame
	quit()
