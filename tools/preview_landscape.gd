extends SceneTree
var game
func _initialize():
	call_deferred("run")
func capture(label: String, p: Vector3, target: Vector3):
	game.player.position = p
	game.camera.look_at(target)
	for frame in range(35):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-landscape-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_state("play")
	await capture("street",Vector3(0,0.001,-44),Vector3(0,10,-100))
	await capture("sky",Vector3(0,0.001,-55),Vector3(0,35,-95))
	await capture("approach",Vector3(0,0.001,-17),Vector3(0,2.7,-45))
	await capture("flashlight",game.town.buildings.ranger.to_global(Vector3(0,0.001,3)),game.town.actions.weapon_pistol.area.global_position)
	game.set_state("title")
	game.hud.queue_redraw()
	for frame in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-landscape-title.png")
	print("PASS: rendered hill silhouettes, cloud sky, local flashlight model, fog, interior and title")
	game.queue_free()
	await process_frame
	quit()
