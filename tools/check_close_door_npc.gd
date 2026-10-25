extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 g.state="play";g.crash_site.wake_phase=""
 var t=g.town;var npc=t.townspeople.characters.values()[0]
 for id in ["ranger","clinic","workshop","house"]:
  var d=t.doors[id]
  g.player.global_position=t.buildings[id].to_global(Vector3(0,0.01,6.5))
  npc.actor.global_position=t.doorway_position(id)
  assert(t.set_building_door(id,true,false,true))
  await create_timer(0.6).timeout
  t.perform(id+"_door")
  await create_timer(0.6).timeout
  assert(not d.open and absf(d.hinge.rotation.y)<0.01 and not d.collision.disabled,"Door closes fully with NPC in doorway")
  for i in range(10):assert(not t.set_building_door(id,true),"NPC cannot override player's nearby close")
  assert(t.set_building_door(id,true,false,true),"Player can still reopen")
  t.set_building_door(id,false,false,true)
  assert(t.set_building_door(id,true,false,false,true),"Monster breach still works")
  t.set_building_door(id,false,false,true)
  g.player.global_position=t.doorway_position(id)+Vector3(0,0,8)
  assert(t.set_building_door(id,true),"NPC routine resumes once player leaves")
 print("PASS: NPC doorway overlap, fully closed door collision, NPC override prevention, player reopen, monster breach and NPC resumption")
 g.queue_free();await process_frame;quit()
