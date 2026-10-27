extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 g.crash_site.wake_phase="";g.state="play";g.crash_site.has_backpack=true;g.story.clinic_rescue_done=true
 var layout=load("res://editing/hotel_layout.tscn").instantiate()
 var authored=layout.get_node("RoomShell_REFERENCE/house_note")
 var area=g.town.actions.house_note.area
 var source=authored.get_child(0);var collision=area.get_child(0)
 assert(collision is CollisionShape3D and collision.transform.is_equal_approx(source.transform))
 assert(collision.shape is BoxShape3D and collision.shape.size.is_equal_approx(source.shape.size))
 var paper=area.get_node("RealisticPaperNote");var authored_paper=authored.get_node("RealisticPaperNote")
 assert(paper.get_child(0).transform.is_equal_approx(authored_paper.get_child(0).transform),"Paper placement matches the edited collision")
 var center=collision.global_position
 g.player.global_position=center+Vector3(0,0.02,1.4)
 g.camera.global_position=center+Vector3(0,1.25,1.4)
 g.camera.look_at(center)
 await physics_frame;await physics_frame
 g.town.refresh_focus()
 assert(g.town.focus_action=="house_note","A real camera ray targets the moved letter rather than its old location")
 g.town.perform("house_note")
 assert(g.town.inventory.ada_letter==1 and g.town.actions.house_note.taken and not area.visible,"Edited letter remains collectible")
 var snapshot=g.saves.backend.capture();g.saves.backend.apply(snapshot)
 assert(g.town.inventory.ada_letter==1 and g.town.actions.house_note.taken and not area.visible,"Loading does not respawn the letter")
 assert(collision.transform.is_equal_approx(source.transform),"Save/load retains the edited pickup target")
 print("PASS: edited letter visual/collision, real focus ray, collection and save/load")
 layout.free();g.queue_free();await process_frame;quit()
