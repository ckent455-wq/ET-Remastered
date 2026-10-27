extends SceneTree
func _initialize():call_deferred("run")
func topic(c,id):
 for i in range(c.TOPICS.size()):
  if c.TOPICS[i].id==id:return i
 return -1
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false);g.controller.set_process(false)
 while not g.surface_details.completed:await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.state="play";g.crash_site.has_backpack=true
 var c=g.town.townspeople.conversation;var people=g.town.townspeople;var world=g.town_changes
 world.set_process(false);world.sync()
 assert(not world.motor.playing and not world.lights[0].visible)
 c.begin("",false,"nurse");assert(topic(c,"consequence_coffins")==-1 and topic(c,"consequence_power")==-1)
 g.set_state("play")
 var terminal=g.town.actions.battery_panel.area.get_node("HighVoltageTerminal")
 terminal.activate_power();world.sync()
 assert(g.state=="play" and not c.active,"Power never starts an unsolicited conversation")
 assert(world.motor.playing and world.interference.playing and world.lights[0].visible)
 world._process(0.1);world.startup=0.5;world.sync();assert(not world.lights[0].visible)
 world.startup=1.9;world._process(0.1);world._process(0.1);assert(world.startup<0 and world.lights[0].visible)
 c.greetings.nurse=true;people.talk("nurse")
 assert(not c.choosing and c.greetings.has("reaction_nurse_power") and "motor" in g.dialogue_text)
 world.sync();assert(not world.motor.stream_paused,"Ambience continues during dialogue")
 g.set_state("play");people.talk("nurse");assert(c.choosing,"Each reaction is delivered once")
 c.choose(topic(c,"consequence_power"));assert(g.town.journal_entries.any(func(e):return e.id=="aubrey_consequence_power"))
 g.set_state("play");g.story.pat_cellar_seen=true;people.talk("nurse")
 assert("cuffs" in g.dialogue_text and not c.choosing)
 c.show_topics();c.choose(topic(c,"consequence_coffins"))
 assert("Wrapped bodies?" in g.dialogue_text)
 assert(g.town.journal_entries.any(func(e):return e.id=="aubrey_consequence_coffins"))
 assert(g.town.journal_entries.any(func(e):return e.id=="aubrey_consequence_power"),"New reports preserve previous journal entries")
 g.set_state("play");c.greetings.mechanic=true;g.enemies.workshop_defeated=true;people.talk("mechanic")
 assert("shots" in g.dialogue_text and c.greetings.has("reaction_mechanic_attack"))
 g.set_state("play");g.story.repeater.shutdown_done=true;world.sync()
 assert(not world.interference.playing and world.motor.playing,"Shutdown removes interference but leaves workshop machinery running")
 for id in ["ranger","nurse","mechanic"]:
  c.greetings[id]=true;g.set_state("play");people.talk(id)
  assert(c.greetings.has("reaction_"+id+"_silence"))
  c.show_topics();assert(topic(c,"consequence_silence")>=0)
  c.choose(topic(c,"consequence_silence"))
  assert("county" in g.dialogue_text.to_lower())
 var snapshot=g.saves.backend.capture();g.saves.backend.apply(snapshot)
 assert(c.greetings.has("reaction_mechanic_attack") and c.greetings.has("reaction_nurse_coffins"),"Save/load retains witnessed reactions")
 world.sync();assert(world.startup<0 and not world.motor.stream_paused,"Loading restores power without replaying startup")
 g.set_state("paused");world.sync()
 assert(not world.motor.playing and not world.motor_running,"Pause stops machinery audio until resume")
 g.set_state("play");world.sync();assert(world.motor_running and world.motor.playing)
 g.reset_game();world.sync();assert(not world.motor.playing and not world.lights[0].visible and c.greetings.is_empty())
 print("PASS: manual reactions, evidence gates, stage-specific journal, power hesitation, dialogue ambience, isolated shutdown, save/load and reset")
 g.queue_free();await process_frame;quit()
