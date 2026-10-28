extends Control
## Compact quest reminders; checks follow actual progress, not changed wording.
const FONT=preload("res://assets/font.ttf")
const HOLD=1.6
var game
var current={}
var completed=false
var remaining=0.0
var gap=0.0
func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE
func reset():
 current={};completed=false;remaining=0;gap=0;hide();queue_redraw()
func task(id:String,title:String)->Dictionary:return {"id":id,"title":title}
func goal()->Dictionary:
 var t=game.town;var e=game.enemies;var car=game.crash_site
 var panel=t.actions.battery_panel.area.get_node("HighVoltageTerminal")
 if not game.story.clinic_rescue_done:
  return task("leave_car","Get out of the wrecked car.") if car.wake_phase!="" else task("find_help","Follow Old Mill Road toward town for help.")
 if not car.has_backpack:return task("backpack","Retrieve your backpack from the car trunk.")
 if not car.has_flashlight:return task("flashlight","Collect your flashlight from the trunk.")
 if t.radio_ready:
  if not game.story.repeater_is_off():return task("repeater","Shut down the chapel's MAIN ISOLATOR.")
  if not game.story.direct_channel_selected():return task("bypass","Set the station bypass to GREEN.")
  return task("call","Call county dispatch on the station radio.")
 if not t.reached_town:return task("town","Reach Blackwood.")
 if t.needs_workshop_introduction():return task("john","Ask John at the workshop about the radio.")
 if not t.powered:
  if panel.installed:return task("switch","Flip the rear workshop power switch.")
  if t.inventory.workshop_fuse>0:return task("install_fuse","Fit the fuse in the rear workshop cabinet.")
  if t.inventory.station_key==0:return task("station_key","Take the station key from Pat's desk drawer.")
  return task("fuse","Find the fuse in the general store's counter drawer.")
 if e.workshop_danger() and e.creatures[e.WORKSHOP_INDEX].state=="ambush_wait":return task("alley_return","Return through the alley to Main Street.")
 if t.inventory.coil==0:return task("coil","Take the signal coil from the workshop cabinet.")
 if t.inventory.station_key==0:return task("station_key","Take the station key from Pat's desk drawer.")
 if not t.cemetery.unlocked:
  if t.inventory.mausoleum_key==0:return task("vault_key","Get the mausoleum key from Pat's desk." if t.townspeople.characters.ranger.dead else "Ask Pat for the mausoleum key.")
  return task("vault_door","Unlock the Whitcomb mausoleum.")
 if t.inventory.antenna==0:return task("coupler","Recover the coupler inside the mausoleum.")
 var basement=t.streetscape.church.basement
 if t.inventory.chapel_key==0 and not basement.unlocked:return task("chapel_key","Find the cellar key at the tunnel's far end.")
 if not basement.unlocked:return task("chapel_door","Unlock the chapel cellar.")
 if t.inventory.tuner==0:return task("tuner","Recover the tuning unit in the chapel cellar.")
 if not game.story.repeater_is_off():return task("repeater","Shut down the chapel's MAIN ISOLATOR.")
 return task("repair","Fit the three radio parts in the station receiver.")
func achieved(id:String)->bool:
 var t=game.town;var car=game.crash_site
 var panel=t.actions.battery_panel.area.get_node("HighVoltageTerminal")
 match id:
  "leave_car":return car.wake_phase=="" and not game.camera.top_level
  "find_help":return game.story.clinic_rescue_done
  "backpack":return car.has_backpack
  "flashlight":return car.has_flashlight
  "town":return t.reached_town
  "john":return t.townspeople.conversation.greetings.has("mechanic")
  "station_key":return t.inventory.station_key>0
  "fuse":return t.inventory.workshop_fuse>0 or panel.installed or t.powered
  "install_fuse":return panel.installed or t.powered
  "switch":return t.powered
  "alley_return":return game.player.global_position.x<=7.2
  "coil":return t.inventory.coil>0 or t.radio_ready
  "vault_key":return t.inventory.mausoleum_key>0 or t.cemetery.unlocked
  "vault_door":return t.cemetery.unlocked
  "coupler":return t.inventory.antenna>0 or t.radio_ready
  "chapel_key":return t.inventory.chapel_key>0 or t.streetscape.church.basement.unlocked
  "chapel_door":return t.streetscape.church.basement.unlocked
  "tuner":return t.inventory.tuner>0 or t.radio_ready
  "repeater":return game.story.repeater_is_off()
  "repair":return t.radio_ready
  "bypass":return game.story.direct_channel_selected()
  "call":return game.state=="won"
 return false
func _process(delta):update_reminder(delta)
func update_reminder(delta:float):
 if game.state in ["intro","title"] or (game.testing_mode and game.testing_mode.enabled):reset();return
 var playing=game.state=="play"
 if gap>0:
  if playing:gap=maxf(0,gap-delta)
  hide();return
 var next=goal()
 if current.is_empty():current=next
 if not completed:
  if achieved(current.id):completed=true;remaining=HOLD
  elif next.id!=current.id:current=next
 elif playing:
  remaining=maxf(0,remaining-delta)
  if remaining==0:current={};completed=false;gap=0.18;hide();return
 visible=playing
 queue_redraw()
func lines(value:String)->Array[String]:
 var result:Array[String]=[];var line=""
 for word in value.split(" "):
  var candidate=word if line=="" else line+" "+word
  if FONT.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x>265 and line!="":result.append(line);line=word
  else:line=candidate
 if line!="":result.append(line)
 return result
func _draw():
 if current.is_empty():return
 var alpha=clampf(remaining/0.45,0,1) if completed else 1.0
 var ink=Color("b8d6af") if completed else Color("d2dfd0");ink.a=alpha
 draw_rect(Rect2(16,290,304,45),Color(0.025,0.035,0.03,0.88*alpha))
 draw_rect(Rect2(16,290,2,45),ink)
 draw_string(FONT,Vector2(26,302),"OBJECTIVE COMPLETE" if completed else "CURRENT OBJECTIVE",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color(0.58,0.65,0.60,alpha))
 draw_rect(Rect2(26,310,9,9),ink,false,1)
 if completed:draw_polyline(PackedVector2Array([Vector2(27,314),Vector2(30,317),Vector2(36,309)]),ink,1.5)
 var wrapped=lines(current.title)
 for i in mini(2,wrapped.size()):draw_string(FONT,Vector2(43,318+i*14),wrapped[i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
