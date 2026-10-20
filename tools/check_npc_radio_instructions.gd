extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 g.reset_game();g.crash_site.wake_phase="";g.state="play"
 var people=g.town.townspeople
 for stage in ["coupler","tuner","shutdown","repair","route","call"]:
  var answers=[]
  for id in ["ranger","nurse","mechanic"]:
   var line=people.radio_advice(id,stage)
   assert(not line.is_empty() and not line in answers,"Every NPC has a distinct answer at every radio stage")
   answers.append(line)
   if id=="nurse":assert(not "Aubrey" in line and not "her records" in line,"Aubrey never refers to herself in third person")
   if stage=="coupler":assert("Whitcomb" in line and "key" in line and "Pat" in line if id!="ranger" else "vault key from me" in line,"Correct speaker and mausoleum directions")
   if stage in ["tuner","shutdown"]:assert("MAIN ISOLATOR" in line,"Required shutdown remains clear")
   if stage in ["shutdown","repair","route","call"]:assert("GREEN" in line or "Green" in line,"Direct county routing stays consistent")
   if stage=="call":assert("Hold E" in line and "sirens" in line,"All final instructions retain interaction and quiet rescue")
 g.town.powered=true;g.town.inventory.coil=1
 assert(people.words("nurse")==people.radio_advice("nurse","coupler"))
 g.town.inventory.antenna=1
 assert(people.words("mechanic")==people.radio_advice("mechanic","tuner"))
 g.town.inventory.tuner=1
 assert(people.words("ranger")==people.radio_advice("ranger","shutdown"))
 g.story.repeater.shutdown_done=true
 assert(people.words("mechanic")==people.radio_advice("mechanic","repair"))
 g.town.radio_ready=true
 assert(people.words("nurse")==people.radio_advice("nurse","route"))
 g.story.county_bypass=true
 assert(people.words("ranger")==people.radio_advice("ranger","call"))
 g.story.repeater.shutdown_done=false
 assert(people.words("mechanic")==people.radio_advice("mechanic","shutdown"),"Green routing never hides required shutdown")
 g.story.repeater.shutdown_done=true;people.talk("nurse")
 while not people.conversation.choosing:g.advance_dialogue()
 people.conversation.choose(2)
 assert(g.dialogue_text==people.radio_advice("nurse","call") and "Aubrey" not in g.dialogue_text,"Aubrey's actual advice menu uses her own voice")
 print("PASS: three distinct voices across six radio stages, first-person Aubrey, accurate steps, progression selection and real menu advice")
 g.queue_free();await process_frame;quit()
