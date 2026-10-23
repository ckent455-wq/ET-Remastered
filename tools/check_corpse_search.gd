extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 while not g.surface_details.completed:await process_frame
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.weapons.set_physics_process(false);g.controller.set_process(false)
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 var e=g.enemies;var d=e.creatures[0]
 d.actor.global_position=g.player.global_position+Vector3(0,0,-1.5)
 d.hp=0;d.state="dead";d.actor.collision_layer=0;d.actor.collision_mask=0
 d.body_ammo=2;d.body_ammo_type=0;d.body_note=0
 g.camera.look_at(d.visual.to_global(Vector3(0,0.8,0)))
 await physics_frame;await physics_frame
 g.town.refresh_focus();assert(g.town.focus_action=="body_search_0","Downed body can be targeted")
 assert(g.town.prompt()=="E / Search body")
 var ammo=g.weapons.reserves[0];g.town.perform("body_search_0")
 assert(d.body_searched and g.weapons.reserves[0]==ammo+2,"Search awards a small ammo find")
 assert(g.state=="journal" and g.town.journal_entries.any(func(n):return n.id=="personal_body_0"),"Personal note opens in journal")
 var snapshot=g.saves.backend.capture()
 g.state="play";e.reset_creature(d);d.hp=0;d.state="dead"
 d.actor.global_position=g.player.global_position+Vector3(0,0,-1.5)
 e.corpse_search.search(0);assert(g.weapons.reserves[0]==ammo+2 and d.body_searched,"Reviving cannot refill body loot")
 g.saves.backend.apply(snapshot);assert(d.body_searched and g.weapons.reserves[0]==ammo+2,"Save restore preserves search and ammo")
 g.state="play";var empty=e.creatures[1];empty.actor.global_position=g.player.global_position+Vector3(0,0,-1.5);empty.hp=0;empty.state="dead";empty.body_ammo=0;empty.body_note=-1
 e.corpse_search.search(1);assert(empty.body_searched and "Nothing useful" in g.message,"Empty bodies can be searched once")
 g.state="play";g.testing_mode.toggle()
 empty.body_searched=false;empty.body_ammo=2;empty.body_ammo_type=0;empty.body_note=2
 empty.actor.global_position=g.player.global_position+Vector3(0,0,-1.5)
 e.corpse_search.search(1)
 assert(empty.body_searched and g.state=="journal" and g.weapons.reserves[0]==g.weapons.LOADOUT[0].max_reserve,"Dev mode permits searching full-ammo bodies and reading notes")
 g.reset_game();assert(not d.body_searched,"New journey resets body searches")
 print("PASS: aimed body interaction, ammo, lore journal, empty search, revival deduplication, save/load and new journey")
 quit()
