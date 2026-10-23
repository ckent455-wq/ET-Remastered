extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.weapons.set_physics_process(false)
 g.reset_game();g.crash_site.wake_phase="";g.state="play"
 var e=g.enemies;var d=e.creatures[e.CELLAR_INDEX]
 d.actor.global_position=Vector3(100,0.1,100);d.actor.rotation=Vector3.ZERO
 for i in range(5):g.town.box(g,Vector3(100,0.1+i*0.15,100+i*0.4),Vector3(3,0.2+i*0.3,0.4),g.town.mats.wood)
 await physics_frame;await physics_frame
 d.hp=0;d.state="dead";d.fall_time=1;d.visual.rotation.x=-PI/2
 e.support_mummy_corpse(d)
 print("CORPSE ",d.corpse_lift," MESHES ",d.visual.find_children("*","MeshInstance3D",true,false).size());assert(d.corpse_lift>0 and d.corpse_settled,"Corpse is lifted above stepped geometry and settles")
 var lift=d.visual.position.y;e.support_mummy_corpse(d);assert(d.visual.position.y==lift,"Resting corpse stays stable")
 e.reset_creature(d);assert(d.visual.position==Vector3.ZERO and not d.corpse_settled)
 d.state="chase";d.hp=144;g.weapons.selected=2
 g.weapons.impact({"collider":d.actor,"position":g.camera.global_position+Vector3.FORWARD*3,"zone":"body"},24)
 assert(d.state=="stagger" and d.push_velocity.length()>3,"Shotgun produces physical stagger")
 var start=d.actor.global_position;e.tick_shot_reaction(d,0.04)
 assert(d.actor.global_position.distance_to(start)>0.01,"Knockback displaces the collision body")
 print("PASS: stair corpse clearance, stable settling, reset and physical shotgun impact")
 quit()
