extends RefCounted
## Physical pursuit through ordinary hinged doors. Portal/locked doors remain barriers.
var voices={}
var held_open={}
func reset():
 for voice in voices.values():
  if is_instance_valid(voice):voice.stop()
 held_open.clear()
func update_audio(game):
 for voice in voices.values():
  if is_instance_valid(voice):voice.stream_paused=game.state not in ["play","dialogue"]
func clear_attempt(data):
 data["forcing_door"]="";data["door_effort"]=0.0;data["door_beat"]=0.0
func protected_door(town,id:String)->bool:
 return town.shelter_locks.get(id,false) or not town.doors[id].get("unlocked",id!="radio")
func holding_open(id:String,clock:float)->bool:
 return held_open.get(id,0.0)>clock
func pound(enemies,data,point:Vector3,mummy:bool):
 if not voices.has(data.index):
  var v=enemies.game.soundscape.spatial_voice(enemies.game,enemies.game.soundscape.stream("monster_door_pound"),2.0,32)
  v.unit_size=9;v.attenuation_filter_cutoff_hz=6500
  voices[data.index]=v
 var voice=voices[data.index]
 voice.global_position=point+Vector3.UP*1.1
 voice.pitch_scale=0.82 if mummy else (0.92 if int(data.get("door_hits",0))%2==0 else 0.84)
 voice.play()
 data["door_hits"]=data.get("door_hits",0)+1
 data.clip=""
 enemies.play(data,"punch")
 data.animation.speed_scale=1.0
func update(enemies,data,delta:float,goal:Variant=null)->bool:
 var game=enemies.game
 if data.hp<=0 or data.state not in ["chase","investigate","tunnel_chase","house_rush","cellar_rush","reaper_chase","returning_home"]:
  clear_attempt(data);return false
 var town=game.town
 for id in town.doors:
  var building=town.buildings[id]
  var local_actor:Vector3=building.to_local(data.actor.global_position)
  var player:Vector3=building.to_local(goal if goal is Vector3 else game.player.global_position)
  var door=town.doors[id]
  var door_z:float=door.hinge.position.z
  if absf(local_actor.y-player.y)>1.6 or absf(local_actor.y)>1.3:continue
  # Only react to a door separating the pursuing creature and player.
  var actor_inside=absf(local_actor.x)<5.4 and local_actor.z> -5.2 and local_actor.z<door_z
  var target_inside=absf(player.x)<5.4 and player.z> -5.2 and player.z<door_z
  if actor_inside==target_inside:continue
  var side=1.0 if local_actor.z>door_z else -1.0
  var approach=building.to_global(Vector3(0,local_actor.y,door_z+side*1.25))
  if data.actor.global_position.distance_to(approach)>9.0:continue
  var mummy=data.index in [enemies.HOUSE_INDEX,enemies.CELLAR_INDEX] or data.index in enemies.TUNNEL_INDICES
  var speed=2.2 if mummy else 2.05
  if door.open:
   held_open[id]=game.clock+3.0
   var through=building.to_global(Vector3(0,local_actor.y,door_z-side*1.5))
   var direction=through-data.actor.global_position;direction.y=0
   enemies.play(data,"walk1")
   enemies.house_encounter.move(data,direction.normalized()*speed,delta)
   clear_attempt(data)
   return true
  var offset=approach-data.actor.global_position;offset.y=0
  if offset.length()>0.35:
   enemies.play(data,"walk1")
   enemies.house_encounter.move(data,offset.normalized()*speed,delta)
   clear_attempt(data)
   return true
  enemies.house_encounter.move(data,Vector3.ZERO,delta)
  data.actor.rotation.y=atan2((town.doorway_position(id)-data.actor.global_position).x,(town.doorway_position(id)-data.actor.global_position).z)
  if data.get("forcing_door","")!=id:
   clear_attempt(data);data.forcing_door=id;data["door_hits"]=0
  data.door_effort+=delta;data.door_beat-=delta
  if data.door_beat<=0:
   pound(enemies,data,town.doorway_position(id),mummy)
   data.door_beat=1.5 if mummy else 0.9
  var duration=5.5 if mummy else 3.8
  if data.door_effort>=duration and not protected_door(town,id):
   if town.set_building_door(id,true,false,false,true):
    # Mummies slowly force the leaf inward. Collision stays until it is open.
    if mummy:
     door.tween.kill();door.collision.set_deferred("disabled",false)
     door.tween=town.create_tween()
     door.tween.tween_property(door.hinge,"rotation:y",1.55,1.6)
     door.tween.tween_callback(func():door.collision.set_deferred("disabled",true))
    held_open[id]=game.clock+4.0
    clear_attempt(data)
  return true
 clear_attempt(data)
 return false
