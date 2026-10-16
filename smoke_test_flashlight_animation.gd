extends SceneTree
func _initialize():
	call_deferred("check")
func toggle(game):
	var key = InputEventKey.new()
	key.keycode = KEY_F
	key.pressed = true
	game._unhandled_input(key)
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.state = "play"
	assert(game.arm_visual.get_child_count()==1 and game.arm_visual.get_child(0)==game.flashlight_model,"No arm, palm or finger geometry")
	var camera_pose = game.camera.transform
	toggle(game)
	assert(not game.flashlight.visible,"Beam switches off immediately")
	game.update_flashlight_visual(0.12)
	assert(game.flashlight_model.visible and game.flashlight_model.position.y<game.FLASHLIGHT_UP.y,"Flashlight lowers before hiding")
	var halfway = game.flashlight_raise
	game.state = "paused"
	game.update_flashlight_visual(1)
	assert(game.flashlight_raise==halfway,"Animation pauses")
	game.state = "play"
	toggle(game)
	game.update_flashlight_visual(0.03)
	assert(game.flashlight_raise>halfway and game.flashlight_raise<1,"Rapid toggle reverses smoothly")
	game.update_flashlight_visual(1)
	assert(game.flashlight_model.position==game.FLASHLIGHT_UP,"Raised pose settles")
	toggle(game)
	game.update_flashlight_visual(1)
	assert(not game.flashlight_model.visible,"Off flashlight disappears")
	game.flashlight_charge = 0
	toggle(game)
	game.update_flashlight_visual(1)
	assert(not game.flashlight.visible and not game.flashlight_model.visible,"Empty battery cannot raise flashlight")
	game.reset_game()
	assert(game.flashlight_model.visible and game.flashlight_raise==1,"Restart restores raised flashlight")
	game.weapons.collect(0)
	game.update_flashlight_visual(1)
	assert(not game.flashlight_model.is_visible_in_tree(),"Gun hides flashlight")
	game.weapons.equip(-1)
	game.update_flashlight_visual(1)
	assert(game.flashlight_model.is_visible_in_tree(),"Holstering raises enabled flashlight")
	assert(game.camera.transform==camera_pose,"Animation never moves camera")
	print("PASS: no arm geometry, animated lowering/hiding/raising, rapid reversal, pause, depleted battery, weapons, restart, steady camera")
	game.queue_free()
	await process_frame
	quit()
