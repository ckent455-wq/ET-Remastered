extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	await physics_frame
	var town = game.town
	var details = town.interiors
	assert(details.containers.size()==12,"Twelve searchable drawers and cabinets")
	var seen = {}
	for prop in get_nodes_in_group("LocalInteriorProps"):
		seen[prop.get_meta("source_asset")] = true
	assert(seen.size()==8 and details.prop_count>=65,"Eight local model types used throughout interiors")
	for row in details.manifest.values():
		assert(row.triangles<=1800 and row.texture_limit==256,"PS2 geometry and texture budgets")
	for material in details.material_cache.values():
		if material.albedo_texture!=null:
			assert(material.albedo_texture.get_width()<=256 and material.albedo_texture.get_height()<=256,"Reduced source textures")
	for data in details.containers.values():
		for id in data.loot_ids:
			assert(not town.actions[id].area.visible and not town.actions[id].taken,"Loot concealed before search")
	town.perform("workshop_cabinet")
	assert(not details.containers.workshop_cabinet.open and not details.containers.workshop_cabinet.searched,"Power lock blocks opening and searching")
	town.perform("ranger_drawer")
	assert(town.inventory.station_key==1 and details.containers.ranger_drawer.searched,"Search finds key")
	await create_timer(0.10).timeout
	game.set_state("journal")
	await process_frame
	var paused_position = details.containers.ranger_drawer.moving[0].position.z
	await create_timer(0.20).timeout
	assert(is_equal_approx(details.containers.ranger_drawer.moving[0].position.z,paused_position),"Storage animation pauses with journal")
	game.set_state("play")
	# Allow real tween time to check the visible tray movement.
	await create_timer(0.4).timeout
	assert(details.containers.ranger_drawer.moving[0].position.z>0.45,"Drawer slides outward")
	town.perform("ranger_drawer")
	await create_timer(0.4).timeout
	assert(details.containers.ranger_drawer.moving[0].position.z<0.01,"Drawer closes")
	town.perform("ranger_drawer")
	assert(town.inventory.station_key==1,"Reopening cannot duplicate loot")
	town.perform("store_drawer")
	town.perform("battery_panel")
	town.perform("workshop_cabinet")
	assert(town.inventory.coil==1,"Powered cabinet grants quest coil")
	await create_timer(0.45).timeout
	assert(absf(details.containers.workshop_cabinet.moving[0].rotation.y)>1.6,"Cabinet doors swing")
	for panel in details.containers.workshop_cabinet.moving:
		var local_center = details.containers.workshop_cabinet.root.to_local(panel.get_child(0).global_position)
		assert(local_center.z>panel.position.z+0.2,"Cabinet doors swing outward")
	for id in details.containers:
		var data = details.containers[id]
		if not data.searched:
			town.perform(id)
	assert(town.inventory.medkit==3 and town.inventory.battery==6,"All search rewards accounted for")
	assert(details.containers.clinic_drawer.searched and details.containers.radio_cabinet.searched,"Empty searches are remembered")
	var stock = town.inventory.duplicate()
	for repeat in range(4):
		for id in details.containers:
			town.perform(id)
	assert(town.inventory==stock,"Rapid open/close never duplicates rewards")
	game.reset_game()
	for data in details.containers.values():
		assert(not data.open and not data.searched and data.tweens.is_empty(),"Storage resets without leftover animation")
		for part in data.moving:
			assert(part.position.z==0 if data.mode=="drawer" else part.rotation.y==0,"Closed pose restored")
		for id in data.loot_ids:
			assert(not town.actions[id].taken and not town.actions[id].area.visible,"Concealed loot restored")
	town.perform("ranger_drawer")
	assert(town.inventory.station_key==1,"New journey can collect key again")
	game.set_state("journal")
	game.soundscape.update_sound(0.1)
	await physics_frame
	await process_frame
	assert(not game.soundscape.storage_voice.playing,"Storage audio stops during journal pause")
	print("PASS: 12 containers, 8 local asset types, retro budgets, concealed loot, drawer/cabinet animation, power lock, rewards, no duplication, reset, paused search audio")
	game.queue_free()
	await process_frame
	quit()
