extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.health=100;g.set_state("play")
 var staff=g.hotel_staff;staff.set_physics_process(false)
 await physics_frame
 for x in [-2.45,-1.1625,-.1]:
  g.player.global_position=staff.to_global(Vector3(x,.04,.1));g.player.move_and_collide(staff.global_basis*Vector3(0,0,-3.4))
  assert(staff.to_local(g.player.global_position).z> -1.3,"Wall and locked door completely block the marked opening")
 g.player.global_position=staff.to_global(Vector3(staff.CENTER,.04,.4));g.player.rotation=Vector3.ZERO;g.camera.position=Vector3(0,g.STANDING_EYE,0);g.camera.look_at(g.town.actions.hotel_staff_door.area.global_position);g.camera.make_current();g.town.refresh_focus()
 assert(g.town.focus_action=="hotel_staff_door");g.town.interact();assert(not staff.opened and not staff.unlocked)
 g.player.global_position=staff.to_global(Vector3(staff.CENTER,.04,-2.7));staff.interact();staff._physics_process(1)
 assert(staff.opened and staff.unlocked,"Returning through the existing basement route cannot strand the player")
 var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved));g.saves.backend.apply(saved);assert(staff.opened and staff.unlocked)
 var file=FileAccess.open("C:/Users/jkern/Documents/Codex/2026-10-16/go-x20/work/pre-zombie-save.bin",FileAccess.READ);var old=file.get_var();file.close();assert(g.saves.backend.valid(old))
 print("PASS: solid partition/locked lobby door, actual interaction, staff-side return, state save/load and old save compatibility")
 g.queue_free();await process_frame;quit()
