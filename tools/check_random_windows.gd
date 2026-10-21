extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_state("title");var t=g.title_weather;t.set_process(false)
 assert(t.lit_window_order.size()==1)
 t.update_window_glows(0.01)
 var count=0
 for w in t.windows:
  if w.glow.visible:count+=1
 assert(count==1,"Exactly one initial lit window")
 for step in range(20):
  t.next_window_change=0;t.update_window_glows(0.01)
  count=0
  for w in t.windows:
   if w.glow.visible:count+=1
   else:assert(w.material.emission_energy_multiplier==0)
  assert(count==2,"Only two randomly selected windows remain lit")
 print("PASS: one initial window, random additional windows, maximum two lit, original dark colors")
 g.queue_free();await process_frame;quit()
