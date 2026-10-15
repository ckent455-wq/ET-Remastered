extends SceneTree
var game
func _initialize():
	call_deferred("run")
func snapshot(label: String):
	for frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-death-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var people = game.town.townspeople
	people.set_physics_process(false)
	game.state = "play"
	game.player.position = Vector3(-23.5,0.001,-58.7)
	var data = people.characters.ranger
	game.camera.look_at(data.actor.global_position+Vector3(0,0.85,0))
	await snapshot("standing")
	people.shoot("ranger")
	people._physics_process(0.55)
	await snapshot("collapse")
	people._physics_process(1.2)
	game.camera.look_at(data.actor.global_position+Vector3(0,0.3,0.7))
	await snapshot("settled")
	game.player.position = Vector3(1,0.001,-30)
	game.camera.look_at(Vector3(4.4,1.45,-35))
	await snapshot("sign")
	print("PASS: rendered NPC collapse, settled pose and Population 3 sign")
	game.queue_free()
	await process_frame
	quit()
