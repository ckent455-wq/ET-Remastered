extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	await physics_frame
	var enemies = game.enemies
	enemies.set_physics_process(false)
	assert(enemies.creatures.size()==3)
	for i in range(3): assert(enemies.shoot(i,999))
	enemies._physics_process(119)
	for data in enemies.creatures: assert(data.state=="dead" and is_equal_approx(data.respawn_remaining,1))
	game.state = "journal"
	enemies._physics_process(80)
	for data in enemies.creatures: assert(data.state=="dead" and is_equal_approx(data.respawn_remaining,1))
	game.state = "play"
	enemies._physics_process(1)
	for data in enemies.creatures:
		assert(data.state=="lurking" and data.hp==85 and data.actor.collision_layer==1)
		assert(data.actor.position.is_equal_approx(data.spawn) and data.clip=="crouch_pose")
	assert(enemies.shoot(2,999))
	enemies._physics_process(60)
	assert(not enemies.shoot(2,999) and enemies.creatures[2].respawn_remaining==60)
	game.reset_game()
	assert(enemies.creatures[2].respawn_remaining==0)
	print("PASS: three monsters; 120 gameplay seconds respawn; journal pause; original hiding places, health, collision and animation restored; reset")
	game.queue_free()
	await process_frame
	quit()
