extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	await physics_frame
	var box = game.weapons.lockbox
	assert(not box.unlocked and not box.pickup.visible)
	game.town.perform("weapon_shotgun")
	game.town.perform("shotgun_lockbox")
	assert(not game.weapons.owned[2] and not box.opened)
	game.player.position = game.town.buildings.ranger.to_global(Vector3(-2.7,0.05,-1.3))
	game.camera.look_at(box.to_global(Vector3(0,0.65,0.54)))
	await physics_frame
	await physics_frame
	game.town.refresh_focus()
	assert(game.town.focus_action=="shotgun_lockbox", "Real view targets the closed box")
	game.player.position = game.town.buildings.house.to_global(Vector3(-2.8,0.05,-2.7))
	game.camera.look_at(game.town.actions.shotgun_key.area.global_position)
	await physics_frame
	await physics_frame
	game.town.refresh_focus()
	assert(game.town.focus_action=="shotgun_key", "Key reachable on actual dresser")
	game.town.perform("shotgun_key")
	game.player.position = game.town.buildings.ranger.to_global(Vector3(-2.7,0.05,-1.3))
	assert(game.town.inventory.shotgun_key==1)
	game.town.perform("shotgun_lockbox")
	assert(box.unlocked and game.town.inventory.shotgun_key==0)
	game.state = "journal"
	box._process(3)
	assert(box.hinge.rotation.x==0)
	game.state = "play"
	box._process(1)
	assert(box.can_take() and box.pickup.collision_layer==2)
	game.camera.look_at(box.pickup.global_position)
	await physics_frame
	await physics_frame
	game.town.refresh_focus()
	assert(game.town.focus_action=="weapon_shotgun", "Real view targets the gun above crate collision")
	game.town.perform("weapon_shotgun")
	assert(game.weapons.owned[2])
	box._process(0)
	assert(not box.pickup.visible)
	game.town.perform("shotgun_lockbox")
	box._process(1)
	game.town.perform("shotgun_lockbox")
	box._process(1)
	assert(not box.pickup.visible)
	game.reset_game()
	assert(not box.unlocked and not box.opened and not game.weapons.owned[2] and not box.pickup.visible)
	assert(not game.town.actions.shotgun_key.taken)
	print("PASS: locked shotgun, physical key and consumed unlock, hinged lid, pause, pickup, no duplicates, journey reset")
	game.queue_free()
	await process_frame
	quit()
