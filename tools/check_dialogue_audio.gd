extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.controller.set_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 await create_timer(0.1).timeout
 var s=g.soundscape;var a=s.atmosphere
 g.crash_site.wake_phase="";g.state="play";s.update_sound(0.1)
 var wind_volume=s.wind.volume_db
 a.play_accent("metal_moan",g.player.global_position,-22)
 var timer=a.event_timer
 g.state="dialogue";s.update_sound(0.1)
 assert(not s.wind.stream_paused and not s.leaves.stream_paused)
 assert(not a.bed.stream_paused and not a.radio.stream_paused)
 assert(a.accent.playing,"Existing sound is not stopped by dialogue")
 assert(s.wind.volume_db==wind_volume,"Dialogue does not change ambient mix")
 assert(a.event_timer<timer,"Atmosphere continues during dialogue")
 var repeater=g.story.repeater;repeater._process(0)
 assert(not repeater.hum.stream_paused)
 repeater.shutdown_done=true;repeater.hum.stop();s.update_sound(0.1)
 assert(a.radio.stream_paused and not repeater.hum.playing,"Story shutdown stays silent")
 g.state="paused";s.update_sound(0.1);repeater._process(0)
 assert(s.wind.stream_paused and s.leaves.stream_paused and a.bed.stream_paused and (not repeater.hum.playing or repeater.hum.stream_paused))
 g.state="dialogue";s.update_sound(0.1)
 assert(not a.bed.stream_paused and not s.wind.stream_paused)
 print("DIALOGUE AUDIO CHECK PASSED")
 g.queue_free();await process_frame;quit()
