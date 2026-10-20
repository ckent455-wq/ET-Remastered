extends Node
## Three-slot save/load menu; the underlying journey stays paused.
var game
var backend
var panel:Panel
var heading:Label
var status:Label
var slot_buttons:Array[Button]=[]
var save_button:Button
var load_button:Button
var back_button:Button
var death_load:Button
var selected=1
var origin="title"
var confirmation=""
var load_only=false
func _ready():
 backend=preload("res://save_game.gd").new();backend.game=game;add_child(backend)
 panel=Panel.new();panel.position=Vector2(52,32);panel.size=Vector2(536,338);panel.z_index=110;panel.mouse_filter=Control.MOUSE_FILTER_STOP
 var style=StyleBoxFlat.new();style.bg_color=Color("101918");style.border_color=Color("8a8771");style.set_border_width_all(2);panel.add_theme_stylebox_override("panel",style);game.hud.add_child(panel)
 heading=label("",Vector2(22,16),20,Vector2(490,28))
 label("BLACKWOOD / FIELD RECORDS",Vector2(22,44),11,Vector2(490,20))
 for i in range(3):
  var button=make_button("",Vector2(22,76+i*54),Vector2(492,48),func():select(i+1))
  button.alignment=HORIZONTAL_ALIGNMENT_LEFT;slot_buttons.append(button)
 status=label("",Vector2(22,241),12,Vector2(492,39));status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 save_button=make_button("SAVE",Vector2(22,289),Vector2(150,30),save_selected)
 load_button=make_button("LOAD",Vector2(181,289),Vector2(150,30),load_selected)
 back_button=make_button("BACK",Vector2(340,289),Vector2(174,30),close)
 death_load=make_button("LOAD JOURNEY",Vector2(220,244),Vector2(200,34),func():open(true))
 death_load.reparent(game.hud,false);death_load.z_index=10;death_load.hide()
 panel.hide()
func _process(_delta):
 death_load.visible=game.state=="lost" and not opened()
func label(value:String,p:Vector2,font_size:int,size:Vector2)->Label:
 var item=Label.new();item.text=value;item.position=p;item.size=size;item.add_theme_font_override("font",preload("res://assets/font.ttf"));item.add_theme_font_size_override("font_size",font_size);item.add_theme_color_override("font_color",Color("d6d3bc"));panel.add_child(item);return item
func make_button(value:String,p:Vector2,size:Vector2,callback:Callable)->Button:
 var button=Button.new();button.text=value;button.position=p;button.size=size;button.add_theme_font_override("font",preload("res://assets/font.ttf"));button.add_theme_font_size_override("font_size",13)
 for state in ["normal","hover","pressed","focus"]:
  var style=StyleBoxFlat.new();style.bg_color=Color("28352e") if state!="normal" else Color("18231f");style.border_color=Color("c3a777") if state!="normal" else Color("626c5b");style.set_border_width_all(1);button.add_theme_stylebox_override(state,style)
 button.add_theme_color_override("font_color",Color("ded9c1"));button.pressed.connect(callback);panel.add_child(button);return button
func opened()->bool:return panel!=null and panel.visible
func open(only_load=false):
 if game.state not in ["paused","title","lost"]:return
 origin=game.state;load_only=only_load or origin in ["title","lost"];confirmation="";panel.show();refresh();slot_buttons[selected-1].grab_focus()
func close():
 confirmation="";panel.hide();game.hud._process(0)
 if game.state=="title":game.hud.menu_buttons[5].grab_focus()
 elif game.state=="paused":game.hud.pause_buttons[4].grab_focus()
 elif game.state=="lost":death_load.grab_focus()
func select(slot:int):
 selected=slot;confirmation="";refresh()
func buttons()->Array:
 var result:Array=[]
 for button in slot_buttons+[save_button,load_button,back_button]:
  if button.visible and not button.disabled:result.append(button)
 return result
func refresh(message=""):
 heading.text="LOAD JOURNEY" if load_only else "SAVE / LOAD JOURNEY"
 for i in range(3):
  var data=backend.read_slot(i+1);var name="EMPTY SLOT"
  if not data.is_empty():name="%s  |  HEALTH %d%%\n%s%s" % [data.location,int(data.health),data.date,"  / BACKUP" if data.get("recovered",false) else ""]
  elif FileAccess.file_exists(backend.path(i+1)):name="DAMAGED OR INCOMPATIBLE SAVE"
  slot_buttons[i].text=("> " if i+1==selected else "  ")+"SLOT %d  /  " % (i+1)+name
 var data=backend.read_slot(selected)
 save_button.visible=not load_only;save_button.disabled=backend.blocked_reason()!=""
 load_button.disabled=data.is_empty()
 if message!="":status.text=message
 elif not load_only and save_button.disabled:status.text=backend.blocked_reason()
 elif data.get("recovered",false):status.text="Primary save unavailable. A verified backup can be loaded."
 else:status.text="Choose a slot. Saved journeys include equipment, quests and the world."
func save_selected():
 if load_only or backend.blocked_reason()!="":refresh(backend.blocked_reason());return
 var occupied=FileAccess.file_exists(backend.path(selected)) or FileAccess.file_exists(backend.path(selected)+".bak")
 if occupied and confirmation!="save":confirmation="save";refresh("Replace slot %d? Press SAVE again to confirm. BACK cancels." % selected);return
 confirmation=""
 if backend.save_slot(selected):refresh("Journey saved to slot %d." % selected)
 else:refresh(backend.error)
func load_selected():
 if backend.read_slot(selected).is_empty():refresh("This slot has no usable save.");return
 if origin=="paused" and confirmation!="load":confirmation="load";refresh("Load slot %d and replace this unsaved journey? Press LOAD again." % selected);return
 confirmation=""
 if backend.load_slot(selected):panel.hide()
 else:refresh(backend.error)
func _input(event):
 if not opened() or not event is InputEventKey or not event.pressed or event.echo:return
 if event.keycode==KEY_ESCAPE:close()
 elif event.keycode in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_TAB]:
  var list=buttons();var step=-1 if event.keycode in [KEY_UP,KEY_LEFT] or (event.keycode==KEY_TAB and event.shift_pressed) else 1
  list[wrapi(list.find(get_viewport().gui_get_focus_owner())+step,0,list.size())].grab_focus()
 elif event.keycode in [KEY_ENTER,KEY_SPACE,KEY_E]:
  var focus=get_viewport().gui_get_focus_owner()
  if focus is Button and focus in buttons():focus.pressed.emit()
 else:return
 get_viewport().set_input_as_handled()
