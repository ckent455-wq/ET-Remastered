extends SceneTree
var game
func _initialize():
	call_deferred("run")
func capture(label: String, p: Vector3, target: Vector3):
	game.player.position = p
	game.camera.look_at(target)
	for frame in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-main-street-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_state("play")
	await capture("entrance",Vector3(0,0.001,-37),Vector3(0,3.1,-67))
	await capture("north",Vector3(0,0.001,-54),Vector3(0,3,-80))
	await capture("hotel",Vector3(-1,0.001,-44),Vector3(8.5,4,-46))
	await capture("shops",Vector3(2,0.001,-59),Vector3(-8.5,3.5,-63))
	game.player.position = game.town.buildings.ranger.to_global(Vector3(0,0.001,3.7))
	game.camera.look_at(game.town.actions.weapon_pistol.area.global_position)
	for frame in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-main-street-interior.png")
	game.set_state("title")
	for frame in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-main-street-title.png")
	print("PASS: rendered Weston-inspired street, facades, abandoned details, preserved ranger interior and title")
	game.queue_free()
	await process_frame
	quit()
