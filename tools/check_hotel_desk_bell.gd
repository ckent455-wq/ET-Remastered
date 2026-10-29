extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout or not g.hotel_reception.area:await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.health=100;g.set_state("play")
 var bell=g.hotel_reception;bell.set_physics_process(false)
 g.player.global_position=g.town.buildings.house.to_global(Vector3(4.64,.04,2.35));g.player.rotation=Vector3.ZERO;g.camera.position=Vector3(0,g.STANDING_EYE,0);g.camera.look_at(bell.area.global_position);g.camera.make_current()
 await physics_frame;g.town.refresh_focus();assert(g.town.focus_action=="hotel_reception_bell","Real bell can be targeted through normal interaction")
 assert(g.town.prompt()=="E / Ring desk bell")
 g.town.interact();assert(bell.voice.playing and is_equal_approx(bell.button.position.y,bell.button_y-.007))
 assert(bell.voice.stream.resource_path=="res://assets/audio/hotel_desk_bell.wav")
 bell._physics_process(.3);assert(is_equal_approx(bell.button.position.y,bell.button_y))
 var before=bell.area.global_position;bell.bell.position.x+=.2;bell.sync();assert(bell.area.global_position.distance_to(before)>.19,"Interaction follows the editable bell model")
 bell.bell.position.x-=.2;bell.sync()
 var f=FileAccess.open("C:/Users/jkern/Documents/Codex/2026-10-16/go-x20/work/pre-zombie-save.bin",FileAccess.READ);var old=f.get_var();f.close();assert(g.saves.backend.valid(old))
 g.reset_game();assert(not bell.voice.playing)
 print("PASS: actual bell focus/E interaction, supplied ding playback, press animation, moved-model target, reset and older save compatibility")
 g.queue_free();await process_frame;quit()
