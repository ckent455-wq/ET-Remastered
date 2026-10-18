extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.town.townspeople.set_physics_process(false)
	await physics_frame
	var barriers = game.get_node("CrampedRoadside").alley_barriers
	assert(barriers.size()==5,"Five unused alley mouths guarded")
	var samples = 0
	for barrier in barriers:
		var side: float = barrier.get_meta("side")
		var near_edge: float = barrier.get_meta("near_edge")
		var far_edge: float = barrier.get_meta("far_edge")
		for i in range(31):
			var z = lerpf(far_edge-0.15,near_edge+0.15,i/30.0)
			game.player.position = Vector3(side*5.3,0.001,z)
			await physics_frame
			var hit = game.player.move_and_collide(Vector3(side*3.2,0,0))
			assert(hit!=null,"No gap around alley barrier at "+str(Vector2(side,z)))
			assert(absf(game.player.position.x)<6.9,"Player stopped before entering alley")
			samples += 1
	var types = []
	for child in game.town.streetscape.get_children():
		if child.has_meta("vehicle_model"):
			types.append(child.get_meta("vehicle_model"))
	assert(types.size()==5 and "res://assets/vehicles/abandoned_classic.glb" in types and "res://assets/vehicles/abandoned_van.glb" in types,"Two different downloaded vehicles added")
	print("PASS: five unused alley mouths and endpoints block ",samples," real player sweeps; five parked vehicles including classic car and van")
	game.queue_free()
	await process_frame
	quit()
