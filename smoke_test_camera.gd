extends SceneTree
func _initialize():
	call_deferred("check")
func key(pressed: bool):
	var event = InputEventKey.new()
	event.physical_keycode = KEY_W
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.state = "play"
	assert(not "drones" in game and not "drone_voices" in game.soundscape)
	for id in game.town.interiors.containers:
		var storage = game.town.interiors.containers[id]
		var facing: Basis = storage.root.global_basis
		game.player.global_position = storage.root.global_position+facing.z*1.4
		game.player.position.y = 0.01
		game.player.global_basis = facing
		game.player.velocity = Vector3.ZERO
		key(true)
		for frame in range(90):
			await physics_frame
		key(false)
		await physics_frame
		var previous: Vector3 = game.camera.global_position
		# Opening/closing nearby storage must not move the stationary camera.
		game.town.interiors.toggle(id)
		for frame in range(40):
			await physics_frame
			assert(absf(game.camera.position.y-1.25)<0.00001,"Fixed eye height: "+id)
			assert(game.camera.global_position.distance_to(previous)<0.002,"Stable view at storage: "+id)
			previous = game.camera.global_position
		game.town.interiors.toggle(id)
		# Keep walking into the solid storage, with no head bob at contact.
		key(true)
		for frame in range(40):
			await physics_frame
			assert(absf(game.camera.global_position.y-previous.y)<0.002,"Stable blocked eye height: "+id+str(previous)+str(game.camera.global_position))
			previous = game.camera.global_position
		key(false)
		print("CAMERA PASS / ",id)
	print("PASS: steady camera at all 12 containers, storage animation, blocked walking, no drones or drone audio")
	game.queue_free()
	await process_frame
	quit()
