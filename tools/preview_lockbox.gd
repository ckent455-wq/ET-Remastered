extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	game.soundscape.toggle_mute()
	var views = [["ranger",Vector3(-2.7,0.05,-1.3),Vector3(-2.7,0.45,-3),"locked"],["ranger",Vector3(-2.7,0.05,-1.3),Vector3(-2.7,0.45,-3),"open"],["house",Vector3(1.9,0.05,-2.3),Vector3(1.9,1.1,-4.23),"fridge-house"],["store",Vector3(4.8,0.05,-2.3),Vector3(5,1.1,-4.25),"fridge-store"],["house",Vector3(-2.8,0.05,-2.7),Vector3(-2.8,1,-1.38),"key"]]
	for shot in views:
		if shot[3]=="key": game.reset_game(); game.state = "play"
		if shot[3]=="open":
			game.town.perform("shotgun_key")
			game.town.perform("shotgun_lockbox")
			game.weapons.lockbox._process(1)
		var building = game.town.buildings[shot[0]]
		game.player.position = building.to_global(shot[1])
		game.camera.look_at(building.to_global(shot[2]))
		for frame in range(20): await process_frame
		game.town.refresh_focus()
		print("FOCUS ",shot[3]," ",game.town.focus_action)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/lockbox-"+shot[3]+".png")
	game.queue_free()
	await process_frame
	quit()
