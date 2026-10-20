extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.weapons.set_physics_process(false)
	game.crash_site.wake_phase = ""
	game.state = "play"
	var w = game.weapons
	var m = w.melee
	print("ARM CLIPS ",m.clips)
	game.player.position = Vector3(0,0.01,-55)
	var enemy = game.enemies.creatures[0]
	enemy.actor.position = Vector3(0,0.01,-56.25)
	game.camera.look_at(enemy.actor.position+Vector3(0,1,0))
	await physics_frame
	await physics_frame
	var hp = enemy.hp
	var view = game.camera.transform
	assert(not m.raised and not m.model.visible and not w.fire(),"Fists start lowered; fire cannot draw them")
	game.crash_site.has_flashlight=true
	game.flashlight.show()
	game.update_flashlight_visual(1)
	assert(game.flashlight_model.is_visible_in_tree(),"Flashlight model appears with hands lowered")
	var toggle = InputEventKey.new()
	toggle.keycode = KEY_0
	toggle.pressed = true
	game._unhandled_input(toggle)
	assert(m.raised and m.model.visible,"0 raises fists")
	game.update_flashlight_visual(1)
	assert(not game.flashlight_model.is_visible_in_tree() and game.flashlight.visible,"Raised fists hide the held flashlight without turning off its beam")
	assert(w.fire() and not w.fire(),"Unarmed fire starts one jab, cooldown rejects spam")
	assert(enemy.hp==hp,"Windup causes no instant damage")
	m.update(0.29)
	assert(enemy.hp==hp-m.DAMAGE and w.hit_feedback>0,"Punch damages enemy in actual reach")
	m.update(0.1)
	assert(enemy.hp==hp-m.DAMAGE,"Only one hit per swing")
	game.state = "journal"
	var t = m.elapsed
	m.update(1)
	assert(m.elapsed==t,"Menus pause punch timing")
	game.state = "play"
	m.update(1)
	w.delay = 0
	assert(w.fire() and not m.right_hand,"Alternating hands")
	enemy.actor.position.z = -60
	await physics_frame
	m.update(0.29)
	assert(enemy.hp==hp-m.DAMAGE,"Out of range misses")
	m.update(1)
	w.delay = 0
	enemy.actor.position.z = -56.25
	var wall = game.town.box(game,Vector3(0,1,-55.5),Vector3(2,2,0.1),game.town.mats.wood)
	await physics_frame
	assert(w.fire())
	m.update(0.29)
	assert(enemy.hp==hp-m.DAMAGE,"Wall blocks melee")
	wall.queue_free()
	w.collect(0)
	assert(m.elapsed<0,"Equipping cancels pending melee")
	m.update(0)
	assert(not m.model.visible,"Arms hidden with gun")
	assert(game.camera.transform==view,"Melee never shakes the camera")
	w.delay = 0
	assert(w.fire() and w.magazines[0]==2,"Equipped pistol still fires real ammunition")
	w.reserves[0] = 6
	w.reload()
	w._physics_process(2)
	assert(w.magazines[0]==8 and w.reserves[0]==0,"Gun reload conserves ammunition")
	w.equip(-1)
	w.delay = 0
	m.update(0)
	assert(not m.raised and not m.model.visible and not w.fire(),"Holstering gun keeps fists lowered")
	game._unhandled_input(toggle)
	assert(m.model.visible and w.fire(),"0 raises fists after holstering")
	game._unhandled_input(toggle)
	assert(not m.raised and not m.model.visible and m.elapsed<0,"0 lowers fists and cancels pending contact")
	game.update_flashlight_visual(1)
	assert(game.flashlight_model.is_visible_in_tree() and game.flashlight.visible,"Lowering fists restores the flashlight model")
	m.update(1)
	assert(not w.fire(),"Lowered fists cannot attack")
	game.state = "paused"
	game._unhandled_input(toggle)
	assert(not m.raised,"Pause cannot raise fists")
	game.state = "play"
	game.controller.activate(0)
	game.controller.button(JOY_BUTTON_RIGHT_STICK)
	assert(m.raised,"R3 raises fists")
	game.controller.button(JOY_BUTTON_RIGHT_STICK)
	assert(not m.raised,"R3 lowers fists")
	game.reset_game()
	assert(m.elapsed<0 and not m.right_hand and not m.raised and not m.model.visible,"New journey resets punch and lowers fists")
	print("PASS: original rig, real enemy damage, windup, single contact, cooldown, alternating hands, range, walls, pause, gun switching, camera stability and reset")
	game.queue_free()
	await process_frame
	quit()
