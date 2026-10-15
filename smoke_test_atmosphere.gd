extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.town.townspeople.set_physics_process(false)
	var sound = game.soundscape
	sound.set_process(false)
	var atmosphere = sound.atmosphere
	for frame in range(3):
		await process_frame
	game.state = "play"
	game.player.position = Vector3(0,0.001,-41)
	sound.update_sound(0.1)
	assert(atmosphere.entered_town and atmosphere.last_cue=="bell","Arrival accent")
	assert(atmosphere.accent.playing,"Downloaded audio is playable")
	var count = atmosphere.events_played
	sound.update_sound(0.1)
	assert(atmosphere.events_played==count,"No repeated arrival accent")
	atmosphere.accent.stop()
	game.player.position = game.town.buildings.ranger.to_global(Vector3(0,0.001,1))
	sound.update_sound(0.1)
	assert(atmosphere.current_interior=="ranger","Indoor acoustics follow rotated buildings")
	assert(sound.wind.volume_db== -20,"Outdoor wind reduced inside")
	atmosphere.event_timer = 0
	sound.update_sound(0.1)
	assert(atmosphere.last_cue=="house_creak" and atmosphere.accent.playing,"Contextual indoor creak")
	game.state = "paused"
	var remaining = atmosphere.event_timer
	sound.update_sound(2)
	assert(not atmosphere.accent.playing and atmosphere.radio.stream_paused and atmosphere.bed.stream_paused,"Audio pauses")
	assert(atmosphere.event_timer==remaining,"Timers freeze while paused")
	sound.toggle_mute()
	assert(AudioServer.is_bus_mute(sound.bus_index),"Shared bus mutes downloaded sounds too")
	sound.toggle_mute()
	game.state = "play"
	sound.update_sound(0.1)
	assert(not atmosphere.radio.stream_paused and not atmosphere.bed.stream_paused,"Looping ambience resumes")
	for sliding in [true,false]:
		for opening in [true,false]:
			sound.storage_move(Vector3.ZERO,sliding,opening)
			var expected = ("drawer" if sliding else "cabinet")+("_open" if opening else "_close")
			assert(sound.storage_voice.stream==sound.storage_streams[expected],"Correct recorded storage direction")
	for enabled in [true,false]:
		sound.flashlight_click(enabled)
		assert(sound.click.stream==sound.flashlight_streams[enabled],"Distinct flashlight recordings")
	game.town.radio_ready = true
	sound.update_sound(0.1)
	assert(atmosphere.radio.volume_db== -39,"Repaired radio static recedes")
	var streetscape = game.town.streetscape
	assert(streetscape.road_mesh.get_surface_count()==3,"Asphalt surfaces retained, raised concrete omitted")
	var segments = 0
	for child in streetscape.get_children():
		if child.name.begins_with("DownloadedRoadSegment") or (child is MeshInstance3D and child.mesh==streetscape.road_mesh):
			segments += 1
	assert(segments==10,"Downloaded road covers both approach and town")
	game.reset_game()
	assert(not atmosphere.entered_town and atmosphere.visited_interiors.is_empty() and not atmosphere.accent.playing,"Fresh journey resets horror cues")
	print("PASS: downloaded sound playback, arrival/indoor cues, pause/resume, mute, directional storage and flashlight sounds, radio repair, ten downloaded road segments, reset")
	game.queue_free()
	await process_frame
	quit()
