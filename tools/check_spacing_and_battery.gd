extends SceneTree
func _initialize():call_deferred("run")
func furniture(g,room,asset):
	return g.town.apartment_interiors.instances.filter(func(n):return n.get_meta("room")==room and n.get_meta("apartment_asset")==asset)[0]
func box(g,node):
	return g.town.apartment_interiors.retro.bounds(node,node.get_parent())
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	g.set_physics_process(false);g.enemies.set_physics_process(false)
	g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
	for room in ["house","radio"]:
		var sofa=box(g,furniture(g,room,"sofa"))
		var table=box(g,furniture(g,room,"coffee_table"))
		assert(sofa.position.z-table.end.z>0.6,"Comfortable sofa-to-coffee-table clearance")
		var stand=g.town.apartment_interiors.retro.instances.filter(func(n):return n.get_parent()==g.town.buildings[room] and n.get_meta("retro_asset")=="table")[0]
		assert(table.position.z-box(g,stand).end.z>0.8,"TV stand separated from lounge table")
	var stove=box(g,furniture(g,"house","stove"))
	print("OVEN BOUNDS ",stove)
	assert(stove.size.y>1.1 and stove.size.x>0.83 and stove.size.z>0.73,"Full-size oven including raised control panel")
	var oven=furniture(g,"house","stove")
	var hob=oven.position.y+0.734713*oven.scale.y
	for counter in g.town.apartment_interiors.instances.filter(func(n):return n.get_meta("room")=="house" and n.get_meta("apartment_asset")=="counter"):
		var cabinet=box(g,counter)
		assert(absf(cabinet.end.y-hob)<0.03,"Cooking surface aligns with counters; control panel rises above it")
		assert(not cabinet.intersects(stove),"Appliances do not intersect")
	var e=g.enemies;var data=e.creatures[e.WORKSHOP_INDEX]
	var original:Vector3=data.spawn
	assert(data.state=="dormant" and not data.actor.visible)
	for i in range(4):await physics_frame
	g.player.global_position=g.town.actions.battery_panel.area.global_position+Vector3(1.0,-1.14,0)
	g.town.inventory.workshop_fuse=1
	g.town.perform("battery_panel")
	var terminal=g.town.actions.battery_panel.area.get_node("HighVoltageTerminal")
	terminal.set_process(false)
	for i in range(45):terminal._process(1.0/60)
	g.town.perform("battery_panel")
	assert(not g.town.powered and e.workshop_spawned,"Battery triggers encounter; workshop power waits for switch")
	g.town.perform("battery_panel")
	for i in range(40):terminal._process(1.0/60)
	assert(g.town.powered and e.workshop_spawned and not e.workshop_armed and data.state=="chase","Power switch immediately starts pursuit")
	assert(data.actor.global_position==original and data.actor.visible,"Same spawn point; no teleport toward battery")
	var initial=data.actor.global_position.distance_to(g.player.global_position)
	for i in range(120):
		e._physics_process(1.0/60)
		await physics_frame
	assert(data.actor.global_position.distance_to(original)>1,"Walks immediately without alley crossing or waiting for NPCs")
	g.state="journal";var before:Vector3=data.actor.global_position
	e._physics_process(2)
	assert(data.actor.global_position==before,"Journal pauses pursuit")
	g.state="play"
	for i in range(1200):
		e._physics_process(1.0/60)
		await physics_frame
		if data.actor.global_position.distance_to(g.player.global_position)<2.5:break
	assert(data.actor.global_position.distance_to(g.player.global_position)<initial-3,"Navigates toward rear terminal")
	var hp=data.hp
	g.town.perform("battery_panel")
	assert(data.hp==hp and data.actor.global_position!=original,"Reusing powered terminal does not reset encounter")
	g.reset_game()
	assert(data.state=="dormant" and not e.workshop_spawned,"New game resets encounter")
	print("PASS: spaced lounge groups, full-size aligned oven, real battery installation starts immediate walking from original spawn, route, pause, no retrigger, reset")
	g.queue_free();await process_frame;quit()
