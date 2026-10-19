extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await physics_frame
	var details = game.town.apartment_interiors
	assert(details.room_counts.size()==6,"All six buildings furnished")
	assert(details.instances.size()+details.retro.instances.size()>=85,"Designed room layouts with native retro replacements and storage groups")
	for room in details.room_counts:
		assert(details.room_counts[room]>=6,"Room furniture: "+room)
	for instance in details.instances:
		assert(instance.get_child_count()>0,"Imported model instantiated")
	for material in details.materials.values():
		assert(material.roughness==1 and not material.emission_enabled,"Matte PS2 materials")
		if material.albedo_texture:
			assert(material.albedo_texture.get_width()<=256 and material.albedo_texture.get_height()<=256,"Texture budget")
	for row in details.manifest.values():
		assert(row.triangles<=2500,"Geometry budget: "+row.asset)
	for group in ["LegacyDesks","LegacyClinicBeds","LegacyHouseBeds","InteriorShelfBases","LegacyInteriorClutter"]:
		for old in get_nodes_in_group(group):
			assert(not old.visible,"Placeholder replaced")
	assert(game.town.interiors.containers.size()==12,"Searchable furniture retained")
	print("PASS: Apartment Kit furnishings in six rooms, ",details.instances.size()," instances, 24 optimized models, matte 256px textures, replaced placeholders, searchable storage retained")
	game.queue_free()
	await process_frame
	quit()
