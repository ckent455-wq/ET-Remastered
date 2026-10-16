extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
	var world = Node3D.new()
	root.add_child(world)
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("293031")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.8
	world.add_child(env)
	var light = DirectionalLight3D.new()
	world.add_child(light)
	light.rotation_degrees = Vector3(-35,-25,0)
	var cam = Camera3D.new()
	world.add_child(cam)
	cam.current = true
	for asset in ["front","nave","apse","gothic_trim","door","pew"]:
		var model = load("res://assets/church/"+asset+".glb").instantiate()
		world.add_child(model)
		cam.position = Vector3(14,11,24) if asset in ["front","nave","apse"] else Vector3(10,6,15) if asset=="gothic_trim" else Vector3(3,2.8,5)
		cam.look_at(Vector3(0,5,0) if asset in ["front","nave","apse"] else Vector3(0,3.5,0) if asset=="gothic_trim" else Vector3(0,1,0))
		for f in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/church-asset-"+asset+".png")
		model.queue_free()
		await process_frame
	quit()
