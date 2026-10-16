extends SceneTree
var game
func _initialize():
	call_deferred("run")
func walk_to(target: Vector3):
	for frame in range(420):
		var delta = target-game.player.position
		delta.y = 0
		if delta.length()<0.25:
			return true
		game.player.rotation.y = atan2(-delta.x,-delta.z)
		await physics_frame
	for i in range(game.player.get_slide_collision_count()):
		var hit = game.player.get_slide_collision(i)
		print("BLOCKER ",hit.get_collider().name," normal ",hit.get_normal()," at ",hit.get_position())
	push_error("Walk blocked toward "+str(target)+" at "+str(game.player.position))
	return false
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_state("play")
	game.player.position = Vector3(0,0.001,-88)
	var key = InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	for point in game.town.streetscape.chapel_hill.ROAD_POINTS:
		if not await walk_to(point):
			quit(1)
			return
	assert(game.player.position.y>8.9,"Real nine metre climb")
	assert(await walk_to(Vector3(32,9,-130)),"Forecourt path")
	assert(await walk_to(Vector3(29,9,-132)),"Approach doors along footpath")
	game.town.perform("chapel_doors")
	assert(await walk_to(Vector3(29,9,-144)),"Enter chapel aisle")
	assert(game.town.streetscape.church.contains(game.player.position),"Inside hilltop chapel")
	assert(await walk_to(Vector3(29,9,-134)),"Exit chapel")
	assert(await walk_to(Vector3(32,9,-130)),"Follow path back")
	var reverse = game.town.streetscape.chapel_hill.ROAD_POINTS.duplicate()
	reverse.reverse()
	for point in reverse:
		assert(await walk_to(point),"Return downhill")
	assert(await walk_to(Vector3(0,0,-88)))
	assert(game.player.position.y<0.1,"Return to Main Street level")
	key.pressed = false
	Input.parse_input_event(key)
	print("PASS: walked uphill nine metres, entered and exited chapel, walked back to Main Street using normal player physics")
	quit()
