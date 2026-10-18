extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.state = "play"
	var town = game.town
	var basement = town.streetscape.church.basement
	assert(basement.is_ancestor_of(town.actions.weapon_rifle.area),"Rifle physically moved to cellar")
	town.perform("weapon_rifle")
	assert(not game.weapons.owned[1],"Cannot take locked cellar rifle remotely")
	for id in ["ranger_drawer","store_drawer","battery_panel","workshop_cabinet","cellar_door"]: town.perform(id)
	game.player.position = basement.to_global(Vector3(2.8,0.01,3.0))
	game.camera.look_at(town.actions.weapon_rifle.area.global_position)
	await physics_frame
	town.refresh_focus()
	assert(town.focus_action=="weapon_rifle","Rifle targetable with E from the cellar floor")
	var event = InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	game._unhandled_input(event)
	assert(game.weapons.owned[1],"Real E picks up cellar rifle")
	game.player.position = Vector3(0,0.01,-56)
	var data = game.enemies.creatures[0]
	data.actor.position = Vector3(0,0.01,-61)
	data.actor.rotation.y = 0
	data.state = "chase"
	game.camera.look_at(data.actor.position+Vector3(0,1.1,0))
	game.weapons.collect(0)
	game.weapons.equip(0)
	game.town.perform("ammo_pistol_store")
	game.weapons.reload()
	game.weapons._physics_process(2)
	await physics_frame
	assert(game.enemies.health_bar_targets().size()==1,"Visible active enemy gets a health bar")
	for index in [0,1]:
		data.hp = game.enemies.HEALTH
		data.state = "chase"
		data.actor.collision_layer = 1
		game.weapons.equip(index)
		var hits = 0
		while data.hp>0 and hits<5:
			game.weapons.delay = 0
			await physics_frame
			assert(game.weapons.fire(),"Actual weapon ray")
			hits += 1
			if hits==1:
				var bars = game.enemies.health_bar_targets()
				assert(bars.size()==1 and is_equal_approx(bars[0].fraction,data.hp/game.enemies.HEALTH),"Bar follows actual health")
		assert(hits==(4 if index==0 else 2),"Four pistol hits versus two rifle hits")
		assert(game.enemies.health_bar_targets().is_empty(),"Dead enemy loses health bar")
	data.hp = 85
	data.state = "lurking"
	assert(game.enemies.health_bar_targets().is_empty(),"Bars do not reveal hidden enemies")
	data.state = "chase"
	data.actor.position = town.buildings.store.to_global(Vector3(-6.8,0.01,0))
	game.player.position = town.buildings.store.to_global(Vector3(-4,0.01,0))
	game.camera.look_at(data.actor.position+Vector3(0,1,0))
	await physics_frame
	assert(game.enemies.health_bar_targets().is_empty(),"Walls occlude enemy health bars")
	game.state = "journal"
	assert(game.enemies.health_bar_targets().is_empty(),"No enemy HUD in journal")
	game.reset_game()
	assert(not game.weapons.owned[1] and not town.actions.weapon_rifle.taken,"New journey restores cellar pickup")
	print("PASS: locked basement rifle, real E pickup, real gun-ray damage (pistol 24 / rifle 48), 4 versus 2 hits, health-bar values, hidden/dead/menu guards, reset")
	game.queue_free()
	await process_frame
	quit()
