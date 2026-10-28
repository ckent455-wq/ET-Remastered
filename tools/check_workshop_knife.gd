extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false);g.knife.set_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.story.clinic_rescue_done=true;g.state="play"
 var k=g.knife;var p=k.pickups.workshop_knife;k.sync()
 assert(not k.collect("workshop_knife") and p.source.visible,"Backpack is required for the workshop knife")
 g.crash_site.has_backpack=true;g.town.inventory.medkit=24
 assert(not k.collect("workshop_knife") and not g.town.actions.workshop_knife.taken,"Full backpack leaves workshop knife on table")
 g.town.inventory.medkit=0
 var center=p.collision.global_position
 g.player.global_position=center+Vector3(0,.02,1);g.camera.global_position=center+Vector3(0,.8,1);g.camera.look_at(center)
 await physics_frame;await physics_frame
 g.town.refresh_focus();assert(g.town.focus_action=="workshop_knife","Actual aiming finds the moved workshop knife")
 g.town.perform(g.town.focus_action)
 assert(k.owned() and g.weapons.selected==-2 and not p.source.visible and p.area.collision_layer==0)
 assert(k.source.visible and not g.town.actions.hotel_knife.taken,"Taking workshop knife leaves hotel knife available")
 assert(not k.collect("workshop_knife") and g.town.inventory.knife==1,"Workshop pickup cannot duplicate itself")
 var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved));g.saves.backend.apply(saved)
 assert(g.town.actions.workshop_knife.taken and not p.source.visible and k.source.visible and g.weapons.selected==-2)
 assert(k.collect("hotel_knife") and g.town.inventory.knife==2,"Each location is an independent physical knife")
 assert(g.backpack.pack(g.backpack.counts()).filter(func(e):return e.id=="knife").size()==2,"Both knives consume their own backpack space")
 var legacy=g.saves.backend.capture();legacy.actions.erase("workshop_knife");legacy.town.inventory.knife=1
 assert(g.saves.backend.valid(legacy));g.saves.backend.apply(legacy)
 assert(g.town.inventory.knife==1 and not k.source.visible and p.source.visible,"Earlier hotel-knife saves retain the new workshop pickup")
 g.reset_game();assert(not k.owned() and p.source.visible and k.source.visible)
 print("PASS: workshop aiming/collection, backpack/capacity gates, shared equipped weapon, independent hotel pickup, inventory space, save/load, older saves and reset")
 quit()
