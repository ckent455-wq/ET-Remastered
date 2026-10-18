extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.state = "play"
	assert(not "parts" in game and not "found" in game,"Ship-part collection removed")
	assert(not "beam" in game and not "pulse" in game,"Alien beacon and pulse removed")
	assert(not "drones" in game,"Drones removed")
	assert(game.player.position==game.START_POSITION and game.weapons.selected== -1,"Unarmed crash-site start")
	game.town.perform("ranger_drawer")
	game.town.perform("store_drawer")
	game.town.perform("battery_panel")
	game.town.perform("workshop_cabinet")
	game.town.perform("receiver")
	game.player.position = game.town.buildings.radio.to_global(Vector3(-2.7,0.001,-2.0))
	game.update_contact(4.1,true)
	assert(game.state=="won","Rescue ending")
	game.reset_game()
	game.state = "play"
	game.health = 0
	game._physics_process(0.016)
	assert(game.state=="lost","Defeat")
	game.reset_game()
	assert(game.health==100 and not game.town.radio_ready,"Restart")
	game.state = "play"
	game.player.position = Vector3(0,0.1,4)
	game.hud.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview-first-person.png")
	print("PASS: 3D scene, human crash-site start, no alien mechanics, radio rescue, defeat, restart")
	game.queue_free()
	await process_frame
	quit()
