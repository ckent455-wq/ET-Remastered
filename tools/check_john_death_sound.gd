extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.weapons.set_physics_process(false);g.town.townspeople.set_physics_process(false);g.knife.set_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.story.clinic_rescue_done=true;g.state="play"
 var npcs=g.town.townspeople;var john=npcs.characters.mechanic
 for d in g.enemies.creatures:d.actor.hide();d.actor.collision_layer=0
 g.player.global_position=Vector3(0,.02,-48);g.player.rotation=Vector3.ZERO;g.camera.position=Vector3(0,g.STANDING_EYE,0)
 john.actor.global_position=Vector3(0,.02,-49);g.camera.look_at(john.actor.global_position+Vector3.UP*1.1)
 g.knife.collect();var saved=g.saves.backend.capture()
 await physics_frame;await physics_frame
 g.weapons.delay=0;assert(g.weapons.fire());g.knife._process(g.knife.HIT_TIME+.01)
 assert(john.dead,"Actual knife attack kills John")
 var voice=g.soundscape.john_death_voice
 assert(voice!=null and voice.playing and voice.stream.resource_path.ends_with("john_death_1.wav"),"Knife kill plays the user's recording")
 assert(voice.bus==g.soundscape.BUS and voice.global_position.distance_to(john.actor.global_position+Vector3.UP*1.3)<.01)
 assert(not npcs.shoot("mechanic"),"Corpse cannot retrigger the death event")
 assert(g.saves.backend.valid(saved),"Audio does not change old snapshot hierarchy")
 g.reset_game();assert(not voice.playing)
 g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.story.clinic_rescue_done=true;g.state="play"
 g.player.global_position=Vector3(0,.02,-48);g.player.rotation=Vector3.ZERO;g.camera.position=Vector3(0,g.STANDING_EYE,0)
 john.actor.global_position=Vector3(0,.02,-49);g.camera.look_at(john.actor.global_position+Vector3.UP*1.1)
 g.weapons.collect(0);g.weapons.equip(0);g.weapons.delay=0;g.weapons.aiming=true
 await physics_frame;await physics_frame
 assert(g.weapons.fire());assert(john.dead and voice.playing,"Actual gunshot plays the same John death sound")
 g.reset_game();g.state="play";assert(npcs.shoot("nurse") and not voice.playing,"Other NPCs do not use John's recording")
 print("PASS: actual knife and gun kills, John-only spatial audio, single death event, reset and save compatibility")
 quit()
