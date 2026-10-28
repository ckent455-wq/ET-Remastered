extends RefCounted
## Keep original saved nodes; the rendered zombie is a runtime-only child.
static func install(original:Node3D,variant:int,game)->Node3D:
 var existing=original.get_node_or_null("ZombieReplacement")
 if existing:return existing
 for child in original.get_children():
  if child is Node3D:child.hide()
  if child is AnimationPlayer:child.stop()
 var model=load("res://assets/enemies/local_zombie/zombie_%d.glb" % variant).instantiate()
 model.name="ZombieReplacement";model.set_meta("runtime_visual_only",true)
 original.add_child(model);game.town.apartment_interiors.adapt(model)
 return model
static func conceal_original(original:Node3D):
 for child in original.get_children():
  if child is Node3D:child.visible=child.name=="ZombieReplacement"
static func combat_model(original:Node3D)->Node3D:
 var replacement=original.get_node_or_null("ZombieReplacement")
 return replacement if replacement else original
static func clips(animation:AnimationPlayer)->Dictionary:
 var result={}
 for clip in animation.get_animation_list():result[String(clip).get_slice("/",String(clip).get_slice_count("/")-1)]=clip
 var aliases={"idle1":"idle","idle2":"idle","sniff":"idle","crouch_pose":"idle","walk1":"walk","walk2":"walk","punch":"attack","roar":"idle"}
 for alias in aliases:result[alias]=result[aliases[alias]]
 for key in ["idle","walk","run"]:animation.get_animation(result[key]).loop_mode=Animation.LOOP_LINEAR
 return result
