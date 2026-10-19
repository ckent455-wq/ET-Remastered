extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	g.set_physics_process(false);g.enemies.set_physics_process(false)
	var kit=g.town.apartment_interiors.retro
	assert(kit.scenes.size()==14 and kit.instances.size()>70,"Native asset variety and authored building dressing")
	assert(kit.replacements>60,"Placeholder clocks, mats, shelf packs, tools and counter visuals replaced")
	var used={}
	for item in kit.instances:
		used[item.get_meta("retro_asset")]=true
		var box=kit.bounds(item,item)
		assert(absf(box.position.y)<0.003,"Every model rests on its authored support plane")
		if item.get_meta("retro_asset") in ["bucket","plate","knife","clock","entrance_mat","cutting_board","burner","shovel","scythe","sheet_metal","slate"]:
			assert(not item is StaticBody3D,"Small clutter never obstructs movement or interactions")
		for mesh in item.find_children("*","MeshInstance3D",true,false):
			for i in range(mesh.mesh.get_surface_count()):
				var mat=mesh.get_active_material(i)
				assert(mat is StandardMaterial3D and mat.roughness==1,"Matte PSX materials")
				assert(mat.albedo_texture and mat.albedo_texture.get_width()<=256 and mat.albedo_texture.get_height()<=256,"Native diffuse texture present within 256px budget")
	assert(used.size()==14,"All fourteen curated models used")
	assert(g.town.interiors.containers.size()==12,"Searchable containers retained")
	g.state="play"
	g.crash_site.has_backpack=true
	g.town.perform("ranger_drawer")
	assert(g.town.interiors.containers.ranger_drawer.open and g.town.inventory.station_key==1,"Existing drawer still opens and yields its real quest key")
	g.town.perform("ranger_drawer")
	assert(not g.town.interiors.containers.ranger_drawer.open,"Existing drawer still closes")
	await physics_frame
	await physics_frame
	# Actual player capsule, rather than just a point, fits along each entry aisle.
	for data in g.town.BUILDINGS:
		for z in [4.4,3.4,2.4,1.4,0.4]:
			var query=PhysicsShapeQueryParameters3D.new()
			query.shape=g.player_collider.shape
			query.collision_mask=1
			query.exclude=[g.player.get_rid()]
			query.transform.origin=g.town.buildings[data.id].to_global(Vector3(0,0.82,z))
			var hits=g.get_world_3d().direct_space_state.intersect_shape(query)
			for hit in hits:
				assert(not hit.collider.has_meta("retro_asset"),"New furniture leaves the existing entry aisle clear in "+data.id)
	print("PASS: fourteen local retro models, ",kit.instances.size()," props, ",kit.replacements," replacements, grounded surfaces, native textures, unobstructed entry aisles and original storage")
	g.queue_free();await process_frame;quit()
