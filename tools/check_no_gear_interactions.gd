extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.state="play"
 g.clinic_rescue.place_in_bed();g.clinic_rescue.begin_explanation();g.set_state("play")
 assert(not g.crash_site.has_backpack and not g.crash_site.has_flashlight)
 for id in ["clinic","ranger","store","workshop","house"]:
  g.player.global_position=g.town.buildings[id].to_global(Vector3(0,0.02,3))
  g.town.perform(id+"_door");assert(g.town.doors[id].open,"Door opens without backpack: "+id)
  g.town.perform(id+"_door");assert(not g.town.doors[id].open,"Door closes without backpack: "+id)
 g.town.perform("radio_door");assert(not g.town.doors.radio.open and "Locked" in g.message,"Actual key locks stay locked")
 g.town.perform("npc_nurse");assert(g.state=="dialogue" and g.town.townspeople.conversation.choosing)
 g.set_state("play");g.town.perform("clinic_note");assert(g.story.evidence.has("clinic_note"));g.set_state("play")
 g.town.perform("ranger_drawer");assert(g.town.inventory.station_key==1)
 g.town.perform("radio_door");assert(g.town.doors.radio.open)
 g.town.perform("house_note");assert(g.town.inventory.ada_letter==1)
 g.set_state("play");g.town.perform("police_driver_door");assert(not "backpack and flashlight" in g.message)
 assert(not g.crash_site.has_backpack and not g.crash_site.has_flashlight,"Interactions do not grant missing gear")
 assert("trunk" in g.town.objective())
 g.player.global_position=g.crash_site.wreck.global_position;g.crash_site.hatch_open=true
 g.town.perform("crash_backpack");g.town.perform("crash_flashlight");assert(g.crash_site.tutorial_complete())
 print("PASS: no-gear pharmacy exit, all unlocked town doors, real key lock, dialogue, evidence, searchable storage/key, letter, police car, gear reminder and trunk retrieval")
 g.queue_free();await process_frame;quit()
