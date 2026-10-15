extends SceneTree
var game
func _initialize():
	call_deferred("run")
func capture(label: String):
	for frame in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-crash-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_state("play")
	await capture("start")
	game.player.position = Vector3(0.3,0.001,10)
	game.camera.look_at(game.crash_site.WRECK_POSITION+Vector3(0,0.7,0))
	await capture("wreck")
	game.player.position = game.START_POSITION
	game.player.rotation.y = 0
	game.camera.rotation = Vector3.ZERO
	await capture("road")
	game.player.position = game.town.buildings.ranger.to_global(Vector3(-1.9,0.001,4.1))
	game.camera.look_at(game.town.actions.weapon_pistol.area.global_position)
	await capture("pistol")
	game.town.perform("weapon_pistol")
	await capture("equipped")
	game.set_state("journal")
	await capture("journal")
	print("PASS: rendered crash opening, downloaded hatchback, road, pistol discovery, equipped weapon and story journal")
	game.queue_free()
	await process_frame
	quit()
