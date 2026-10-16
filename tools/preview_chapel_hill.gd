extends SceneTree
var game
func _initialize():
	call_deferred("run")
func capture(label: String, p: Vector3, target: Vector3):
	game.player.position = p
	game.camera.look_at(target)
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-chapel-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_state("play")
	game.set_physics_process(false)
	await capture("base",Vector3(0,0.001,-90),Vector3(8,4,-109))
	await capture("bend",Vector3(15,3.51,-111),Vector3(29,13,-139))
	await capture("arrival",Vector3(29,9.001,-126),Vector3(29,14,-141))
	game.town.perform("chapel_doors")
	await create_timer(0.8).timeout
	await capture("interior",Vector3(29,9.001,-136),Vector3(29,11.7,-146))
	game.set_state("journal")
	game.journal_page = 0
	game.hud.queue_redraw()
	await capture("journal",game.player.position,Vector3(29,11,-146))
	print("PASS: hill road and chapel previews")
	quit()
