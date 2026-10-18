extends SceneTree
var game
func _initialize(): call_deferred("check")
func read_record(id: String):
	game.state = "play"
	game.town.perform(id)
	assert(game.state=="journal" and game.story.evidence.has(id),"Record saved: "+id)
func complete_quest(direct = false):
	var town = game.town
	game.state = "play"
	for id in ["ranger_drawer","store_drawer","battery_panel","workshop_cabinet","cellar_door","radio_tuner","cellar_exit","receiver"]:
		town.perform(id)
	assert(town.radio_ready,"Original quest still works")
	if direct: town.perform("radio_bypass")
	game.player.position = town.buildings.radio.to_global(Vector3(-2.7,0.001,-2))
	game.update_contact(4.1,true)
	assert(game.state=="won","Rescue stays available without mandatory evidence")
func real_read(id: String, feet: Vector3):
	game.state = "play"
	game.player.global_position = feet
	game.player.rotation = Vector3.ZERO
	game.camera.rotation = Vector3.ZERO
	game.camera.look_at(game.town.actions[id].area.global_position)
	await physics_frame
	game.town.refresh_focus()
	assert(game.town.focus_action==id,"Physical story document reachable: "+id+" got "+game.town.focus_action)
	var event = InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	game._unhandled_input(event)
	assert(game.state=="journal" and game.story.evidence.has(id),"Real E reads document: "+id)
func check():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.state = "play"
	await physics_frame
	assert(game.story.RECORDS.size()==9 and game.story.evidence.is_empty(),"Nine original story records; clean start")
	game.town.perform("crash_wreck")
	assert(game.story.evidence.has("crash_record") and not game.town.reached_town,"Wreck reveals detour without skipping arrival")
	read_record("ranger_note")
	var known = game.town.journal_entries.size()
	read_record("ranger_note")
	assert(game.town.journal_entries.size()==known,"No duplicated evidence or journal entries")
	assert("barrier" in game.town.townspeople.words("ranger"),"Clue-aware NPC conversation")
	var event = InputEventKey.new()
	event.keycode = KEY_C
	event.pressed = true
	game._unhandled_input(event)
	assert(game.journal_casefile,"C opens case notes inside journal")
	await real_read("workshop_record",game.town.buildings.workshop.to_global(Vector3(-3.15,0.01,-0.9)))
	await real_read("chapel_record",game.town.streetscape.church.to_global(Vector3(-3.1,0.01,5.3)))
	await real_read("cellar_record",game.town.streetscape.church.basement.to_global(Vector3(-1.2,0.01,-1.7)))
	game.reset_game()
	assert(game.story.evidence.is_empty() and not game.journal_casefile,"New journey clears the investigation")
	complete_quest()
	assert(game.story.ending_title()=="SOMETHING ANSWERED" and "repeater" in game.story.ending_text(),"Repeater still connected ending")
	game.reset_game()
	for id in game.story.PROTOCOL: read_record(id)
	assert(not game.story.direct_channel_selected(),"Reading documents alone cannot retune hardware")
	game.state = "play"
	game.town.perform("radio_bypass")
	assert(not game.story.direct_channel_selected(),"Bypass needs repaired transmitter")
	complete_quest(true)
	assert("without sirens" in game.story.rescue_line(1),"Player transmits learned warning")
	assert(game.story.ending_title()=="NO SIRENS" and "surviving residents" in game.story.ending_text(),"Informed county response")
	game.town.townspeople.characters.nurse.dead = true
	assert("2 surviving" in game.story.ending_text(),"Ending reflects NPC survival")
	print("PASS: nine story records, wreck evidence, clue-aware dialogue, deduplicated journal, case notes, full quest with both endings, survivor count and reset")
	game.queue_free()
	await process_frame
	quit()
