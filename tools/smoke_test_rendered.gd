extends SceneTree
var game
var frames = 0
var worst_frame_ms = 0
func _initialize():
	call_deferred("run")
func observe(stage: String, seconds: float):
	var start = Time.get_ticks_msec()
	var previous = start
	var reported = start
	var local_frames = 0
	while Time.get_ticks_msec()-start<seconds*1000:
		await process_frame
		var now = Time.get_ticks_msec()
		worst_frame_ms = maxi(worst_frame_ms,now-previous)
		previous = now
		local_frames += 1
		frames += 1
		if now-reported>=1000:
			print("RENDER HEARTBEAT / ",stage," / frames=",local_frames," / state=",game.state)
			reported = now
	print("STAGE PASS / ",stage," / ",local_frames," rendered frames")
func look_from(p: Vector3, target: Vector3):
	game.player.position = p
	game.camera.look_at(target)
	game.invincible = 999
func run():
	if DisplayServer.get_name()=="headless":
		push_error("This regression must run with a real rendering driver.")
		quit(2)
		return
	Engine.max_fps = 60
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	print("RENDERER / ",RenderingServer.get_video_adapter_name())
	await observe("Traingle Studios presentation",4)
	await observe("title screen",3)
	game.state = "play"
	look_from(Vector3(0,0.1,4),Vector3(-8,2,-14))
	await observe("forest physics and audio",4)
	look_from(Vector3(0,0.1,-55),Vector3(7,2,-69))
	await observe("town physics",4)
	look_from(Vector3(-26,0.1,-58.5),Vector3(-26,1.35,-61))
	game.town.perform("npc_ranger")
	await observe("NPC conversation",2)
	game.state = "play"
	look_from(Vector3(-23,0.1,-66),Vector3(-26,0.9,-69))
	game.town.perform("ranger_drawer")
	game.town.perform("ranger_cabinet")
	await observe("interior furniture and storage",3)
	game.town.perform("ranger_drawer")
	await observe("closing drawer",1)
	game.state = "journal"
	game.journal_page = 0
	await observe("journal inventory",2)
	game.journal_page = 1
	await observe("town map",2)
	game.state = "play"
	game.town.perform("store_drawer")
	game.town.perform("fuse_panel")
	game.town.perform("workshop_cabinet")
	look_from(Vector3(21,0.1,-49),Vector3(25,1.1,-46.6))
	await observe("powered workshop and cabinets",3)
	game.town.perform("receiver")
	look_from(Vector3(0,0.1,3),Vector3(0,4,0))
	await observe("rescue beacon",2)
	game.player.position = Vector3(0,0.1,3)
	game.update_contact(4.1,true)
	assert(game.state=="won","Full rescue ending")
	await observe("victory screen",2)
	game.reset_game()
	game.state = "title"
	await observe("restart title",1)
	print("PASS: real-renderer stability / frames=",frames," / worst frame ms=",worst_frame_ms," / title, physics, forest, town, furniture, storage, journal, map, rescue, restart")
	game.queue_free()
	await process_frame
	quit()
