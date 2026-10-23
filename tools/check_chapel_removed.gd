extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 while not g.surface_details.completed:await process_frame
 g.set_physics_process(false);g.enemies.set_physics_process(false)
 g.reset_game();g.crash_site.wake_phase="";g.state="play"
 var e=g.enemies;var d=e.creatures[e.HOLLOW_INDEX]
 assert(d.hp==0 and d.state=="removed" and not d.actor.visible and d.actor.collision_layer==0,"No chapel monster or blocking collision")
 var snap=g.saves.backend.capture()
 snap.enemies[e.HOLLOW_INDEX].hp=168;snap.enemies[e.HOLLOW_INDEX].state="chase"
 snap.roots.hollow.visible=true;snap.roots.hollow.layer=1;snap.roots.hollow.mask=1
 g.saves.backend.apply(snap)
 assert(d.hp==0 and not d.actor.visible and d.actor.collision_layer==0,"Older active-encounter save cannot restore monster")
 e.reset_creature(d);assert(d.state=="removed" and not d.actor.visible,"Respawn cannot restore encounter")
 assert(g.town.actions.has("weapon_rifle") and g.town.actions.has("chapel_repeater") and g.town.actions.has("radio_tuner"),"Chapel equipment and story interactions preserved")
 print("PASS: chapel monster removed, old-save restore and respawn suppressed, basement progression retained")
 quit()
