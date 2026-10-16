extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var fog = game.fog_atmosphere
	fog.set_process(false)
	var total = 0
	for emitter in fog.emitters:
		assert(emitter is CPUParticles3D and emitter.emitting and emitter.mesh!=null,"Working compatibility particle emitter")
		assert(emitter.gravity==Vector3.ZERO and emitter.lifetime>=15,"Slow drifting mist")
		total += emitter.amount
	assert(total<=128,"Bounded particle/overdraw budget")
	game.state = "play"
	game.player.position = Vector3(0,0.001,-44)
	fog.update_fog(3)
	assert(not fog.indoors and fog.environment.fog_density>=0.065,"Dense exterior haze")
	game.player.position = game.town.buildings.ranger.to_global(Vector3(0,0.001,1))
	fog.update_fog(3)
	assert(fog.indoors and fog.environment.fog_density<0.02,"Interior interaction visibility retained")
	game.state = "paused"
	var elapsed = fog.elapsed
	fog.update_fog(3)
	assert(fog.elapsed==elapsed,"Fog animation freezes in pause")
	for emitter in fog.emitters:
		assert(emitter.speed_scale==0,"Particles pause")
	game.state = "title"
	fog.update_fog(3)
	assert(fog.material.get_shader_parameter("eye_position")==game.title_camera.global_position,"Title fog uses title camera")
	for emitter in fog.emitters:
		assert(emitter.speed_scale==1,"Particles resume")
	var enclosure = game.get_node("CrampedRoadside")
	assert(enclosure.shoulder_trees>=20 and enclosure.shoulder_bushes>=30 and enclosure.fences>=6,"Roadside enclosure added")
	print("PASS: ",total," drifting CPU fog particles, dense exterior, readable interiors, pause/resume, active camera, dense shoulder vegetation and fences")
	game.queue_free()
	await process_frame
	quit()
