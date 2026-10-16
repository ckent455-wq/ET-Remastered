extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "play"
	await physics_frame
	await physics_frame
	var enemies = game.enemies
	assert(enemies.navigation.graph.get_point_count()>100,"Real chapel route graph built")
	for index in range(3):
		game.reset_game()
		game.state = "play"
		game.player.position = Vector3(29,9.05,-128)
		game.camera.look_at(Vector3(29,10,-143))
		for other_index in range(3):
			if other_index!=index: enemies.shoot(other_index,999)
		var data = enemies.creatures[index]
		var start: Vector3 = data.actor.position
		for frame in range(1800):
			await physics_frame
			if game.health<100: break
		assert(data.actor.position.distance_to(start)>7,"Leaves actual woodland hiding place: "+str(index))
		print("FINAL ",index," ",data.actor.position," ",data.state," waypoint ",data.waypoint," hp ",game.health)
		assert(game.health==78,"Reaches and damages player on real church hill: "+str(index))
		assert(data.actor.position.y>8.7,"No downhill drift or sinking")
		print("HILL ATTACK PASS / ",index," / ",data.actor.position)
	print("PASS: all three hidden woodland creatures navigate real trees and cover, climb to the court and land telegraphed attacks")
	game.queue_free()
	await process_frame
	quit()
