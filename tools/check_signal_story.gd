extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.controller.set_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 for id in g.story.RECORDS:
  var record=g.story.RECORDS[id]
  var h=g.hud.note_height(record[1],10)
  print("NOTE HEIGHT ",id,": ",h)
  assert(h<=200,"Record fits readable journal page: "+id)
  if g.town.actions.has(id) and g.town.actions[id].has("text"):assert(g.town.actions[id].text==record[1])
 var c=g.town.townspeople.conversation
 c.speaker="mechanic"
 assert("pulled the plug" in c.answer("origin") and "No incoming station" in c.answer("origin"))
 c.begin("John",false,"mechanic");c.show_topics();c.choose(0)
 assert(c.current_topic=="origin" and g.town.journal_entries.any(func(e):return e.id=="john_origin"))
 var count=g.town.journal_entries.size();c.show_topics();c.choose(0);assert(count==g.town.journal_entries.size())
 assert("MAIN ISOLATOR" in c.answer("church") and "GREEN" in c.answer("church"))
 c.speaker="nurse";assert("No bites" in c.answer("signal") and "already dead" in c.answer("patients"))
 for id in ["radio_note","clinic_note","chapel_record","workshop_record","cellar_record"]:
  g.story.read_evidence(id)
  assert(g.story.evidence.has(id))
 for id in g.story.PROTOCOL:assert(g.hud.note_height(g.story.RECORDS[id][2],11)<=32)
 g.story.reset();g.story.read_evidence("radio_note");assert("no power" in g.story.question())
 g.story.read_evidence("clinic_note");assert("wakes the dead" in g.story.question())
 g.story.read_evidence("cellar_record");assert("MAIN ISOLATOR" in g.story.question())
 g.town.journal_entries.append({"id":"radio_note","title":"Old title","text":"Outdated origin"})
 g.town.journal_entries.append({"id":"john_church","title":"John / Church","text":"Outdated storm story"})
 var before=g.town.journal_entries.size();g.story.refresh_collected_notes()
 assert(g.town.journal_entries.size()==before)
 assert(g.town.journal_entries[-2].text==g.story.RECORDS.radio_note[1])
 assert("station signal" in g.town.journal_entries[-1].text)
 var pages=preload("res://dialogue_style.gd")
 c.speaker="mechanic"
 for topic in ["origin","church","stayed"]:assert(pages.pages(c.answer(topic)).size()>0)
 print("PASS: station origin, exposure and deceased, amplification, isolation procedure, live notes, optional dialogue, deduplicated journal, evidence progression and page fit")
 g.queue_free();await process_frame;quit()
