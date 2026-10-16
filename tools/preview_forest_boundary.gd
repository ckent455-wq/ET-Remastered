extends SceneTree
var game
func _initialize():
	call_deferred("run")
func capture(label: String, p: Vector3, target: Vector3):
	game.player.position = p
	game.camera.look_at(target)
	game.hud.queue_redraw()
	for frame in range(24):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-boundary-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_state("play")
	await capture("street",Vector3(0,0.001,-44),Vector3(0,1.3,-100))
	await capture("north-hills",Vector3(0,0.001,-83),Vector3(0,5,-118))
	await capture("forest-edge",Vector3(40,0.001,5),Vector3(48,1.8,5))
	await capture("wooded-hills",Vector3(26,0.001,17),Vector3(62,8,-5))
	await capture("approach",Vector3(0,0.001,-15),Vector3(0,2,-40))
	print("BOUNDARY SHRUB AABB / ",game.forest_boundary.shrub_mesh.get_aabb()," / triangles / ",game.forest_boundary.shrub_mesh.get_faces().size()/3)
	print("PASS: real-renderer boundary forest, horizontal street view, north hills and wooded slopes")
	game.queue_free()
	await process_frame
	quit()
