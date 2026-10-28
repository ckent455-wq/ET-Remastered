extends SceneTree
var g
var nav
func _initialize():call_deferred("run")
func segment(point:Vector3):
 var count=0
 while Vector2(g.player.global_position.x-point.x,g.player.global_position.z-point.z).length()>.22 and count<500:
  await physics_frame
  var direction=point-g.player.global_position;direction.y=0
  g.player.velocity=direction.normalized()*3.5;g.player.velocity.y=-3
  g.player.move_and_slide();count+=1
 assert(Vector2(g.player.global_position.x-point.x,g.player.global_position.z-point.z).length()<.3,"Opening route blocked on the way to "+str(point)+" at "+str(g.player.global_position))
 assert(g.player.global_position.y>-.2 and g.player.global_position.y<.6,"Walking route stays at street height")
 return true
func walk(point:Vector3):
 var route=nav.path(g.player.global_position,point)
 assert(not route.is_empty(),"A walkable route exists")
 for waypoint in route:assert(await segment(waypoint))
 assert(await segment(point))
 return true
func run():
 Engine.physics_ticks_per_second=120;Engine.time_scale=4
 g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false);g.falling_tree.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.state="play";g.story.clinic_rescue_done=true;g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true
 for building in ["clinic","ranger","store","workshop"]:g.town.set_building_door(building,true,false,true)
 await physics_frame;await physics_frame
 nav=preload("res://chapel_enemy_paths.gd").new(g.enemies);nav.build(Rect2i(-18,-79,39,42))
 g.player.global_position=Vector3(0,.1,-59)
 for building in ["clinic","ranger","store","workshop"]:
  var room=g.town.buildings[building]
  var door=room.to_global(Vector3(0,0,6.8));door.y=0
  assert(await walk(Vector3(0,0,door.z)));assert(await walk(door))
  g.town.set_building_door(building,true,false,true);await physics_frame;await physics_frame
  assert(await walk(room.to_global(Vector3(0,0,3.3))))
  assert(await walk(door));assert(await walk(Vector3(0,0,door.z)))
 assert(await walk(Vector3(0,0,-51.5)))
 assert(await walk(Vector3(18.3,0,-51.5)));assert(await walk(Vector3(18.3,0,-59)))
 assert(await walk(Vector3(18.3,0,-51.5)));assert(await walk(Vector3(6.8,0,-51.5)));assert(await walk(Vector3(0,0,-51.5)))
 print("PASS: real player capsule walks through pharmacy/ranger/hardware/workshop entrances and the complete enclosed service alley in both directions without jumping")
 quit()
