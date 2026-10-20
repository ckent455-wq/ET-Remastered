extends SceneTree
func _initialize():call_deferred("run")
func press(g,key):
 var event=InputEventKey.new();event.keycode=key;event.pressed=true;g._unhandled_input(event)
func finish_answer(g,c):
 var guard=0
 while not c.choosing and guard<100:g.advance_dialogue();guard+=1
 assert(c.choosing and g.state=="dialogue","Answer returns to the question menu")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 var people=g.town.townspeople;var c=people.conversation
 var original_view=g.camera.transform;var original_yaw=g.player.rotation.y
 people.talk("ranger")
 assert(c.active and not c.choosing and g.state=="dialogue","Pat's first introduction remains before optional questions")
 finish_answer(g,c)
 assert(g.hud.note_height(g.story.RECORDS.chapel_record[1],10)<=200,"The expanded church history stays readable within its journal page")
 press(g,KEY_DOWN);press(g,KEY_ENTER)
 assert(c.current_topic=="house" and "Nine years" in g.dialogue_text and "cellar" in g.dialogue_text,"Keyboard asks about the old Victorian house")
 assert(g.town.journal_entries.any(func(entry):return entry.id=="pat_house"),"Answer is saved in the journal")
 finish_answer(g,c)
 var count=g.town.journal_entries.size();c.choose(1);finish_answer(g,c)
 assert(g.town.journal_entries.size()==count,"Repeated questions never duplicate journal entries")
 g.town.journal_entries.append({"id":"victorian_letter","title":"House clearance notice","text":"Nine years ago"})
 c.choose(1);assert("You found the notice" in g.dialogue_text,"House answer responds to finding the clearance notice")
 finish_answer(g,c)
 g.controller.activate(0);g.controller.button(JOY_BUTTON_DPAD_DOWN);g.controller.button(JOY_BUTTON_A)
 assert(c.current_topic=="church" and "1891" in g.dialogue_text and "flood line" in g.dialogue_text,"Gamepad chooses church history")
 g.controller.button(JOY_BUTTON_B);assert(c.choosing,"Gamepad back returns from an answer")
 var click=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=c.row(3).get_center();g._unhandled_input(click)
 assert(c.current_topic=="signal" and "Ordinary radio" in g.dialogue_text,"Mouse chooses signal history")
 finish_answer(g,c);g.story.read_evidence("clinic_note");c.choose(3)
 assert("our neighbors" in g.dialogue_text,"Investigated evidence deepens the answer without changing the signal's origin")
 press(g,KEY_ESCAPE);press(g,KEY_ESCAPE)
 assert(g.state=="play" and not c.active and g.camera.transform.is_equal_approx(original_view) and is_equal_approx(g.player.rotation.y,original_yaw),"Leaving restores the player's view")
 people.talk("ranger");assert(c.choosing,"Later visits open directly to questions")
 c.choose(5);assert("station key" in g.dialogue_text.to_lower(),"Advice follows the current quest")
 press(g,KEY_ESCAPE);press(g,KEY_ESCAPE)
 g.town.powered=true;g.town.inventory.coil=1
 people.talk("ranger")
 assert(people.grave_key_given and g.town.inventory.mausoleum_key==1 and "Whitcomb" in g.dialogue_text,"Mausoleum key handoff retains priority")
 finish_answer(g,c);c.choose(c.TOPICS.size())
 people.talk("ranger");assert(g.town.inventory.mausoleum_key==1,"Questions cannot duplicate quest keys")
 c.choose(c.TOPICS.size());people.talk("nurse")
 assert(g.state=="dialogue" and not c.active and g.dialogue_name=="Aubrey / Nurse","Other NPC dialogue remains normal")
 g.set_state("play");people.characters.ranger.dead=true;people.talk("ranger")
 assert(g.state=="play" and not c.active,"Dead Pat cannot open a conversation")
 g.reset_game();assert(not c.active and not c.greeted and c.asked.is_empty() and not g.town.journal_entries.any(func(entry):return entry.id.begins_with("pat_")),"New journey clears conversation history and notes")
 print("PASS: Pat questions, keyboard/mouse/controller, lore continuity, evidence-aware answers, deduplicated journal, view restore, quest advice, key handoff, other NPCs, death and reset")
 g.queue_free();await process_frame;quit()
