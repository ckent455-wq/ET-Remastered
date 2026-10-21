extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 g.crash_site.wake_phase="";g.state="play"
 await create_timer(0.15).timeout
 var e=g.enemies;var data=e.creatures[e.HOUSE_INDEX];var h=g.victorian_house
 assert(data.actor.visible and data.state=="house_wait" and data.actor.position.y>3.4)
 g.player.global_position=h.to_global(Vector3(0,0.23,-1.5))
 e.house_encounter.update(e,data,0.1);assert(data.state=="house_wait","Ground floor cannot trigger ambush")
 g.player.global_position=h.to_global(Vector3(0,3.46,-1.65))
 assert(not e.line_clear(data,g.player.global_position+Vector3.UP),"Partition hides the preplaced creature")
 var hp=g.health
 e.house_encounter.update(e,data,0.1)
 assert(data.state=="house_rush" and data.voice.playing and g.health==hp)
 g.state="paused";var before=data.actor.position;e._physics_process(0.5);assert(data.actor.position==before)
 g.state="play"
 for i in range(75):
  e.house_encounter.update(e,data,1.0/60)
  await physics_frame
 print("HOUSE CREATURE LOCAL ",h.to_local(data.actor.global_position)," WAYPOINT ",data.house_waypoint," STATE ",data.state)
 assert(data.house_waypoint==2,"Creature physically clears the bedroom doorway")
 assert(h.to_local(data.actor.global_position).z< -0.85,"Creature reaches the player side of the wall")
 assert(data.actor.global_position.y>3.3,"Creature stays on second floor")
 assert(e.shoot(e.HOUSE_INDEX,24) and data.hp==120)
 assert(e.shoot(e.HOUSE_INDEX,24) and data.hp==96)
 assert(e.shoot(e.HOUSE_INDEX,96) and data.state=="dead")
 e.house_encounter.update(e,data,150);assert(data.state=="dead","No repeated respawn scare")
 g.reset_game();assert(data.state=="house_wait" and data.hp==e.MUMMY_HEALTH and data.house_waypoint==0)
 print("PASS: preplaced hidden creature, upstairs-only trigger, sharp cue without instant damage, pause, real doorway traversal, combat, no respawn, restart reset")
 quit()
