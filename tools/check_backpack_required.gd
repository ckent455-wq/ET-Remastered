extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera()
 var rescue=g.clinic_rescue;rescue.place_in_bed();rescue.begin_explanation();g.set_state("play")
 assert(g.story.clinic_rescue_done and not g.crash_site.has_backpack)
 var inventory=g.town.inventory.duplicate(true)
 for id in ["medkit_a","battery_a","ammo_pistol_clinic","house_note","workshop_shovel"]:
  var taken=g.town.actions[id].taken;g.town.perform(id)
  assert(g.town.actions[id].taken==taken and g.town.inventory==inventory,"No collection without backpack: "+id)
  assert("backpack" in g.message and "trunk" in g.message)
 var storage=g.town.interiors
 for id in ["clinic_cabinet","clinic_drawer"]:
  var extras=storage.containers[id].remaining_extras.duplicate(true)
  storage.toggle(id)
  assert(storage.containers[id].open and not storage.containers[id].searched and storage.containers[id].remaining_extras==extras,"Container can open but cannot transfer loot without backpack")
 assert(not g.weapons.collect(0) and g.weapons.add_ammo(0,6)==0 and not g.knife.collect())
 assert(not g.weapons.owned[0] and g.weapons.reserves[0]==0 and not g.knife.owned())
 g.town.townspeople.offer_grave_key();assert(not g.town.townspeople.grave_key_given and g.town.inventory.mausoleum_key==0)
 g.set_state("play");g.grave_dig.interact_shovel();assert(g.town.inventory.shovel==0)
 var d=g.enemies.creatures[0];d.hp=0;d.state="dead";g.enemies.corpse_search.search(0);assert(not d.get("body_searched",false))
 g.crash_site.hatch_open=true;g.crash_site.interact_tutorial("crash_flashlight");assert(not g.crash_site.has_flashlight)
 var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved));g.saves.backend.apply(saved)
 assert(not g.crash_site.has_backpack and not g.backpack.room_for("battery"),"No-backpack restriction survives a post-clinic save/load")
 g.crash_site.interact_tutorial("crash_backpack");assert(g.crash_site.has_backpack)
 g.crash_site.interact_tutorial("crash_flashlight");assert(g.crash_site.has_flashlight)
 for id in ["clinic_cabinet","clinic_drawer"]:
  if storage.containers[id].open:storage.toggle(id)
  storage.toggle(id)
 assert(g.town.inventory.medkit==2 and g.town.inventory.bandage>=2,"Untouched pharmacy supplies can be collected after retrieving the backpack")
 g.town.perform("ammo_pistol_clinic");assert(g.weapons.reserves[0]>0)
 assert(g.weapons.collect(0) and g.knife.collect(),"Equipment pickups resume normally with backpack")
 print("PASS: actual pharmacy wake-up, blocked supplies/ammo/weapons/letter/shovel/key/body loot, untouched storage, trunk pickup order, save/load and collection after backpack")
 quit()
