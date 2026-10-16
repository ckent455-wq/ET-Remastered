extends SceneTree
var game
func _initialize():
	call_deferred("run")
func capture(label: String):
	for frame in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-flashlight-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_state("play")
	game.set_process(false)
	game.set_physics_process(false)
	game.player.position = Vector3(0,0.001,-44)
	game.camera.look_at(Vector3(0,2,-70))
	game.hud.queue_redraw()
	await capture("raised")
	game.flashlight.visible = false
	game.update_flashlight_visual(0.15)
	await capture("lowering")
	game.update_flashlight_visual(0.2)
	assert(not game.flashlight_model.visible)
	await capture("off")
	game.flashlight.visible = true
	game.update_flashlight_visual(0.3)
	await capture("returned")
	print("PASS: rendered flashlight-only raised, lowering, hidden and returned poses")
	game.queue_free()
	await process_frame
	quit()
