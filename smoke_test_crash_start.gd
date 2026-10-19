extends SceneTree
func _initialize():
	call_deferred("check")
func move_key(pressed: bool):
	var key = InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = pressed
	Input.parse_input_event(key)
	Input.flush_buffered_events()
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.set_state("play")
	assert(game.player.position.distance_to(game.START_POSITION)<0.05,"Starts beside the accident")
	assert(game.crash_site.wreck.get_child_count()>3,"Downloaded car and crash dressing")
	assert(game.weapons.selected== -1 and game.weapons.magazines==[0,0,0] and not game.weapons.owned.has(true),"Starts unarmed without ammo")
	for index in range(3):
		game.weapons.equip(index)
		assert(game.weapons.selected== -1 and not game.weapons.owned.has(true),"Cannot bypass gun discovery using number keys; unarmed attacks use fists")
	assert("Reach Blackwood" in game.town.objective(),"Crash-to-town first objective")
	game.player.rotation.y = 0
	move_key(true)
	for frame in range(850):
		await physics_frame
		if game.player.position.z< -39:
			break
	move_key(false)
	assert(game.player.position.z< -39 and game.town.reached_town,"Actual walk from wreck into Blackwood is unobstructed")
	assert(game.weapons.selected== -1,"Reaching town does not grant a free weapon")
	var area = game.town.actions.weapon_pistol.area
	game.player.position = game.town.buildings.ranger.to_global(Vector3(-1.9,0.001,4.1))
	game.camera.look_at(area.global_position)
	await physics_frame
	game.town.refresh_focus()
	assert(game.town.focus_action=="weapon_pistol","Pistol pickup reachable with crosshair")
	var interact = InputEventKey.new()
	interact.keycode = KEY_E
	interact.pressed = true
	game._unhandled_input(interact)
	assert(game.weapons.owned[0] and game.weapons.selected==0 and not area.visible,"E discovers and equips pistol")
	game.weapons.magazines[0] -= 1
	game.town.perform("weapon_pistol")
	assert(game.weapons.magazines[0]==2,"Repeated pickup cannot duplicate ammo")
	game.reset_game()
	assert(game.player.position==game.START_POSITION and not game.town.reached_town,"New journey restores crash opening")
	assert(not game.weapons.owned.has(true) and game.weapons.selected== -1 and area.visible and area.collision_layer==2,"Weapon discovery resets")
	print("PASS: downloaded wreck, unarmed crash start, no weapon shortcut, real walk into town, actual E pistol pickup, no duplicate ammo, restart")
	game.queue_free()
	await process_frame
	quit()
