extends SceneTree
var g
func _initialize():call_deferred("run")
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false);g.controller.set_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 var t=g.town;var e=g.enemies;var car=g.crash_site
 g.reset_game();car.start_opening()
 assert("ignition" in t.objective() and not car.has_backpack)
 car.leave_seat_for_testing();car.wake_phase="";g.state="play"
 assert("help" in t.objective() and t.navigation_target().z==-16,"Opening objective follows the injury, not a forced gear detour")
 g.clinic_rescue.place_in_bed();g.clinic_rescue.begin_explanation()
 assert("workshop across the street" in g.dialogue_text and "backpack" in g.dialogue_text)
 g.set_state("play");assert("trunk" in t.objective())
 t.perform("medkit_a");assert(not t.actions.medkit_a.taken and t.inventory.medkit==0)
 car.hatch_open=true;car.interact_tutorial("crash_backpack");car.interact_tutorial("crash_flashlight")
 t.reached_town=true
 assert("Speak to John" in t.objective() and t.navigation_target().distance_to(t.buildings.workshop.to_global(Vector3(0,0,6.5)))<.01)
 t.perform("npc_mechanic");assert("electric latch" in g.dialogue_text and "general store" in g.dialogue_text and "alley" in g.dialogue_text)
 assert(t.journal_entries.any(func(entry):return entry.id=="workshop_plan"))
 g.set_state("play");assert("desk drawer" in t.objective())
 t.perform("ranger_drawer");assert(t.inventory.station_key==1)
 assert("general store" in t.objective())
 t.perform("store_drawer");assert(t.inventory.workshop_fuse==1)
 assert("rear workshop cabinet" in t.objective())
 # The same optional knife remains available without replacing objective progression.
 t.perform("workshop_knife");assert(g.knife.owned() and "rear workshop cabinet" in t.objective())
 var terminal=t.actions.battery_panel.area.get_node("HighVoltageTerminal")
 g.player.global_position=Vector3(18.3,.02,-59)
 terminal.interact();terminal._process(10);assert(terminal.opened)
 terminal.interact();assert(terminal.installed and t.inventory.workshop_fuse==0)
 var monster=e.creatures[e.WORKSHOP_INDEX];var identity=monster.actor.get_instance_id()
 assert(monster.state=="ambush_wait" and monster.actor.visible and "switch" in t.objective())
 e.update_workshop_creature(monster,.016);assert(monster.state=="ambush_wait","Fuse installation does not launch the attack")
 var waiting_position=monster.actor.global_position
 terminal.interact();terminal._process(10);assert(t.powered)
 assert(monster.state=="chase" and "signal coil" in t.objective(),"The power switch immediately launches pursuit while the player is at the rear cabinet")
 for i in 20:
  await physics_frame;e.update_workshop_creature(monster,1.0/60.0)
 assert(monster.actor.global_position.distance_to(waiting_position)>.1,"Monster physically walks toward the player after the switch")
 e.update_workshop_creature(monster,.016);assert(monster.state=="chase","Creature approaches while the player is behind the workshop")
 for line in [t.objective(),g.hud.objectives.goal().title]:
  assert(not "creature" in line.to_lower() and not "monster" in line.to_lower() and not "kill" in line.to_lower(),"Neither objective UI reveals the approaching monster")
 var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved));g.saves.backend.apply(saved)
 assert(monster.state=="chase" and terminal.energized,"Save/load retains active pursuit and the installed fuse")
 g.player.global_position=Vector3(9,.02,-51.5);e.update_workshop_creature(monster,.016);assert(monster.state=="chase")
 g.player.global_position=Vector3(8.4,.02,-51.5);e.update_workshop_creature(monster,.016)
 assert(monster.state=="chase" and monster.actor.get_instance_id()==identity,"Pursuit uses the same pre-existing creature without respawning at the exit")
 assert("signal coil" in t.objective())
 assert(e.shoot(e.WORKSHOP_INDEX,10000) and e.workshop_defeated)
 assert("signal coil" in t.objective())
 t.perform("workshop_cabinet");assert(t.inventory.coil==1)
 assert("Pat" in t.objective() and "mausoleum" in t.objective())
 var line=t.townspeople.conversation.progress.intro(t.townspeople.conversation,"mechanic").line
 assert(not "shots" in line,"John does not invent gunshots after a knife kill")
 # Exploration can discover the fuse before meeting John; no dialogue lock is added.
 g.reset_game();car.wake_phase="";car.has_backpack=true;car.has_flashlight=true;g.story.clinic_rescue_done=true;t.reached_town=true;g.state="play"
 t.perform("store_drawer");assert(not t.needs_workshop_introduction() and "rear workshop cabinet" in t.objective())
 terminal.interact();terminal._process(10);terminal.interact()
 assert("switch" in t.objective(),"An installed fuse takes priority over a missing station key")
 terminal.interact();terminal._process(10)
 assert("signal coil" in t.objective(),"Restoring power keeps the repair objective without revealing the approaching monster")
 print("PASS: opening injury objective, clinic/gear handoff, no-backpack gate, John plan, key/fuse/knife, terminal sequence, pre-spawned creature pursuing on the switch, save/load, coil handoff and out-of-order discovery")
 quit()
