extends SceneTree
func _initialize():
	call_deferred("check_game")
func check_game():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.state = "play"
	for i in range(3):
		game.player = game.parts[i]
		game._process(0.016)
	assert(game.found.count(true) == 3, "Parts must be collected")
	game.player = game.HOME
	Input.action_press("ui_accept")
	var press = InputEventKey.new()
	press.keycode = KEY_SPACE
	press.pressed = true
	game.cooldown = 0
	game._unhandled_key_input(press)
	assert(game.cooldown == 6, "Pulse cooldown")
	game.health = 0
	game._process(0.016)
	assert(game.state == "lost", "Loss state")
	game.reset_game()
	assert(game.health == 100 and game.found.count(true) == 0, "Restart")
	game.state = "play"
	game.found.fill(true)
	game.player = game.HOME
	var interact = InputEventKey.new()
	interact.physical_keycode = KEY_E
	interact.pressed = true
	Input.parse_input_event(interact)
	Input.flush_buffered_events()
	game._process(4.1)
	assert(game.state == "won", "Rescue ending")
	interact.pressed = false
	Input.parse_input_event(interact)
	print("PASS: collection, pulse, loss, restart, rescue ending")
	game.queue_free()
	await process_frame
	quit()

