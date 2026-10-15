extends SceneTree
var game
func _initialize():
	call_deferred("check")
func check():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	await physics_frame
	assert(game.state=="intro","Studio presentation before title")
	var key = InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_ENTER
	game._unhandled_input(key)
	assert(game.state=="title","Enter skips presentation to title only")
	game.state = "intro"
	game.intro_elapsed = 3.59
	game._process(0.1)
	assert(game.state=="title","Presentation auto advances")
	var legacy = game.get_property_list().any(func(p): return p.name in ["parts","found","PART_POSITIONS"])
	assert(not legacy,"Ship-part collection removed")
	game.state = "play"
	var town = game.town
	assert(get_nodes_in_group("TownNPCs").size()==3,"Three local humanoid NPCs")
	for id in town.townspeople.characters:
		var data = town.townspeople.characters[id]
		game.player.position = data.actor.global_position+Vector3(0,0.1,2.4)
		game.player.rotation = Vector3.ZERO
		game.camera.rotation = Vector3.ZERO
		game.camera.look_at(town.actions["npc_"+id].area.global_position)
		await physics_frame
		town.refresh_focus()
		assert(town.focus_action=="npc_"+id,"NPC interaction reachable: "+id)
		key.keycode = KEY_E
		game._unhandled_input(key)
		assert(game.state=="dialogue" and game.dialogue_name==data.name and game.dialogue_text.length()>40,"NPC conversation")
		game.soundscape.update_sound(0.1)
		assert(game.soundscape.wind.stream_paused,"Dialogue pauses ambience")
		game._unhandled_input(key)
		assert(game.state=="play","E closes conversation without reopening it")
	# Inside protection works for both north-facing and south-facing buildings.
	town.inventory.station_key = 1
	for data in town.BUILDINGS:
		var house = town.buildings[data.id]
		game.player.position = house.to_global(Vector3(0,0.1,7))
		town.perform(data.id+"_door")
		assert(town.doors[data.id].open,"Door opens from outside")
		game.player.position = house.to_global(Vector3(0,0.1,-3))
		town.perform(data.id+"_door")
		assert(town.doors[data.id].open,"Door cannot close from deep inside: "+data.id)
		game.player.position = house.to_global(Vector3(0,0.1,5))
		town.perform(data.id+"_door")
		assert(town.doors[data.id].open,"Threshold protection")
		game.player.position = house.to_global(Vector3(0,0.1,7))
		town.perform(data.id+"_door")
		assert(not town.doors[data.id].open,"Door closes after exiting")
	game.reset_game()
	game.state = "play"
	town.perform("ranger_drawer")
	town.perform("store_drawer")
	town.perform("fuse_panel")
	town.perform("workshop_cabinet")
	town.perform("receiver")
	assert(town.radio_ready and game.beam.visible,"Town quest works without ship parts")
	game.player.position = Vector3.ZERO
	game.update_contact(4.1,true)
	assert(game.state=="won","Rescue without forest collection")
	for data in town.actions.values():
		if data.kind=="note":
			assert(not "three forest" in data.text.to_lower() and not "transmitter parts" in data.text.to_lower(),"No obsolete note objectives")
	print("PASS: studio intro/skip, removed parts, three NPCs, real E conversations, dialogue pause, six protected building doors, outside closure, town-only rescue")
	key = null
	game.queue_free()
	await process_frame
	quit()
