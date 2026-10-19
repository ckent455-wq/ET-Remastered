extends RefCounted
## Preplaced behind the bedroom partition; a single, physical upstairs ambush.
func update(enemies,data,delta:float):
 var game=enemies.game
 if data.state=="dead":return # This encounter never respawns.
 var house=game.victorian_house
 if not house:return
 var p:Vector3=house.to_local(game.player.global_position)
 if data.state=="house_wait":
  if p.y>3.1 and p.y<4.3 and p.x> -0.9 and p.x<1.25 and p.z> -2.1 and p.z< -0.85:
   data.state="house_rush";data.timer=0.0
   data.voice.stream=enemies.streams.attack;data.voice.volume_db=-5;data.voice.pitch_scale=0.83
   data.voice.play();enemies.play(data,"walk1")
   data.animation.speed_scale=2.0
  return
 data.timer=maxf(0,data.timer-delta)
 data.cooldown=maxf(0,data.cooldown-delta)
 if data.state=="stagger":
  if data.timer<=0:data.state="house_rush" if data.house_waypoint<2 else "chase"
  return
 if data.state=="attack":
  if not data.did_hit and data.timer<0.55:
   data.did_hit=true
   if data.actor.global_position.distance_to(game.player.global_position)<1.8 and enemies.line_clear(data,game.player.global_position+Vector3.UP):game.take_damage(18)
  if data.timer<=0:data.state="chase";data.cooldown=1.1
  return
 var destination:Vector3
 if data.house_waypoint<2:
  var route=[Vector3(0,3.45,0.45),Vector3(0,3.45,-1.35)]
  destination=house.to_global(route[data.house_waypoint])
  if data.actor.global_position.distance_to(destination)<0.5:
   data.house_waypoint+=1
   return
 else:
  data.state="chase"
  # Stay upstairs rather than tumbling down the open stairwell after a retreat.
  if p.y<3.1 or absf(p.x)>4.5 or absf(p.z)>4.5:
   enemies.play(data,"idle1");move(data,Vector3.ZERO,delta);return
  var local_target=Vector3(clampf(p.x,-4.3,2.0),3.45,clampf(p.z,-4.3,4.3))
  var here:Vector3=house.to_local(data.actor.global_position)
  if (here.z< -0.9 and p.z> -0.4) or (here.z> -0.4 and p.z< -0.9):local_target=Vector3(0,3.45,-0.7)
  destination=house.to_global(local_target)
  if data.actor.global_position.distance_to(game.player.global_position)<1.55 and data.cooldown<=0 and enemies.line_clear(data,game.player.global_position+Vector3.UP):
   data.state="attack";data.timer=1.15;data.did_hit=false
   enemies.play(data,"punch");data.voice.stream=enemies.streams.attack;data.voice.volume_db=-11;data.voice.play();return
 var direction=destination-data.actor.global_position;direction.y=0
 enemies.play(data,"walk1")
 data.animation.speed_scale=2.0 if data.house_waypoint<2 else 1.3
 move(data,direction.normalized()*(4.0 if data.house_waypoint<2 else 1.8) if direction.length()>0.25 else Vector3.ZERO,delta)
func move(data,desired:Vector3,delta:float):
 var actor:CharacterBody3D=data.actor
 if desired.length()>0.1:actor.rotation.y=lerp_angle(actor.rotation.y,atan2(desired.x,desired.z),minf(1,delta*14))
 actor.velocity=Vector3(desired.x,-0.5 if actor.is_on_floor() else maxf(-12,actor.velocity.y-18*delta),desired.z)
 actor.move_and_slide()
