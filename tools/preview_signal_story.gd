extends SceneTree
func _initialize():call_deferred("run")
func shot(g,name):
 for i in range(4):
  g.hud.queue_redraw();await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("C:/Users/jkern/Documents/Codex/2026-10-21/b/outputs/story-"+name+".png")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false);g.controller.set_process(false)
 g.crash_site.wake_phase="";g.crash_site.has_backpack=true
 g.state="journal";g.journal_page=2
 for id in ["radio_note","cellar_record"]:
  g.town.journal_entries.assign([{"id":id,"title":g.story.RECORDS[id][0],"text":g.story.RECORDS[id][1]}])
  await shot(g,id)
 for id in ["radio_note","clinic_note","cellar_record"]:g.story.read_evidence(id)
 g.journal_casefile=true;await shot(g,"casefile")
 g.journal_casefile=false;g.state="play";g.town.townspeople.talk("mechanic")
 g.town.townspeople.conversation.show_topics();await shot(g,"john-topics")
 print("PASS: signal story screens rendered")
 g.queue_free();await process_frame;quit()
