extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	var landscape = game.distant_landscape
	assert(landscape.environment.background_mode==Environment.BG_SKY and landscape.environment.sky!=null,"Cloud sky enabled")
	assert(landscape.environment.ambient_light_source==Environment.AMBIENT_SOURCE_COLOR,"Overcast sky retains horror lighting")
	var panorama = landscape.sky_material.get_shader_parameter("panorama")
	assert(panorama.get_width()==512 and panorama.get_height()==256,"Small local panoramic sky")
	var triangles = 0
	for ridge in landscape.ridges:
		triangles += ridge.mesh.get_faces().size()/3
		assert(ridge.get_child_count()==0,"Backdrop adds no playable collision")
	assert(triangles<=1000 and landscape.ridges.size()==2,"Two low-poly hill layers")
	assert(game.camera.far>=230 and game.title_camera.far>=230,"Hill silhouettes visible from both views")
	assert(game.flashlight_model.get_parent()==game.arm_visual and game.flashlight_model.is_visible_in_tree(),"Local flashlight replaces placeholder")
	game.state = "play"
	var input = InputEventKey.new()
	input.keycode = KEY_F
	input.pressed = true
	game._unhandled_input(input)
	assert(not game.flashlight.visible,"Flashlight switches off")
	game._unhandled_input(input)
	assert(game.flashlight.visible,"Flashlight switches on")
	game.weapons.collect(0)
	assert(not game.arm_visual.visible and not game.flashlight_model.is_visible_in_tree(),"No flashlight or arm in equipped gun view")
	game.weapons.equip(-1)
	assert(game.flashlight_model.is_visible_in_tree(),"Holstering restores local flashlight")
	game.reset_game()
	assert(game.flashlight.visible and game.flashlight_model.is_visible_in_tree() and game.weapons.selected== -1,"New journey preserves flashlight behavior")
	print("PASS: cloudy local panorama, ",triangles," backdrop triangles, no terrain collision, local flashlight, F input, gun/holster visibility and restart")
	game.queue_free()
	await process_frame
	quit()
