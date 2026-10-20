extends SceneTree
func _initialize():call_deferred("run")
func go_receiver(g):
 g.player.global_position=g.town.buildings.radio.to_global(Vector3(-2.7,0.02,-2))
 g.camera.position=Vector3(0,g.STANDING_EYE,0);g.camera.rotation=Vector3.ZERO
 g.town.focus_action="receiver";g.state="play"
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.state="play"
 var rack=g.story.repeater;var cellar=g.town.streetscape.church.basement
 assert(not g.story.repeater_is_off() and rack.hum.playing,"Repeater begins powered")
 assert(not rack.shutdown(),"Shutdown cannot be triggered remotely or through a locked cellar")
 g.town.inventory.coil=1;g.town.inventory.tuner=1;g.town.inventory.antenna=1
 g.town.perform("receiver");assert(g.town.radio_ready)
 g.town.perform("radio_bypass");go_receiver(g)
 assert(not g.rescue_available(),"Green routing alone cannot finish with the carrier on")
 g.update_contact(4.5,true);assert(g.state=="play" and g.contact_progress==0 and "Shut down" in g.message,"Holding interact cannot bypass mandatory shutdown")
 cellar.unlocked=true
 g.player.global_position=cellar.to_global(Vector3(2.65,0.02,1.0))
 g.camera.global_position=g.player.global_position+Vector3(0,g.STANDING_EYE,0);g.camera.look_at(g.town.actions.chapel_repeater.area.global_position)
 await physics_frame;await physics_frame
 g.town.refresh_focus();assert(g.town.focus_action=="chapel_repeater","Physical main isolator is reachable with the crosshair")
 g.town.interact();assert(g.story.repeater_is_off() and not rack.hum.playing,"Actual interaction cuts carrier power and local hum")
 assert(rack.lamp.material_override==g.town.mats.dark and not rack.shutdown(),"Indicator goes dark and shutdown is one-way")
 var notes=g.town.journal_entries.filter(func(e):return e.id=="repeater_shutdown")
 assert(notes.size()==1,"Shutdown logged exactly once")
 g.soundscape.atmosphere.update_sound(0.1);assert(g.soundscape.atmosphere.radio.stream_paused,"Compromised radio noise is silent")
 var creature=g.enemies.creatures[0];creature.state="dead";creature.respawn_remaining=0.01
 g.enemies._physics_process(1);assert(creature.state=="dead","Dead chapel creatures stay down with the carrier off")
 go_receiver(g);g.story.toggle_bypass();assert(not g.story.direct_channel_selected())
 g.update_contact(4.5,true);assert(g.state=="play" and "amber route is dead" in g.message,"Dead amber route cannot produce an incoherent ending")
 g.story.toggle_bypass();assert(g.rescue_available())
 g.update_contact(4.5,true);assert(g.state=="won" and "repeater is off" in g.story.ending_text(),"Shutdown plus direct county permits the ending")
 g.reset_game();assert(not g.story.repeater_is_off() and rack.hum.playing and not g.story.direct_channel_selected(),"New journey restores powered rack and routing")
 assert(not g.town.journal_entries.any(func(e):return e.id=="repeater_shutdown"),"Shutdown record resets")
 for id in ["radio_note","workshop_record","cellar_record"]:assert(g.hud.note_height(g.story.RECORDS[id][1],10)<=200,"Updated record fits its journal page: "+id)
 print("PASS: physical locked-room shutdown, real crosshair interaction, powered/silent visuals and audio, mandatory completion gate, no respawn, direct routing, journal and new journey")
 g.queue_free();await process_frame;quit()
