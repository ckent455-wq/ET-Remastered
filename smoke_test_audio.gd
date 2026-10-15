extends SceneTree
func _initialize():
	call_deferred("check_audio")
func check_audio():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var sound = game.soundscape
	sound.set_process(false)
	game.state = "play"
	sound.update_sound(0.016)
	assert(sound.wind.playing and sound.leaves.playing,"Forest loops")
	assert(sound.wind.stream.loop_end>0,"Loop configured")
	var key = InputEventKey.new()
	key.keycode = KEY_F
	key.pressed = true
	var was_enabled = game.flashlight.visible
	game._unhandled_input(key)
	assert(game.flashlight.visible!=was_enabled and sound.click.playing,"F toggles light and clicks")
	sound.moved(2.1,false,true)
	assert(sound.steps[0].playing,"Walking triggers step")
	sound.moved(2.6,true,true)
	assert(sound.steps[1].playing and sound.steps[1].volume_db>sound.steps[0].volume_db,"Running step is louder")
	sound.moved(0,false,true)
	assert(sound.step_distance==0,"No accumulated steps when blocked or stopped")
	sound.moved(5,false,false)
	assert(sound.step_distance==0,"No midair steps")
	assert(not "drone_voices" in sound,"Drone audio removed")
	sound.animal_timer = 0
	sound.update_sound(0.1)
	assert(sound.animals[0].playing and sound.animal_timer>=10,"Random spaced animal call")
	var distance = sound.animals[0].global_position.distance_to(game.player.global_position)
	assert(distance>=13 and distance<27,"Animal placed in surrounding forest")
	sound.toggle_mute()
	assert(AudioServer.is_bus_mute(sound.bus_index),"M mutes every game sound")
	sound.toggle_mute()
	assert(not AudioServer.is_bus_mute(sound.bus_index),"Unmute")
	game.state = "paused"
	sound.update_sound(0.1)
	await physics_frame
	await process_frame
	assert(sound.wind.stream_paused and sound.leaves.stream_paused,"Pause ambience")
	assert(not sound.animals[0].playing,"Stop animal calls on pause")
	assert(not sound.click.playing,"Stop flashlight click on pause")
	game.state = "play"
	sound.update_sound(0.1)
	assert(not sound.wind.stream_paused and not sound.leaves.stream_paused,"Resume")
	game.reset_game()
	assert(not sound.animals[0].playing and sound.step_distance==0,"Restart clears transient sounds")
	key = null
	game.queue_free()
	await process_frame
	assert(AudioServer.get_bus_index("ForestAudio")==-1,"Audio bus cleanup")
	print("PASS: flashlight, footsteps, sprint, stationary/airborne silence, no drone audio, animals, mute, pause/resume, restart, cleanup")
	quit()
