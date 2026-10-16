extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.state = "play"
	var data = game.enemies.creatures[0]
	data.actor.position = Vector3(0,0.01,-56)
	data.actor.rotation.y = 0
	data.state = "chase"
	data.hp = 37
	game.player.position = Vector3(0,0.01,-51)
	game.camera.look_at(data.actor.position+Vector3(0,1.1,0))
	game.enemies.play(data,"idle1")
	await save(game,"health-bar")
	for id in ["ranger_drawer","store_drawer","fuse_panel","workshop_cabinet","cellar_door"]: game.town.perform(id)
	var basement = game.town.streetscape.church.basement
	game.player.position = basement.to_global(Vector3(2.8,0.01,3.0))
	game.camera.look_at(game.town.actions.weapon_rifle.area.global_position)
	game.town.refresh_focus()
	await save(game,"cellar-rifle")
	game.town.perform("radio_tuner")
	game.town.perform("cellar_exit")
	game.town.perform("receiver")
	game.player.position = game.town.buildings.radio.to_global(Vector3(-4.0,0.01,-1.55))
	game.camera.look_at(game.town.actions.radio_bypass.area.global_position)
	game.town.refresh_focus()
	await save(game,"radio-bypass")
	game.queue_free()
	await process_frame
	quit()
func save(game, suffix):
	for frame in range(6):
		game.hud.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/combat-update-"+suffix+".png")
