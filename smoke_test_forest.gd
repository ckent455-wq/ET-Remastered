extends SceneTree
func _initialize():
	call_deferred("check_forest")
func check_forest():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	var forest = game.get_node("DetailedForest")
	assert(forest.tree_count==180 and forest.bush_count==210 and forest.rock_count==85,"Forest populated")
	for group in ["Trees","Bushes","Rocks"]:
		for obj in get_nodes_in_group(group):
			assert(forest.can_place(Vector3(obj.position.x,0,obj.position.z),1.7,6.0),"Landing area, objectives, and corridors clear")
	for i in range(3):
		var target = forest.TARGETS[i]
		# Sweep the actual player capsule along each trail in both directions.
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = game.player.get_child(0).shape
		query.exclude = [game.player.get_rid()]
		for j in range(41):
			var position = target*float(j)/40+Vector3(0,0.79,0)
			query.transform = Transform3D(Basis.IDENTITY,position)
			var hits = game.get_world_3d().direct_space_state.intersect_shape(query)
			assert(hits.is_empty(),"Player capsule fits along route %d, sample %d" % [i,j])
	var tree = get_nodes_in_group("Trees")[0]
	assert(tree.get_children().any(func(n): return n is CollisionShape3D),"Tree trunks collide")
	var materials = forest.shared_materials.values()
	assert(materials.size()>=6,"Source materials loaded")
	var cutouts = 0
	for material in materials:
		assert(material.albedo_texture!=null,"Asset texture retained")
		assert(material.albedo_texture.get_width()<=256,"Retro texture budget")
		if material.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
			cutouts += 1
	assert(cutouts>=2,"Foliage cutouts configured")
	print("PASS: 180 trees, 210 bushes, 85 rocks, textured low-poly materials, foliage cutouts, trunk collision, 123 player-capsule route samples")
	game.queue_free()
	await process_frame
	quit()
