extends SceneTree
var game
func _initialize():
	call_deferred("run")
func walk_to(target: Vector3):
	for frame in range(180):
		var delta = target-game.player.position
		delta.y = 0
		if delta.length()<0.22:
			return true
		game.player.rotation.y = atan2(-delta.x,-delta.z)
		await physics_frame
	for i in range(game.player.get_slide_collision_count()):
		var hit = game.player.get_slide_collision(i)
		print("BLOCK ",hit.get_collider().name," ",hit.get_normal()," ",hit.get_position())
	push_error("Road blocked at "+str(game.player.position)+" toward "+str(target))
	return false
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.reset_game()
	game.set_state("play")
	var hill = game.town.streetscape.chapel_hill
	var faces = hill.get_node("UphillAsphalt").mesh.get_faces()
	for i in range(hill.samples.size()-2):
		assert(faces[i*6+1].is_equal_approx(faces[(i+1)*6]),"Continuous left edge")
		assert(faces[i*6+5].is_equal_approx(faces[(i+1)*6+2]),"Continuous right edge")
	for i in range(faces.size()/3):
		assert((faces[i*3+1]-faces[i*3]).cross(faces[i*3+2]-faces[i*3]).y<0,"Asphalt top faces upward")
	var key = InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	for offset in [-1.2,1.2]:
		game.player.position = hill.samples[0]+hill.road_sides[0]*offset+Vector3(0,0.02,0)
		game.player.velocity = Vector3.ZERO
		for i in range(4,hill.samples.size(),4):
			assert(await walk_to(hill.samples[i]+hill.road_sides[i]*offset),"Full-width climb")
		assert(await walk_to(hill.samples[-1]+hill.road_sides[-1]*offset),"Forecourt arrival")
		assert(game.player.position.y>8.8,"Nine metre road climb")
		for i in range(hill.samples.size()-5,-1,-4):
			assert(await walk_to(hill.samples[i]+hill.road_sides[i]*offset),"Full-width descent")
		assert(await walk_to(hill.samples[0]+hill.road_sides[0]*offset),"Street arrival")
		assert(game.player.position.y<0.15,"Back to street level")
	key.pressed = false
	Input.parse_input_event(key)
	print("PASS: continuous shared road edges, upward winding, uphill/downhill walks on both sides of lane")
	quit()
