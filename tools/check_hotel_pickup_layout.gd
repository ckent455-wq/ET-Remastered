extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.story.clinic_rescue_done=true;g.state="play"
 var layout=load("res://editing/hotel_layout.tscn").instantiate();root.add_child(layout)
 layout.global_transform=g.town.buildings.house.global_transform
 var shell=layout.get_node("RoomShell_REFERENCE")
 for id in ["ammo_pistol_house","ammo_shotgun_house","house_note"]:
  var edited=shell.get_node(id);var actual=g.town.actions[id].area
  var a=g.surface_details.bounds_of(edited);var b=g.surface_details.bounds_of(actual)
  assert(a.position.is_equal_approx(b.position) and a.size.is_equal_approx(b.size),"Gameplay visible bounds match the editor: "+id)
  assert(actual.get_child(0).transform.is_equal_approx(edited.get_child(0).transform),"Pickup collision matches the saved editor")
 var ammo=g.town.actions.ammo_pistol_house.area
 var collider=ammo.get_child(0)
 var center=collider.global_position
 g.player.global_position=center+Vector3(0,0.02,1.0)
 g.camera.global_position=center+Vector3(0,1.2,1.0);g.camera.look_at(center)
 await physics_frame;await physics_frame
 g.town.refresh_focus();assert(g.town.focus_action=="ammo_pistol_house","Moved ammo is actually targetable")
 var before=g.weapons.reserves[0]
 g.town.perform("ammo_pistol_house")
 assert(g.weapons.reserves[0]>before and g.town.actions.ammo_pistol_house.taken)
 var saved=g.saves.backend.capture();g.saves.backend.apply(saved)
 assert(g.town.actions.ammo_pistol_house.taken and not ammo.visible,"Layout restore cannot respawn collected ammunition")
 print("PASS: exact editor/game pickup bounds, collision, real aiming, collection and save/load")
 layout.free();g.queue_free();await process_frame;quit()
