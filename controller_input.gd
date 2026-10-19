extends Node
## Standard SDL/Godot gamepad layout with input-aware prompts and menu navigation.
var game
var using_controller=false
var device=-1
var family="xbox"
var axes={}
var held={}
var nav_wait=0.0
const DEADZONE=0.22
func _ready():
 name="ControllerInput"
 Input.joy_connection_changed.connect(connection_changed)
func connection_changed(id:int,connected:bool):
 if not connected and id==device:
  axes.clear()
  held.clear()
  using_controller=false
  device=-1
  if game.state=="play":game.set_state("paused")
func activate(id:int):
 if id!=device:
  axes.clear()
  held.clear()
  device=id
 var title=Input.get_joy_name(id).to_lower()
 family="playstation" if "sony" in title or "dual" in title or "playstation" in title or "ps4" in title or "ps5" in title else ("nintendo" if "nintendo" in title or "switch" in title else "xbox")
 using_controller=true
func _input(event):
 if event is InputEventJoypadMotion:
  if absf(event.axis_value)>DEADZONE:activate(event.device)
  if event.device==device:axes[event.axis]=event.axis_value
  get_viewport().set_input_as_handled()
 elif event is InputEventJoypadButton:
  if event.pressed:activate(event.device)
  if event.device==device:
   held[event.button_index]=event.pressed
   if event.pressed:
    button(event.button_index)
    nav_wait=0.28
  get_viewport().set_input_as_handled()
 elif (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed) or (event is InputEventMouseMotion and event.relative.length()>2):
  using_controller=false
func stick(x:int,y:int)->Vector2:
 var value=Vector2(axes.get(x,0.0),axes.get(y,0.0))
 var strength=value.length()
 if not using_controller or strength<=DEADZONE:return Vector2.ZERO
 return value.normalized()*clampf((strength-DEADZONE)/(1-DEADZONE),0,1)
func movement()->Vector2:return stick(JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y)
func down(button_id:int)->bool:return using_controller and held.get(button_id,false)
func aiming()->bool:return using_controller and axes.get(JOY_AXIS_TRIGGER_LEFT,0.0)>0.35
func interact_held()->bool:return down(JOY_BUTTON_X)
func send_key(key:int):
 var event=InputEventKey.new()
 event.keycode=key
 event.pressed=true
 game._unhandled_input(event)
func direction(button_id:int)->Vector2i:
 return {JOY_BUTTON_DPAD_LEFT:Vector2i.LEFT,JOY_BUTTON_DPAD_RIGHT:Vector2i.RIGHT,JOY_BUTTON_DPAD_UP:Vector2i.UP,JOY_BUTTON_DPAD_DOWN:Vector2i.DOWN}.get(button_id,Vector2i.ZERO)
func button(id:int):
 var state=game.state
 if state in ["title","paused"]:
  if id==JOY_BUTTON_START and state=="paused":game.set_state("play");return
  if id==JOY_BUTTON_B:
   if state=="paused":game.set_state("play")
   else:game.hud.controls_open=false
  elif id==JOY_BUTTON_A or id==JOY_BUTTON_X:
   var focus=get_viewport().gui_get_focus_owner()
   if focus is Button and focus.is_visible_in_tree():focus.pressed.emit()
   else:
    if state=="title":game.hud.begin_game()
    else:game.set_state("play")
  elif direction(id)!=Vector2i.ZERO:menu_move(1 if id in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_RIGHT] else -1)
  return
 if state=="backpack":
  game.backpack.controller_button(id)
  return
 if state=="journal":
  if id in [JOY_BUTTON_B,JOY_BUTTON_START,JOY_BUTTON_DPAD_UP]:send_key(KEY_ESCAPE)
  elif id==JOY_BUTTON_BACK:send_key(KEY_I)
  elif id in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_DPAD_LEFT]:send_key(KEY_LEFT)
  elif id in [JOY_BUTTON_RIGHT_SHOULDER,JOY_BUTTON_DPAD_RIGHT]:send_key(KEY_RIGHT)
  elif id==JOY_BUTTON_Y:send_key(KEY_C)
  return
 if state=="dialogue":
  if id in [JOY_BUTTON_A,JOY_BUTTON_X]:send_key(KEY_E)
  elif id in [JOY_BUTTON_B,JOY_BUTTON_START]:send_key(KEY_ESCAPE)
  return
 if state=="waking":
  if id==JOY_BUTTON_X:send_key(KEY_E)
  elif id==JOY_BUTTON_START:send_key(KEY_ESCAPE)
  return
 if state in ["intro","won","lost"]:
  if id in [JOY_BUTTON_A,JOY_BUTTON_X,JOY_BUTTON_START]:send_key(KEY_ENTER)
  return
 if state!="play":return
 var mapping={JOY_BUTTON_A:KEY_SPACE,JOY_BUTTON_X:KEY_E,JOY_BUTTON_Y:KEY_R,JOY_BUTTON_DPAD_DOWN:KEY_F,JOY_BUTTON_DPAD_UP:KEY_TAB,JOY_BUTTON_DPAD_LEFT:KEY_H,JOY_BUTTON_DPAD_RIGHT:KEY_Q,JOY_BUTTON_BACK:KEY_I,JOY_BUTTON_START:KEY_ESCAPE,JOY_BUTTON_RIGHT_STICK:KEY_0}
 if mapping.has(id):send_key(mapping[id])
 elif id==JOY_BUTTON_LEFT_SHOULDER:game.weapons.cycle(-1)
 elif id==JOY_BUTTON_RIGHT_SHOULDER:game.weapons.cycle(1)
func menu_move(step:int):
 var buttons=[]
 if game.state=="title":
  for b in game.hud.menu_buttons:
   if b.is_visible_in_tree():buttons.append(b)
 elif game.state=="paused":buttons=game.hud.pause_buttons
 if buttons.is_empty():return
 var current=buttons.find(get_viewport().gui_get_focus_owner())
 buttons[wrapi(current+step,0,buttons.size())].grab_focus()
func _process(delta):
 if not using_controller:return
 nav_wait=maxf(0,nav_wait-delta)
 if game.state=="play":
  var look=stick(JOY_AXIS_RIGHT_X,JOY_AXIS_RIGHT_Y)
  var rate=1.55 if aiming() else 2.25
  game.player.rotate_y(-look.x*rate*delta)
  game.pitch=clampf(game.pitch-look.y*rate*delta,-1.35,1.35)
  game.camera.rotation.x=game.pitch
  if axes.get(JOY_AXIS_TRIGGER_RIGHT,0.0)>0.35:game.weapons.fire()
 elif game.state in ["title","paused","backpack","journal"] and nav_wait<=0:
  var v=movement()
  for id in [JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]:
   if down(id):v=Vector2(direction(id));break
  if v.length()>0.6:
   var d=Vector2i(signi(int(signf(v.x))),0) if absf(v.x)>absf(v.y) else Vector2i(0,signi(int(signf(v.y))))
   if game.state=="backpack":game.backpack.controller_move(d)
   elif game.state=="journal":send_key(KEY_LEFT if d.x<0 or d.y<0 else KEY_RIGHT)
   else:menu_move(-1 if d.x<0 or d.y<0 else 1)
   nav_wait=0.17
func label(token:String)->String:
 var values={"south":"A","east":"B","west":"X","north":"Y","lb":"LB","rb":"RB","lt":"LT","rt":"RT","view":"VIEW","start":"START"}
 if family=="playstation":values={"south":"CROSS","east":"CIRCLE","west":"SQUARE","north":"TRIANGLE","lb":"L1","rb":"R1","lt":"L2","rt":"R2","view":"TOUCHPAD","start":"OPTIONS"}
 elif family=="nintendo":values.merge({"south":"B","east":"A","west":"Y","north":"X"},true)
 return values.get(token,token)
func hint(value:String)->String:
 if not using_controller:return value
 if game.state=="journal" and "case notes" in value:
  return label("view")+"  Backpack   "+label("north")+"  Case notes   "+label("lb")+" / "+label("rb")+"  Pages   "+label("east")+"  Close"
 var map={"WASD":"LS","ARROWS":"D-PAD","MOUSE":"RS","SPACE":label("south"),"CTRL":label("east"),"SHIFT":"L3","LMB":label("rt"),"RMB":label("lt"),"ENTER":label("south"),"ESC":label("east"),"TAB":"D-PAD UP","E":label("west"),"F":"D-PAD DOWN","I":label("view"),"H":"D-PAD LEFT","Q":"D-PAD RIGHT","R":label("north"),"V":label("rb"),"0":"R3"}
 for key in ["WASD","MOUSE","SHIFT","SPACE","CTRL"]:value=value.replace(key,map[key])
 var regex=RegEx.new()
 regex.compile("\\b(WASD|ARROWS|MOUSE|SPACE|CTRL|SHIFT|LMB|RMB|ENTER|ESC|TAB|E|F|I|H|Q|R|V|0)\\b(?=\\s*(?:/|$)|\\s{2,})")
 var matches=regex.search_all(value)
 matches.reverse()
 for m in matches:value=value.substr(0,m.get_start())+map[m.get_string()]+value.substr(m.get_end())
 for key in ["E","F","I","H","Q","R"]:
  for prefix in ["Press ","press ","Hold ","hold ","with "]:value=value.replace(prefix+key+" ",prefix+map[key]+" ")
 return value
func control_rows()->Array:
 return ["LS  Move     RS  Look     L3  Sprint",label("south")+"  Jump     "+label("east")+" (hold)  Crouch",label("west")+"  Interact / talk / stand up",label("lt")+"  Aim     "+label("rt")+"  Fire     "+label("north")+"  Reload",label("lb")+" / "+label("rb")+"  Cycle weapons     R3  Holster","D-PAD DOWN  Flashlight     UP  Journal / map","D-PAD LEFT  First aid     RIGHT  Battery",label("view")+"  Backpack     "+label("start")+"  Pause"]
