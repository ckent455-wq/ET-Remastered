extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	var enemies = game.enemies
	var data = enemies.creatures[0]
	assert(enemies.creatures.size()==3,"Three staged encounters")
	for clip in ["walk1","walk2","idle1","sniff","roar","punch","death"]:
		assert(data.clips.has(clip),"Original animated clip: "+clip)
	game.player.position = Vector3(0,0.01,-56)
	data.actor.position = Vector3(0,0.05,-62)
	data.state = "chase"
	data.memory = 8
	var start = data.actor.position
	for i in range(160): await physics_frame
	assert(data.actor.position.distance_to(start)>1.5,"Creature actually pursues")
	for i in range(180): await physics_frame
	assert(game.health<100 and game.health>=56,"Telegraphed attack with bounded damage")
	game.state = "journal"
	var before: Vector3 = data.actor.position
	var hp = game.health
	for i in range(60): await physics_frame
	assert(data.actor.position.is_equal_approx(before) and game.health==hp,"Journal pauses attacks and movement")
	assert(data.animation.speed_scale==0 and data.voice.stream_paused,"Paused animation and audio")
	game.state = "play"
	game.health = 100
	game.invincible = 0
	data.actor.position = Vector3(0,0.01,-62)
	data.state = "attack"
	data.timer = 1.45
	data.did_hit = false
	game.player.position = Vector3(0,0.01,-58)
	for i in range(60): await physics_frame
	assert(game.health==100,"Stepping out of reach avoids the telegraphed strike")
	# Sight and damage respect building walls.
	data.actor.position = game.town.buildings.store.to_global(Vector3(-6.8,0.01,0))
	game.player.position = game.town.buildings.store.to_global(Vector3(-4,0.01,0))
	await physics_frame
	assert(not enemies.line_clear(data,game.player.global_position+Vector3(0,1,0)),"No vision or melee through walls")
	enemies.set_physics_process(false)
	data.actor.position = Vector3(0,0.01,-61)
	data.actor.rotation.y = 0
	game.player.position = Vector3(0,0.01,-56)
	game.camera.look_at(data.actor.position+Vector3(0,1,0))
	data.hp = enemies.HEALTH
	game.weapons.collect(0)
	game.town.perform("ammo_pistol_store")
	game.weapons.reload()
	game.weapons._physics_process(2)
	game.weapons.equip(0)
	for i in range(4):
		game.weapons.delay = 0
		await physics_frame
		assert(game.weapons.fire(),"Actual gunshot")
	assert(data.hp==0 and data.state=="dead","Actual weapon rays kill creature")
	assert(data.actor.collision_layer==0 and data.clip=="death" and not data.voice.playing,"Death animation, silent corpse, no collision blocker")
	assert(not enemies.shoot(0,10),"Corpse cannot take repeated hits")
	game.reset_game()
	assert(data.hp==enemies.HEALTH and data.state=="lurking" and data.actor.collision_layer==1,"New journey restores hidden enemies")
	enemies.alert_shot(data.spawn+Vector3(3,1,0))
	assert(data.state=="stalking" and data.memory>0,"Nearby gunfire attracts stalking from cover")
	game.player.position = game.START_POSITION
	assert(game.player.position.distance_to(data.spawn)>70,"Opening remains safe and unarmed")
	print("PASS: animated enemies, actual pursuit and telegraphed damage, pause/audio, wall occlusion, actual weapon-ray death, corpse cleanup, reset, safe opening")
	game.queue_free()
	await process_frame
	quit()
