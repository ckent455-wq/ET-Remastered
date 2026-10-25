extends SceneTree
func _initialize():
 var combat=load("res://creature_combat.gd").new()
 var d={"index":6,"hp":288.0,"max_hp":288.0}
 combat.reset(d)
 combat.hit(d,"body",100)
 assert(d.limp_time==0,"Torso hits cannot disable legs")
 combat.hit(d,"leg",15.6);assert(d.limp_time==0)
 combat.hit(d,"leg",15.6)
 assert(d.limp_time==3.0 and combat.movement(d)==0.48,"Two aimed pistol leg hits buy distance")
 combat.tick(d,2);combat.hit(d,"leg",100)
 assert(d.limp_time==1.0,"Repeat shots cannot extend the same limp indefinitely")
 combat.tick(d,1.1);assert(combat.movement(d)==1.0)
 d.hp=80;d.combat_clock=0
 assert(combat.movement(d)>1.0,"A wounded creature makes a brief effort")
 combat.tick(d,1.3);assert(combat.movement(d)<1.0,"Wounded bursts have a recovery period")
 combat.reset(d);assert(d.limp_time==0 and d.leg_resistance==0)
 print("PASS: targeted legs, temporary limp, resistance, wounded bursts and reset")
 quit()
