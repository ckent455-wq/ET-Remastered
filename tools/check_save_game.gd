extends SceneTree
func _initialize():call_deferred("run")
func setup():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 return g
func run():
 var g=setup();await process_frame;await physics_frame
 while not g.surface_details.completed:await process_frame
 var store=g.saves.backend
 store.directory="user://save-check-"+str(Time.get_ticks_usec())
 g.reset_game();g.crash_site.wake_phase="";g.state="play"
 assert(not store.save_slot(1) and "backpack" in store.error,"Opening cannot be saved half seated")
 g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.crash_site.hatch_open=true;g.crash_site.hatch.rotation.x=g.crash_site.hatch_closed.x-g.crash_site.HATCH_OPEN_ANGLE
 g.crash_site.bag_visual.hide();g.crash_site.light_visual.hide()
 g.health=47;g.flashlight_charge=23;g.flashlight.visible=true
 g.town.inventory.ada_letter=1;g.story.ada_letter_requested=true;g.story.ada_letter_delivered=false
 g.story.evidence.clinic_note=true;g.story.county_bypass=true;g.story.repeater.shutdown_done=true
 g.town.inventory.bandage=2;g.town.powered=true;g.town.radio_ready=true
 var panel=store.roots().panel;panel.installed=true;panel.energized=true;panel.opened=true;panel.phase="on"
 g.town.actions.weapon_pistol.taken=true;g.town.actions.weapon_pistol.area.hide();g.town.actions.weapon_pistol.area.collision_layer=0
 g.weapons.owned.assign([true,true,false]);g.weapons.magazines.assign([3,4,0]);g.weapons.reserves.assign([8,9,0]);g.weapons.equip(1)
 g.town.interiors.containers.clinic_drawer.searched=true;g.town.interiors.containers.clinic_drawer.remaining_extras.bandage=0
 g.town.journal_entries.append({"id":"save_test","title":"Saved note","text":"A readable journal entry."})
 g.town.townspeople.conversation.greetings.nurse=true;g.town.townspeople.conversation.asked.aubrey_signal=true
 g.town.townspeople.grave_key_given=true;g.town.cemetery.unlocked=true
 g.town.streetscape.church.basement.unlocked=true
 g.hotel_basement.hotel_unlocked=true
 g.enemies.workshop_spawned=true;g.enemies.workshop_defeated=true;g.enemies.creatures[3].state="dead";g.enemies.creatures[3].hp=0
 g.enemies.creatures[0].hp=24;g.enemies.creatures[0].state="dead";g.enemies.creatures[0].respawn_remaining=38
 g.enemies.creatures[4].state="dead";g.enemies.creatures[4].hp=0
 g.town.townspeople.shoot("ranger");g.town.sign_crow.dead=true;g.town.sign_crow.hit_shape.set_deferred("disabled",true)
 g.grave_dig.dug=true;g.grave_dig.exposed.show();g.grave_dig.mound.hide();g.grave_dig.cover_collision.set_deferred("disabled",true)
 g.falling_tree.triggered=true;g.falling_tree.landed=true;g.falling_tree.reaction_shown=true;g.falling_tree.tree.rotation.z=-PI/2;g.falling_tree.elapsed=5
 g.enemies.creatures[6].state="dead";g.enemies.creatures[6].actor.hide()
 var position=g.hotel_basement.to_global(Vector3(0,0.03,0));g.player.global_position=position;g.pitch=0.23
 await physics_frame
 var original=g.player.global_transform
 g.set_state("paused");g.saves.open()
 assert(g.saves.opened() and g.saves.heading.text=="SAVE / LOAD JOURNEY")
 assert(store.save_slot(1),store.error)
 var saved=store.read_slot(1)
 assert(not saved.is_empty() and saved.health==47 and saved.location.contains("CELLAR"),"Slot metadata reflects the saved underground room")
 var folder=store.directory
 g.saves.close();g.reset_game();g.state="title"
 assert(store.load_slot(1),store.error)
 await physics_frame
 assert(g.state=="play" and g.player.global_transform.is_equal_approx(original) and g.health==47 and g.flashlight_charge==23,"Health and underground position round trip")
 assert(g.weapons.selected==1 and g.weapons.owned==[true,true,false] and g.weapons.magazines==[3,4,0] and g.weapons.reserves==[8,9,0],"Weapons and ammunition persist")
 assert(g.crash_site.has_backpack and g.crash_site.has_flashlight and g.town.inventory.ada_letter==1 and g.town.inventory.bandage==2,"Gear and quest items persist")
 assert(g.story.repeater_is_off() and not g.story.repeater.hum.playing and g.story.county_bypass and g.town.radio_ready,"Radio repair and silent repeater persist")
 assert(g.town.townspeople.characters.ranger.dead and g.town.sign_crow.dead and g.grave_dig.dug and g.falling_tree.reaction_shown,"Dead NPC/crow, uncovered grave and completed scare remain resolved")
 assert(g.story.evidence.has("clinic_note") and g.town.journal_entries.any(func(e):return e.id=="save_test"),"Journal and evidence persist")
 assert(g.town.interiors.containers.clinic_drawer.searched and g.town.interiors.containers.clinic_drawer.remaining_extras.bandage==0,"Searched loot cannot be duplicated")
 assert(g.town.actions.weapon_pistol.taken and not g.town.actions.weapon_pistol.area.visible,"Collected world pickup stays gone")
 assert(g.enemies.creatures[0].state=="dead" and g.enemies.creatures[0].respawn_remaining==38 and g.enemies.creatures[4].state=="dead","Dead enemies and revival timers persist")
 assert(g.town.cemetery.unlocked and g.hotel_basement.hotel_unlocked and g.town.streetscape.church.basement.unlocked,"Quest locks persist")
 assert(g.town.townspeople.conversation.greetings.has("nurse") and g.town.townspeople.grave_key_given,"NPC conversation and key handoff history persist")
 g.set_state("paused");g.saves.open();g.saves.save_selected()
 assert(g.saves.confirmation=="save" and store.read_slot(1).health==47,"Overwrite requires a second press")
 g.health=63;g.saves.save_selected();assert(store.read_slot(1).health==63,"Confirmed overwrite succeeds")
 var broken=FileAccess.open(store.path(1),FileAccess.WRITE);broken.store_string("bad save");broken.close()
 assert(store.read_slot(1).get("recovered",false) and store.read_slot(1).health==47,"Damaged primary recovers verified previous save")
 g.saves.slot_buttons[1].pressed.emit();assert(g.saves.selected==2,"Slot buttons select their own independent slot")
 g.saves.save_selected();assert(store.read_slot(2).health==63 and store.read_slot(1).health==47,"Different slots remain independent")
 g.saves.slot_buttons[0].pressed.emit();g.saves.load_selected();assert(g.saves.confirmation=="load" and g.health==63,"Loading over a paused journey requires confirmation")
 g.saves.close();assert(g.health==63 and g.state=="paused","Cancelling a load preserves the current journey")
 var before=g.health;assert(not store.load_slot(3) and g.health==before,"Empty or corrupt load never destroys current journey")
 g.saves.close();g.set_state("play");g.testing_mode.begin();assert(not store.save_slot(2) and "testing mode" in store.error,"Testing equipment cannot contaminate normal saves");g.testing_mode.finish()
 # A second newly instantiated world catches unstable generated node paths and reconstruction errors.
 g.queue_free();await process_frame
 var fresh=setup();await process_frame;await physics_frame
 while not fresh.surface_details.completed:await process_frame
 fresh.saves.backend.directory=folder
 assert(fresh.saves.backend.load_slot(1),fresh.saves.backend.error)
 await physics_frame
 assert(fresh.health==47 and fresh.player.global_position.is_equal_approx(position) and fresh.weapons.selected==1 and fresh.story.repeater_is_off(),"Save loads in a fresh scene instance")
 fresh.set_state("title");fresh.saves.open(true);fresh.hud._process(0)
 assert(fresh.saves.save_button.visible==false and fresh.hud.menu_buttons.all(func(b):return not b.visible),"Title offers a modal load screen")
 fresh.controller.activate(0);fresh.saves.back_button.grab_focus();fresh.controller.button(JOY_BUTTON_B)
 assert(not fresh.saves.opened() and fresh.state=="title","Controller back closes the modal without starting gameplay")
 fresh.set_state("lost");fresh.saves._process(0);assert(fresh.saves.death_load.visible)
 fresh.controller.button(JOY_BUTTON_Y);assert(fresh.saves.opened() and fresh.saves.load_only,"Controller opens saved journeys from death")
 fresh.saves.close();fresh.controller.button(JOY_BUTTON_B);assert(fresh.state=="title","Death back returns to title rather than reviving a dead player")
 for i in range(1,4):
  for suffix in ["",".bak",".tmp"]:
   var file=ProjectSettings.globalize_path(folder+"/slot_%d.sav" % i+suffix)
   if FileAccess.file_exists(file):DirAccess.remove_absolute(file)
 DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))
 print("PASS: save UI, world/quest/equipment/underground round trip, fresh scene load, overwrite, backup recovery, invalid-load protection, test-mode guard, title/controller modal")
 fresh.queue_free();await process_frame;quit()
