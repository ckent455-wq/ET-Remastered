extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	game.town.townspeople.set_physics_process(false)
	var guns = game.weapons
	guns.set_physics_process(false)
	game.state = "play"
	assert(guns.models.size()==3,"Three adapted local weapons")
	assert(guns.selected== -1 and not guns.owned.has(true) and guns.magazines==[0,0,0],"Unarmed start with no free ammunition")
	for index in range(3):
		guns.equip(index)
		assert(guns.selected== -1 and not guns.fire(),"Cannot select or fire undiscovered gun")
	for id in ["weapon_pistol","weapon_rifle","weapon_shotgun"]:
		if id=="weapon_rifle":
			for quest in ["ranger_drawer","store_drawer","battery_panel","workshop_cabinet","cellar_door"]: game.town.perform(quest)
		if id=="weapon_shotgun":
			game.town.perform("shotgun_key")
			game.town.perform("shotgun_lockbox")
			game.weapons.lockbox._process(1)
		game.town.perform(id)
	assert(guns.magazines[0]==3 and guns.reserves[0]==0,"Pistol starts with exactly three rounds and no spare ammo")
	game.town.perform("ammo_pistol_store")
	guns.equip(0)
	guns.reload()
	guns._physics_process(2)
	guns.delay = 0
	assert(not game.arm_visual.visible,"Arm hidden with discovered gun")
	game.player.position = Vector3(30,0.001,-40)
	game.camera.look_at(guns.targets[0].global_position)
	await physics_frame
	var eye = game.camera.global_transform
	assert(guns.fire() and guns.magazines[0]==7,"Pistol firing consumes one round")
	assert(guns.targets[0].get_meta("hits",0)>0,"Ray hits metal target")
	assert(game.camera.global_transform==eye,"Recoil never shakes the camera")
	assert(not guns.fire(),"Fire rate enforced")
	for state in ["title","intro","paused","journal","dialogue","won"]:
		game.state = state
		guns.delay = 0
		assert(not guns.fire() and guns.magazines[0]==7,"No firing in "+state)
	game.state = "play"
	guns.magazines[0] = 0
	assert(not guns.fire() and guns.magazines[0]==0,"Empty gun never fires")
	game.town.perform("ammo_pistol_house")
	game.town.perform("ammo_pistol_clinic")
	var total: int = guns.reserves[0]
	guns.reload()
	game.state = "paused"
	var remaining: float = guns.reload_remaining
	guns._physics_process(3)
	assert(guns.reload_remaining==remaining,"Reload pauses with game")
	game.state = "play"
	guns._physics_process(3)
	assert(guns.magazines[0]==8 and guns.reserves[0]==total-8,"Reload conserves ammunition")
	guns.magazines[0] = 1
	guns.reload()
	guns.equip(1)
	assert(guns.reload_remaining==0 and guns.magazines[0]==1,"Switch cancels reload without free ammo")
	for index in [1,2]:
		guns.equip(index)
		guns.delay = 0
		assert(guns.fire(),"Weapon fires: "+str(index))
	assert(guns.marks.size()<=20,"Bounded impact effects")
	guns.equip(-1)
	assert(not guns.fire(),"Holstered cannot fire")
	assert(game.arm_visual.visible and game.arm_visual.name=="FlashlightHolder","Holstering restores the flashlight holder")
	game.reset_game()
	assert(guns.selected== -1 and guns.magazines==[0,0,0] and not guns.owned.has(true) and guns.marks.is_empty(),"Restart returns to unarmed and clears ammo")
	var sign = game.town.get_node("BlackwoodRoadSign")
	assert(sign.position.x>4 and sign.rotation_degrees.z<0,"Sign fully beside road")
	print("PASS: three guns, target hits, stable camera recoil, fire cadence, menu guards, dry fire, reload/pause/conservation, switching, holster, bounded effects, reset, roadside sign")
	game.queue_free()
	await process_frame
	quit()
