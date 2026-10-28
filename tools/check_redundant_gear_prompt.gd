extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.story.clinic_rescue_done=true;g.state="play"
 g.hud.message_seconds=10;g.message=g.clinic_rescue.missing_gear_prompt()
 assert(g.hud.instruction_text()=="","Return-to-car objective does not produce a second large reminder")
 g.hud.objectives.update_reminder(0);assert(g.hud.objectives.current.id=="backpack")
 g.crash_site.hatch_open=false;g.town.focus_action="crash_rear_hatch"
 assert(not g.town.prompt().is_empty(),"Hatch retains its contextual interaction prompt")
 g.message="Your backpack is full. The knife needs two slots."
 assert(g.hud.instruction_text()==g.message,"Action failure feedback still appears")
 g.set_state("dialogue");g.dialogue_text="Test conversation";assert(g.dialogue_text=="Test conversation")
 print("PASS: duplicate gear reminder removed, objective retained, contextual car prompt and useful action feedback preserved")
 quit()
