extends SceneTree
func _initialize(): call_deferred("check")
func press(game, keycode):
	var event = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	game._unhandled_input(event)
func wheel(game, button):
	var event = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	game._unhandled_input(event)
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	var weapons = game.weapons
	press(game,KEY_V)
	assert(weapons.selected== -1,"No undiscovered guns from cycling")
	weapons.collect(0)
	weapons.collect(2)
	press(game,KEY_V)
	assert(weapons.selected==2,"V skips uncollected rifle")
	var ammunition = weapons.magazines.duplicate()
	wheel(game,MOUSE_BUTTON_WHEEL_DOWN)
	assert(weapons.selected==0,"Forward wrap")
	wheel(game,MOUSE_BUTTON_WHEEL_UP)
	assert(weapons.selected==2,"Reverse wrap")
	weapons.equip(-1)
	press(game,KEY_V)
	assert(weapons.selected==0,"Cycling draws a collected gun from holster")
	weapons.collect(1)
	press(game,KEY_V)
	assert(weapons.selected==1,"Newly obtained rifle enters cycle")
	game.town.perform("ammo_rifle_workshop")
	weapons.magazines[1] = 0
	weapons.reload()
	assert(weapons.reload_remaining>0,"Scavenged rounds start a real reload")
	press(game,KEY_V)
	assert(weapons.selected==2 and weapons.reload_remaining==0,"Cycle cleanly cancels reload")
	assert(weapons.magazines[0]==ammunition[0] and weapons.magazines[2]==ammunition[2],"Cycling preserves ammunition")
	game.state = "journal"
	press(game,KEY_V)
	wheel(game,MOUSE_BUTTON_WHEEL_UP)
	assert(weapons.selected==2,"Journal blocks cycling")
	print("PASS: real V and wheel input, only owned guns, both directions, wrap, holster, newly collected gun, reload cancellation, ammunition conservation, menu guard")
	game.queue_free()
	await process_frame
	quit()
