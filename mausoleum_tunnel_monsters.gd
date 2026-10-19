extends RefCounted
## Two passage Wrappers and one hidden behind the far cellar storage screen.
func inside(tunnel,point:Vector3)->bool:
 var p:Vector3=tunnel.to_local(point)
 return p.y> -0.4 and p.y<2.8 and absf(p.x)<1.55 and p.z>=-30.2 and p.z< -5.1
func update(enemies,data,delta:float):
 var game=enemies.game
 if not game.hotel_basement:return
 var tunnel=game.hotel_basement
 var room_monster=data.index==enemies.TUNNEL_INDICES[2]
 var local_player:Vector3=tunnel.to_local(game.player.global_position)
 var active=tunnel.contains(game.player.global_position) if room_monster else inside(tunnel,game.player.global_position)
 var distance:float=data.actor.global_position.distance_to(game.player.global_position)
 if data.state=="tunnel_wait":
  var wake_room=room_monster and active and local_player.z> -3.6
  var wake_passage=not room_monster and active and local_player.z> -27.2 and distance<6.5 and enemies.line_clear(data,game.player.global_position+Vector3.UP)
  if wake_room or wake_passage:
   data.state="tunnel_chase"
   data.voice.stream=enemies.streams.growl;data.voice.volume_db=-13;data.voice.pitch_scale=0.78
   data.voice.play()
  return
 data.timer=maxf(0,data.timer-delta);data.cooldown=maxf(0,data.cooldown-delta)
 if data.state=="stagger":
  if data.timer<=0:data.state="tunnel_chase"
  return
 if data.state=="attack":
  if not data.did_hit and data.timer<0.55:
   data.did_hit=true
   if active and distance<1.8 and enemies.line_clear(data,game.player.global_position+Vector3.UP):game.take_damage(16)
  if data.timer<=0:data.state="tunnel_chase";data.cooldown=1.3
  return
 if not active:
  enemies.play(data,"idle1");enemies.house_encounter.move(data,Vector3.ZERO,delta)
  return
 if distance<1.5 and data.cooldown<=0 and enemies.line_clear(data,game.player.global_position+Vector3.UP):
  data.state="attack";data.timer=1.15;data.did_hit=false
  enemies.play(data,"punch")
  data.voice.stream=enemies.streams.attack;data.voice.volume_db=-14;data.voice.play()
  return
 var target:Vector3=local_player
 if room_monster:
  var route=[Vector3(1.0,0.01,0.9),Vector3(1.0,0.01,-2.1),Vector3(0,0.01,-3.5)]
  if data.tunnel_waypoint<route.size():
   target=route[data.tunnel_waypoint]
   if data.actor.global_position.distance_to(tunnel.to_global(target))<0.3:data.tunnel_waypoint+=1
  else:
   target=Vector3(clampf(target.x,-3.65,3.65) if target.z> -5 else clampf(target.x,-0.7,0.7),0.01,clampf(target.z,-28.6,4.0))
 else:target=Vector3(clampf(target.x,-0.7,0.7),0.01,clampf(target.z,-28.6,-5.8))
 var direction:Vector3=tunnel.to_global(target)-data.actor.global_position;direction.y=0
 var desired=direction.normalized()*1.2 if direction.length()>(0.15 if room_monster and data.tunnel_waypoint<3 else 1.15) else Vector3.ZERO
 if room_monster and desired.length()>0.1:
  var steered=Vector3.ZERO
  for angle in [0.0,0.65,-0.65,1.15,-1.15,1.6,-1.6]:
   var trial=desired.rotated(Vector3.UP,angle)
   if not data.actor.test_move(data.actor.global_transform,trial.normalized()*0.5+Vector3(0,0.04,0)):
    steered=trial;break
  desired=steered
 # Queue behind the other creature instead of pushing it into the player or walls.
 for index in enemies.TUNNEL_INDICES:
  var other=enemies.creatures[index]
  if index==data.index or other.hp<=0:continue
  var offset:Vector3=other.actor.global_position-data.actor.global_position;offset.y=0
  if offset.length()<1.0 and desired.dot(offset.normalized())>0.4:desired=Vector3.ZERO
 enemies.play(data,"walk1" if desired.length()>0.1 else "idle1")
 data.animation.speed_scale=0.9 if desired.length()>0.1 else 1.0
 enemies.house_encounter.move(data,desired,delta)
