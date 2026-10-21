extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false)
 g.state="play";g.crash_site.has_flashlight=true;g.flashlight_charge=75
 var t=g.hotel_basement;t.set_process(false)
 g.player.global_position=t.to_global(Vector3(0,0.02,-28.5))
 t.start_entry_flicker()
 var changes=0;var last=false
 for i in range(140):
  t._process(0.01)
  if g.flashlight.visible!=last:changes+=1;last=g.flashlight.visible
 assert(changes>=9,"Uneven flashes before steady light")
 assert(g.flashlight.visible and is_equal_approx(g.flashlight.light_energy,2.5))
 assert(g.flashlight_charge==75,"No battery refill or consumption in scripted pulses")
 t.start_entry_flicker();t.get_node("CellarCoffinStacks").blackout_active=true
 t._process(0.1)
 assert(not g.flashlight.visible and t.entry_flicker_time==0,"Coffin blackout takes priority")
 print("PASS: entry flicker, steady light, charge preservation, blackout priority")
 quit()
