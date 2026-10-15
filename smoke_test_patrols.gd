extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	game.state = "play"
	game.player.position = Vector3(0,0.001,4)
	var people = game.town.townspeople
	var starts = {}
	var greatest = {}
	for id in people.characters:
		var data = people.characters[id]
		starts[id] = data.actor.global_position
		greatest[id] = 0.0
		assert(data.actor is CharacterBody3D and data.animation!=null and data.walk!="","Walking rig and collision: "+id)
	for frame in range(720):
		await physics_frame
		for id in people.characters:
			var data = people.characters[id]
			greatest[id] = maxf(greatest[id],data.actor.global_position.distance_to(starts[id]))
	for id in people.characters:
		var data = people.characters[id]
		assert(greatest[id]>1.0,"Patrol makes progress: "+id)
		game.player.global_position = data.actor.global_position+Vector3(0,0,2.3)
		await physics_frame
		await physics_frame
		var stopped: Vector3 = data.actor.global_position
		for frame in range(10):
			await physics_frame
		assert(data.actor.global_position.distance_to(stopped)<0.002,"Stops for conversation: "+id)
		people.talk(id)
		for frame in range(5):
			await physics_frame
		assert(data.actor.global_position.distance_to(stopped)<0.002 and not data.animation.is_playing(),"Dialogue freezes patrol: "+id)
		game.state = "play"
		game.player.position = Vector3(0,0.001,4)
	game.reset_game()
	for data in people.characters.values():
		assert(data.actor.position==data.spawn and data.waypoint==1,"Patrol resets")
	print("PASS: three collision-aware patrols, skinned walk animation, route progress, proximity stop, conversation freeze, reset")
	game.queue_free()
	await process_frame
	quit()
