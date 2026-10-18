extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.reset_game()
	game.set_state("play")
	game.set_physics_process(false)
	var church = game.town.streetscape.church
	await physics_frame
	assert(not church.doors_open and not church.entrance_collision.disabled,"Church starts shut and solid")
	game.player.position = Vector3(29,9.01,-131)
	game.camera.look_at(game.town.actions.chapel_doors.area.global_position)
	await physics_frame
	game.town.refresh_focus()
	assert(game.town.focus_action=="chapel_doors","Door can be targeted from outside")
	var hit = game.player.move_and_collide(Vector3(0,0,-4))
	assert(hit!=null,"Shut entrance blocks walking")
	var event = InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	game._unhandled_input(event)
	await create_timer(0.8).timeout
	assert(church.doors_open and church.entrance_collision.disabled,"E opens both doors")
	for hinge in church.door_hinges:
		var leaf_center = hinge.to_global(Vector3(0.7 if hinge.position.x<0 else -0.7,1,0))
		assert(leaf_center.z>church.global_position.z+7.5,"Leaves swing outward")
	game.player.position = Vector3(29,9.01,-136)
	church.toggle_doors()
	assert(church.doors_open,"Cannot close onto player inside")
	game.player.position = Vector3(29,9.01,-130)
	game.camera.look_at(game.town.actions.chapel_doors.area.global_position)
	church.toggle_doors()
	await create_timer(0.8).timeout
	assert(not church.doors_open and not church.entrance_collision.disabled,"Can close from safe distance")
	assert(game.town.streetscape.chapel_hill.ROAD_POINTS[-1].distance_to(Vector3(29,9,-134))>7,"Asphalt ends away from church doors")
	assert(game.flashlight_charge==game.START_FLASHLIGHT_CHARGE,"Partial starting cell")
	game.flashlight.visible = true
	game.update_flashlight_battery(10)
	assert(game.flashlight_charge==game.START_FLASHLIGHT_CHARGE-5,"Charge drains while on")
	game.flashlight.visible = false
	var saved_charge = game.flashlight_charge
	game.update_flashlight_battery(100)
	assert(game.flashlight_charge==saved_charge,"Off saves charge")
	game.flashlight.visible = true
	game.state = "journal"
	game.update_flashlight_battery(100)
	assert(game.flashlight_charge==saved_charge,"Journal pauses drain")
	game.state = "play"
	game.update_flashlight_battery(200)
	assert(game.flashlight_charge==0 and not game.flashlight.visible,"Empty battery switches light off")
	game.toggle_flashlight()
	assert(not game.flashlight.visible,"Cannot turn on empty light")
	game.town.use_battery()
	assert(game.flashlight_charge==0,"No free battery")
	game.town.perform("store_cabinet")
	assert(game.town.inventory.battery==2,"Search stock cabinet for batteries")
	game.town.use_battery()
	assert(game.flashlight_charge==100 and game.town.inventory.battery==1,"Fitting battery consumes one collected cell")
	game.toggle_flashlight()
	assert(game.flashlight.visible,"Refilled flashlight works")
	game.flashlight_charge = 12
	game.town.powered = true
	game.town.perform("battery_panel")
	assert(game.flashlight_charge==12,"Workshop cannot recharge disposable cell")
	game.reset_game()
	await physics_frame
	assert(not church.doors_open and not church.entrance_collision.disabled,"Restart closes church")
	print("PASS: closed physical chapel doors, E interaction, outward swing, safe closing, separated road, charge drain/off/pause/exhaustion, collected battery use, restart")
	quit()
