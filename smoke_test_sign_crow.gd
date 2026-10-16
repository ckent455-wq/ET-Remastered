extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var crow = game.town.sign_crow
	assert(crow.get_parent().name=="BlackwoodRoadSign","Crow attached to entrance sign")
	assert(crow.position.is_equal_approx(crow.PERCH_POSITION),"Feet aligned with sign top")
	assert(crow.animation.has_animation("watch") and crow.animation.has_animation("call") and crow.animation.has_animation("ruffle"),"Original perch/call animations")
	var material = crow.model.get_node("Skeleton3D/Crow").get_surface_override_material(0)
	assert(material.albedo_texture.get_width()==256 and material.roughness==1,"Retro texture and matte feathers")
	assert(crow.calls.size()==2 and crow.calls[0].get_length()>1 and crow.calls[1].get_length()>1,"Both original crow calls")
	game.set_state("title")
	game.player.position = crow.global_position+Vector3(0,-2,8)
	crow._process(2)
	assert(crow.calls_played==0,"No calls over title")
	game.set_state("play")
	crow._process(0.1)
	assert(crow.greeted and crow.calls_played==1,"First approach triggers sign call")
	assert(crow.voice.bus==game.soundscape.BUS and crow.voice.max_distance==36 and crow.voice.volume_db>=-4 and crow.voice.unit_size>=12,"Local sound follows game mute bus")
	await process_frame
	await process_frame
	var timer = crow.call_timer
	game.set_state("journal")
	crow._process(5)
	assert(crow.voice.stream_paused and crow.animation.speed_scale==0 and crow.call_timer==timer,"Journal pauses calls, animation and timer")
	game.set_state("play")
	crow._process(0.1)
	assert(not crow.voice.stream_paused and crow.calls_played==1,"Resume does not repeat greeting")
	crow.voice.stop()
	crow._process(40)
	assert(crow.calls_played==2,"Spaced repeat uses second call")
	crow.voice.stop()
	game.player.position = game.START_POSITION
	crow._process(60)
	assert(crow.calls_played==2,"No sign calls while far away")
	game.soundscape.toggle_mute()
	assert(AudioServer.is_bus_mute(game.soundscape.bus_index),"Crow muted with other game audio")
	game.reset_game()
	assert(not crow.greeted and crow.calls_played==0 and crow.animation.current_animation=="watch","Restart restores perched greeting")
	print("PASS: original crow and animations, sign-top placement, 256 texture, both spatial calls, approach/distance gating, pause/mute/resume and reset")
	game.queue_free()
	await process_frame
	quit()
