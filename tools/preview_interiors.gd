extends SceneTree
func _initialize():
	call_deferred("capture")
func capture():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	game.soundscape.toggle_mute()
	for shot in range(5):
		var root_node = game.town.buildings.ranger
		var p = Vector3(0,0.1,3)
		var look = Vector3(-1.2,1.4,-1)
		if shot==1:
			p = Vector3(-2.4,0.1,2.1)
			look = Vector3(-3.25,0.44,1.07)
			game.town.perform("ranger_drawer")
		elif shot==2:
			root_node = game.town.buildings.clinic
			p = Vector3(0,0.1,3)
			look = Vector3(0,1.3,-2.2)
		elif shot==3:
			root_node = game.town.buildings.house
			p = Vector3(0,0.1,-3.6)
			look = Vector3(3.7,1.1,-4.4)
			game.town.perform("house_cabinet")
		elif shot==4:
			root_node = game.town.buildings.store
			p = Vector3(0,0.1,11)
			look = Vector3(0,2.1,5)
		game.player.position = root_node.to_global(p)
		game.camera.look_at(root_node.to_global(look))
		for frame in range(30):
			game.town.refresh_focus()
			game.hud.queue_redraw()
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview-interior-%d.png" % shot)
	print("Interior previews captured; local model instances: ",game.town.interiors.prop_count)
	game.queue_free()
	await process_frame
	quit()
