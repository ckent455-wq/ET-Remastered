extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.state = "play"
	game.invincible = 999
	var data = game.enemies.creatures[0]
	data.actor.position = Vector3(0,0.06,-56)
	data.actor.rotation.y = 0
	game.enemies.creatures[1].actor.hide()
	game.player.position = Vector3(0,0.01,-51)
	game.camera.look_at(Vector3(0,1.2,-56))
	for clip in ["idle1","walk1","roar","punch","death"]:
		game.enemies.play(data,clip)
		data.animation.advance(0.65 if clip!="death" else 1.8)
		for frame in range(3): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/enemy-"+clip+".png")
	print("ENEMY CLIPS: ",data.clips)
	game.queue_free()
	await process_frame
	quit()
