extends SceneTree
var game
func _initialize(): call_deferred("run")
func key(code: Key, pressed: bool):
	var e = InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func save(label: String):
	game.hud.queue_redraw()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/movement-"+label+".png")
func frames(n: int):
	for i in range(n): await physics_frame
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.state = "play"
	game.enemies.set_physics_process(false)
	game.soundscape.toggle_mute()
	var church = game.town.streetscape.church
	game.player.position = church.to_global(Vector3(0,0.01,4.8))
	game.camera.look_at(church.to_global(Vector3(0,1.4,-5.5)))
	await frames(20)
	await save("standing")
	key(KEY_CTRL,true)
	await frames(20)
	await save("crouched")
	assert(game.crouching and game.camera.position.y<0.7)
	key(KEY_CTRL,false)
	await frames(20)
	key(KEY_SPACE,true)
	await frames(12)
	key(KEY_SPACE,false)
	await save("jumping")
	assert(game.player.position.y>church.position.y+0.5)
	await frames(60)
	game.set_state("title")
	game.hud.controls_open = true
	for i in range(5):
		game.hud.queue_redraw()
		await process_frame
	await save("controls")
	print("PASS: rendered standing/crouching/jumping with flashlight and updated controls")
	game.queue_free()
	await process_frame
	quit()
