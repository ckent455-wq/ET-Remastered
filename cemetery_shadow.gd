extends Node3D
## A noncombat apparition walks the east fence, disappearing beyond the mausoleum.
var game
var actor:Node3D
var animation:AnimationPlayer
var material:StandardMaterial3D
var idle_clip=""
var walk_clip=""
var appeared=false
var vanished=false
var vanishing=false
var fade=0.0
var escape_elapsed=0.0
var zombie_animation_time=0.0
const SPOT=Vector3(22.5,0.03,-18.5)
const END=Vector3(22.5,0.03,-23.55)
const WALK_SPEED=1.5
func _ready():
 name="CemeteryShadow"
 actor=Node3D.new()
 add_child(actor)
 actor.position=SPOT
 actor.scale=Vector3.ONE*1.1
 var model=preload("res://assets/enemies/creep.glb").instantiate()
 actor.add_child(model)
 var rendered=preload("res://zombie_enemy_models.gd").install(model,3,game)
 material=StandardMaterial3D.new()
 material.albedo_color=Color(0.018,0.022,0.019,1)
 material.roughness=1
 material.metallic_specular=0
 material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 for mesh in rendered.find_children("*","MeshInstance3D",true,false):
  mesh.material_override=material
  mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 animation=rendered.find_child("AnimationPlayer",true,false)
 for clip in animation.get_animation_list():
  var short=str(clip).split("/")[-1].to_lower()
  if short in ["idle","walk"]:animation.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
  if short=="idle":idle_clip=clip
  elif short=="walk":walk_clip=clip
 reset()
func reset():
 zombie_animation_time=0
 appeared=false
 vanished=false
 vanishing=false
 fade=0
 escape_elapsed=0
 actor.position=SPOT
 actor.rotation.y=PI
 material.albedo_color.a=1
 actor.show()
 if idle_clip!="":animation.play(idle_clip)
func restore_zombie_model():
 var original=actor.get_child(0)
 preload("res://zombie_enemy_models.gd").conceal_original(original)
 for clip in animation.get_animation_list():
  var short=String(clip).get_slice("/",String(clip).get_slice_count("/")-1)
  if short=="idle":idle_clip=clip
  if short=="walk":walk_clip=clip
 animation.play(walk_clip if appeared else idle_clip)
 animation.seek(zombie_animation_time,true);animation.advance(0)
func _physics_process(delta):
 zombie_animation_time=animation.current_animation_position if animation.is_playing() else 0.0
 animation.speed_scale=(1.22 if appeared else 0.5) if game.state=="play" else 0
 if game.state!="play" or vanished:return
 var p:Vector3=game.player.global_position
 # He is already waiting in the world; approaching the gate starts his escape.
 var near_gate=p.x>3.5 and p.x<10 and p.z> -16 and p.z< -8
 if not appeared and (near_gate or game.town.cemetery.contains(p)):
  appeared=true
  if walk_clip!="":animation.play(walk_clip,0.12)
 if not appeared:return
 escape_elapsed+=delta
 if not vanishing:
  actor.position=actor.position.move_toward(END,WALK_SPEED*delta)
  if actor.position.distance_to(END)<0.01:vanishing=true
  # React when the building actually hides him, rather than waiting for the full route.
  if escape_elapsed>0.5:
   var ray=PhysicsRayQueryParameters3D.create(game.camera.global_position,actor.global_position+Vector3(0,1,0))
   ray.exclude=[game.player.get_rid()]
   var hit=get_world_3d().direct_space_state.intersect_ray(ray)
   if not hit.is_empty() and game.town.cemetery.crypt.is_ancestor_of(hit.collider):vanishing=true
 if vanishing:
  fade+=delta
  material.albedo_color.a=clampf(1.0-fade/0.15,0,1)
  if fade>=0.15:
   vanished=true
   actor.hide()
   game.dialogue_name=""
   game.dialogue_text="I'm seeing things, I must have hit my head harder than I thought..."
   game.set_state("dialogue")
