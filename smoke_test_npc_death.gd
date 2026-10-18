extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	game.weapons.set_physics_process(false)
	var people = game.town.townspeople
	people.set_physics_process(false)
	game.state = "play"
	game.town.perform("weapon_pistol")
	var sign = game.town.get_node("BlackwoodRoadSign")
	var labels = sign.get_children().filter(func(child): return child is Label3D)
	assert(labels[0].text=="Blackwood" and labels[1].text=="Population 3","Requested sign wording")
	for id in people.characters:
		var data = people.characters[id]
		assert(data.skeleton!=null and data.skeleton.find_bone("shin_L")>=0,"Skinned collapse bones")
		game.player.global_position = data.actor.global_position+Vector3(0,0.001,2.4)
		game.camera.look_at(data.actor.global_position+Vector3(0,0.95,0))
		await physics_frame
		game.weapons.delay = 0
		assert(game.weapons.fire(),"Shot fired at "+id)
		assert(data.dead and data.actor.velocity==Vector3.ZERO,"Shot kills and stops patrol: "+id)
		assert(not data.label.visible and not game.town.actions["npc_"+id].area.visible,"No name or conversation marker")
		assert(data.actor.collision_layer==0 and data.area.collision_layer==0,"Corpse cannot block player, doorway or interaction rays")
		assert(not people.shoot(id),"Repeated pellets never restart death")
		people._physics_process(0.5)
		var mid_pose: Transform3D = data.visual.transform
		assert(mid_pose!=Transform3D.IDENTITY,"Animated intermediate collapse")
		game.state = "paused"
		people._physics_process(2)
		assert(data.visual.transform==mid_pose and data.death_time==0.5,"Death animation pauses")
		game.state = "play"
		people._physics_process(2)
		assert(data.death_time==people.DEATH_DURATION and absf(data.visual.rotation.x-PI/2)<0.001 and data.visual.rotation.z < -0.3,"Settled forward keel-over pose")
		var arm_index = data.skeleton.find_bone("arm_L")
		var arm_rest = data.skeleton.get_bone_rest(arm_index).basis.get_rotation_quaternion()
		assert(data.skeleton.get_bone_pose_rotation(arm_index).is_equal_approx(arm_rest),"Settled arms retain imported rest orientation")
		var settled: Transform3D = data.visual.transform
		people._physics_process(2)
		assert(data.visual.transform==settled,"Corpse stays down")
		people.talk(id)
		assert(game.state=="play","Dead NPC cannot speak")
	# The quest remains completable without talking to any survivor.
	for action in ["ranger_drawer","store_drawer","battery_panel","workshop_cabinet","receiver"]:
		game.town.perform(action)
	assert(game.town.radio_ready,"NPC deaths do not break item quest")
	game.reset_game()
	await physics_frame
	for id in people.characters:
		var data = people.characters[id]
		assert(not data.dead and data.death_time==0 and data.label.visible,"Restart revives "+id)
		assert(data.visual.transform==Transform3D.IDENTITY and data.actor.collision_layer==1,"Standing pose and collision restored")
		assert(not game.town.actions["npc_"+id].taken and data.area.visible and data.area.collision_layer==2,"Conversation restored")
	print("PASS: Population 3 sign, real gun hits kill all three NPCs, skinned collapse, pause, persistent corpses, no repeated deaths or dialogue, quest completion, full revival on restart")
	game.queue_free()
	await process_frame
	quit()
