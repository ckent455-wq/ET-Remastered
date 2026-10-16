extends SceneTree
var game
func _initialize(): call_deferred("run")
func capture(label: String, feet: Vector3, target: Vector3):
	var church = game.town.streetscape.church
	game.player.position = church.to_global(feet)
	game.camera.look_at(church.to_global(target))
	for frame in range(14): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/church-repair-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.state = "play"
	game.soundscape.toggle_mute()
	await capture("front",Vector3(0,0.02,12),Vector3(0,2.4,7))
	await capture("closed-close",Vector3(0,0.02,9.3),Vector3(0,1.5,7))
	await capture("whole",Vector3(0,0.02,25),Vector3(0,9,2))
	game.town.perform("chapel_doors")
	await create_timer(0.8).timeout
	await capture("open-close",Vector3(0,0.02,10.5),Vector3(0,1.5,5.5))
	await capture("nave",Vector3(0,0.02,5.3),Vector3(0,2,-5.5))
	await capture("ceiling",Vector3(0,0.02,-0.5),Vector3(0,7.7,-3))
	await capture("side",Vector3(0,0.02,-0.5),Vector3(-4.7,2.2,-0.5))
	await capture("door-back",Vector3(0,0.02,4.9),Vector3(-1.4,1.2,8.4))
	await capture("rear",Vector3(0,0.02,-4.4),Vector3(0,2.0,6.8))
	await capture("altar",Vector3(0,0.02,-3.9),Vector3(0,1,-5.5))
	await capture("cellar",Vector3(3.25,0.02,-4.9),Vector3(3.25,1.4,-6.7))
	game.town.inventory.chapel_key = 1
	game.town.perform("cellar_door")
	await create_timer(0.7).timeout
	await capture("cellar-open",Vector3(3.25,0.02,-4.8),Vector3(3.25,1.3,-6.7))
	print("PASS: church repair exterior, closed/open doors, nave, ceiling, side, rear, altar and cellar renders")
	game.queue_free()
	await process_frame
	quit()
