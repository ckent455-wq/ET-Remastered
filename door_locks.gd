extends RefCounted
## Inside bolts are separate from quest keys and never unlock a quest entrance.
func supported(data:Dictionary)->bool:
 return data.kind in ["door","chapel_door","hotel_room_door"]
func key(data:Dictionary)->String:
 if data.kind=="door":return str(data.building)
 if data.kind=="hotel_room_door":return "room_"+str(data.room_index)
 return "chapel"
func inside(town,data:Dictionary)->bool:
 var p=town.game.player.global_position
 if data.kind=="door":
  var local:Vector3=town.buildings[data.building].to_local(p)
  return absf(local.x)<5.4 and local.z> -5.2 and local.z<town.doors[data.building].hinge.position.z-.3 and absf(local.y)<1.3
 if data.kind=="chapel_door":
  var local:Vector3=town.streetscape.church.to_local(p)
  return absf(local.x)<4.9 and local.z> -8 and local.z<6.65 and absf(local.y)<1.3
 var frame:Node3D=town.game.hotel_upper.room_hinges[data.room_index].get_parent()
 var local:Vector3=frame.to_local(p)
 return local.z>.3 and absf(local.y)<1.5
func locked(town,data:Dictionary)->bool:
 return bool(town.shelter_locks.get(key(data),false))
func suffix(town,data:Dictionary)->String:
 if not supported(data) or not inside(town,data):return ""
 return "  |  L / "+("Unlock" if locked(town,data) else "Lock")
func toggle(town):
 town.refresh_focus()
 if town.focus_action=="":return
 var data:Dictionary=town.actions[town.focus_action]
 if not supported(data):return
 if not inside(town,data):
  town.game.message="You can only use the lock from inside."
  return
 if data.kind=="door" and not town.doors[data.building].get("unlocked",false):return
 var next=not locked(town,data)
 if next:
  if data.kind=="door":
   if not town.set_building_door(data.building,false,false,true):return
  elif data.kind=="chapel_door":
   if town.streetscape.church.doors_open:town.streetscape.church.toggle_doors()
  else:
   var hotel=town.game.hotel_upper
   if hotel.room_open[data.room_index]:town.game.soundscape.door_move(data.area.global_position,false)
   hotel.room_open[data.room_index]=false
   hotel.room_colliders[data.room_index].set_deferred("disabled",false)
 town.shelter_locks[key(data)]=next
 town.game.soundscape.deadbolt(data.area.global_position,next)
 town.game.message="Door locked from inside." if next else "Door unlocked."
func opening_allowed(town,data:Dictionary)->bool:
 if not locked(town,data):return true
 town.game.message="Unlock the inside bolt before opening the door." if inside(town,data) else "Door is locked from inside."
 return false
