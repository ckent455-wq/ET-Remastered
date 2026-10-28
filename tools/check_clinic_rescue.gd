extends SceneTree
func _initialize():call_deferred("run")
func step(r,seconds):
 for i in range(int(seconds*10)+1):r._process(0.1)
func prep(g):
 g.reset_game();g.crash_site.wake_phase="";g.state="play";g.clinic_rescue.set_process(false);g.falling_tree.set_physics_process(false)
 g.player.position=Vector3(0,0.02,-10)
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 await process_frame
 prep(g);var r=g.clinic_rescue
 assert(g.crash_site.tutorial_prompt()=="" and g.town.inventory.bandage==0)
 g.crash_site.hatch_open=true;g.crash_site.interact_tutorial("crash_backpack");assert(g.town.inventory.bandage==0)
 g.story.crash_wound_treated=true;g.player.position.z=-16;r.update_approach(1)
 assert(r.caption_visible() and r.phase=="dimming","The new opening always leads to Aubrey, regardless of earlier treatment flags")
 var initial=r.movement_scale();step(r,0.8);assert(r.caption_visible());step(r,1.2);assert(not r.caption_visible());var middle=r.movement_scale();assert(middle<initial and absf(g.camera.rotation.z)>0)
 var before=r.elapsed;g.state="paused";step(r,1);assert(r.elapsed==before);g.state="play"
 step(r,2);assert(r.movement_scale()<middle and r.veil.color.a>0.25)
 g.player.position.z=-22;g.falling_tree.previous_z=-20;g.falling_tree._physics_process(0.1)
 assert(r.phase=="dimming" and not g.falling_tree.triggered,"Crossing the tree trigger cannot skip the warning")
 while r.phase=="dimming":r._process(0.01)
 assert(r.phase=="faint")
 step(r,0.8);assert(g.camera.position.y<g.STANDING_EYE and r.veil.color.a<0.5,"The player sees the drop before blackout")
 step(r,1.1);assert(r.phase=="blackout" and r.veil.color.a==1)
 step(r,2.0);assert(r.phase=="blackout" and r.veil.color.a==1 and not r.caption_visible(),"Opening thought clears after two seconds")
 var previous_elapsed=r.elapsed
 for moment in [[2.6,3],[3.6,2],[4.6,1]]:
  r.elapsed=moment[0];assert(r.blackout_dots()==moment[1])
 r.elapsed=previous_elapsed
 step(r,r.BLACKOUT_SECONDS-1.9);assert(r.phase=="wake" and g.town.player_inside_building("clinic"))
 assert(g.story.clinic_rescue_done and g.town.inventory.bandage==1)
 g.hud._process(0)
 assert(g.health>=65 and g.hud.last_health==g.health and g.hud.blood_opacities().x<0.24,"Treatment refreshes injury state without player movement")
 r.elapsed=0;assert(r.eye_opening()==0 and not r.caption_visible());step(r,0.7);var opening=r.eye_opening();step(r,0.3);assert(r.eye_opening()<opening)
 step(r,2.2);assert(not r.caption_visible() and g.state=="dialogue" and r.phase=="bed" and g.story.AUBREY_OPENING in g.dialogue_text)
 assert("head wound you sustained" in g.dialogue_text)
 g.set_state("play");assert(r.phase=="" and r.movement_scale()==1)
 assert(g.hud.last_health==g.health and g.hud.blood_opacities().y==0 and g.hurt_flash==0 and g.invincible==3,"Bed exit gives protection without a red damage flash")
 g.town.townspeople.talk("nurse");assert(g.town.townspeople.conversation.choosing);g.set_state("play")
 var snapshot=g.saves.backend.capture();g.saves.backend.apply(snapshot);r.update_approach(1);assert(r.phase=="")
 g.health=50;g.town.use_bandage();assert(g.health==60 and g.town.inventory.bandage==0)
 for gear in [[false,false],[true,false],[false,true]]:
  prep(g);g.crash_site.has_backpack=gear[0];g.crash_site.has_flashlight=gear[1];g.player.position.z=-16;r.update_approach(1);assert(r.phase=="dimming")
  r.begin_collapse();r.place_in_bed();r.begin_explanation();assert(g.crash_site.has_backpack==gear[0] and g.crash_site.has_flashlight==gear[1])
  g.set_state("play");assert("trunk" in g.message and "trunk" in g.crash_site.tutorial_prompt())
  var saved=g.saves.backend.capture();g.saves.backend.apply(saved);assert("trunk" in g.town.objective())
  g.crash_site.hatch_open=true
  if not gear[0]:g.crash_site.interact_tutorial("crash_backpack")
  if not gear[1]:g.crash_site.interact_tutorial("crash_flashlight")
  assert(g.crash_site.tutorial_complete() and g.town.inventory.bandage==1)
  r.update_approach(1);assert(r.phase=="")
 for fps in [15,60,144]:
  prep(g);g.player.position=Vector3(0,0.02,-14.99)
  var dt=1.0/float(fps)
  g.player.position.z-=8.0*dt;r.update_approach(dt)
  assert(r.phase=="dimming" and r.movement_scale()<=0.55)
  g.player.position.z=-22;g.falling_tree.previous_z=-20
  g.falling_tree._physics_process(dt)
  assert(r.phase=="dimming" and r.elapsed==0,"Fast crossing cannot cut the five-second warning short")
  step(r,4.0);assert(r.phase=="dimming")
  step(r,1.1);assert(r.phase=="faint")
  step(r,0.6)
  assert(g.camera.position.y<g.STANDING_EYE and r.veil.color.a<0.5)
  var collapse_elapsed=r.elapsed;r.begin_collapse()
  assert(r.elapsed==collapse_elapsed,"Repeated triggers cannot reset the collapse")
 prep(g);g.testing_mode.enabled=true;g.player.position.z=-16;r.update_approach(1);assert(r.phase=="");g.testing_mode.enabled=false
 prep(g);assert(r.movement_scale()==1 and not g.story.clinic_rescue_done)
 print("PASS: required rescue, early gear without bandage, progressive stagger/slowing, pause, collapse before tree, blinking wake, shared Aubrey briefing, treatment, later bandage, missing gear, save/load, reset")
 g.queue_free();await process_frame;quit()
