extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 while not g.surface_details.completed:await process_frame
 g.set_physics_process(false);g.enemies.set_physics_process(false)
 g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 var e=g.enemies;var w=g.weapons
 for index in [0,e.HOUSE_INDEX,e.CELLAR_INDEX,e.TUNNEL_INDICES[0]]:
  var d=e.creatures[index]
  for gun in range(3):
   e.reset_creature(d);d.state="chase";w.selected=gun
   var shots=0
   while d.hp>0:
    w.impact({"collider":d.actor,"position":g.camera.global_position+Vector3.FORWARD*3,"zone":"body"},w.shot_damage(gun,"body",3)*w.LOADOUT[gun].pellets)
    shots+=1
   assert(shots==([13,7,4] if e.is_mummy(index) else [10,5,3])[gun],"Weapon lethality preserves headshot and close-range rewards")
  e.reset_creature(d);d.state="chase"
  e.shoot(index,24)
  assert(d.state=="chase","First pistol body hit cannot interrupt pursuit")
  e.shoot(index,24)
  assert(d.state=="chase","Two pistol hits cannot stop a pursuer")
  e.shoot(index,24)
  if e.is_mummy(index):
   assert(d.state=="chase","Mummies resist three pistol hits")
   e.shoot(index,24)
  assert(d.state=="stagger","Sufficient impact causes a readable stagger")
  var timer=d.timer
  e.shoot(index,12)
  assert(d.timer==timer,"Hits during resistance cannot prolong stagger")
  d.state="attack";d.timer=0.7;d.did_hit=false
  e.shoot(index,12)
  assert(d.state=="attack" and d.timer==0.7 and not d.did_hit,"Resisted hit cannot erase a pending attack")
  e.tick_poise(d,3)
  assert(d.stagger_lock==0,"Stagger resistance expires")
 # A nearly landed swing survives an otherwise staggering shot.
 e.reset_creature(e.creatures[0])
 var committed=e.creatures[0]
 committed.state="attack";committed.timer=0.4;committed.did_hit=false
 e.shoot(0,96)
 assert(committed.state=="attack" and not committed.did_hit,"A committed attack cannot be erased by gunfire")
 assert(w.shot_damage(0,"head",3)==42 and w.shot_damage(1,"head",3)==84,"Headshots reward deliberate aim")
 assert(is_equal_approx(w.shot_damage(2,"body",5),9.6) and is_equal_approx(w.shot_damage(2,"body",15),2.4),"Shotgun damage drops from full at 5m to quarter at 15m")
 var cellar=g.victorian_house.cellar
 var attacker=e.creatures[e.CELLAR_INDEX]
 e.reset_creature(attacker)
 g.player.global_position=cellar.to_global(Vector3(0,0.02,0.8))
 attacker.actor.global_position=cellar.to_global(Vector3(0,0.02,-0.2))
 g.health=100;g.invincible=0
 attacker.state="attack";attacker.timer=0.5;attacker.did_hit=false
 await physics_frame;await physics_frame
 e.cellar_encounter.update(e,attacker,0.01)
 assert(g.health==75,"A cellar mummy's committed swing deals 25 damage")
 e.cellar_encounter.update(e,attacker,0.01)
 assert(g.health==75,"A swing cannot damage twice")
 # Loading earlier balance preserves the fraction of remaining health, including death.
 var snapshot=g.saves.backend.capture()
 snapshot.enemies[e.CELLAR_INDEX].hp=30.0;snapshot.enemies[e.CELLAR_INDEX].max_hp=60.0
 snapshot.enemies[0].hp=0;snapshot.enemies[0].max_hp=85.0
 g.saves.backend.apply(snapshot)
 assert(e.creatures[e.CELLAR_INDEX].hp==120 and e.creatures[e.CELLAR_INDEX].max_hp==240,"Old saved enemy health scales proportionally")
 assert(e.creatures[0].hp==0,"Loading cannot revive a dead enemy")
 print("PASS: weapon lethality, headshots, range falloff, mummy resistance, no stun lock or canceled attacks, old-save health scaling")
 g.queue_free();await process_frame;quit()
