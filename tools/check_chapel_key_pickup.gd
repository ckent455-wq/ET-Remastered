extends SceneTree
func _initialize():call_deferred("run")
func aim_key(g):
 var area=g.town.actions.cemetery_cellar_key.area
 var bounds=g.surface_details.bounds_of(area.get_child(1))
 g.camera.position=Vector3(0,g.STANDING_EYE,0);g.camera.look_at(bounds.get_center())
 await physics_frame;await physics_frame
 g.town.refresh_focus()
 assert(g.town.focus_action=="cemetery_cellar_key","Aiming at the visible key reaches its actual pickup target")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 g.town.powered=true;g.town.inventory.coil=1;g.town.townspeople.talk("ranger")
 assert(g.town.inventory.mausoleum_key==1,"Pat still hands over the vault key")
 g.set_state("play");g.town.cemetery.interact_door();await create_timer(0.8).timeout
 for point in [Vector3(-1.95,0.02,-0.8),Vector3(-1.45,0.02,-1.1),Vector3(-2.25,0.02,-0.7)]:
  g.player.global_position=g.hotel_basement.to_global(point)
  await aim_key(g)
 g.town.interact()
 assert(g.town.inventory.chapel_key==1 and g.town.actions.cemetery_cellar_key.taken and not g.town.actions.cemetery_cellar_key.area.visible,"Real aimed interaction collects the key")
 g.town.perform("cemetery_cellar_key");assert(g.town.inventory.chapel_key==1,"Key cannot duplicate")
 g.town.perform("cellar_door");assert(g.town.streetscape.church.basement.unlocked,"Collected key unlocks the chapel basement")
 # Simulate a pre-fix save restoring the old misplaced target.
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play";g.town.cemetery.unlocked=true;g.town.cemetery.opened=true
 g.player.global_position=g.hotel_basement.to_global(Vector3(-1.95,0.02,-0.8))
 g.town.actions.cemetery_cellar_key.area.position=Vector3(-0.25,1.03,-1.25)
 var collision=g.town.actions.cemetery_cellar_key.area.get_child(0)
 collision.position=Vector3.ZERO;collision.shape.size=Vector3(0.35,0.25,0.35)
 g.saves.backend.directory="user://chapel-key-check-"+str(Time.get_ticks_usec());assert(g.saves.backend.save_slot(1))
 assert(g.saves.backend.load_slot(1))
 await aim_key(g)
 g.town.interact();assert(g.town.inventory.chapel_key==1,"Loading an older target layout repairs pickup without restarting the journey")
 var file=ProjectSettings.globalize_path(g.saves.backend.path(1));DirAccess.remove_absolute(file);DirAccess.remove_absolute(ProjectSettings.globalize_path(g.saves.backend.directory))
 print("PASS: visible key aiming from three positions, pickup, no duplication, chapel unlock, Pat handoff and existing-save target repair")
 g.queue_free();await process_frame;quit()
