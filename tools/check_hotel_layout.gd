extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 var layout=load("res://editing/hotel_layout.tscn").instantiate()
 var items=layout.get_node("Furniture")
 assert(items.get_child_count()>8 and g.hotel_layout.applied_count==items.get_child_count())
 var cabinet=null
 for entry in items.get_children():
  if entry.get_meta("runtime_asset")=="house_drawer":cabinet=entry;break
 assert(cabinet!=null)
 var actual=g.town.interiors.containers.house_drawer.root
 var area=g.town.interiors.containers.house_drawer.area
 var before=actual.transform;var local_area=actual.global_transform.affine_inverse()*area.global_transform
 var shop_table=g.workshop_layout.added_furniture.extra_table_01.global_transform
 cabinet.position.x+=0.4;cabinet.rotation.y+=0.2
 g.hotel_layout.apply_layout(layout)
 var expected=cabinet.transform;expected.origin+=Vector3(0,g.hotel_upper.UPPER,5.3)
 assert(actual.transform.is_equal_approx(expected))
 assert((actual.global_transform.affine_inverse()*area.global_transform).is_equal_approx(local_area),"Hotel storage interaction follows the cabinet")
 assert(g.workshop_layout.added_furniture.extra_table_01.global_transform==shop_table,"Hotel editing does not move workshop furniture")
 cabinet.transform=before;g.hotel_layout.apply_layout(layout)
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved));g.saves.backend.apply(saved)
 assert(actual.transform.is_equal_approx(before))
 print("PASS: ",items.get_child_count()," hotel furniture roots, collision/interaction hierarchy, workshop independence and save/load")
 layout.free();g.queue_free();await process_frame;quit()

