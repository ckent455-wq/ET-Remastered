extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.state = "play"
	for id in ["ranger_drawer","store_drawer","fuse_panel","workshop_cabinet","cellar_door","radio_tuner","cellar_exit","receiver"]: game.town.perform(id)
	assert(not game.story.county_bypass,"Repair preserves amber repeater routing")
	for id in game.story.RECORDS: game.story.read_evidence(id)
	assert(not game.story.county_bypass,"No magical retuning from reading")
	game.player.position = game.town.buildings.radio.to_global(Vector3(-4.0,0.01,-1.55))
	game.camera.look_at(game.town.actions.radio_bypass.area.global_position)
	await physics_frame
	game.town.refresh_focus()
	assert(game.town.focus_action=="radio_bypass","Physical switch has real targeting")
	var event = InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	game._unhandled_input(event)
	assert(game.story.county_bypass,"Real E selects green county channel")
	game.update_contact(1,true)
	assert(game.contact_progress==0,"Holding switch does not also transmit")
	game.camera.look_at(game.town.actions.receiver.area.global_position)
	await physics_frame
	game.town.refresh_focus()
	game.update_contact(4.1,true)
	assert(game.state=="won" and game.story.ending_title()=="NO SIRENS","Actual routing selects outside response")
	game.reset_game()
	assert(not game.story.county_bypass,"Switch resets with journey")
	print("PASS: real radio bypass targeting/toggle, repair and reading do not reroute, no switch/transmit overlap, county ending and reset")
	game.queue_free()
	await process_frame
	quit()
