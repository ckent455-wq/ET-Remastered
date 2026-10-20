extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 g.crash_site.wake_phase="";g.state="play";g.crash_site.has_flashlight=true;g.crash_site.has_backpack=true
 await create_timer(0.15).timeout
 var e=g.enemies;var b=g.hotel_basement;var c=b.get_node("CellarCoffinStacks");c.set_process(false)
 g.player.global_position=b.to_global(Vector3(0,0.02,-12));g.flashlight_charge=87;g.flashlight.show()
 e.shoot(e.TUNNEL_INDICES[0],100)
 assert(not c.blackout_active and g.flashlight.visible,"First monster does not cause blackout")
 e.shoot(e.TUNNEL_INDICES[1],100)
 assert(c.blackout_active and not g.flashlight.visible and g.flashlight_charge==87)
 g.toggle_flashlight();assert(not g.flashlight.visible)
 g.controller.activate(0);g.controller.button(JOY_BUTTON_DPAD_DOWN);assert(not g.flashlight.visible,"Controller cannot bypass blackout")
 g.town.inventory.battery=2;g.town.use_battery();assert(g.town.inventory.battery==2 and g.flashlight_charge==87)
 c._process(2);assert(c.blackout_active and not g.flashlight.visible)
 g.testing_mode.begin();assert(not g.flashlight.visible,"Testing gear cannot override scripted blackout")
 g.testing_mode.finish(true);assert(not g.flashlight.visible)
 g.player.global_position=b.to_global(Vector3(0,0.02,-3.3))
 var d=e.creatures[e.TUNNEL_INDICES[2]]
 e.tunnel_encounter.update(e,d,0.01)
 assert(c.busted and d.state=="coffin_breakout" and not c.blackout_active and g.flashlight.visible)
 assert(g.flashlight_charge==87,"Normal charge preserved during outage")
 assert(c.sting.playing and c.sting.stream.resource_path.ends_with("tree_scream.mp3"),"Approved scream unchanged")
 g.reset_game();g.crash_site.wake_phase="";g.state="play";g.crash_site.has_flashlight=true
 g.player.global_position=b.to_global(Vector3(0,0.02,-12));g.flashlight_charge=0
 c.start_blackout();c.burst();assert(g.flashlight.visible and g.flashlight_charge>=5,"Reveal works even with an empty battery")
 g.reset_game();g.crash_site.wake_phase="";g.state="play";g.crash_site.has_flashlight=true
 g.player.global_position=b.to_global(Vector3(0,0.02,-12));g.flashlight_charge=73;g.flashlight.show()
 c.start_blackout();g.player.global_position=Vector3.ZERO;c._process(0.1)
 assert(not c.blackout_active and g.flashlight.visible and g.flashlight_charge==73,"Leaving by portal restores ordinary light")
 g.reset_game();assert(not c.blackout_active and not c.blackout_spent and not c.busted)
 print("PASS: second-kill blackout, full/empty charge, switch/controller/battery/test-mode guards, synchronized approved scream and light restoration, portal escape, restart")
 quit()
