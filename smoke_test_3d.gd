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
	assert(not game.beam.visible,"Rescue beacon waits for town radio calibration")
	assert(not "drones" in game,"Drones removed")
	game.activate_pulse()
	assert(game.pulse==1 and game.cooldown==6,"Cosmetic alien pulse")
	game.player.position = Vector3.ZERO
	game.town.perform("ranger_drawer")
	game.town.perform("store_drawer")
	game.town.perform("fuse_panel")
	game.town.perform("workshop_cabinet")
	game.town.perform("receiver")
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
	print("PASS: 3D scene, no ship parts, pulse, beacon, town-only rescue, defeat, restart")
	game.queue_free()
	await process_frame
	quit()
