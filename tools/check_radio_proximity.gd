extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.controller.set_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 await create_timer(0.1).timeout
 g.crash_site.wake_phase="";g.state="play"
 var a=g.soundscape.atmosphere
 a.soundscape.rng.seed=421
 var receiver=g.town.actions.receiver.area.global_position
 g.player.global_position=g.town.buildings.radio.to_global(Vector3(0,0.02,3))
 g.camera.global_position=receiver+Vector3(0,0,9)
 a.update_sound(2)
 var far_volume=a.radio.volume_db;var far_pitch=a.radio.pitch_scale;var far_filter=a.radio.attenuation_filter_cutoff_hz
 g.camera.global_position=receiver+Vector3(0,0,0.8)
 a.update_sound(2)
 assert(a.radio.volume_db>far_volume+10 and a.radio.pitch_scale>far_pitch and a.radio.attenuation_filter_cutoff_hz>far_filter)
 assert(a.radio.stream is AudioStreamMP3 and a.radio.stream.loop)
 assert(a.radio.global_position==receiver and not a.radio.stream_paused)
 assert(a.radio_voices.stream is AudioStreamWAV and a.radio_voices.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD)
 assert(a.radio_voices.global_position==receiver and a.radio_voices.playing)
 assert(AudioServer.get_bus_effect_count(AudioServer.get_bus_index(a.VOICE_BUS))==2)
 var gaps=0;var bursts=0
 for i in range(200):
  a.update_sound(0.05)
  await process_frame
  if a.voice_dropout:gaps+=1
  else:bursts+=1
 assert(gaps>0 and bursts>0,"Voices alternate between irregular gaps and phrases")
 g.player.global_position=Vector3(0,0,100);a.update_sound(2)
 assert(a.radio_voices.volume_db< -59)
 assert(a.radio.volume_db< -59)
 g.state="paused";a.update_sound(1);await process_frame;assert(a.radio.stream_paused and a.radio_voices.stream_paused)
 g.state="dialogue";a.update_sound(1);await process_frame;assert(not a.radio.stream_paused and not a.radio_voices.stream_paused)
 g.story.repeater.shutdown_done=true;a.update_sound(1);await process_frame;assert(a.radio.stream_paused and a.radio_voices.stream_paused)
 print("PASS: distorted looping voices, irregular dropouts, spatial mixing and pause/shutdown verified; downloaded static loops at receiver; approach increases loudness, pitch and brightness; outdoor fade, pause, dialogue and shutdown")
 g.queue_free();await process_frame;quit()
