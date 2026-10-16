extends SceneTree
func _initialize(): call_deferred("check")
func key(code: Key, pressed: bool):
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func frames(count: int):
	for i in range(count): await physics_frame
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.state = "play"
	game.enemies.set_physics_process(false)
	game.town.townspeople.set_physics_process(false)
	game.invincible = 999
	var arena = Vector3(0,10,35)
	game.town.box(game,arena-Vector3(0,0.2,0),Vector3(12,0.4,12),game.town.mats.floor)
	game.player.position = arena+Vector3(0,0.001,0)
	game.player.rotation = Vector3.ZERO
	await frames(10)
	assert(game.player.is_on_floor())
	key(KEY_SPACE,true)
	await frames(4)
	key(KEY_SPACE,false)
	var peak: float = game.player.position.y
	key(KEY_SPACE,true)
	for i in range(65):
		await physics_frame
		peak = maxf(peak,game.player.position.y)
	assert(peak>10.6 and peak<10.9,"Space jumps; repeated midair press cannot double-jump")
	assert(game.player.is_on_floor() and absf(game.player.position.y-10)<0.02,"Holding Space cannot auto-bounce after landing")
	key(KEY_SPACE,false)
	key(KEY_CTRL,true)
	await frames(18)
	assert(game.crouching and is_equal_approx(game.player_collider.shape.height,0.9) and is_equal_approx(game.camera.position.y,0.68),"Ctrl lowers capsule and view")
	assert(absf(game.player.position.y-10)<0.02,"Crouching preserves foot position")
	key(KEY_W,true)
	key(KEY_SHIFT,true)
	await frames(15)
	assert(absf(Vector2(game.player.velocity.x,game.player.velocity.z).length()-2.1)<0.01 and game.stamina==100,"Crouch is slower and overrides sprint")
	key(KEY_W,false)
	key(KEY_SHIFT,false)
	game.player.position = arena+Vector3(0,0.001,0)
	game.player.velocity = Vector3.ZERO
	game.town.box(game,arena+Vector3(0,1.3,0),Vector3(3,0.2,4),game.town.mats.wood)
	await frames(3)
	key(KEY_CTRL,false)
	await frames(20)
	assert(game.crouching and is_equal_approx(game.player_collider.shape.height,0.9) and is_equal_approx(game.camera.position.y,0.68),"Low ceiling prevents standing after Ctrl release")
	key(KEY_SPACE,true)
	await frames(4)
	key(KEY_SPACE,false)
	var low_peak: float = game.player.position.y
	for i in range(30):
		await physics_frame
		low_peak = maxf(low_peak,game.player.position.y)
	assert(low_peak<10.31,"Jump under low ceiling respects head collision")
	key(KEY_W,true)
	await frames(85)
	key(KEY_W,false)
	await frames(15)
	assert(not game.crouching and is_equal_approx(game.player_collider.shape.height,1.5) and is_equal_approx(game.camera.position.y,1.25),"Leaving the overhang safely restores standing")
	game.set_state("journal")
	var p: Vector3 = game.player.position
	key(KEY_SPACE,true)
	key(KEY_CTRL,true)
	await frames(15)
	assert(game.player.position.is_equal_approx(p) and not game.jump_queued and not game.crouching,"Journal blocks jump and stance movement")
	key(KEY_SPACE,false)
	key(KEY_CTRL,false)
	game.set_state("play")
	await frames(10)
	assert(game.player.is_on_floor(),"Resume does not queue a jump")
	key(KEY_CTRL,true)
	await frames(15)
	game.reset_game()
	assert(not game.crouching and not game.jump_queued and game.camera.position.y==1.25 and game.player_collider.shape.height==1.5,"Restart resets stance and vertical motion")
	key(KEY_CTRL,false)
	var cellar = game.town.streetscape.church.basement
	cellar.move_player(cellar.to_global(Vector3(0,0.01,1.5)),0)
	await frames(12)
	var baseline: float = game.player.position.y
	key(KEY_SPACE,true)
	await frames(5)
	key(KEY_SPACE,false)
	var cellar_peak: float = game.player.position.y
	for i in range(55):
		await physics_frame
		cellar_peak = maxf(cellar_peak,game.player.position.y)
	assert(cellar_peak>baseline+0.6 and game.player.is_on_floor() and game.player.position.y< -3.9,"Jump and landing work below world ground in cellar")
	print("PASS: real Space jump, no midair jump/held bounce, crouch feet/view/speed, sprint override, low-ceiling safety and jump collision, safe standing, journal pause, reset, cellar jump")
	game.queue_free()
	await process_frame
	quit()
