extends SceneTree
var game
func _initialize():
	call_deferred("run")
func frame_and_capture(label: String):
	for frame in range(8):
		await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview-title-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_state("title")
	await frame_and_capture("main")
	assert(game.title_camera.current and not game.camera.current,"Town menu camera")
	assert(game.hud.menu_buttons[0].visible and not game.hud.menu_buttons[3].visible,"Main menu buttons")
	var weather = game.title_weather
	weather.set_process(false)
	weather._process(0.01)
	weather.strike()
	weather._process(0.1)
	weather._process(0.1)
	weather._process(0.1)
	assert(weather.intensity>0 and weather.intensity<=0.7 and weather.light.light_energy<0.46,"Soft capped lightning")
	assert(not game.soundscape.thunder.playing,"Thunder follows lightning after a delay")
	await frame_and_capture("lightning")
	for frame in range(35):
		weather._process(0.1)
	assert(game.soundscape.thunder.playing and game.soundscape.thunder.volume_db<=-21,"Quiet delayed thunder")
	assert(weather.intensity==0 and weather.next_strike>7,"Single flash fades with a long gap")
	assert(game.soundscape.thunder.bus=="ForestAudio","Thunder uses game mute bus")
	game.soundscape.toggle_mute()
	assert(AudioServer.is_bus_mute(game.soundscape.bus_index),"Mute includes thunder")
	game.soundscape.toggle_mute()
	var spawn: Vector3 = game.player.position
	game.hud.menu_buttons[1].pressed.emit()
	await frame_and_capture("controls")
	assert(game.hud.controls_open and game.hud.menu_buttons[3].visible,"Controls panel")
	assert(game.player.position==spawn,"Menu camera never moves the player")
	game.hud.menu_buttons[3].pressed.emit()
	await process_frame
	assert(not game.hud.controls_open,"Back returns to title")
	var escape = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	game._unhandled_input(escape)
	assert(game.state=="title","Escape cannot accidentally begin game")
	game.hud.menu_buttons[0].pressed.emit()
	weather._process(0.01)
	await process_frame
	assert(game.state=="play" and game.camera.current and not game.title_camera.current,"Start switches to player camera")
	assert(not game.hud.menu_buttons[0].visible,"Title buttons hidden during play")
	assert(weather.light.light_energy==0 and weather.thunder_delay<0 and not game.soundscape.thunder.playing,"Storm stops completely during gameplay")
	game.set_state("paused")
	await frame_and_capture("paused")
	var enter = InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	game._unhandled_input(enter)
	assert(game.state=="play","Pause resume preserved")
	print("PASS: horror title, soft lightning, delayed quiet thunder, mute, storm cleanup, real town camera, controls/back, safe Escape, clickable start, player camera restoration, pause/resume")
	game.queue_free()
	await process_frame
	quit()
