extends SceneTree
func _initialize():
	call_deferred("capture")
func capture():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	game.soundscape.toggle_mute()
	await process_frame
	for shot in range(2):
		if shot==1:
			game.player.position = Vector3(-12,0.1,-12)
			game.player.rotation.y = 0.9
			game.camera.rotation.x = 0.16
		game.hud.queue_redraw()
		for i in range(12):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview-forest-%d.png" % shot)
	print("Forest previews captured")
	game.queue_free()
	await process_frame
	quit()
