extends SceneTree
func _initialize():
	call_deferred("capture")
func capture():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.soundscape.toggle_mute()
	for shot in range(5):
		if shot==0:
			game.state = "intro"
			game.intro_elapsed = 1.8
		elif shot==1:
			game.state = "play"
			game.player.position = Vector3(-26,0.1,-58.4)
			game.camera.look_at(Vector3(-26,1.35,-61))
		elif shot==2:
			game.town.perform("npc_ranger")
		elif shot==3:
			game.state = "play"
			game.player.position = game.town.buildings.clinic.to_global(Vector3(2.4,0.1,-2.4))
			game.camera.look_at(game.town.buildings.clinic.to_global(Vector3(2.4,1.0,-4.45)))
			game.town.perform("clinic_cabinet")
		else:
			game.state = "title"
		for frame in range(30):
			game.town.refresh_focus()
			game.hud.queue_redraw()
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview-townspeople-%d.png" % shot)
	print("Presentation, townspeople, dialogue, outward cabinets, and title previews captured")
	game.queue_free()
	await process_frame
	quit()
