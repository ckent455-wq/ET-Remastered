extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	g.set_physics_process(false);g.enemies.set_physics_process(false)
	g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
	var panel=g.town.actions.battery_panel.area
	var terminal=panel.get_node("HighVoltageTerminal")
	terminal.set_process(false)
	assert(terminal.model.scene_file_path=="res://assets/high_voltage/fuse_box.glb","Native downloaded high-voltage model")
	assert(terminal.animation.has_animation("open") and terminal.animation.has_animation("pull"),"Original door and switch clips")
	assert(not terminal.energized and not panel.get_node("InstalledFuse").visible,"Unpowered starting state")
	var door=terminal.model.find_child("fuse_box_door",true,false)
	var closed=door.transform
	g.town.perform("store_drawer")
	assert(g.town.inventory.workshop_fuse==1 and g.town.actions.workshop_fuse.taken,"Original store drawer now grants the native fuse pickup")
	var packed=g.backpack.pack({"workshop_fuse":1})
	assert(packed.size()==1 and packed[0].size==Vector2i(1,1),"Fuse takes one backpack slot")
	g.town.inventory.workshop_fuse=0
	g.town.perform("battery_panel")
	assert(terminal.phase=="opening" and not g.town.powered,"First interaction only opens cabinet")
	g.town.inventory.workshop_fuse=1
	for i in range(4):g.town.perform("battery_panel")
	assert(g.town.inventory.workshop_fuse==1 and not terminal.installed,"Rapid input cannot skip opening")
	g.state="journal"
	terminal._process(2)
	assert(terminal.phase_time==0,"Opening pauses with journal")
	g.state="play"
	for i in range(45):terminal._process(1.0/60)
	assert(terminal.opened and not door.transform.is_equal_approx(closed),"Cabinet opens before battery installation")
	assert(g.town.actions.battery_panel.label=="Install workshop fuse","Prompt follows cabinet state")
	g.town.inventory.workshop_fuse=0
	g.town.perform("battery_panel")
	assert(not terminal.installed and not g.town.powered,"Cannot install a missing fuse")
	g.town.inventory.workshop_fuse=1
	g.town.perform("battery_panel")
	assert(terminal.installed and g.town.inventory.workshop_fuse==0 and panel.get_node("InstalledFuse").visible,"Second interaction installs exactly one fuse")
	var fitted=panel.get_node("InstalledFuse")
	var dimensions=g.town.apartment_interiors.retro.bounds(fitted,panel)
	assert(dimensions.size.y<0.10 and dimensions.size.x<0.04 and dimensions.position.x> -0.20 and dimensions.end.x< -0.06 and dimensions.position.y>0.20 and dimensions.end.y<0.32,"Native cartridge fits vertically inside the left holder")
	assert(fitted.find_child("fuse",true,false)!=null,"Installed fuse uses the downloaded model")
	assert(dimensions.position.z> -0.084 and dimensions.position.z< -0.080 and dimensions.end.z< -0.05,"Fuse sits against recessed panel instead of floating in front of cabinet")
	assert(not terminal.fuse_glow.visible and terminal.fuse_materials.all(func(m):return not m.emission_enabled),"Installed fuse stays dark before switch")
	assert(not g.town.powered and g.enemies.workshop_spawned,"Fuse triggers creature while workshop remains unpowered")
	var spawn=g.enemies.creatures[g.enemies.WORKSHOP_INDEX].actor.global_position
	assert(g.town.actions.battery_panel.label=="Flip power switch","Explicit switch prompt")
	g.town.perform("battery_panel")
	assert(terminal.phase=="switching" and not g.town.powered,"Third interaction flips switch")
	g.state="journal"
	var time=terminal.animation.current_animation_position
	terminal._process(2)
	assert(terminal.animation.current_animation_position==time and not g.town.powered,"Journal pauses switch and power activation")
	g.state="play"
	for i in range(40):terminal._process(1.0/60)
	assert(g.town.powered and terminal.energized,"Switch completion powers workshop")
	assert(terminal.fuse_glow.visible and terminal.fuse_materials.all(func(m):return m.emission_enabled and m.emission.g>m.emission.r),"Switch lights fuse green with local spill")
	assert(g.enemies.workshop_spawned and g.enemies.creatures[g.enemies.WORKSHOP_INDEX].state=="chase" and g.enemies.creatures[g.enemies.WORKSHOP_INDEX].actor.global_position==spawn,"Switch does not restart the existing battery encounter")
	g.town.perform("battery_panel")
	assert(g.town.inventory.workshop_fuse==0 and terminal.phase=="on","Powered interaction cannot consume another fuse or restart animation")
	g.reset_game()
	assert(not terminal.energized and not terminal.installed and not terminal.opened and not panel.get_node("InstalledFuse").visible and door.transform.is_equal_approx(closed),"New journey closes cabinet, restores switch and removes fuse")
	assert(not terminal.fuse_glow.visible and terminal.fuse_materials.all(func(m):return not m.emission_enabled),"Reset clears green glow")
	print("PASS: separate open/install/flip interactions, prompts, no skipping, missing fuse, fuse-triggered monster, switch-only power, pause and reset")
	g.queue_free();await process_frame;quit()
