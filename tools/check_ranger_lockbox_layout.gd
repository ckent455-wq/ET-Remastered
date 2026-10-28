extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false);g.controller.set_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 var scene=load("res://editing/ranger_layout.tscn").instantiate();root.add_child(scene);scene.global_transform=g.town.buildings.ranger.global_transform
 var edited=scene.get_node("RoomShell_REFERENCE/RangerShotgunLockbox")
 var box=g.weapons.lockbox
 var a=g.surface_details.bounds_of(edited.get_node("body"));var b=g.surface_details.bounds_of(box.get_node("body"))
 assert(a.position.is_equal_approx(b.position) and a.size.is_equal_approx(b.size),"Gameplay case matches your moved crate mesh")
 assert(g.surface_details.bounds_of(box.hinge).position.is_equal_approx(g.surface_details.bounds_of(edited.get_child(2)).position),"Lid follows the same crate placement")
 var shape=box.get_child(1).get_child(1)
 assert(shape.global_position.distance_to(box.global_position+Vector3.UP*.28)<.01,"Physical collision follows the case")
 assert(box.pickup.global_position.distance_to(box.global_position+Vector3.UP*.75)<.01,"Shotgun stays inside the moved case")
 g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.state="play"
 g.town.inventory.shotgun_key=1;box.interact();box._process(1)
 assert(box.unlocked and box.can_take() and box.pickup.visible and box.pickup.collision_layer==2)
 var position=box.global_transform;var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved));g.saves.backend.apply(saved)
 assert(box.global_transform.is_equal_approx(position) and box.unlocked and box.opened,"Save/load retains placement and working lock/lid")
 box._process(1);g.town.perform("weapon_shotgun")
 assert(g.weapons.owned[2] and g.town.actions.weapon_shotgun.taken,"Shotgun can be collected from the moved case")
 print("PASS: editor-aligned crate/lid, collision, shotgun placement, key unlock, lid animation, save/load and collection")
 scene.free();g.queue_free();await process_frame;quit()
