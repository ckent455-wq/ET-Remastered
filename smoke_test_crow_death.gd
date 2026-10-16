extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.reset_game()
	game.set_state("play")
	game.set_physics_process(false)
	var progress = game.achievements
	var test_path = "user://crow-achievement-test-"+str(Time.get_ticks_usec())+".cfg"
	progress.storage_path = test_path
	progress.unlocked.clear()
	var crow = game.town.sign_crow
	assert(crow.animation.has_animation("die"),"Original death animation")
	game.player.position = Vector3(1.5,0.01,-31.8)
	game.camera.look_at(crow.hit_shape.global_position)
	game.town.perform("weapon_pistol")
	game.weapons.delay = 0
	game.weapons.aiming = true
	await physics_frame
	assert(game.weapons.fire(),"Fire real pistol ray at perched crow")
	assert(crow.dead,"Gun ray kills crow")
	assert(progress.toast_title=="Wow, what an asshole" and progress.toast_seconds>0,"Exact requested achievement popup")
	assert(not crow.voice.playing,"Death stops calls")
	await physics_frame
	assert(crow.hit_shape.disabled,"No repeated corpse hitbox")
	for frame in range(90):
		await process_frame
	assert(crow.global_position.y<0.15 and crow.animation.current_animation!="watch","Crow falls off sign and stays dead")
	var calls = crow.calls_played
	crow._process(60)
	assert(crow.calls_played==calls and not crow.shoot(),"Dead crow neither calls nor dies twice")
	var saved = ConfigFile.new()
	assert(saved.load(test_path)==OK and saved.get_value("unlocked","crow_killer")=="Wow, what an asshole","Achievement saved to local profile")
	var other = Node.new()
	other.set_script(load("res://achievements.gd"))
	other.storage_path = test_path
	root.add_child(other)
	assert(other.unlocked.has("crow_killer"),"Achievement survives reload")
	game.reset_game()
	await physics_frame
	assert(not crow.dead and not crow.hit_shape.disabled and crow.position.is_equal_approx(crow.PERCH_POSITION),"New journey restores perched live crow")
	assert(progress.unlocked.has("crow_killer") and progress.toast_seconds==0,"Achievement persists without stale popup")
	progress.load_progress()
	game.player.position = Vector3(1.5,0.01,-31.8)
	game.camera.look_at(crow.hit_shape.global_position)
	game.town.perform("weapon_pistol")
	game.weapons.delay = 0
	game.weapons.aiming = true
	await physics_frame
	assert(game.weapons.fire() and crow.dead,"Actual second kill with saved achievement loaded")
	assert(progress.toast_seconds>0 and progress.toast_title=="Wow, what an asshole" and not progress.toast_is_new,"Loaded achievement still shows notification")
	assert(progress.unlocked.size()==1,"Achievement is saved once")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	print("PASS: actual gun hit, original death animation and fall, stopped calls, exact achievement toast, persistent reload, one-time unlock, live crow restart")
	other.queue_free()
	game.queue_free()
	await process_frame
	quit()
