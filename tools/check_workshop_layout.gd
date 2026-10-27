extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 var layout=load("res://editing/workshop_layout.tscn").instantiate()
 var items=layout.get_node("Furniture")
 assert(items.get_child_count()>8 and g.workshop_layout.applied_count==items.get_child_count())
 var extra=items.get_node("New_Table_Position_Me")
 assert(g.workshop_layout.added_furniture.size()==1)
 var runtime_extra=g.workshop_layout.added_furniture.extra_table_01
 var original_extra=extra.transform
 extra.position.z+=0.7;g.workshop_layout.apply_layout(layout)
 assert(runtime_extra.global_transform.is_equal_approx(g.town.buildings.workshop.global_transform*items.transform*extra.transform),"Added table uses the editor placement")
 assert(runtime_extra.find_children("*","CollisionShape3D",true,false).size()>0)
 g.workshop_layout.apply_layout(layout);assert(g.workshop_layout.added_furniture.size()==1,"Reloading layouts cannot duplicate the added table")
 extra.transform=original_extra;g.workshop_layout.apply_layout(layout)
 var cabinet=null
 for entry in items.get_children():
  if entry.get_meta("runtime_asset")=="workshop_cabinet":cabinet=entry;break
 assert(cabinet!=null)
 var actual=g.town.interiors.containers.workshop_cabinet.root
 var area=g.town.interiors.containers.workshop_cabinet.area
 var before=actual.transform;var local_area=actual.global_transform.affine_inverse()*area.global_transform
 cabinet.position.x+=0.5;cabinet.rotation.y+=0.25
 g.workshop_layout.apply_layout(layout)
 assert(actual.transform.is_equal_approx(cabinet.transform),"Editor cabinet transform reaches the live room")
 assert((actual.global_transform.affine_inverse()*area.global_transform).is_equal_approx(local_area),"Interaction area moves and rotates with its cabinet")
 assert(actual.find_children("*","CollisionShape3D",true,false).size()>0,"Furniture retains gameplay collision")
 cabinet.transform=before;g.workshop_layout.apply_layout(layout)
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved));g.saves.backend.apply(saved)
 assert(actual.transform.is_equal_approx(before),"Save/load preserves editable layout and storage hierarchy")
 print("PASS: ",items.get_child_count()," editable workshop roots, cabinet transform, collision/interaction attachment and save/load")
 layout.free();g.queue_free();await process_frame;quit()
