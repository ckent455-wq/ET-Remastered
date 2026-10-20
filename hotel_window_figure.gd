extends Node3D
## Silent, noncombat watcher framed behind an upstairs sash window.
var game
var actor:Node3D
var pane:StandardMaterial3D
var spill:OmniLight3D
var flicker_time=-1.0
var vanished=false
var watched_time=0.0
var first_distance=0.0
var window_point:Vector3
func _ready():
 name="HotelWindowFigure"
 var hotel=game.town.buildings.house
 transform=hotel.transform
 # The facade is solid geometry: a shallow recess and flattened silhouette
 # sit behind its existing sash bars, without cutting the building open.
 pane=StandardMaterial3D.new()
 pane.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 # Warm room light makes the dark person readable through the fog.
 pane.albedo_color=Color(0.48,0.34,0.18)
 pane.emission_enabled=true
 pane.emission=Color(0.56,0.36,0.15)
 pane.emission_energy_multiplier=0.7
 var lit_window=game.town.box(self,Vector3(-2.15,5.16,5.094),Vector3(1.13,1.63,0.008),pane,false)
 lit_window.name="LitRoomWindow"
 spill=game.town.lamp(self,Vector3(-2.15,5.4,5.28),Color(0.95,0.66,0.32),0.3,2.5)
 spill.name="WindowLightSpill"
 spill.shadow_enabled=false
 actor=Node3D.new();actor.name="Watcher";add_child(actor)
 actor.position=Vector3(-2.15,4.39,5.115)
 var model=preload("res://assets/npcs/ranger.glb").instantiate()
 actor.add_child(model)
 var shadow=StandardMaterial3D.new()
 shadow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 shadow.albedo_color=Color(0.008,0.011,0.01)
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  mesh.material_override=shadow
  mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 # This humanoid is authored at player scale with arms lowered.
 actor.scale=Vector3(0.86,0.86,0.025)
 window_point=to_global(Vector3(-2.15,5.48,5.12))
 reset()
func reset():
 vanished=false;watched_time=0;first_distance=0
 actor.show()
 flicker_time=-1.0
 set_window_light(true)
func set_window_light(on:bool):
 pane.albedo_color=Color(0.48,0.34,0.18) if on else Color(0.018,0.028,0.026)
 pane.emission_energy_multiplier=0.7 if on else 0.0
 spill.light_energy=0.3 if on else 0.0
func _physics_process(delta):
 if game.state!="play":return
 if flicker_time>=0.0:
  flicker_time+=delta
  # Two brief, uneven flashes, then permanent darkness until restart.
  var on=(flicker_time>=0.09 and flicker_time<0.15) or (flicker_time>=0.29 and flicker_time<0.33)
  set_window_light(on)
  if flicker_time>=0.4:flicker_time=-1.0
  return
 if vanished:return
 var p:Vector3=game.player.global_position
 var distance=Vector2(p.x-window_point.x,p.z-window_point.z).length()
 # A player going inside without looking still leaves an empty window.
 if distance<3.6:
  disappear();return
 if game.camera.is_position_in_frustum(window_point):
  var ray=PhysicsRayQueryParameters3D.create(game.camera.global_position,window_point)
  ray.exclude=[game.player.get_rid()]
  if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
   if first_distance==0:first_distance=distance
   watched_time+=delta
 if watched_time>=0.5 and distance<9.5 and first_distance-distance>2.0:
  disappear()
func disappear():
 if vanished:return
 vanished=true
 actor.hide()
 flicker_time=0.0
 set_window_light(false)
