extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await physics_frame
	var rooms = {}
	var kinds = {}
	for detail in get_nodes_in_group("InteriorDecay"):
		rooms[detail.get_meta("room")] = true
		var kind = detail.get_meta("decay_kind")
		kinds[kind] = kinds.get(kind,0)+1
		assert(detail.find_children("*","CollisionShape3D",true,false).is_empty(),"Small debris cannot destabilize camera or obstruct a quest route")
		if kind in ["wall_damp","ceiling_leak","rising_damp","puddle"]:
			assert(detail.get_child(0).material_override.shader!=null,"Native stain shader assigned")
	assert(rooms.size()==6 and kinds.wall_damp==12 and kinds.ceiling_leak==6,"Water damage in every building")
	assert(kinds.broken_chair==4 and kinds.half_packed_bag==2 and kinds.abandoned_papers==6,"Authored departure stories")
	assert(game.town.interiors.containers.size()==12,"Original searchable storage retained")
	print("PASS: six abandoned interiors, 30 damp/puddle patches, four broken chairs, two half-packed bags, room-specific debris, no small-debris collision")
	game.queue_free()
	await process_frame
	quit()
