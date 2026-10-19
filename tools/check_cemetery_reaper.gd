extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.crash_site.wake_phase=""
	game.state="play"
	var e=game.enemies
	var d=e.creatures[e.REAPER_INDEX]
	for i in range(4): await physics_frame
	assert(d.visual.scene_file_path=="res://assets/enemies/reaper/reaper.glb" and d.clips.has("motion_4"),"Supplied Reaper mesh and clips")
	assert(d.state=="reaper_wait" and not d.actor.visible and d.actor.collision_layer==0,"Absent before trigger")
	game.player.position=Vector3(20,0.01,-14)
	e._physics_process(1)
	assert(d.state=="reaper_wait","Normal cemetery exploration does not trigger edge encounter")
	assert(e.reaper_navigation.graph.get_point_count()>50,"Real forest clearance navigation")
	var nav=e.reaper_navigation
	var id=nav.graph.get_closest_point(Vector3(36,0,-17))
	var edge:Vector3=nav.graph.get_point_position(id)
	assert(e.reaper_encounter.at_edge(edge),"Trigger has accessible clear forest cells")
	var approach=nav.path(Vector3(24,0,-26),edge)
	assert(not approach.is_empty() and approach[-1].distance_to(edge)<1,"Rear cemetery path connects to trigger")
	game.player.position=edge+Vector3.UP*0.01
	game.camera.rotation=Vector3.ZERO
	await physics_frame
	e._physics_process(0.01)
	assert(d.state=="reaper_warning" and not d.actor.visible,"Warning precedes reveal")
	game.state="journal"
	var remaining=d.timer
	e._physics_process(5)
	assert(d.timer==remaining and not d.actor.visible,"Journal pauses warning")
	game.state="play"
	e._physics_process(0.9)
	assert(d.state=="reaper_chase" and d.actor.visible and d.actor.collision_layer==1,"Edge spawns physical creature")
	var distance=d.actor.global_position.distance_to(game.player.global_position)
	assert(distance>=7 and distance<=14,"Spawn safely separated from player")
	var origin:Vector3=d.actor.global_position
	for i in range(900):
		e._physics_process(1.0/60)
		await physics_frame
		if game.health<100: break
	assert(d.actor.global_position.distance_to(origin)>2,"Creature pursues around real trees")
	assert(game.health<100,"Creature reaches player and attacks")
	assert(e.shoot(e.REAPER_INDEX,100),"Reaper can be defeated with normal combat")
	e._physics_process(1.5)
	assert(d.state=="dead" and d.actor.collision_layer==0 and d.clip=="death" and d.visual.rotation==Vector3.ZERO,"Native fall animation and released collision")
	e._physics_process(150)
	assert(d.state=="dead","No repeated spawn while camping at edge")
	game.reset_game()
	assert(d.state=="reaper_wait" and not d.actor.visible and d.hp==e.HEALTH,"New journey resets hidden encounter")
	print("PASS: local Reaper, reachable rear forest trigger, hidden until approach, delayed spawn, pause, safe placement, tree navigation, actual attack, kill and reset")
	game.queue_free()
	await process_frame
	quit()
