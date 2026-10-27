extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false);g.weapons.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.story.clinic_rescue_done=true;g.state="play"
 var k=g.knife;var w=g.weapons;k.set_process(false);k.sync()
 w.equip(-2);assert(w.selected==-1 and not k.owned() and not k.held.visible,"Knife cannot be equipped before the physical pickup")
 g.town.inventory.medkit=24;assert(not k.collect() and not k.owned() and k.source.visible,"Full pack leaves the knife on the board")
 g.town.inventory.medkit=0
 var center=k.collision.global_position
 g.player.global_position=center+Vector3(0,0.02,1.0);g.camera.global_position=center+Vector3(0,1.0,1.0);g.camera.look_at(center)
 await physics_frame;await physics_frame
 g.town.refresh_focus();print("KNIFE FOCUS ",g.town.focus_action," center ",center," area ",k.area.global_position," visible ",k.area.visible," source ",k.source.global_position);assert(g.town.focus_action=="hotel_knife","Actual aiming finds the kitchen knife")
 g.town.perform("hotel_knife")
 assert(k.owned() and w.selected==-2 and not k.source.visible and k.area.collision_layer==0)
 assert(not g.arm_visual.visible and not g.flashlight_model.visible,"Knife hides the held flashlight")
 assert(not k.collect() and g.town.inventory.knife==1,"Knife cannot be collected twice")
 assert(g.backpack.counts().knife==1 and not g.backpack.pack(g.backpack.counts()).is_empty())
 var inventory=g.backpack.pack(g.backpack.counts())
 assert(inventory.any(func(e):return e.id=="knife" and e.size==Vector2i(1,2)))
 w.delay=0;g.stamina=13;assert(not k.attack())
 g.stamina=100;assert(k.attack() and g.stamina==86)
 assert(not k.attack(),"Holding attack cannot bypass recovery")
 k.apply_pose(-1);var rest=k.held.position
 k.apply_pose(k.HIT_TIME);assert(k.held.position.z<rest.z-0.3 and absf(k.held.rotation.z)<0.001,"Fast stab extends forward without a sideways slash")
 k.apply_pose(k.RECOVERY);assert(k.held.position.is_equal_approx(rest),"Stab returns to its resting pose")
 # Attack traces use animated enemy volumes and solid cover, not distance-only damage.
 k.elapsed=-1;w.delay=0
 for d in g.enemies.creatures:d.actor.hide();d.actor.collision_layer=0
 var d=g.enemies.creatures[0];g.enemies.reset_creature(d);d.state="chase"
 g.player.global_position=Vector3(0,0.02,-48);d.actor.global_position=Vector3(0,0.02,-48.9)
 g.camera.position=Vector3(0,g.STANDING_EYE,0)
 w.enemy_hitboxes=preload("res://enemy_shot_hitboxes.gd").new(g.enemies)
 g.camera.look_at(w.enemy_hitboxes.head_center(d))
 await physics_frame;await physics_frame
 var hp=d.hp;k.strike();assert(d.hp==hp-k.DAMAGE,"Close slash deals bounded knife damage")
 d.actor.global_position.z=-52;hp=d.hp;g.camera.look_at(w.enemy_hitboxes.head_center(d));k.strike();assert(d.hp==hp,"Knife cannot hit a distant enemy")
 d.actor.global_position.z=-48.9;g.camera.look_at(w.enemy_hitboxes.head_center(d))
 var wall=g.town.box(g,Vector3(0,1,-48.45),Vector3(2,2,0.1),g.town.mats.wood)
 await physics_frame;await physics_frame
 k.strike();assert(d.hp==hp,"Solid cover blocks a slash")
 wall.queue_free();await physics_frame
 w.selected=-1;g.controller.activate(0);g.controller.button(JOY_BUTTON_RIGHT_SHOULDER)
 assert(w.selected==-2,"Controller cycling reaches the collected knife")
 var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved));g.saves.backend.apply(saved)
 assert(k.owned() and w.selected==-2 and not k.source.visible,"Equipped knife and physical pickup persist")
 # A normal level stab must connect with a hunched enemy, once per thrust.
 g.state="play";g.player.rotation=Vector3.ZERO;g.camera.rotation=Vector3.ZERO
 d.actor.global_position=Vector3(0,0.02,-49.5);d.state="chase"
 k.elapsed=-1;w.delay=0;g.stamina=100;w.selected=-2
 await physics_frame;await physics_frame
 hp=d.hp;assert(w.fire(),"Normal attack input starts the knife")
 k._process(k.HIT_TIME+0.01);assert(d.hp==hp-k.DAMAGE,"Level stab damages a hunched monster at combat distance")
 k._process(0.05);assert(d.hp==hp-k.DAMAGE,"Several contact samples cannot multiply damage")
 k.elapsed=-1
 # Old saves without the optional knife fields remain valid and start unowned.
 saved.town.inventory.erase("knife");saved.actions.erase("hotel_knife");saved.selected=-1
 assert(g.saves.backend.valid(saved));g.saves.backend.apply(saved)
 assert(not k.owned() and k.source.visible,"Earlier saves do not grant the knife")
 g.reset_game();assert(not k.owned() and w.selected==-1)
 print("PASS: physical hotel pickup, capacity, inventory, stamina/recovery, range, cover, controller cycling, saves and reset")
 g.queue_free();await process_frame;quit()



