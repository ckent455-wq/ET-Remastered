extends Node3D
## Local asset viewing mode, entered only by the explicit preview launch flag.
var game
var actor:StaticBody3D
var model:Node3D
var animation:AnimationPlayer
var variant=0
var clip=0
var info:Control
const CLIPS=["idle","walk","run","attack","death"]
const FONT=preload("res://assets/font.ttf")
func _ready():
 name="LocalZombiePreview"
 game.message=""
 game.enemies.set_physics_process(false)
 actor=StaticBody3D.new();actor.name="ZombieDisplay";add_child(actor)
 actor.position=Vector3(0,.02,-54)
 var shape=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.3;capsule.height=1.78
 shape.shape=capsule;shape.position.y=.89;actor.add_child(shape)
 info=Control.new();info.mouse_filter=Control.MOUSE_FILTER_IGNORE;game.hud.add_child(info);info.draw.connect(draw_info)
 show_variant()
func show_variant():
 if model:model.free()
 model=load("res://assets/enemies/local_zombie/zombie_%d.glb" % (variant+1)).instantiate();actor.add_child(model)
 game.town.apartment_interiors.adapt(model)
 animation=model.find_child("AnimationPlayer",true,false)
 for name in animation.get_animation_list():animation.get_animation(name).loop_mode=Animation.LOOP_NONE if "death" in name else Animation.LOOP_LINEAR
 play_clip()
 print("ZOMBIE PREVIEW variant=",variant+1," bounds=",game.surface_details.bounds_of(model)," animations=",animation.get_animation_list())
func play_clip():
 for name in animation.get_animation_list():
  if String(name).get_slice("/",String(name).get_slice_count("/")-1)==CLIPS[clip]:
   animation.play(name);animation.advance(0);break
 info.queue_redraw()
func _unhandled_key_input(event):
 if game.state!="play" or not event is InputEventKey or not event.pressed or event.echo:return
 if event.physical_keycode==KEY_N:variant=(variant+1)%3;show_variant();get_viewport().set_input_as_handled()
 elif event.physical_keycode==KEY_B:clip=(clip+1)%CLIPS.size();play_clip();get_viewport().set_input_as_handled()
func _process(_delta):
 game.hud.objectives.hide();game.arm_visual.hide()
 info.visible=game.state=="play"
func draw_info():
 info.draw_rect(Rect2(16,290,285,45),Color(0.025,0.035,0.03,.9))
 info.draw_string(FONT,Vector2(26,307),"ZOMBIE %d / %s" % [variant+1,CLIPS[clip].to_upper()],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("d2dfd0"))
 info.draw_string(FONT,Vector2(26,325),"N  Change model     B  Change animation",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("87a39f"))
func _exit_tree():
 if is_instance_valid(info):info.queue_free()
 if is_instance_valid(game.enemies):game.enemies.set_physics_process(true)
