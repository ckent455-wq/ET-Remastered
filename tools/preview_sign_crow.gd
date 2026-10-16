extends SceneTree
var game
func _initialize():
	call_deferred("run")
func capture(label: String, p: Vector3, target: Vector3):
	game.player.position = p
	game.camera.look_at(target)
	for i in range(25):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-crow-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.reset_game()
	game.set_state("play")
	game.set_physics_process(false)
	var crow = game.town.sign_crow
	crow.greeted = true
	crow.call_timer = 90
	await capture("approach",Vector3(0,0.01,-29),crow.global_position+Vector3(0,-0.3,0))
	await capture("perch",Vector3(2.7,0.01,-32.2),crow.global_position+Vector3(0,0.25,0))
	await capture("side",Vector3(1.8,0.01,-35),crow.global_position+Vector3(0,0.2,0))
	crow.caw()
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-crow-calling.png")
	print("PASS: original animated crow perched on Blackwood sign, approach and calling views")
	quit()
