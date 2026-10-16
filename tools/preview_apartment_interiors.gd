extends SceneTree
func _initialize():
	call_deferred("capture")
func capture():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	game.soundscape.toggle_mute()
	var views = [
		["ranger",Vector3(0,0.1,3.9),Vector3(-2.4,1.1,0)],
		["clinic",Vector3(0,0.1,3.9),Vector3(-1.8,1.1,0)],
		["store",Vector3(0,0.1,3.9),Vector3(-3.4,1.0,0)],
		["house",Vector3(0,0.1,3.9),Vector3(-3.3,1.0,0)],
		["house",Vector3(0,0.1,-2.8),Vector3(3.8,1.3,-4.3)],
		["workshop",Vector3(0,0.1,3.9),Vector3(-3.1,1.0,-2)],
		["radio",Vector3(0,0.1,3.9),Vector3(3.7,1.0,2)],
		["house",Vector3(-1.35,0.1,-1.6),Vector3(-3.6,1.1,-3.4)],
		["house",Vector3(0,0.1,3.9),Vector3(3,1.0,0)],
		["clinic",Vector3(0,0.1,4),Vector3(4.5,1.2,2.4)],
		["store",Vector3(0,0.1,2.8),Vector3(4.8,1.1,0)],
		["ranger",Vector3(0,0.1,3.9),Vector3(4.5,1.1,2.4)],
		["radio",Vector3(0,0.1,1.3),Vector3(-2.8,1.2,-3.4)]
	]
	for shot in range(views.size()):
		var building = game.town.buildings[views[shot][0]]
		game.player.position = building.to_global(views[shot][1])
		game.camera.look_at(building.to_global(views[shot][2]))
		for frame in range(12):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/apartment-%d.png" % shot)
	print("Apartment previews captured: ",game.town.apartment_interiors.room_counts)
	game.queue_free()
	await process_frame
	quit()
