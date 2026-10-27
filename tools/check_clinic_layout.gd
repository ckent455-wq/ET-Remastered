extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 var layout=load("res://editing/clinic_layout.tscn").instantiate()
 var items=layout.get_node("Furniture")
 assert(items.get_child_count()>8 and g.clinic_layout.applied_count==items.get_child_count())
 assert(g.clinic_layout.reference.count>20,"Saved clinic architecture is connected")
 var reference=g.clinic_layout.reference
 var shell=layout.get_node("RoomShell_REFERENCE")
 var candidate=-1
 for i in range(reference.targets.size()):
  var node=reference.targets[i]
  if node.get_script()==null and not node is Area3D and node!=g.town.doors.clinic.hinge and node.find_children("*","Area3D",true,false).is_empty():candidate=i;break
 assert(candidate>=0)
 var edited_shell=shell.get_child(candidate);var shell_before=edited_shell.transform
 edited_shell.position.x+=0.03;g.clinic_layout.apply_layout(layout)
 assert(reference.targets[candidate].transform.is_equal_approx(shell.transform*edited_shell.transform),"Edited reference transforms reach gameplay")
 edited_shell.transform=shell_before;g.clinic_layout.apply_layout(layout)
 var cabinet=null
 for entry in items.get_children():
  if entry.get_meta("runtime_asset")=="clinic_cabinet":cabinet=entry;break
 assert(cabinet!=null)
 var actual=g.town.interiors.containers.clinic_cabinet.root
 var area=g.town.interiors.containers.clinic_cabinet.area
 var before=actual.transform;var local_area=actual.global_transform.affine_inverse()*area.global_transform
 var shop_table=g.workshop_layout.added_furniture.extra_table_01.global_transform
 cabinet.position.x+=0.4;cabinet.rotation.y+=0.2
 g.clinic_layout.apply_layout(layout)
 assert(actual.transform.is_equal_approx(cabinet.transform))
 assert((actual.global_transform.affine_inverse()*area.global_transform).is_equal_approx(local_area),"Clinic storage interaction follows the cabinet")
 assert(g.workshop_layout.added_furniture.extra_table_01.global_transform==shop_table,"Clinic editing does not move workshop furniture")
 cabinet.transform=before;g.clinic_layout.apply_layout(layout)
 var bed=items.get_node("Patient_Bed");var original_bed=bed.transform
 bed.position.x+=0.6;bed.rotation.y+=0.2;g.clinic_layout.apply_layout(layout)
 g.clinic_rescue.place_in_bed()
 assert(g.player.global_position.is_equal_approx(g.clinic_layout.rescue_points.Wake),"Wake position follows the edited patient bed")
 assert(g.town.townspeople.characters.nurse.actor.global_position.is_equal_approx(g.clinic_layout.rescue_points.NurseStand))
 g.clinic_rescue.phase="bed";g.clinic_rescue.leave_bed()
 assert(g.player.global_position.is_equal_approx(g.clinic_layout.rescue_points.BedExit),"Bed exit follows the edited patient bed")
 bed.transform=original_bed;g.clinic_layout.apply_layout(layout)
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved));g.saves.backend.apply(saved)
 assert(actual.transform.is_equal_approx(before))
 print("PASS: ",items.get_child_count()," clinic furniture roots, collision/interaction hierarchy, workshop independence and save/load")
 layout.free();g.queue_free();await process_frame;quit()
