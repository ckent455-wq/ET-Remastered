extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	game.invincible = 999
	var enemies = game.enemies
	game.player.position = Vector3(0,0.01,-80)
	for i in range(240): await physics_frame
	for data in enemies.creatures:
		assert(data.state=="lurking" and data.clip=="crouch_pose","No visible Main Street sentries")
		assert(data.actor.position.distance_to(data.spawn)<0.3,"No wandering out of the woods before approach")
		assert(data.spawn.z< -120 and data.spawn.y>7,"Church woodland spawns on hillside")
		assert(not enemies.line_clear(data,Vector3(27,10,-118)),"Approach sightline blocked by real cover")
	var data = enemies.creatures[0]
	game.player.position = Vector3(29,9.05,-128)
	game.camera.look_at(Vector3(29,10,-142))
	var before: Vector3 = data.actor.position
	for i in range(600): await physics_frame
	assert(data.state in ["stalking","chase","attack"],"Delayed woodland encounter activated")
	assert(data.actor.position.distance_to(before)>1.5,"Creature emerges using actual movement")
	assert(data.actor.position.y>7,"No falling through the chapel hillside")
	game.state = "journal"
	before = data.actor.position
	for i in range(60): await physics_frame
	assert(data.actor.position.is_equal_approx(before),"Stalking pauses with journal")
	game.reset_game()
	assert(data.state=="lurking" and data.actor.position.distance_to(data.spawn)<0.01,"Reset returns creature to its hiding place")
	print("PASS: hidden church woodland starts, occluded road approach, quiet Main Street, delayed stalking, real hillside movement, paused stalking and reset")
	game.queue_free()
	await process_frame
	quit()
