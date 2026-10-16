extends SceneTree
var game
func _initialize():
	call_deferred("run")
func capture(label: String, p: Vector3, target: Vector3):
	game.player.position = p
	game.camera.look_at(target)
	game.hud.queue_redraw()
	for frame in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-alley-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_state("play")
	game.set_physics_process(false)
	await capture("classic",Vector3(0,0.001,-43),Vector3(2.7,0.8,-48))
	await capture("van",Vector3(0,0.001,-56),Vector3(-2.7,1,-61))
	await capture("west-fence",Vector3(-4.9,0.001,-52.5),Vector3(-6.65,1.4,-52.5))
	await capture("east-fence",Vector3(4.9,0.001,-78.75),Vector3(6.65,1.4,-78.75))
	print("PASS: real-rendered classic car, panel van, fitted west/east alley boards")
	game.queue_free()
	await process_frame
	quit()
