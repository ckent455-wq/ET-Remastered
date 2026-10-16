extends SceneTree
var game
func _initialize():
	call_deferred("run")
func press_e():
	var event = InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	game._unhandled_input(event)
func aim(id: String):
	game.camera.look_at(game.town.actions[id].area.global_position)
	await physics_frame
	game.town.refresh_focus()
	assert(game.town.focus_action==id,"Real targeting: "+id+" got "+game.town.focus_action)
func walk_to(target: Vector3):
	game.camera.rotation = Vector3.ZERO
	var key = InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	var reached = false
	for frame in range(300):
		var delta = target-game.player.position
		delta.y = 0
		if delta.length()<0.22:
			reached = true
			break
		game.player.rotation.y = atan2(-delta.x,-delta.z)
		await physics_frame
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	await physics_frame
	assert(reached,"Walkable cellar at "+str(target)+" from "+str(game.player.position))
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.reset_game()
	game.set_state("play")
	var town = game.town
	var chapel = town.streetscape.church
	var cellar = chapel.basement
	await physics_frame
	game.player.position = chapel.to_global(Vector3(0,0.01,5.4))
	await walk_to(chapel.to_global(Vector3(0,0.01,-4.6)))
	await walk_to(chapel.to_global(Vector3(3.25,0.01,-4.6)))
	await aim("cellar_door")
	press_e()
	assert(not cellar.unlocked and not cellar.contains(game.player.position),"Locked cellar cannot be entered")
	town.perform("radio_tuner")
	assert(town.inventory.tuner==0,"Cannot claim part outside locked cellar")
	town.perform("workshop_cabinet")
	assert(town.inventory.chapel_key==0,"Cabinet requires power before key")
	town.perform("store_drawer")
	town.perform("fuse_panel")
	town.perform("workshop_cabinet")
	assert(town.inventory.chapel_key==1 and town.inventory.coil==1,"Cabinet gives key and coil")
	town.perform("receiver")
	assert(not town.radio_ready and town.inventory.coil==1,"Missing cellar part blocks repair without consuming coil")
	await aim("cellar_door")
	press_e()
	assert(cellar.unlocked and not cellar.padlock.visible,"Key unlocks physical door")
	assert(not cellar.contains(game.player.position),"Unlock is separate from descending")
	await aim("cellar_door")
	press_e()
	assert(cellar.contains(game.player.position),"Enter real cellar interior")
	for i in range(30):
		await physics_frame
	assert(game.player.position.y< -3.9,"Basement movement not clamped onto surface")
	town.game.fog_atmosphere.update_fog(3)
	assert(game.fog_atmosphere.indoors and town.location_name().contains("CELLAR"),"Interior visibility and journal location")
	await walk_to(cellar.to_global(Vector3(-2.6,0.01,-1.8)))
	await aim("radio_tuner")
	press_e()
	assert(town.inventory.tuner==1 and town.actions.radio_tuner.taken,"Workbench pickup through E")
	town.perform("radio_tuner")
	assert(town.inventory.tuner==1,"No duplicate tuning unit")
	await walk_to(cellar.to_global(Vector3(0,0.01,1.4)))
	await walk_to(cellar.to_global(Vector3(0,1.1,4.5)))
	assert(game.player.position.y> -3.25,"Actual walk up return stairs")
	await aim("cellar_exit")
	press_e()
	assert(not cellar.contains(game.player.position) and chapel.contains(game.player.position),"Return upstairs")
	town.perform("receiver")
	assert(town.radio_ready and town.inventory.coil==0 and town.inventory.tuner==0,"Repair consumes both required parts")
	game.player.position = town.buildings.radio.to_global(Vector3(-2.7,0.001,-2))
	game.update_contact(4.1,true)
	assert(game.state=="won","Church-inclusive rescue quest can finish")
	game.reset_game()
	await physics_frame
	assert(not cellar.unlocked and not cellar.visited and cellar.padlock.visible,"New journey relocks cellar")
	assert(town.inventory.chapel_key==0 and town.inventory.tuner==0 and not town.actions.radio_tuner.taken,"Key and part reset")
	print("PASS: locked cellar, power-gated key, real E unlock/enter/pickup/exit, negative-height physics, walkable room and stairs, both-part rescue gate, no duplicates, reset")
	quit()
