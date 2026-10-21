extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 while not g.surface_details.completed:await process_frame
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 var e=g.enemies;var p=e.pursuit;var d=e.creatures[0]
 e.reset_creature(d);d.state="chase";d.memory=0;d.seen=false
 g.player.global_position=Vector3(0,0.02,-35);d.actor.global_position=Vector3(0,0.02,-31)
 await physics_frame;await physics_frame
 assert(p.update(e,d,0.1) and d.pursuing and d.memory>0 and d.target==g.player.global_position,"A chase latches through lost line of sight and expired memory")
 g.player.global_position=Vector3(0,0.02,-37)
 p.update(e,d,0.1)
 assert(d.target==g.player.global_position and d.state!="returning","Pursuit tracks a moving player indefinitely")
 # Physical doors can also be opened while leaving a building after the target.
 var b=g.town.buildings.workshop
 g.town.set_building_door("workshop",false,false,true)
 await create_timer(0.7).timeout
 d.actor.global_position=b.to_global(Vector3(0,0.02,3.75));d.state="chase"
 g.player.global_position=b.to_global(Vector3(0,0.02,11))
 await physics_frame;await physics_frame
 for i in range(45):
  p.update(e,d,0.1);await physics_frame
 assert(g.town.doors.workshop.open,"Monster forces the exit door when the player retreats away from the building")
 var church=g.town.streetscape.church
 church.reset_doors()
 d.actor.global_position=church.to_global(Vector3(0,0.02,8.15))
 var church_goal:Vector3=church.to_global(Vector3(0,0.02,3))
 await physics_frame;await physics_frame
 for i in range(42):
  p.special_door(e,d,church_goal,0.1);await physics_frame
 assert(church.doors_open,"Pursuer can force the chapel's custom double doors")
 # A basement follower takes the same doorway route after a short transition.
 var mummy=e.creatures[e.CELLAR_INDEX];e.reset_creature(mummy)
 mummy.state="cellar_rush";mummy.pursuing=true
 var edge=p.portal(g,"victorian",true)
 mummy.actor.global_position=edge.point
 g.player.global_position=g.victorian_house.to_global(Vector3(0,0.24,1))
 await physics_frame;await physics_frame
 for i in range(17):p.update(e,mummy,0.1)
 assert(p.space(g,mummy.actor.global_position)=="surface","Cellar mummy follows through its upstairs doorway")
 assert(mummy.pursuing,"Portal travel retains pursuit")
 assert(not p.portal(g,"chapel",false).allowed,"Locked chapel cellar is protected")
 g.town.streetscape.church.basement.unlocked=true
 assert(p.portal(g,"chapel",false).allowed,"Opened chapel route admits pursuing enemies")
 var reaper=e.creatures[e.REAPER_INDEX];e.reset_creature(reaper)
 assert(not p.update(e,reaper,0.1) and not reaper.pursuing,"Untriggered hidden monsters remain dormant")
 var upstairs=e.creatures[e.HOUSE_INDEX];e.reset_creature(upstairs)
 upstairs.state="chase";upstairs.house_waypoint=2
 upstairs.actor.global_position=g.victorian_house.to_global(Vector3(0,g.victorian_house.UPPER+0.02,-1.35))
 g.player.global_position=g.victorian_house.to_global(Vector3(0,g.victorian_house.FLOOR+0.02,2.8))
 await physics_frame;await physics_frame
 for i in range(900):
  p.update(e,upstairs,1.0/60);await physics_frame
  if g.victorian_house.to_local(upstairs.actor.global_position).y<1.0:break
 print("STAIR FOLLOW ",g.victorian_house.to_local(upstairs.actor.global_position))
 assert(g.victorian_house.to_local(upstairs.actor.global_position).y<1.0,"Upstairs mummy physically follows down the staircase")
 var saved=g.saves.backend.capture();g.saves.backend.apply(saved)
 assert(e.creatures[e.CELLAR_INDEX].pursuing,"Save/load retains a pursuing monster")
 e.reset_creature(mummy)
 assert(not mummy.pursuing,"New journey/respawn clears pursuit")
 print("PASS: persistent target, loss of sight, moving target, physical door exit, cellar follow, locked portals, dormant guards, save/load and reset")
 g.queue_free();await process_frame;quit()
