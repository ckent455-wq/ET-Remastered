extends SceneTree
func _initialize():
	call_deferred("capture")
func capture():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	game.soundscape.toggle_mute()
	for i in range(5):
		if i==0:
			game.player.position = Vector3(0,0.1,-54)
			game.camera.look_at(Vector3(1,1.7,-68))
		elif i==1:
			game.town.perform("ranger_door")
			game.player.position = game.town.buildings.ranger.to_global(Vector3(0,0.1,2.7))
			game.camera.look_at(game.town.actions.station_key.area.global_position)
		elif i==2:
			game.state = "journal"
			game.journal_page = 0
		elif i==3:
			game.journal_page = 1
		else:
			game.state = "play"
			game.town.perform("ranger_note")
		game.town.refresh_focus()
		game.hud.queue_redraw()
		for frame in range(12):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview-town-%d.png" % i)
	print("Town previews captured")
	game.queue_free()
	await process_frame
	quit()
