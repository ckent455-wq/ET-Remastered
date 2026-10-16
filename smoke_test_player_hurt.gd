extends SceneTree

func _initialize(): call_deferred("check")

func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.soundscape.set_process(false)
	var sound = game.soundscape
	game.state = "play"
	assert(sound.hurt_streams.size()==3 and sound.hurt_voice.bus=="ForestAudio","Three player recordings on the game audio bus")
	for clip in sound.hurt_streams:
		assert(clip is AudioStreamWAV and clip.get_length()>1 and clip.loop_mode==AudioStreamWAV.LOOP_DISABLED,"Imported non-looping voice")
	var previous = -1
	for cycle in range(4):
		var heard = []
		for hit in range(3):
			game.health = 100
			game.invincible = 0
			assert(game.take_damage(22) and game.health==78,"Accepted hit loses health")
			assert(sound.hurt_voice.playing and sound.last_hurt!=previous,"Hurt voice plays without immediate repeats")
			assert(not sound.last_hurt in heard,"All three clips rotate before recycling")
			heard.append(sound.last_hurt)
			previous = sound.last_hurt
			var remaining = sound.hurt_bag.size()
			assert(not game.take_damage(22) and game.health==78 and sound.hurt_bag.size()==remaining,"Invulnerable contact produces no new voice")
	for state in ["paused","journal","dialogue","title"]:
		game.state = state
		game.invincible = 0
		sound.hurt_voice.stop()
		assert(not game.take_damage(22) and not sound.hurt_voice.playing,"Menus reject damage and voice")
	game.state = "play"
	game.take_damage(22)
	game.state = "journal"
	sound.update_sound(0.01)
	assert(sound.hurt_voice.stream_paused,"Journal pauses the player voice")
	game.state = "play"
	sound.update_sound(0.01)
	assert(not sound.hurt_voice.stream_paused,"Gameplay resumes the voice")
	sound.hurt_voice.stop()
	game.health = 40
	game.town.inventory.medkit = 1
	game.town.use_medkit()
	assert(game.health>40 and not sound.hurt_voice.playing,"Healing does not trigger pain")
	# Exercise the actual enemy melee damage route, including a missed swing.
	var data = game.enemies.creatures[0]
	game.player.position = Vector3(0,0.01,-55)
	data.actor.position = Vector3(0,0.01,-56.2)
	await physics_frame
	await physics_frame
	game.health = 100
	game.invincible = 0
	data.state = "attack"
	data.timer = 0.64
	data.did_hit = false
	game.enemies._physics_process(0.01)
	assert(game.health==78 and sound.hurt_voice.playing,"Actual enemy melee triggers hurt voice")
	sound.hurt_voice.stop()
	game.enemies._physics_process(0.01)
	assert(game.health==78 and not sound.hurt_voice.playing,"Same swing cannot retrigger")
	data.actor.position = Vector3(0,0.01,-60)
	await physics_frame
	game.invincible = 0
	data.state = "attack"
	data.timer = 0.64
	data.did_hit = false
	game.enemies._physics_process(0.01)
	assert(game.health==78 and not sound.hurt_voice.playing,"Missed swing stays silent")
	game.health = 5
	game.invincible = 0
	assert(game.take_damage(22) and game.health==0 and game.state=="lost","Fatal hit enters death screen")
	sound.update_sound(0.01)
	assert(sound.hurt_voice.playing and not sound.hurt_voice.stream_paused,"Fatal grunt can finish")
	assert(not game.take_damage(22),"Dead player cannot retrigger pain")
	game.reset_game()
	assert(not sound.hurt_voice.playing and sound.hurt_bag.is_empty() and sound.last_hurt==-1,"New journey clears voice state")
	print("PASS: three imported hurt voices, rotation, actual melee, immunity, misses, menus, healing, fatal hit and reset")
	game.queue_free()
	await process_frame
	quit()
