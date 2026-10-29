extends RefCounted
## Pursuit memory expires out of sight; retreat uses the same physical routes.
const HIDE_SECONDS=20.0
func visible(e,data)->bool:
 var player:Vector3=e.game.player.global_position
 return data.actor.global_position.distance_to(player)<24.0 and space(e.game,data.actor.global_position)==space(e.game,player) and e.line_clear(data,player+Vector3.UP)
func forget(e,data):
 data.pursuing=false;data.state="returning_home";data.seen=false;data.memory=0.0
 data["hidden_time"]=0.0;data["portal_wait"]=0.0;data["stair_direction"]=""
 data["path"]=PackedVector3Array();data["path_timer"]=0.0
 data["special_effort"]=0.0;data["special_door"]=""
 data.target=e.to_global(data.spawn)
 data.voice.stop();e.door_encounter.clear_attempt(data)
func space(g,p:Vector3)->String:
 if g.victorian_house.cellar_contains(p):return "victorian"
 if g.hotel_basement.contains(p):return "hotel"
 if g.town.streetscape.church.basement.contains(p):return "chapel"
 return "surface"

func portal(g,room:String,leaving:bool)->Dictionary:
 var house=g.victorian_house;var hotel=g.hotel_basement;var church=g.town.streetscape.church
 if room=="victorian":
  var below=house.cellar.to_global(Vector3(0,0.55,3.3))
  var above=house.to_global(Vector3(1.5,house.FLOOR+0.02,-3.0))
  return {"point":below if leaving else above,"exit":above if leaving else house.cellar.to_global(Vector3(0,0.02,0.8)),"allowed":true}
 if room=="chapel":
  var below=church.basement.to_global(Vector3(0,0.02,4.4))
  var above=church.to_global(Vector3(3.25,0.02,-4.9))
  return {"point":below if leaving else above,"exit":above if leaving else church.basement.to_global(Vector3(0,0.02,1.5)),"allowed":church.basement.unlocked}
 if hotel.hotel_unlocked:
  var below=hotel.to_global(Vector3(0,0.02,3.5))
  var above=g.town.buildings.house.to_global(Vector3(-0.4,0.05,-3.5))
  return {"point":below if leaving else above,"exit":above if leaving else below,"allowed":true}
 var crypt=g.town.cemetery.crypt
 var below=hotel.to_global(Vector3(0,0.02,-28.5))
 var above=crypt.to_global(Vector3(-0.65,0.05,-0.75))
 return {"point":below if leaving else above,"exit":above if leaving else below,"allowed":g.town.cemetery.unlocked}

func stair_goal(g,data,target:Vector3)->Vector3:
 var house=g.victorian_house
 var here:Vector3=house.to_local(data.actor.global_position)
 var there:Vector3=house.to_local(target)
 var actor_up=here.y>2.2 and absf(here.x)<5.2 and absf(here.z)<5.2
 var target_up=there.y>2.8 and absf(there.x)<5.2 and absf(there.z)<5.2
 if data.get("stair_direction","")=="" and actor_up!=target_up:
  data["stair_direction"]="down" if actor_up else "up";data["stair_step"]=0
 var direction=data.get("stair_direction","")
 if direction!="":
  var route=[Vector3(0,house.UPPER,-1.35),Vector3(2.1,house.UPPER,-3.85),Vector3(3.72,house.UPPER,-3.65),Vector3(3.72,house.FLOOR,3.45)]
  if direction=="up":route.reverse()
  var step=int(data.get("stair_step",0))
  var point:Vector3=house.to_global(route[step])
  if data.actor.global_position.distance_to(point)<0.65:
   step+=1;data.stair_step=step
   if step>=route.size():data.stair_direction="";return target
   point=house.to_global(route[step])
  return point
 if actor_up and target_up and ((here.z< -0.9 and there.z> -0.4) or (here.z> -0.4 and there.z< -0.9)):
  return house.to_global(Vector3(0,house.UPPER,-0.7))
 return target

func special_door(e,data,goal:Vector3,delta:float)->bool:
 var g=e.game;var church=g.town.streetscape.church;var crypt=g.town.cemetery
 var entries=[{"root":church,"z":6.95,"width":4.9,"open":church.doors_open,"allowed":not g.town.shelter_locks.get("chapel",false),"kind":"chapel"},{"root":crypt.crypt,"z":1.88,"width":1.5,"open":crypt.opened,"allowed":crypt.unlocked,"kind":"crypt"}]
 for i in g.hotel_upper.room_hinges.size():
  var frame:Node3D=g.hotel_upper.room_hinges[i].get_parent()
  if absf(frame.to_local(data.actor.global_position).y)>1.3:continue
  entries.append({"root":frame,"z":0.0,"width":1.5,"open":g.hotel_upper.room_open[i],"allowed":not g.town.shelter_locks.get("room_"+str(i),false),"kind":"room_"+str(i),"room_index":i})
 for entry in entries:
  var here:Vector3=entry.root.to_local(data.actor.global_position)
  var there:Vector3=entry.root.to_local(goal)
  if absf(here.y-there.y)>1.6:continue
  var a=absf(here.x)<entry.width and here.z<entry.z and here.z> -8.0
  var b=absf(there.x)<entry.width and there.z<entry.z and there.z> -8.0
  if a==b:continue
  var side= -1.0 if a else 1.0
  var approach:Vector3=entry.root.to_global(Vector3(0,here.y,entry.z+side*1.2))
  if data.actor.global_position.distance_to(approach)>9:
   walk(e,data,approach,delta);return true
  if entry.open:
   walk(e,data,entry.root.to_global(Vector3(0,here.y,entry.z-side*1.5)),delta)
   data["special_effort"]=0.0
  elif data.actor.global_position.distance_to(approach)>0.5:walk(e,data,approach,delta)
  else:
   e.move_creature(data,Vector3.ZERO,delta)
   if data.get("special_door","")!=entry.kind:
    data["special_effort"]=0.0;data["special_beat"]=0.0;data["special_door"]=entry.kind
   data["special_effort"]=data.get("special_effort",0.0)+delta
   data["special_beat"]=data.get("special_beat",0.0)-delta
   if data.special_beat<=0:
    e.door_encounter.pound(e,data,approach,e.is_mummy(data.index));data.special_beat=1.2
   if data.special_effort>=4 and entry.allowed:
    if entry.kind=="chapel":church.toggle_doors()
    elif entry.has("room_index"):g.hotel_upper.interact("hotel_room_door",g.town.actions["hotel_room_"+str(entry.room_index)])
    else:
     crypt.interact_door()
     if crypt.opened:g.message="Something forces the mausoleum door open."
    data.special_effort=0.0
  return true
 return false

func walk(e,data,target:Vector3,delta:float):
 var direction:Vector3=e.path_direction(data,target,delta)
 e.play(data,"walk1")
 data.animation.speed_scale=1.6
 var speed=1.25 if data.state=="returning_home" else 3.3 if e.is_mummy(data.index) else 3.0 if data.index==e.REAPER_INDEX else 2.8
 e.move_creature(data,direction*e.combat.movement(data)*speed,delta)

func update(e,data,delta:float)->bool:
 var g=e.game
 if data.hp<=0 or data.state in ["dormant","reaper_wait","reaper_warning","coffin_breakout"]:return false
 var retreating=data.state in ["returning_home","guarding_spawn"]
 if retreating:
  if visible(e,data):
   data.state="chase";data.pursuing=true;data["hidden_time"]=0.0;retreating=false
  elif data.state=="guarding_spawn":
   e.play(data,"idle1");e.move_creature(data,Vector3.ZERO,delta);return true
 if data.state in ["chase","house_rush","cellar_rush","tunnel_chase","reaper_chase","attack"]:data["pursuing"]=true
 if not data.get("pursuing",false) and not retreating:return false
 # Finish the authored reveal routes before taking over ordinary pursuit.
 if data.index==e.HOUSE_INDEX and data.get("house_waypoint",0)<2:return false
 if data.index==e.TUNNEL_INDICES[2] and data.get("tunnel_waypoint",0)<3 and space(g,g.player.global_position)=="hotel":return false
 if not retreating:
  if visible(e,data):
   data["hidden_time"]=0.0;data.target=g.player.global_position;data.seen=true
  else:
   data["hidden_time"]=data.get("hidden_time",0.0)+delta;data.seen=false
   if data.hidden_time>=HIDE_SECONDS:
    forget(e,data);retreating=true
  data.memory=maxf(0.0,HIDE_SECONDS-data.get("hidden_time",0.0))
 var destination:Vector3=e.to_global(data.spawn) if retreating else data.target
 if retreating and data.actor.global_position.distance_to(destination)<.65:
  data.state="guarding_spawn";e.door_encounter.clear_attempt(data)
  e.move_creature(data,Vector3.ZERO,delta);e.play(data,"idle1");return true
 data.timer=maxf(0,data.timer-delta);data.cooldown=maxf(0,data.cooldown-delta)
 if data.state=="stagger":
  e.move_creature(data,Vector3.ZERO,delta)
  if data.timer<=0:data.state="chase"
  return true
 if data.state=="attack":
  var forward:Vector3=g.player.global_position-data.actor.global_position
  forward.y=0
  # A short physical step during windup; attacks still require range and a clear ray.
  var step=forward.normalized()*1.8 if data.timer>0.70 and forward.length()>1.1 else Vector3.ZERO
  e.move_creature(data,step*e.combat.movement(data),delta)
  var mummy=e.is_mummy(data.index)
  if not data.did_hit and data.timer<(0.55 if mummy or data.index==e.REAPER_INDEX else 0.65):
   data.did_hit=true
   if data.actor.global_position.distance_to(g.player.global_position)<1.9 and e.line_clear(data,g.player.global_position+Vector3.UP):
    g.take_damage(25 if mummy else 26 if data.index==e.REAPER_INDEX else 24 if data.index==e.WORKSHOP_INDEX else 28)
  if data.timer<=0:data.state="chase";data.cooldown=0.55
  return true
 data.state="returning_home" if retreating else "chase"
 var here=space(g,data.actor.global_position);var there=space(g,destination)
 var target:Vector3=destination
 if here!=there:
  var edge=portal(g,here if here!="surface" else there,here!="surface")
  if not edge.allowed:e.move_creature(data,Vector3.ZERO,delta);return true
  target=edge.point
  if data.actor.global_position.distance_to(target)<1.0:
   data["portal_wait"]=data.get("portal_wait",0.0)+delta
   e.move_creature(data,Vector3.ZERO,delta)
   if data.portal_wait>=1.5 and edge.exit.distance_to(g.player.global_position)>1.15:
    g.soundscape.door_move(target,true)
    data.actor.global_position=edge.exit;data.actor.velocity=Vector3.ZERO
    data.portal_wait=0.0;data.stair_direction="";data.path=PackedVector3Array();data.path_timer=0.0
   return true
  data["portal_wait"]=0.0
 if here=="surface":
  target=stair_goal(g,data,target)
  # Aim for a building entrance before the final approach, even if it is far away.
  for id in g.town.doors:
   var building=g.town.buildings[id];var door=g.town.doors[id]
   var a:Vector3=building.to_local(data.actor.global_position);var b:Vector3=building.to_local(target)
   if absf(a.y)>1.3:continue
   var inside_a=absf(a.x)<5.4 and a.z> -5.2 and a.z<door.hinge.position.z
   var inside_b=absf(b.y)<1.3 and absf(b.x)<5.4 and b.z> -5.2 and b.z<door.hinge.position.z
   if inside_a!=inside_b:
    target=building.to_global(Vector3(0,a.y,door.hinge.position.z+(1.5 if inside_a else -1.5)));break
  if e.door_encounter.update(e,data,delta,target) or special_door(e,data,target,delta):return true
 if not retreating and here==there and data.actor.global_position.distance_to(g.player.global_position)<1.55 and data.cooldown<=0 and e.line_clear(data,g.player.global_position+Vector3.UP):
  data.state="attack";data.timer=0.9 if e.is_mummy(data.index) or data.index==e.REAPER_INDEX else 0.95;data.did_hit=false
  e.play(data,"punch");data.voice.stream=e.streams.attack;data.voice.play()
 else:walk(e,data,target,delta)
 return true
