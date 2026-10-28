extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame
 var e=g.enemies
 assert(e.reaper_navigation!=null and e.reaper_navigation.graph.get_point_count()>0)
 for index in [0,1,2,e.WORKSHOP_INDEX,e.REAPER_INDEX]:
  var d=e.creatures[index];var model=d.visual.get_node("ZombieReplacement")
  assert(model.get_meta("runtime_visual_only") and d.animation.get_parent()!=d.visual)
  var rig=preload("res://enemy_shot_hitboxes.gd").new(e).rig(d)
  assert(rig.bones.has("base_humanhead"))
  for link in rig.links:assert(rig.bones.has(link[0]) and rig.bones.has(link[1]),"Every combat limb matches the new skeleton")
  for child in d.visual.get_children():
   if child is Node3D:assert(child.visible==(child==model),"Only the new mesh is visible")
 for index in [e.HOUSE_INDEX,e.CELLAR_INDEX,e.TUNNEL_INDICES[0],e.HOLLOW_INDEX]:assert(not e.creatures[index].visual.has_node("ZombieReplacement"))
 assert(g.cemetery_shadow.actor.get_child(0).has_node("ZombieReplacement"))
 var f=FileAccess.open("C:/Users/jkern/Documents/Codex/2026-10-16/go-x20/work/pre-zombie-save.bin",FileAccess.READ)
 var saved=f.get_var();f.close()
 assert(g.saves.backend.valid(saved),"Genuine v2.4.0 save with old enemy meshes remains valid")
 g.saves.backend.apply(saved)
 for index in [0,1,2,e.WORKSHOP_INDEX,e.REAPER_INDEX]:
  var d=e.creatures[index];assert(d.animation.is_playing() and d.animation.has_animation(d.clips[d.clip]),"Old saved animation aliases are rebuilt for the zombie")
  for child in d.visual.get_children():
   if child is Node3D and child.name!="ZombieReplacement":assert(not child.visible,"Old saved mesh visibility cannot produce two overlapping monsters")
 assert(g.cemetery_shadow.animation.has_animation(g.cemetery_shadow.idle_clip))
 var current=g.saves.backend.capture();assert(g.saves.backend.valid(current));g.saves.backend.apply(current)
 print("PASS: selected enemy replacements, complete skeleton hitboxes, other encounters retained, cemetery apparition, navigation, genuine old-save migration and new save/load")
 quit()
