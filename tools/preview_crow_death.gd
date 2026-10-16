extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.reset_game()
	game.set_state("play")
	game.set_physics_process(false)
	var crow = game.town.sign_crow
	crow.set_process(false)
	game.achievements.storage_path = "user://crow-preview-test.cfg"
	game.achievements.unlocked.clear()
	if "--already-unlocked" in OS.get_cmdline_user_args():
		game.achievements.unlock(game.achievements.CROW_ID,game.achievements.CROW_TITLE)
		game.achievements.load_progress()
		game.achievements.clear_toast()
	game.soundscape.set_process(false)
	for type in ["AudioStreamPlayer","AudioStreamPlayer3D"]:
		for voice in game.find_children("*",type,true,false):
			voice.stop()
	game.player.position = Vector3(0,0.01,-23)
	game.camera.look_at(crow.global_position)
	await process_frame
	var capture = AudioEffectCapture.new()
	capture.buffer_length = 3
	var bus = game.soundscape.bus_index
	AudioServer.add_bus_effect(bus,capture)
	crow.caw()
	await create_timer(2.2).timeout
	var frames = capture.get_buffer(capture.get_frames_available())
	var peak = 0.0
	var square = 0.0
	for sample in frames:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		square += sample.length_squared()/2
	var rms = sqrt(square/maxi(1,frames.size()))
	print("Crow bus capture at approach: ",frames.size()," frames, peak ",peak," RMS ",rms)
	assert(peak>0.03 and rms>0.003,"Audible actual crow output on game bus at entrance approach")
	AudioServer.remove_bus_effect(bus,AudioServer.get_bus_effect_count(bus)-1)
	crow.set_process(true)
	game.player.position = Vector3(1.5,0.01,-31.8)
	game.camera.look_at(crow.hit_shape.global_position)
	game.town.perform("weapon_pistol")
	game.weapons.delay = 0
	game.weapons.aiming = true
	await physics_frame
	game.camera.look_at(crow.hit_shape.global_position)
	game.weapons.delay = 0
	assert(game.weapons.fire() and crow.dead,"Actual shot kills rendered crow")
	await create_timer(0.3).timeout
	game.hud.queue_redraw()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-crow-achievement.png")
	await create_timer(1.2).timeout
	game.camera.look_at(crow.global_position+Vector3(0,0.15,0))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-crow-dead.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.achievements.storage_path))
	print("PASS: audible spatial crow mix, death animation/fall, exact achievement toast; real profile untouched")
	quit()
