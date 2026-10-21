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
   assert(shots==[6,3,2][gun],"Body shots require six pistol, three rifle or two close shotgun blasts")
  e.reset_creature(d);d.state="chase"
  e.shoot(index,24)
  assert(d.state=="chase","First pistol body hit cannot interrupt pursuit")
  e.shoot(index,24)
  if e.is_mummy(index):
   assert(d.state=="chase","Mummies resist the second pistol hit")
   e.shoot(index,24)
  assert(d.state=="stagger","Sufficient impact causes a readable stagger")
  var timer=d.timer
  e.shoot(index,12)
  assert(d.timer==timer,"Hits during resistance cannot prolong stagger")
  d.state="attack";d.timer=0.7;d.did_hit=false
  e.shoot(index,12)
  assert(d.state=="attack" and d.timer==0.7 and not d.did_hit,"Resisted hit cannot erase a pending attack")
  e.tick_poise(d,2)
  assert(d.stagger_lock==0,"Stagger resistance expires")
 assert(w.shot_damage(0,"head",3)==36 and w.shot_damage(1,"head",3)==72,"Headshots deal 1.5x damage")
 assert(w.shot_damage(2,"body",5)==12 and w.shot_damage(2,"body",15)==3,"Shotgun damage drops from full at 5m to quarter at 15m")
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
 assert(e.creatures[e.CELLAR_INDEX].hp==72 and e.creatures[e.CELLAR_INDEX].max_hp==144,"Old saved enemy health scales proportionally")
 assert(e.creatures[0].hp==0,"Loading cannot revive a dead enemy")
 print("PASS: weapon lethality, headshots, range falloff, mummy resistance, no stun lock or canceled attacks, old-save health scaling")
 g.queue_free();await process_frame;quit()
