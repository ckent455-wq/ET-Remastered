extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false);g.enemies.set_physics_process(false)
 g.state="play";g.player.global_position=Vector3(0,0,10)
 var town=g.town
 for person in town.townspeople.characters.values():person.actor.global_position=Vector3(50,0,10)
 town.inventory.station_key=1
 for id in town.doors:assert(town.set_building_door(id,true))
 var church=town.streetscape.church;church.toggle_doors()
 await create_timer(0.8).timeout
 for id in town.doors:
  var d=town.doors[id]
  var center=town.buildings[id].to_local(d.body.global_position)
  assert(center.z<d.hinge.position.z-0.8,"Building door swings into room: "+id)
  assert(d.collision.disabled,"Open doorway remains passable")
  assert(town.set_building_door(id,false))
 for i in range(church.door_hinges.size()):
  var hinge=church.door_hinges[i]
  var center=hinge.to_global(Vector3(0.7 if i==0 else -0.7,1,0))
  assert(church.to_local(center).z<6.5,"Both chapel doors swing inward")
 church.toggle_doors()
 await create_timer(0.8).timeout
 for id in town.doors:
  assert(is_zero_approx(town.doors[id].hinge.rotation.y))
  assert(not town.doors[id].collision.disabled)
 assert(not church.doors_open)
 print("INWARD DOORS CHECK PASSED: six buildings and both chapel doors, open/close and collision")
 g.queue_free();await process_frame;quit()
