extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 var people=g.town.townspeople;var c=people.conversation;var letter=g.town.actions.house_note
 people.talk("mechanic")
 while not c.choosing:g.advance_dialogue()
 c.choose(1)
 assert(g.story.ada_letter_requested and not g.story.ada_letter_delivered,"John starts the optional letter quest")
 g.set_state("play");g.town.inventory.medkit=12
 assert(not g.backpack.room_for("ada_letter"))
 g.town.perform("house_note")
 assert(not letter.taken and letter.area.visible and g.town.inventory.ada_letter==0,"A full bag leaves the letter in the hotel")
 g.town.inventory.medkit=0;g.town.perform("house_note")
 assert(letter.taken and not letter.area.visible and letter.area.collision_layer==0 and g.town.inventory.ada_letter==1,"Picking up the letter removes its physical world copy")
 assert(g.story.evidence.has("house_note") and g.town.journal_entries.any(func(e):return e.id=="house_note"),"Letter remains readable evidence")
 assert(g.backpack.pack(g.backpack.counts()).any(func(e):return e.id=="ada_letter" and e.size==Vector2i.ONE),"Letter occupies one inventory cell")
 g.set_state("play");g.town.perform("house_note");assert(g.town.inventory.ada_letter==1,"No duplicate letter")
 people.talk("nurse");assert(not g.story.ada_letter_delivered and g.town.inventory.ada_letter==1,"Only John receives Ada's letter")
 g.set_state("play");people.talk("mechanic")
 assert(g.story.ada_letter_delivered and g.town.inventory.ada_letter==0 and "handwriting" in g.dialogue_text,"John takes and reacts to the letter")
 assert(g.weapons.reserves[0]==12 and g.story.ada_ammo_pending==0,"John rewards twelve pistol rounds")
 assert(c.speaker=="mechanic" and c.active and not c.choosing,"Handoff dialogue precedes John's normal menu")
 assert(g.town.journal_entries.any(func(e):return e.id=="ada_letter_quest" and e.text.begins_with("COMPLETED")),"Journal records completion")
 assert(g.town.journal_entries.any(func(e):return e.id=="house_note"),"Giving the letter keeps its transcript")
 assert(not g.story.deliver_ada_letter() and g.weapons.reserves[0]==12,"Delivery and ammo reward complete only once")
 while not c.choosing:g.advance_dialogue()
 c.choose(1);assert("in my coat" in g.dialogue_text,"Later Ada answers remember the handoff")
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 assert(not g.story.ada_letter_delivered and not g.story.ada_letter_requested and g.town.inventory.ada_letter==0 and letter.area.visible and not letter.taken,"New journey restores the quest and letter")
 g.town.perform("house_note");g.set_state("play");people.talk("mechanic")
 assert(g.story.ada_letter_delivered,"Finding the letter before accepting the quest also works")
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 g.town.perform("house_note");g.set_state("play");g.weapons.reserves[0]=g.weapons.LOADOUT[0].max_reserve
 people.talk("mechanic")
 assert(g.story.ada_letter_delivered and g.story.ada_ammo_pending==12,"Full ammo reserves never lose the reward or block letter delivery")
 g.set_state("play");g.weapons.reserves[0]-=5;people.talk("mechanic")
 assert(g.story.ada_ammo_pending==7 and g.weapons.reserves[0]==g.weapons.LOADOUT[0].max_reserve,"Partial reward leaves only unclaimed rounds with John")
 g.set_state("play");g.weapons.reserves[0]-=7;people.talk("mechanic")
 assert(g.story.ada_ammo_pending==0 and g.weapons.reserves[0]==g.weapons.LOADOUT[0].max_reserve,"Remaining reward can be collected later")
 g.set_state("play");people.talk("mechanic");assert(g.story.ada_ammo_pending==0 and c.choosing,"Completed reward cannot be farmed")
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 g.town.perform("house_note");g.set_state("play");people.shoot("mechanic");people.talk("mechanic")
 assert(not g.story.ada_letter_delivered and g.town.inventory.ada_letter==1,"Dead John cannot receive the letter")
 print("PASS: Ada side quest request, real collection, inventory capacity, deduplication, named handoff, transcript, completion, alternate order, death and reset")
 g.queue_free();await process_frame;quit()
