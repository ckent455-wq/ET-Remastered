extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.grave_dig.set_process(false);g.cemetery_shadow.set_physics_process(false)
 g.town.townspeople.set_physics_process(false)
 g.crash_site.wake_phase="";g.state="play";g.crash_site.has_backpack=true
 await create_timer(0.1).timeout
 assert(g.grave_dig.shovel.get_parent()==g.victorian_house.cellar,"Shovel spawns in Victorian basement")
 g.player.global_position=g.victorian_house.cellar.to_global(Vector3(-1.7,0.01,1.4))
 g.camera.position=Vector3(0,g.STANDING_EYE,0)
 g.camera.look_at(g.grave_dig.shovel.global_position)
 await physics_frame
 await physics_frame
 g.town.refresh_focus()
 assert(g.town.focus_action=="workshop_shovel","Shovel is reachable by interaction ray")
 g.controller.activate(0);g.controller.set_process(false);g.controller.button(JOY_BUTTON_X)
 assert(g.town.inventory.shovel==1)
 g.player.global_position=g.grave_dig.GRAVE+Vector3(0,0.01,2.4)
 g.camera.position=Vector3(0,g.STANDING_EYE,0)
 g.camera.look_at(g.grave_dig.grave.global_position)
 await physics_frame
 await physics_frame
 g.town.refresh_focus()
 assert(g.town.focus_action=="cemetery_disturbed_grave","Only disturbed soil has a dig interaction")
 var e=InputEventJoypadButton.new();e.device=0;e.button_index=JOY_BUTTON_X;e.pressed=true
 g.controller._input(e)
 assert(g.grave_dig.digging and g.controller.interact_held())
 g.grave_dig._process(0.3)
 assert(g.grave_dig.elapsed>0)
 g.controller.family="xbox";assert("Hold X" in g.controller.hint(g.grave_dig.prompt()))
 g.controller.family="playstation";assert("Hold SQUARE" in g.controller.hint(g.grave_dig.prompt()))
 e.pressed=false;g.controller._input(e);g.grave_dig._process(0.1)
 assert(not g.grave_dig.digging)
 print("PASS: Victorian basement and grave raycast access, controller pickup/hold/release digging, Xbox/PlayStation prompts")
 quit()
