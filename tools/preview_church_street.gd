extends SceneTree
var game
func _initialize():
	call_deferred("run")
func capture(label: String, p: Vector3, target: Vector3):
	game.player.position = p
	game.camera.look_at(target)
	game.hud.queue_redraw()
	for frame in range(30):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-church-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_state("play")
	game.set_physics_process(false)
	await capture("road-join",Vector3(0,3.0,-31),Vector3(0,0,-37.5))
	await capture("pickup",Vector3(0,0.001,-47),Vector3(-2.7,0.8,-52))
	await capture("police",Vector3(0,0.001,-61),Vector3(2.7,0.8,-66))
	await capture("muscle",Vector3(0,0.001,-74),Vector3(-2.7,0.8,-79))
	await capture("exterior",Vector3(0,0.001,-79),Vector3(-7.5,7.4,-85))
	await capture("front",Vector3(-0.3,0.001,-85),Vector3(-7,6,-85))
	var chapel = game.town.streetscape.church
	await capture("interior",chapel.to_global(Vector3(0,0.001,5.4)),chapel.to_global(Vector3(0,2.7,-5.5)))
	game.set_state("journal")
	game.journal_page = 1
	game.hud.queue_redraw()
	for frame in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-church-map.png")
	print("PASS: rendered continuous town entry, three replacement cars, Holy Trinity-inspired chapel exterior/interior and map")
	game.queue_free()
	await process_frame
	quit()
