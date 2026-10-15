extends SceneTree
var game
func _initialize():
	call_deferred("check")
func aim_at(area, from: Vector3):
	game.player.global_position = from
	game.player.rotation = Vector3.ZERO
	game.camera.rotation = Vector3.ZERO
	game.camera.look_at(area.global_position,Vector3.UP)
	await physics_frame
	game.town.refresh_focus()
func capsule_clear(p: Vector3) -> bool:
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = game.player.get_child(0).shape
	query.collision_mask = 1
	query.exclude = [game.player.get_rid()]
	query.transform = Transform3D(Basis.IDENTITY,p+Vector3(0,0.79,0))
	return game.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func check_room_access(root_node: Node3D, width: float, depth: float) -> bool:
	var queue = [Vector2i(0,int(depth)-2)]
	var visited = {}
	var accessible: Array[Vector3] = []
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if visited.has(cell):
			continue
		visited[cell] = true
		var local = Vector3(cell.x*0.5,0,cell.y*0.5)
		if absf(local.x)>width/2-0.45 or absf(local.z)>depth/2-0.4:
			continue
		var p = root_node.to_global(local)
		if not capsule_clear(p):
			continue
		accessible.append(p)
		for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			queue.append(cell+step)
	for id in game.town.actions:
		var data = game.town.actions[id]
		if data.taken or not data.area.is_visible_in_tree() or data.kind=="door" or data.kind=="panel" or not root_node.is_ancestor_of(data.area):
			continue
		var reachable = false
		for p in accessible:
			var eye = p+Vector3(0,1.25,0)
			if eye.distance_to(data.area.global_position)>3.1:
				continue
			var ray = PhysicsRayQueryParameters3D.create(eye,data.area.global_position,3,[game.player.get_rid()])
			ray.collide_with_areas = true
			var hit = game.get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty() and hit.collider==data.area:
				reachable = true
				break
		if not reachable:
			push_error("Unreachable indoor interaction: "+id)
			return false
	return true
func check():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	await physics_frame
	var town = game.town
	assert(town.buildings.size()==6,"Six explorable buildings")
	# Real raycast + E input at the locked station door.
	var station = town.buildings.radio
	await aim_at(town.actions.radio_door.area,station.to_global(Vector3(0,0,7)))
	assert(town.focus_action=="radio_door","Door is targetable")
	var event = InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	game._unhandled_input(event)
	assert(not town.doors.radio.open,"Station remains locked without key")
	# World geometry, not proximity alone, gates interactions.
	await aim_at(town.actions.battery_b.area,town.buildings.store.to_global(Vector3(6.8,0,0)))
	assert(town.focus_action=="","Cannot pick up through a wall")
	town.perform("coil")
	assert(town.inventory.coil==0,"Coil cabinet needs power")
	town.perform("fuse_panel")
	assert(not town.powered,"Missing fuse blocks power")
	# Collect key via actual aiming and the same E event.
	await aim_at(town.actions.ranger_drawer.area,town.buildings.ranger.to_global(Vector3(-3.25,0,1.9)))
	assert(town.focus_action=="ranger_drawer","Key drawer targetable")
	game._unhandled_input(event)
	town.perform("station_key")
	assert(town.inventory.station_key==1 and town.actions.station_key.taken,"Single pickup, no duplication")
	for data in town.BUILDINGS:
		town.perform(data.id+"_door")
	await physics_frame
	await physics_frame
	for data in town.BUILDINGS:
		var root_node = town.buildings[data.id]
		assert(town.doors[data.id].open,"Door opens")
		for i in range(13):
			var p = root_node.to_global(Vector3(0,0,7-i*0.5))
			assert(capsule_clear(p),"Clear entrance: %s sample %d" % [data.id,i])
		assert(check_room_access(root_node,data.w,data.d),"All room interactions reachable")
	# Do not close a door onto the player.
	game.player.position = town.buildings.ranger.to_global(Vector3(0,0,5))
	town.perform("ranger_door")
	assert(town.doors.ranger.open,"Door closing blocked while player in doorway")
	# Full supply and quest progression.
	town.perform("clinic_cabinet")
	town.use_medkit()
	assert(town.inventory.medkit==2,"Don't waste a medkit at full health")
	game.health = 48
	town.use_medkit()
	assert(game.health==93 and town.inventory.medkit==1,"Medkit heals")
	town.perform("store_cabinet")
	town.use_battery()
	assert(town.inventory.battery==2,"Don't waste charged battery")
	game.flashlight_charge = 8
	town.use_battery()
	assert(game.flashlight_charge==100 and town.inventory.battery==1,"Battery recharge")
	town.perform("store_drawer")
	town.perform("fuse_panel")
	assert(town.powered and town.inventory.fuse==0,"Fuse consumed, power restored")
	assert(town.powered_lights[0].visible,"Workshop lamps turn on")
	town.perform("workshop_cabinet")
	assert(town.inventory.coil==1,"Coil released")
	game.player.position = Vector3.ZERO
	game.update_contact(4.1,true)
	assert(game.state=="play","Radio must be calibrated before rescue")
	town.perform("receiver")
	assert(town.radio_ready and town.inventory.coil==0,"Receiver repair consumes coil")
	game.update_contact(4.1,true)
	assert(game.state=="play","Cannot call for rescue back at the old clearing")
	game.player.position = town.buildings.radio.to_global(Vector3(-2.7,0.001,-2.0))
	game.update_contact(4.1,true)
	assert(game.state=="won","Rescue after full quest")
	game.state = "play"
	town.perform("ranger_note")
	assert(game.state=="journal" and town.journal_entries.size()==1 and game.journal_page==2,"Notes saved and readable")
	game.state = "play"
	town.perform("ranger_note")
	assert(town.journal_entries.size()==1,"No duplicate journal entries")
	game.reset_game()
	assert(not town.powered and not town.radio_ready and town.journal_entries.is_empty(),"Quest resets")
	assert(town.inventory.station_key==0 and not town.actions.station_key.taken,"Inventory and pickups reset")
	assert(not town.doors.radio.open and not town.radio_ready,"Doors and radio reset")
	print("PASS: six buildings, real E targeting, wall occlusion, locked door, 78 entrance samples, walkable access to every indoor interaction, key/fuse/coil chain, consumables, notes, rescue gating, restart")
	event = null
	game.queue_free()
	await process_frame
	quit()
