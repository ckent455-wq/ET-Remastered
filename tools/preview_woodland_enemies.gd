extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	game.invincible = 999
	var views = [[Vector3(0,0.02,-83),Vector3(0,2,-100)],[Vector3(26,7.8,-117),Vector3(29,10,-135)],[Vector3(29,9.05,-128),Vector3(19,9.8,-127)]]
	for i in range(views.size()):
		game.enemies.reset()
		game.player.position = views[i][0]
		game.camera.look_at(views[i][1])
		for frame in range(12): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/woodland-enemies-%d.png" % i)
	game.queue_free()
	await process_frame
	quit()
