extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.town.townspeople.set_physics_process(false)
	await physics_frame
	var town = game.town
	assert(town.buildings.size()==6,"Six enterable quest buildings retained")
	for data in town.BUILDINGS:
		var front = town.buildings[data.id].to_global(Vector3(0,0,5))
		assert(absf(absf(front.x)-8.5)<0.01,"Storefront faces the shared Main Street: "+data.id)
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = game.player.get_child(0).shape
	query.collision_mask = 1
	query.exclude = [game.player.get_rid()]
	var samples = 0
	for x in [0.0,-6.55,6.55]:
		for i in range(103):
			var p = Vector3(x,0.79,-38-i*0.5)
			query.transform = Transform3D(Basis.IDENTITY,p)
			var hits = game.get_world_3d().direct_space_state.intersect_shape(query)
			assert(hits.is_empty(),"Road/sidewalk blocked at "+str(p))
			samples += 1
	for data in town.BUILDINGS:
		var front = town.buildings[data.id].to_global(Vector3(0,0.001,7))
		game.player.position = front
		game.camera.look_at(town.actions[data.id+"_door"].area.global_position)
		await physics_frame
		town.refresh_focus()
		assert(town.focus_action==data.id+"_door","Each front door targetable from sidewalk: "+data.id)
	print("PASS: facing storefront rows, six usable front doors, ",samples," clear central-road and sidewalk capsule samples")
	game.queue_free()
	await process_frame
	quit()
