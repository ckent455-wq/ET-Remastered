extends SceneTree
var g
func _initialize():call_deferred("run")
func walk(local:Vector3):
 var goal=g.hotel_upper.to_global(local)
 for i in 180:
  await physics_frame
  var direction=goal-g.player.global_position;direction.y=0
  if direction.length()<.12:return
  g.player.velocity=direction.normalized()*3.8+Vector3.DOWN*2;g.player.move_and_slide()
 assert(false,"Hotel walking route blocked at "+str(g.hotel_upper.to_local(g.player.global_position))+" going to "+str(local))
func step_lift(seconds:float):
 for i in int(seconds*60):
  g.hotel_upper._physics_process(1.0/60.0)
  if i%15==0:await physics_frame
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.set_process_input(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 var lift=g.hotel_upper;lift.set_physics_process(false)
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.story.clinic_rescue_done=true;g.story.crash_wound_treated=true;g.town.reached_town=true;g.health=100;g.set_state("play")
 assert(g.town.buildings.house.get_node("Apartment_bed7").position.y>lift.UPPER)
 assert(g.town.actions.hotel_basement_door.area.global_position.distance_to(g.town.buildings.house.to_global(Vector3(-.4,1.20,-4.40)))<.5)
 g.player.global_position=lift.to_global(Vector3(-2.0,.04,-.9))
 assert(lift.door_amount==0 and not lift.landing_doors[0][0].get_child(1).disabled,"Elevator starts closed")
 lift.interact("hotel_lift_call",{"floor":0});await step_lift(1.2)
 await walk(Vector3(-2.2,.04,-1.25));await walk(Vector3(-4.3,.04,-1.25));await walk(lift.LIFT_ORIGIN+Vector3(0,.04,0))
 assert(lift.inside_cab())
 g.player.rotation=Vector3.ZERO;g.camera.position=Vector3(0,g.STANDING_EYE,0)
 g.camera.look_at(g.town.actions.hotel_lift_controls.area.global_position);g.camera.make_current();g.town.refresh_focus()
 assert(g.town.focus_action=="hotel_lift_controls","E/controller interaction reaches the real cab controls")
 assert(g.town.actions.shotgun_key.area.position.y>lift.UPPER,"Dresser key moves with the bedroom furniture")
 lift.interact("hotel_lift_controls",{});assert(lift.rider and lift.phase=="closing")
 assert("elevator" in g.saves.backend.blocked_reason())
 await step_lift(2);g.set_state("paused");var paused_y=lift.cab.position.y;await step_lift(1);assert(lift.cab.position.y==paused_y);g.set_state("play")
 await step_lift(5)
 assert(lift.floor_index==1 and not lift.busy() and not lift.rider)
 assert(absf(g.player.global_position.y-lift.UPPER)<.08,"Player rides continuously with the physical cab")
 await walk(Vector3(-4.3,lift.UPPER,-1.15));await walk(Vector3(-3.35,lift.UPPER,-1.15))
 lift.interact("hotel_room_door",{"room_index":0});await step_lift(1)
 await walk(Vector3(-3.35,lift.UPPER,.05));await walk(Vector3(-3.35,lift.UPPER,-1.15));await walk(Vector3(0,lift.UPPER,-1.15))
 await walk(Vector3(0,lift.UPPER,2.55));lift.interact("hotel_room_door",{"room_index":1});await step_lift(1);await walk(Vector3(2.0,lift.UPPER,2.55));await walk(Vector3(0,lift.UPPER,2.55))
 await walk(Vector3(0,lift.UPPER,-2.55));lift.interact("hotel_room_door",{"room_index":2});await step_lift(1);await walk(Vector3(2.0,lift.UPPER,-2.55));await walk(Vector3(0,lift.UPPER,-2.55))
 assert(g.town.location_name()=="SAINT GEORGE / SECOND FLOOR")
 var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved));g.saves.backend.apply(saved)
 assert(lift.floor_index==1 and lift.room_open==[true,true,true]);assert(lift.contains(g.player.global_position))
 await walk(Vector3(0,lift.UPPER,-1.15));await walk(Vector3(-4.3,lift.UPPER,-1.15));lift.interact("hotel_lift_call",{"floor":1});await step_lift(1.2);await walk(lift.LIFT_ORIGIN+Vector3(0,lift.UPPER,0))
 lift.interact("hotel_lift_controls",{});await step_lift(7)
 assert(lift.floor_index==0 and absf(g.player.global_position.y-.02)<.08)
 await walk(Vector3(-4.3,.02,-1.15));await walk(Vector3(-1.1,.02,-1.15));await walk(Vector3(-.4,.02,-3.5))
 # Empty-car calls close the unserved landing; no exposed shaft.
 lift.begin_trip(1,false);await step_lift(7);assert(lift.floor_index==1 and not lift.landing_doors[0][0].get_child(1).disabled)
 lift.interact("hotel_lift_call",{"floor":0});await step_lift(7);assert(lift.floor_index==0)
 var file=FileAccess.open("C:/Users/jkern/Documents/Codex/2026-10-16/go-x20/work/pre-zombie-save.bin",FileAccess.READ);var old=file.get_var();file.close()
 assert(g.saves.backend.valid(old));g.saves.backend.apply(old);assert(lift.floor_index==0)
 print("PASS: hotel elevator both directions, continuous player ride, pause, call buttons, shaft doors, all guest rooms on foot, basement route, bedroom relocation and new/old save compatibility")
 quit()
