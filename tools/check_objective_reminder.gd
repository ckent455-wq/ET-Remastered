extends SceneTree
func _initialize():call_deferred("run")
func settle(r):
 r.update_reminder(2);r.update_reminder(.2);r.update_reminder(0)
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 var r=g.hud.objectives;r.set_process(false)
 g.reset_game();g.crash_site.start_opening();r.update_reminder(0)
 assert(not r.visible and r.current.id=="leave_car")
 g.crash_site.leave_seat_for_testing();g.crash_site.wake_phase="";g.state="play";r.update_reminder(0)
 assert(r.visible and r.completed and r.current.id=="leave_car","Leaving the car checks off the existing objective")
 var remaining=r.remaining;g.state="paused";r.update_reminder(20);assert(not r.visible and r.remaining==remaining)
 g.state="play";settle(r);assert(not r.completed and r.current.id=="find_help")
 g.clinic_rescue.place_in_bed();g.clinic_rescue.begin_explanation();r.update_reminder(0)
 assert(not r.visible and r.completed and r.current.id=="find_help","Medical rescue completes finding help without showing HUD over dialogue")
 g.set_state("play");settle(r);assert(r.current.id=="backpack")
 g.crash_site.hatch_open=true;g.crash_site.interact_tutorial("crash_backpack");r.update_reminder(0)
 assert(r.completed and r.current.id=="backpack")
 r.update_reminder(2);assert(not r.visible and r.current.is_empty(),"Checked objective disappears")
 r.update_reminder(.2);r.update_reminder(0);assert(r.visible and r.current.id=="flashlight" and not r.completed)
 g.town.reached_town=true;g.crash_site.interact_tutorial("crash_flashlight");r.update_reminder(0);settle(r)
 g.town.reached_town=true;r.update_reminder(0);assert(r.current.id=="john")
 # Finding the fuse skips an introduction but must never check off a conversation that did not happen.
 g.town.perform("store_drawer");r.update_reminder(0)
 assert(not r.completed and r.current.id=="install_fuse")
 var panel=g.town.actions.battery_panel.area.get_node("HighVoltageTerminal")
 panel.opened=true;panel.phase="open";panel.interact();r.update_reminder(0)
 assert(r.completed and r.current.id=="install_fuse");settle(r);assert(r.current.id=="switch")
 var saved=g.saves.backend.capture();g.saves.backend.apply(saved)
 assert(r.current.is_empty() and not r.completed,"Loading does not replay old objective checks")
 r.update_reminder(0);assert(r.current.id=="switch")
 for label in ["Find the fuse in the general store's counter drawer.","Take the station key from Pat's desk drawer.","Find the cellar key at the tunnel's far end.","Take the signal coil from the workshop cabinet."]:
  assert(r.lines(label).size()<=2,"Reminder fits above the health display")
 g.testing_mode.enabled=true;r.update_reminder(0);assert(not r.visible and r.current.is_empty());g.testing_mode.enabled=false
 g.reset_game();assert(r.current.is_empty() and not r.completed)
 print("PASS: quest-driven reminders, completion check/hold/disappearance, next task, paused timers, dialogue/menu hiding, skipped-task accuracy, compact wrapping, save/load and reset")
 quit()
