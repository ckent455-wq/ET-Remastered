extends Node3D
## Reuse the same imported weathered coffin mesh for an unsettling cellar stockpile.
var cellar
var coffins:Array[Node3D]=[]
var material:StandardMaterial3D
var upright:StaticBody3D
var lid:Node3D
var lid_closed=Transform3D.IDENTITY
var burst_time=0.0
var busted=false
var crack:AudioStreamPlayer3D
var sting:AudioStreamPlayer
var throat:AudioStreamPlayer
var scream_elapsed=0.0
var blackout_active=false
var blackout_spent=false
var light_was_on=false
func _ready():
 name="CellarCoffinStacks"
 material=StandardMaterial3D.new()
 material.albedo_texture=preload("res://assets/rustic_coffin/coffin_01_basecolor-1K.png")
 material.albedo_color=Color(0.9,0.87,0.8)
 material.roughness=0.92
 material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
 material.normal_enabled=true
 material.normal_texture=preload("res://assets/rustic_coffin/coffin_01_normal-1K.png")
 material.normal_scale=0.45
 stack(Vector3(-3.72,0,0.45),0.02,3)
 stack(Vector3(-2.95,0,3.1),PI/2-0.06,3)
 stack(Vector3(3.1,0,3.15),PI/2+0.035,2)
 upright=place(Vector3(2.65,0,1.0),Vector3(deg_to_rad(-68),0.4,0),true)
 lid=Node3D.new();lid.name="BreakawayLid";upright.add_child(lid)
 for mesh in upright.get_children():
  if mesh is MeshInstance3D and str(mesh.name) in ["coffin_01_002","Cube"]:mesh.reparent(lid,false)
 lid_closed=lid.transform
 crack=cellar.game.soundscape.spatial_voice(self,preload("res://assets/audio/coffin_break.wav"),-2,20)
 sting=cellar.game.soundscape.voice(preload("res://assets/audio/tree_scream.mp3"),-1.0)
 sting.pitch_scale=0.62
 throat=cellar.game.soundscape.voice(preload("res://assets/enemies/growl.wav"),-3.0)
 throat.pitch_scale=0.72
 crack.position=upright.position
 reset_burst()
func copy_parts(source:Node,parent:Node3D,accumulated=Transform3D.IDENTITY):
 var current:Transform3D=accumulated
 if source is Node3D:current=accumulated*source.transform
 if source is MeshInstance3D and source.mesh:
  var mesh=MeshInstance3D.new();mesh.name=source.name;mesh.mesh=source.mesh;mesh.transform=current;mesh.material_override=material
  parent.add_child(mesh)
 for child in source.get_children():copy_parts(child,parent,current)
func stack(origin:Vector3,yaw:float,count:int):
 var height=0.0
 for i in range(count):
  var offset=Vector3(0.025*i,height,0.035*(i%2))
  var tilt=Vector3(0,yaw+(0.035 if i%2 else -0.02),deg_to_rad(0.8) if i==count-1 else 0)
  var coffin=place(origin+offset,tilt)
  height=coffin.get_meta("top_y")
func place(at:Vector3,angles:Vector3,flip_ends=false)->Node3D:
 var coffin=StaticBody3D.new();coffin.name="WeatheredCoffin%d" % coffins.size();add_child(coffin)
 var source=preload("res://assets/rustic_coffin/coffin.fbx").instantiate()
 copy_parts(source,coffin,Transform3D(Basis(Vector3.UP,PI),Vector3.ZERO) if flip_ends else Transform3D.IDENTITY);source.free()
 var local=AABB();var first=true
 for mesh in coffin.get_children():
  var part:AABB=mesh.transform*mesh.mesh.get_aabb()
  local=part if first else local.merge(part);first=false
 var shape=BoxShape3D.new();shape.size=local.size
 var collision=CollisionShape3D.new();collision.shape=shape;collision.position=local.get_center();coffin.add_child(collision)
 coffin.rotation=angles
 var rotated=coffin.transform*local
 coffin.position=at-Vector3(rotated.get_center().x,rotated.position.y,rotated.get_center().z)
 coffin.set_meta("top_y",at.y+rotated.size.y)
 coffin.set_meta("local_bounds",local)
 coffins.append(coffin)
 return coffin

func occupant_spawn()->Vector3:
 var body:MeshInstance3D=upright.get_node("coffin_01")
 var center:Vector3=upright.to_global((body.transform*body.mesh.get_aabb()).get_center())
 return Vector3(center.x,cellar.global_position.y+0.01,center.z)
func reset_burst():
 busted=false;burst_time=0;scream_elapsed=0
 blackout_active=false;blackout_spent=false;light_was_on=false
 if lid:lid.transform=lid_closed;lid.show()
 if crack:crack.stop()
 if sting:sting.stop()
 if throat:throat.stop()
 for part in upright.get_children():
  if part is CollisionShape3D:part.set_deferred("disabled",false)
 var game=cellar.game
 if game.enemies and game.enemies.creatures.size()>9:
  var data=game.enemies.creatures[game.enemies.TUNNEL_INDICES[2]]
  data.spawn=occupant_spawn();data.actor.global_position=data.spawn
  var facing:Vector3=upright.global_basis*Vector3.UP
  data.actor.rotation.y=atan2(facing.x,facing.z)
  data.actor.collision_layer=0;data.actor.collision_mask=0
  data.visual.hide()
func burst():
 if busted:return
 busted=true;burst_time=0;scream_elapsed=0
 finish_blackout(true)
 for part in upright.get_children():
  if part is CollisionShape3D:part.set_deferred("disabled",true)
 sting.volume_db=-1.0;throat.volume_db=-3.0
 crack.play();sting.play(0.05);throat.play()
func _process(delta):
 var active=cellar.game.state=="play"
 if blackout_active:
  if not cellar.contains(cellar.game.player.global_position):finish_blackout(false)
  else:cellar.game.flashlight.hide()
 if crack:crack.stream_paused=not active
 if sting:sting.stream_paused=not active
 if throat:throat.stream_paused=not active
 if not active or not busted:return
 scream_elapsed+=delta
 if scream_elapsed>1.4:
  var tail=clampf(1.0-(scream_elapsed-1.4)/0.25,0,1)
  sting.volume_db=linear_to_db(maxf(0.0001,tail))-1.0
  throat.volume_db=linear_to_db(maxf(0.0001,tail))-3.0
  if tail<=0:sting.stop();throat.stop()
 burst_time=minf(1,burst_time+delta/0.55)
 var t=burst_time
 var forward:Vector3=upright.global_basis*Vector3.UP;forward.y=0;forward=forward.normalized()
 var displacement=forward*1.25*t+Vector3(-0.18*t,0.4*sin(t*PI)-0.95*t*t,0)
 lid.position=lid_closed.origin+upright.global_basis.inverse()*displacement
 lid.rotation=Vector3(-1.05*t,0.10*t,-0.24*t)
 if t>=1:lid.hide() # The shattered lid leaves no floating or blocking debris.

func start_blackout():
 var game=cellar.game
 if busted or blackout_spent or not cellar.contains(game.player.global_position):return
 blackout_spent=true;blackout_active=true
 light_was_on=game.flashlight.visible
 game.flashlight.hide()
 game.soundscape.flashlight_click(false)
 game.message="The flashlight just died."
func finish_blackout(scare:bool):
 var game=cellar.game
 var was_active=blackout_active
 blackout_active=false
 if not was_active:return
 if scare and game.crash_site.has_flashlight:
  # Preserve its charge; a completely empty lamp gets a short emergency recovery.
  game.flashlight_charge=maxf(5.0,game.flashlight_charge)
  game.flashlight.show()
  game.soundscape.flashlight_click(true)
 elif game.crash_site.has_flashlight:
  game.flashlight.visible=light_was_on and game.flashlight_charge>0
