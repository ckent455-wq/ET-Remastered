extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	await physics_frame
	await physics_frame
	var church = game.town.streetscape.church
	var hill = game.town.streetscape.chapel_hill
	var land = hill.get_node("WoodedChapelHill")
	var faces = land.mesh.get_faces()
	var footprint = Rect2(Vector2(church.position.x-5,church.position.z-7),Vector2(10,14))
	for i in range(0,faces.size(),3):
		var center = (faces[i]+faces[i+1]+faces[i+2])/3
		assert(not footprint.has_point(Vector2(center.x,center.z)),"No hillside triangles underneath the wooden church floor")
	var space = game.get_world_3d().direct_space_state
	for x in range(-4,5):
		for z in range(-6,7):
			var p = church.to_global(Vector3(x,1,z))
			var query = PhysicsRayQueryParameters3D.create(p,p-Vector3(0,1.1,0),1,[game.player.get_rid()])
			var hit = space.intersect_ray(query)
			assert(not hit.is_empty(),"Church floor remains solid")
			# Furniture can be above the floor; sample the central aisle separately.
			if x==0 and z>= -4:
				assert(hit.collider.name=="ContinuousChapelFloor" and absf(hit.position.y-9)<0.002,"Wooden floor is the sole aisle walking surface")
	assert(is_equal_approx(hill.terrain_height_at(Vector3(29,0,-133.8)),9),"Level ground outside the entrance")
	print("PASS: no terrain under church floor, 117 solid floor samples, sole central-aisle floor collision, level entrance")
	game.queue_free()
	await process_frame
	quit()
