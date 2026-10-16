extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.reset_game()
	game.set_state("play")
	game.enemies.set_physics_process(false)
	for data in game.enemies.creatures: data.actor.collision_layer = 0
	game.invincible = 999
	game.player.position = Vector3(20.2,9.1,-128)
	game.player.velocity = Vector3.ZERO
	for i in range(30): await physics_frame
	var key = InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	for target in [Vector3(37.8,9,-128),Vector3(20.2,9,-128)]:
		var reached = false
		for frame in range(600):
			var offset = target-game.player.position
			offset.y = 0
			if offset.length()<0.2:
				reached = true
				break
			game.player.rotation.y = atan2(-offset.x,-offset.z)
			var before: float = game.player.position.y
			await physics_frame
			assert(absf(game.player.position.y-before)<0.08,"No collision bump at court edge")
		assert(reached,"Walk across both terrain/court joins without invisible barriers")
	key.pressed = false
	Input.parse_input_event(key)
	print("PASS: actual player walk across both court edges in both directions, smooth eye height and no raised slab collision")
	game.queue_free()
	await process_frame
	quit()
