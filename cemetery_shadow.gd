extends Node3D
## A noncombat apparition: visible between graves until the player approaches.
var game
var actor:Node3D
var animation:AnimationPlayer
var material:StandardMaterial3D
var appeared=false
var vanished=false
var vanishing=false
var fade=0.0
const SPOT=Vector3(21.5,0.03,-18.6)
func _ready():
 name="CemeteryShadow"
 actor=Node3D.new()
 add_child(actor)
 actor.position=SPOT
 actor.scale=Vector3.ONE*1.1
 var model=preload("res://assets/enemies/creep.glb").instantiate()
 actor.add_child(model)
 material=StandardMaterial3D.new()
 material.albedo_color=Color(0.018,0.022,0.019,1)
 material.roughness=1
 material.metallic_specular=0
 material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  mesh.material_override=material
  mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 animation=model.find_child("AnimationPlayer",true,false)
 for clip in animation.get_animation_list():
  if str(clip).split("/")[-1].to_lower()=="idle1":
   animation.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
   animation.play(clip)
   break
 reset()
func reset():
 appeared=false
 vanished=false
 vanishing=false
 fade=0
 material.albedo_color.a=1
 actor.hide()
func _physics_process(delta):
 animation.speed_scale=0.5 if game.state=="play" else 0
 if game.state!="play" or vanished:return
 var p:Vector3=game.player.global_position
 var distance=p.distance_to(SPOT)
 if not appeared and game.town.cemetery.contains(p) and distance>7.5 and distance<23:
  appeared=true
  actor.show()
 if not appeared:return
 var direction=p-actor.global_position
 actor.rotation.y=atan2(direction.x,direction.z)
 if distance<7.0:vanishing=true
 if vanishing:
  fade+=delta
  material.albedo_color.a=clampf(1.0-fade/0.6,0,1)
  if fade>=0.6:
   vanished=true
   actor.hide()
