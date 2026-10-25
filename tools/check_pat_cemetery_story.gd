extends SceneTree
func _initialize():call_deferred("run")
func topic(c,id):
 for i in range(c.TOPICS.size()):
  if c.TOPICS[i].id==id:return i
 return -1
func menu(c):
 c.begin("",false,"ranger");c.show_topics()
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false);g.cemetery_shadow.set_physics_process(false)
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 var people=g.town.townspeople;var c=people.conversation
 menu(c)
 assert(topic(c,"waiting")>=0 and topic(c,"cemetery")>=0)
 assert(topic(c,"family")==-1 and topic(c,"vault")==-1 and topic(c,"grave")==-1 and topic(c,"shadow")==-1,"No unearned discoveries")
 c.choose(topic(c,"waiting"))
 assert("Not the bus. That came." in g.dialogue_text and not "Patrick" in g.dialogue_text)
 assert(g.town.journal_entries.any(func(e):return e.id=="pat_waiting"))
 # A full pack must not swallow the quest key.
 g.set_state("play");g.town.inventory.medkit=24
 people.offer_grave_key()
 assert(not people.grave_key_given and g.town.inventory.mausoleum_key==0 and "pack is full" in g.dialogue_text)
 g.town.inventory.medkit=0;g.town.powered=true;g.town.inventory.coil=1;g.set_state("play")
 people.talk("ranger")
 assert(people.grave_key_given and g.town.inventory.mausoleum_key==1)
 assert("Whitcomb mausoleum" in g.dialogue_text and not "grandpappy" in g.dialogue_text.to_lower() and "workbench" in g.dialogue_text and "haven't been back" in g.dialogue_text)
 menu(c);assert(topic(c,"family")>=0 and topic(c,"vault")==-1)
 g.town.cemetery.unlocked=true;g.town.cemetery.opened=true
 menu(c);assert(topic(c,"vault")==-1,"Unlocking alone doesn't count as entering")
 g.set_state("play");g.player.global_position=g.town.cemetery.crypt.to_global(Vector3(0,0.01,0))
 g.town.cemetery._process(0.01)
 assert(g.story.pat_vault_seen)
 menu(c);c.choose(topic(c,"vault"))
 assert("That was a lie" in g.dialogue_text and "morning after the bus" in g.dialogue_text and "timber shutter" in g.dialogue_text)
 assert(not "Those coffins you found" in g.dialogue_text,"No far-room spoilers from vault entry")
 assert(c.asked.has("pat_vault"))
 g.set_state("play");g.hotel_basement.interact("mausoleum_tunnel")
 assert(g.story.pat_tunnel_seen)
 g.player.global_position=g.hotel_basement.to_global(Vector3(0,0.02,0));g.hotel_basement._process(0.01)
 assert(g.story.pat_cellar_seen)
 g.town.journal_entries.append({"id":"cemetery_buried_note","title":"Buried in a hurry","text":"P.W."})
 g.cemetery_shadow.vanished=true
 menu(c)
 assert(topic(c,"grave")>=0 and topic(c,"shadow")>=0 and c.TOPICS.size()>c.VISIBLE_QUESTIONS)
 for i in range(c.TOPICS.size()+1):
  assert(c.selected>=c.question_scroll and c.selected<c.question_scroll+c.VISIBLE_QUESTIONS)
  assert(c.row(c.selected).position.y>=272 and c.row(c.selected).end.y<=382)
  c.move_selection(1)
 assert(c.selected==0 and c.question_scroll==0,"Question scrolling wraps and remains visible")
 c.choose(topic(c,"grave"));assert("Patrick Whitcomb" in g.dialogue_text and "empty for years" in g.dialogue_text)
 menu(c);c.choose(topic(c,"waiting"));assert("Don't leave that speaker running" in g.dialogue_text)
 g.story.repeater.shutdown_done=true
 menu(c);c.choose(topic(c,"waiting"));assert("It stopped" in g.dialogue_text)
 assert(not "haven't been back" in people.radio_advice("ranger","coupler"))
 var data=g.saves.backend.capture();g.saves.backend.apply(data)
 assert(g.story.pat_vault_seen and g.story.pat_tunnel_seen and g.story.pat_cellar_seen and c.asked.has("pat_vault"),"Arc progress survives save/load")
 g.reset_game();assert(not g.story.pat_vault_seen and not g.story.pat_tunnel_seen and not g.story.pat_cellar_seen and not c.asked.has("pat_vault"))
 print("PASS: discovery-gated Pat arc, full-pack/key handoff, confession, optional grave/shadow, scrolling, shutdown resolution, save/load and restart")
 g.queue_free();await process_frame;quit()
