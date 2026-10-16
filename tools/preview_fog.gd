extends SceneTree
var game
func _initialize():
	call_deferred("run")
func capture(label: String, p: Vector3, target: Vector3):
	game.player.position = p
	game.camera.look_at(target)
	for frame in range(45):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-fog-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.town.townspeople.set_physics_process(false)
	game.set_state("play")
	await capture("approach",Vector3(0,0.001,-12),Vector3(0,1.35,-36))
	await capture("street",Vector3(0,0.001,-41),Vector3(0,1.4,-68))
	await capture("interior",game.town.buildings.ranger.to_global(Vector3(0,0.001,3)),game.town.actions.weapon_pistol.area.global_position)
	await capture("drift",Vector3(0,0.001,-21),Vector3(0,1.3,-35))
	var with_particles = root.get_texture().get_image()
	for emitter in game.fog_atmosphere.emitters:
		emitter.visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	var without_particles = root.get_texture().get_image()
	var changed = 0
	for y in range(80,300):
		for x in range(50,590):
			var a = with_particles.get_pixel(x,y)
			var b = without_particles.get_pixel(x,y)
			if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.025:
				changed += 1
	assert(changed>400,"Fog particles must visibly affect the actual render")
	print("PASS: real-renderer fog/closed sightlines/interior previews; particle visibility changed ",changed," pixels")
	game.queue_free()
	await process_frame
	quit()
