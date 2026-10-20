extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.controller.set_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false);g.state="play"
 var t=g.town
 for person in t.townspeople.characters.values():person.actor.global_position=Vector3(50,0,10)
 t.inventory.station_key=1
 for id in t.doors:
  g.player.global_position=t.buildings[id].to_global(Vector3(0,0,2.8))
  assert(t.player_inside_building(id))
  assert(t.set_building_door(id,true))
  await create_timer(0.6).timeout
  t.focus_action=id+"_door";assert(t.prompt()=="E / Close door")
  assert(t.set_building_door(id,false),"Can close from inside "+id)
 var chapel=t.streetscape.church
 g.player.global_position=chapel.to_global(Vector3(0,0,5))
 chapel.toggle_doors();await create_timer(0.7).timeout
 chapel.toggle_doors();assert(not chapel.doors_open,"Can close chapel from inside")
 var cemetery=t.cemetery
 cemetery.unlocked=true;g.player.global_position=cemetery.crypt.to_global(Vector3(0,0,0))
 cemetery.interact_door();await create_timer(0.7).timeout
 cemetery.interact_door();assert(not cemetery.opened,"Can close mausoleum from inside")
 print("INSIDE DOOR CLOSING CHECK PASSED")
 g.queue_free();await process_frame;quit()
