extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	var shot = 0
	for id in game.story.RECORDS:
		game.state = "play"
		game.town.perform(id)
		await save(game,"record-"+id)
	game.journal_casefile = true
	await save(game,"case-notes")
	for id in ["ranger","nurse","mechanic"]:
		game.state = "play"
		game.town.townspeople.talk(id)
		await save(game,"dialogue-"+id)
	game.story.county_bypass = true
	game.state = "won"
	await save(game,"ending-informed")
	game.story.evidence.clear()
	game.story.county_bypass = false
	await save(game,"ending-unknown")
	game.queue_free()
	await process_frame
	quit()
func save(game, suffix: String):
	for frame in range(3):
		game.hud.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/story-"+suffix+".png")
