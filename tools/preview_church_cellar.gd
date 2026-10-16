extends SceneTree
var game
func _initialize():
	call_deferred("run")
func capture(label: String, p: Vector3, target: Vector3):
	game.player.position = p
	game.camera.look_at(target)
	for i in range(25):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-cellar-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.reset_game()
	game.set_state("play")
	game.set_physics_process(false)
	var church = game.town.streetscape.church
	var cellar = church.basement
	await capture("entrance",Vector3(29,9.01,-127),Vector3(29,11,-134))
	game.town.perform("chapel_doors")
	await capture("door",church.to_global(Vector3(1.1,0.01,-4.4)),church.to_global(Vector3(3.25,1.35,-6.6)))
	await capture("room",cellar.to_global(Vector3(1.3,0.01,1.4)),cellar.to_global(Vector3(-1.7,1.3,-3.4)))
	await capture("stairs",cellar.to_global(Vector3(-1.2,0.01,0.1)),cellar.to_global(Vector3(0,2.4,5.1)))
	game.set_state("journal")
	game.hud.queue_redraw()
	await capture("journal",game.player.position,cellar.to_global(Vector3(0,2,5)))
	print("PASS: chapel planting, cellar entrance, room, return stairs and journal renders")
	quit()
