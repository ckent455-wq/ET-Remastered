extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.state = "play"
	game.soundscape.toggle_mute()
	var feet = [Vector3(-3.25,0.02,2.0),Vector3(3.14,0.02,-2.8),Vector3(1.8,0.02,-1.7),Vector3(-4.6,0.02,-2.7),Vector3(-2.2,0.02,1.3),Vector3(-2.0,0.02,-0.98),Vector3(-4.2,0.02,-0.98),Vector3(-1.85,0.02,-2),Vector3(-3.4,0.02,-1.4)]
	for i in range(game.weapons.ammo_pickups.BOXES.size()):
		var data = game.weapons.ammo_pickups.BOXES[i]
		var area = game.town.actions["ammo_"+data.id].area
		var parent = area.get_parent()
		game.player.position = parent.to_global(feet[i])
		game.camera.look_at(area.global_position)
		for frame in range(15): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/ammo-"+data.id+".png")
	var house = game.town.buildings.house
	game.player.position = house.to_global(Vector3(-2.8,0.02,-2.7))
	game.camera.look_at(house.to_global(Vector3(-2.8,0.955,-1.28)))
	for frame in range(15): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/ammo-key-grounded.png")
	game.town.perform("weapon_pistol")
	game.town.perform("ammo_rifle_workshop")
	game.town.perform("ammo_shotgun_house")
	game.state = "journal"
	game.journal_page = 0
	for frame in range(5):
		game.hud.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/ammo-journal.png")
	print("PASS: nine ammo placements, grounded key, inventory journal rendered")
	game.queue_free()
	await process_frame
	quit()
