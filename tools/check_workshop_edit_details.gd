extends SceneTree
func _initialize():call_deferred("run")
func compare(edited,actual):
 if edited is Node3D:assert(edited.transform.is_equal_approx(actual.transform),"Edited workshop child transform reaches the game")
 for i in edited.get_child_count():compare(edited.get_child(i),actual.get_child(i))
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 var scene=load("res://editing/workshop_layout.tscn").instantiate()
 var shell=scene.get_node("RoomShell_REFERENCE");var helper=g.workshop_layout.reference
 assert(helper.count>0)
 var checked=0
 for name in ["_Node3D_4619","_StaticBody3D_4741","_StaticBody3D_4744","_StaticBody3D_4747"]:
  var edited=shell.get_node(name);compare(edited,helper.targets[edited.get_index()]);checked+=1
 var note=shell.get_node("workshop_record");var actual=g.town.actions.workshop_record.area
 compare(note,actual)
 g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 var saved=g.saves.backend.capture();g.saves.backend.apply(saved);compare(note,actual)
 print("PASS: ",checked," edited shell/collision roots and the complete workshop note geometry/collider, including save/load")
 scene.free();g.queue_free();await process_frame;quit()
