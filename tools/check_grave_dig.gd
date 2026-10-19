extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.grave_dig.set_process(false);g.cemetery_shadow.set_physics_process(false)
 g.crash_site.wake_phase="";g.state="play";g.crash_site.has_backpack=true
 await create_timer(0.15).timeout
 var d=g.grave_dig
 assert(not d.dug and not d.exposed.visible)
 assert(g.town.actions.cemetery_buried_ammo.area.collision_layer==0)
 d.interact_grave();assert(not d.digging and "shovel" in g.message)
 # A full bag leaves the shovel available instead of losing it.
 g.town.inventory.medkit=12
 d.interact_shovel();assert(g.town.inventory.shovel==0 and d.shovel.visible)
 g.town.inventory.medkit=0
 g.town.perform("workshop_shovel")
 assert(g.town.inventory.shovel==1 and not d.shovel.visible)
 var shovel_entry=g.backpack.pack(g.backpack.counts()).filter(func(e):return e.id=="shovel")
 assert(shovel_entry.size()==1 and shovel_entry[0].size==Vector2i(1,3))
 g.player.global_position=d.GRAVE+Vector3(0,0,2)
 g.town.focus_action="cemetery_disturbed_grave"
 g.town.perform("cemetery_disturbed_grave");assert(d.digging)
 d.update_dig(1.0,true);assert(not d.dug)
 d.update_dig(0.1,false);assert(not d.digging and d.elapsed==0)
 d.interact_grave();g.set_state("paused");d.update_dig(2,true);assert(d.elapsed==0)
 g.set_state("play")
 for i in range(23):d.update_dig(0.1,true)
 assert(d.scraped and not d.exposed.visible,"Coffin scrape precedes reward reveal")
 for i in range(10):d.update_dig(0.1,true)
 assert(d.dug and d.exposed.visible and not d.mound.visible)
 assert(g.town.actions.cemetery_buried_ammo.area.collision_layer==2)
 var before=g.weapons.reserves[0]
 g.town.perform("cemetery_buried_ammo")
 assert(g.weapons.reserves[0]==before+6)
 g.town.perform("cemetery_buried_ammo");assert(g.weapons.reserves[0]==before+6,"No infinite ammo")
 g.town.perform("cemetery_buried_note")
 assert(g.state=="journal" and g.town.journal_entries.any(func(e):return e.id=="cemetery_buried_note"))
 g.set_state("play");d.interact_grave();assert(not d.digging,"Only dig once")
 g.reset_game()
 assert(not d.dug and not d.digging and d.shovel.visible and g.town.inventory.shovel==0)
 assert(not d.exposed.visible and g.town.actions.cemetery_buried_ammo.area.collision_layer==0)
 assert(g.town.actions.cemetery_buried_ammo.amount==6)
 print("PASS: shovel required, limited bag space, pickup, 1x3 icon entry, hold/release cancellation, pause, scrape before reveal, six rounds once, journal note, restart")
 quit()
