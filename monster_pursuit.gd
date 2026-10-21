extends RefCounted
## A spotted player remains the target. Room portals use the same unlocked routes as the player.
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
 for entry in [{"root":church,"z":6.95,"width":4.9,"open":church.doors_open,"allowed":true,"kind":"chapel"},{"root":crypt.crypt,"z":1.88,"width":1.5,"open":crypt.opened,"allowed":crypt.unlocked,"kind":"crypt"}]:
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
    else:
     crypt.interact_door()
     if crypt.opened:g.message="Something forces the mausoleum door open."
    data.special_effort=0.0
  return true
 return false

func walk(e,data,target:Vector3,delta:float):
 var direction:Vector3=e.path_direction(data,target,delta)
 e.play(data,"walk1")
 data.animation.speed_scale=1.3
 e.move_creature(data,direction*(1.8 if e.is_mummy(data.index) or data.index==e.REAPER_INDEX else 2.05),delta)

func update(e,data,delta:float)->bool:
 var g=e.game
 if data.hp<=0 or data.state in ["dormant","reaper_wait","reaper_warning","coffin_breakout"]:return false
 if data.state in ["chase","house_rush","cellar_rush","tunnel_chase","reaper_chase","attack"]:data["pursuing"]=true
 if not data.get("pursuing",false):return false
 # Finish the authored reveal routes before taking over ordinary pursuit.
 if data.index==e.HOUSE_INDEX and data.get("house_waypoint",0)<2:return false
 if data.index==e.TUNNEL_INDICES[2] and data.get("tunnel_waypoint",0)<3 and space(g,g.player.global_position)=="hotel":return false
 data.target=g.player.global_position;data.memory=10.0
 data.timer=maxf(0,data.timer-delta);data.cooldown=maxf(0,data.cooldown-delta)
 if data.state=="stagger":
  e.move_creature(data,Vector3.ZERO,delta)
  if data.timer<=0:data.state="chase"
  return true
 if data.state=="attack":
  e.move_creature(data,Vector3.ZERO,delta)
  var mummy=e.is_mummy(data.index)
  if not data.did_hit and data.timer<(0.55 if mummy or data.index==e.REAPER_INDEX else 0.65):
   data.did_hit=true
   if data.actor.global_position.distance_to(g.player.global_position)<1.9 and e.line_clear(data,g.player.global_position+Vector3.UP):
    g.take_damage(25 if mummy else 26 if data.index==e.REAPER_INDEX else 24 if data.index==e.WORKSHOP_INDEX else 28)
  if data.timer<=0:data.state="chase";data.cooldown=1.0
  return true
 data.state="chase"
 var here=space(g,data.actor.global_position);var there=space(g,g.player.global_position)
 var target:Vector3=g.player.global_position
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
 if here==there and data.actor.global_position.distance_to(g.player.global_position)<1.55 and data.cooldown<=0 and e.line_clear(data,g.player.global_position+Vector3.UP):
  data.state="attack";data.timer=1.15 if e.is_mummy(data.index) or data.index==e.REAPER_INDEX else 1.45;data.did_hit=false
  e.play(data,"punch");data.voice.stream=e.streams.attack;data.voice.play()
 else:walk(e,data,target,delta)
 return true
