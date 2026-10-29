extends SceneTree
var g
func _initialize():call_deferred("run")
func require(condition:bool,message:String):
 if not condition:push_error(message);quit(1);assert(condition,message)
func snap(path:String):
 for i in 5:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.set_process_input(false)
 g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout or not g.door_bolts.built or g.monster_audio.sources.is_empty():await process_frame
 g.monster_audio.set_physics_process(false)
 g.reset_game();g.crash_site.leave_seat_for_testing();g.crash_site.wake_phase="";g.set_state("play")
 var town=g.town;var audio=g.monster_audio;var d=g.enemies.creatures[0]
 var clinic=town.buildings.clinic
 var bolt=g.door_bolts.bolts.filter(func(b):return b.id=="clinic")[0]
 require(bolt.mount.get_parent()==town.doors.clinic.hinge,"Bolt follows moving door leaf")
 require(bolt.mount.get_meta("runtime_visual_only",false),"Hardware excluded from saved hierarchy")
 town.shelter_locks["clinic"]=true;g.door_bolts._process(.25)
 require(is_equal_approx(bolt.slider.position.x,.12),"Bolt slides into locked position")
 town.shelter_locks["clinic"]=false;g.door_bolts._process(.25)
 require(is_zero_approx(bolt.slider.position.x),"Bolt retracts when unlocked")
 g.player.global_position=clinic.to_global(Vector3(0,.04,3.4))
 g.player.rotation=Vector3.ZERO;g.camera.position=Vector3(0,g.STANDING_EYE,0)
 d.actor.global_position=clinic.to_global(Vector3(0,.04,6.5));d.state="chase"
 for i in 4:await physics_frame
 require(audio.obstruction(d)>.66,"Closed door occludes monster sound")
 audio.sample_time=0;audio._physics_process(.5)
 var source:Dictionary=audio.sources[d.index]
 require(source.filter.cutoff_hz<1200,"Closed door applies low-pass filter")
 require(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(source.bus))< -8,"Closed door lowers monster volume")
 town.set_building_door("clinic",true,false,true)
 for i in 50:await physics_frame
 require(audio.obstruction(d)<.34,"Open doorway lets monster sound through")
 audio.sample_time=0;audio._physics_process(.5)
 require(source.filter.cutoff_hz>18000,"Open doorway restores clear sound")
 d.actor.global_position+=Vector3(0,0,1.1);audio.update_steps(d,source)
 require(source.step.playing,"Moving monster produces spatial footsteps")
 require(source.step.bus==d.voice.bus,"Footsteps and monster voice share occlusion")
 g.set_state("paused");audio._physics_process(.1)
 require(not source.step.playing,"Pause stops monster footsteps")
 g.set_state("play")
 town.set_building_door("clinic",false,false,true)
 for i in 45:await physics_frame
 var snapshot=g.saves.backend.capture()
 require(g.saves.backend.valid(snapshot),"New snapshot validates with cosmetic hardware and footsteps")
 # Remove the new runtime modules and validate the same snapshot as an older hierarchy.
 for b in g.door_bolts.bolts:
  b.mount.get_parent().remove_child(b.mount);b.receiver.get_parent().remove_child(b.receiver)
 require(g.saves.backend.valid(snapshot),"Cosmetic bolt nodes do not affect save compatibility")
 for b in g.door_bolts.bolts:
  # Parents can be recovered from the door identity after this read-only validation.
  b.mount.queue_free();b.receiver.queue_free()
 g.door_bolts.bolts.clear();g.door_bolts.build()
 bolt=g.door_bolts.bolts.filter(func(b):return b.id=="clinic")[0]
 g.hud.hide();g.backpack.hide();g.flashlight.hide();g.arm_visual.hide()
 g.player.global_position=clinic.to_global(Vector3(.35,.04,3.9));g.player.rotation=Vector3.ZERO
 g.camera.position=Vector3(0,1.55,0);g.camera.look_at(bolt.mount.global_position);g.camera.make_current()
 var light=OmniLight3D.new();g.add_child(light);light.global_position=g.camera.global_position;light.light_energy=1.4;light.omni_range=3
 if not "--headless" in OS.get_cmdline_args():
  await snap("res://tmp/deadbolt-unlocked.png")
  town.shelter_locks["clinic"]=true;g.door_bolts._process(.3)
  await snap("res://tmp/deadbolt-locked.png")
 print("PASS: sliding bolts, door occlusion, restored open-door sound, monster footsteps, pause and save hierarchy compatibility")
 quit()
