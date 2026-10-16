extends SceneTree
var game
func _initialize():
	call_deferred("run")
func capture(label: String, p: Vector3, target: Vector3):
	game.player.position = p
	game.camera.look_at(target)
	for i in range(18):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-road-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.reset_game()
	game.set_state("play")
	game.set_physics_process(false)
	await capture("start",Vector3(0,0.01,-94),Vector3(7,1.6,-106))
	await capture("bend",Vector3(13,3.3,-110),Vector3(26,7.6,-117))
	await capture("arrival",Vector3(29,8.9,-125),Vector3(29,10,-134))
	game.fog_atmosphere.set_process(false)
	game.fog_atmosphere.environment.fog_density = 0.018
	await capture("overview",Vector3(4,23,-128),Vector3(17,3,-113))
	print("PASS: smoothed chapel road render views")
	quit()
