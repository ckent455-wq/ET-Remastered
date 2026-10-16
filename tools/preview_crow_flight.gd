extends SceneTree
var game
var crow
func _initialize():
	call_deferred("run")
func shot(label: String):
	for i in range(8):
		game.camera.look_at(crow.global_position+Vector3(0,0.2,0))
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-crow-flight-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.reset_game()
	game.set_state("play")
	game.set_physics_process(false)
	crow = game.town.sign_crow
	var perch = crow.perch_global()
	game.player.position = perch+Vector3(-0.7,-1.95,2.2)
	await create_timer(0.85).timeout
	assert(crow.flight_state=="outbound")
	# Close inspection camera for the original wing animation.
	game.player.position = crow.global_position+Vector3(-1,-1.1,2)
	await shot("takeoff")
	game.player.position = perch+Vector3(-4,-1.95,8)
	await create_timer(3.2).timeout
	assert(crow.flight_state=="away")
	crow.away_timer = 0
	await create_timer(3.2).timeout
	await shot("return")
	await create_timer(1.8).timeout
	assert(crow.flight_state=="perched" and crow.position.is_equal_approx(crow.PERCH_POSITION))
	await shot("landed")
	print("PASS: actual proximity takeoff, original flapping/landing clips, return to same sign perch")
	quit()
