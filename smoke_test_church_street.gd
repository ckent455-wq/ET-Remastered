extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await physics_frame
	var street = game.town.streetscape
	var models = {}
	for child in street.get_children():
		if child.has_meta("vehicle_model"):
			var path = child.get_meta("vehicle_model")
			assert(not "crashed_hatchback" in path,"Crash car confined to opening")
			models[path] = true
	assert(models.size()==5,"Five distinct street vehicles")
	var entry = street.get_node("ContinuousTownEntryAsphalt")
	var bounds = entry.mesh.get_aabb()
	assert(bounds.position.z< -38 and bounds.end.z> -35,"Asphalt overlaps both road ends")
	var faces = entry.mesh.get_faces()
	for triangle in range(2):
		var a = faces[triangle*3]
		var b = faces[triangle*3+1]
		var c = faces[triangle*3+2]
		assert((b-a).cross(c-a).y<0,"Clockwise top faces prevent the vanished street join")
	var chapel = street.church
	assert(chapel!=null,"Church on Main Street")
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = game.player.get_child(0).shape
	query.collision_mask = 1
	query.exclude = [game.player.get_rid()]
	for i in range(51):
		var point = chapel.to_global(Vector3(0,0.79,8.5-i*0.25))
		query.transform = Transform3D(Basis.IDENTITY,point)
		assert(game.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"Open church entrance and aisle at "+str(point))
	game.player.position = chapel.to_global(Vector3(0,0.001,0))
	game.state = "play"
	game.fog_atmosphere.update_fog(3)
	assert(game.fog_atmosphere.indoors,"Chapel has readable indoor fog")
	assert(game.soundscape.atmosphere.interior_id()=="church","Chapel uses indoor sound")
	print("PASS: five unique parked models, opening-only crash car, continuous upward-facing asphalt join, 51 chapel entrance/aisle capsule samples, church fog/audio")
	game.queue_free()
	await process_frame
	quit()
