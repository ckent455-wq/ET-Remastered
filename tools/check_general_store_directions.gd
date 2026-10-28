extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.story.clinic_rescue_done=true;g.town.reached_town=true;g.state="play"
 var t=g.town;t.townspeople.conversation.greetings.mechanic=true;t.inventory.station_key=1
 assert("general store" in t.townspeople.words("mechanic") and not "Sebus" in t.townspeople.words("mechanic"))
 assert("general store" in t.objective() and "general store" in g.hud.objectives.goal().title)
 assert(t.BUILDINGS.filter(func(e):return e.id=="store")[0].label=="GENERAL STORE")
 t.journal_entries.append({"id":"workshop_plan","title":"John / A way to call for help","text":"A replacement workshop fuse is in the counter drawer inside Sebus Hardware."})
 var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved));g.saves.backend.apply(saved)
 assert(t.journal_entries.any(func(e):return e.id=="workshop_plan" and "inside the general store" in e.text and not "Sebus" in e.text),"Existing saved journal plan receives corrected directions")
 t.perform("store_drawer");assert(t.inventory.workshop_fuse==1,"Fuse remains in the usable general store")
 print("PASS: John dialogue, objective, reminder, store label, saved journal migration and actual general-store fuse pickup")
 quit()
