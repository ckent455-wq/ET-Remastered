extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await physics_frame
	var boundary = game.forest_boundary
	assert(boundary.tree_count>=650 and boundary.collision_sections==boundary.OUTLINE.size(),"Deep closed forest belt")
	var query = PhysicsRayQueryParameters3D.new()
	query.collision_mask = 1
	var samples = 0
	for i in range(boundary.OUTLINE.size()):
		var a = boundary.OUTLINE[i]
		var b = boundary.OUTLINE[(i+1)%boundary.OUTLINE.size()]
		var outward = boundary.outward_for(a,b)
		for j in range(21):
			var p = a.lerp(b,float(j)/20)
			query.from = p-outward*4+Vector3(0,0.8,0)
			query.to = p+outward*6+Vector3(0,0.8,0)
			var hit = game.get_world_3d().direct_space_state.intersect_ray(query)
			assert(not hit.is_empty(),"Closed forest perimeter at "+str(p))
			samples += 1
	# Sweep a real player capsule into representative tree-belt sections.
	for i in [0,2,4,6,8,10]:
		var a = boundary.OUTLINE[i]
		var b = boundary.OUTLINE[(i+1)%boundary.OUTLINE.size()]
		var outward = boundary.outward_for(a,b)
		game.player.position = (a+b)/2-outward*4+Vector3(0,0.001,0)
		await physics_frame
		var hit = game.player.move_and_collide(outward*9)
		assert(hit!=null,"Actual player cannot cross forest boundary")
	print("PASS: ",boundary.tree_count," boundary trees in five rising rows, ",samples," closed perimeter samples and six blocked player sweeps")
	game.queue_free()
	await process_frame
	quit()
