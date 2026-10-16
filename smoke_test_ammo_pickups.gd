extends SceneTree
func _initialize(): call_deferred("check")
func mesh_points(node: Node) -> PackedVector3Array:
	var result = PackedVector3Array()
	if node is MeshInstance3D:
		for p in node.mesh.get_faces(): result.append(node.to_global(p))
	for child in node.get_children(): result.append_array(mesh_points(child))
	return result
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.state = "play"
	var guns = game.weapons
	assert(guns.ammo_pickups.areas.size()==9,"Three cartons per ammunition type")
	assert(guns.magazines==[0,0,0] and guns.reserves==[0,0,0],"Unarmed start has no free ammo")
	game.town.perform("weapon_pistol")
	assert(guns.magazines[0]==3 and guns.reserves[0]==0,"Found pistol has only three rounds total")
	for i in range(3):
		guns.delay = 0
		assert(guns.fire())
	guns.delay = 0
	assert(not guns.fire())
	guns.reload()
	assert(guns.reload_remaining==0,"Empty pistol cannot reload without scavenging")
	var box = game.town.actions.ammo_pistol_store
	game.player.position = game.town.buildings.store.to_global(Vector3(-3.25,0.02,2.0))
	game.camera.look_at(box.area.global_position)
	await physics_frame
	await physics_frame
	game.town.refresh_focus()
	assert(game.town.focus_action=="ammo_pistol_store","Actual camera ray reaches carton on store table")
	var event = InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	game._unhandled_input(event)
	assert(guns.reserves==[6,0,0] and box.taken and not box.area.visible,"E gives the correct type once")
	game.town.perform("ammo_pistol_store")
	assert(guns.reserves[0]==6,"Collected box cannot duplicate ammunition")
	guns.reload()
	game.state = "journal"
	guns._physics_process(3)
	assert(guns.magazines[0]==0 and guns.reserves[0]==6,"Reload pauses in journal")
	game.state = "play"
	guns._physics_process(3)
	assert(guns.magazines[0]==6 and guns.reserves[0]==0,"Reload uses only collected rounds")
	game.town.perform("ammo_rifle_workshop")
	assert(not guns.owned[1] and guns.reserves[1]==12,"Can store rifle ammo before rifle acquisition")
	guns.collect(1)
	assert(guns.reserves[1]==12 and guns.magazines[1]==20,"Weapon discovery preserves scavenged reserve")
	game.state = "paused"
	game.town.perform("ammo_shotgun_house")
	assert(guns.reserves[2]==0 and not game.town.actions.ammo_shotgun_house.taken,"Menus cannot collect ammunition")
	game.state = "play"
	game.town.perform("ammo_shotgun_house")
	assert(guns.reserves[2]==4 and not guns.owned[2],"Shells are stored separately")
	guns.reserves[0] = guns.LOADOUT[0].max_reserve-2
	game.town.perform("ammo_pistol_house")
	assert(game.town.actions.ammo_pistol_house.amount==4 and not game.town.actions.ammo_pistol_house.taken,"Reserve cap leaves unused rounds in carton")
	game.reset_game()
	assert(guns.magazines==[0,0,0] and guns.reserves==[0,0,0] and not guns.owned.has(true))
	for area in guns.ammo_pickups.areas:
		var data = game.town.actions[area.get_meta("action_id")]
		assert(not data.taken and data.amount==data.initial_amount and area.visible and area.collision_layer==2,"Fresh journey restores cartons")
	var dresser_top = -INF
	for furniture in game.town.apartment_interiors.instances:
		if furniture.get_meta("room")=="house" and furniture.get_meta("apartment_asset")=="dresser":
			for point in mesh_points(furniture): dresser_top = maxf(dresser_top,point.y)
	var key = game.town.actions.shotgun_key.area.get_child(1)
	var lowest = INF
	var highest = -INF
	for point in mesh_points(key): lowest = minf(lowest,point.y); highest = maxf(highest,point.y)
	assert(lowest>=dresser_top-0.001 and lowest-dresser_top<0.002,"Key touches native dresser top without hovering or sinking")
	assert(highest-lowest<0.032,"Key is lying flat")
	print("PASS: three-round pistol, nine native ammo cartons, real E pickup, types, reload/pause, pre-weapon reserves, no duplication, cap leftovers, reset, key flat on dresser")
	game.queue_free()
	await process_frame
	quit()
