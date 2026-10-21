extends Node
## Session-only testing equipment. Original loadout is restored when disabled.
var game
var enabled = false
var saved = {}
var badge: Label
func _ready():
 name="TestingMode"
 var layer=CanvasLayer.new();layer.layer=90;add_child(layer)
 badge=Label.new();badge.position=Vector2(10,8)
 badge.text="TEST MODE  /  F10 OFF  /  ALL GEAR + INFINITE SUPPLIES"
 badge.add_theme_font_size_override("font_size",12)
 badge.modulate=Color("efc58c");badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
 layer.add_child(badge);badge.hide()
func _input(event):
 if game.saves and game.saves.opened():return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F10:
  toggle();get_viewport().set_input_as_handled()
func toggle():
 if enabled: finish(true)
 else: begin()
func begin():
 if enabled:return
 if game.state in ["won","lost"]:game.reset_game()
 var w=game.weapons
 saved={"inventory":game.town.inventory.duplicate(true),"owned":w.owned.duplicate(),"magazines":w.magazines.duplicate(),"reserves":w.reserves.duplicate(),"selected":w.selected,"health":game.health,"stamina":game.stamina,"charge":game.flashlight_charge,"light":game.flashlight.visible,"gear":[game.crash_site.has_backpack,game.crash_site.has_flashlight,game.crash_site.has_detour_sheet],"cells":game.backpack.saved_cells.duplicate(true),"rotations":game.backpack.saved_rotations.duplicate(true),"locks":[game.town.cemetery.unlocked,game.town.streetscape.church.basement.unlocked,w.lockbox.unlocked,game.hotel_basement.hotel_unlocked],"actions":{},"containers":{}}
 for id in game.town.actions:
  var data=game.town.actions[id]
  if data.kind in ["item","weapon","ammo","cellar_part"]:
   saved.actions[id]={"taken":data.taken,"visible":data.area.visible,"layer":data.area.collision_layer,"disabled":data.area.get_child(0).disabled,"amount":data.get("amount",0)}
 for id in game.town.interiors.containers:saved.containers[id]=game.town.interiors.containers[id].searched
 enabled=true;badge.show()
 game.crash_site.leave_seat_for_testing()
 game.crash_site.wake_phase=""
 game.crash_site.has_backpack=true;game.crash_site.has_flashlight=true;game.crash_site.has_detour_sheet=true
 game.crash_site.bag_visual.hide();game.crash_site.light_visual.hide();game.crash_site.detour_visual.hide()
 for id in game.crash_site.tutorial_areas:
  game.crash_site.tutorial_areas[id].collision_layer=2 if id in ["crash_driver_door","crash_rear_hatch"] else 0
 game.crash_site.update_hatch_target()
 for id in game.town.inventory:
  if id!="ada_letter":game.town.inventory[id]=maxi(game.town.inventory[id],1)
 for i in range(3):
  w.owned[i]=true;w.magazines[i]=w.LOADOUT[i].clip;w.reserves[i]=w.LOADOUT[i].max_reserve
 game.town.cemetery.unlocked=true
 game.town.streetscape.church.basement.unlocked=true;game.town.streetscape.church.basement.padlock.hide()
 w.lockbox.unlocked=true;w.lockbox.latch.hide();game.hotel_basement.hotel_unlocked=true
 if game.state in ["intro","title","waking"]:
  game.camera.position=Vector3(0,game.STANDING_EYE,0);game.camera.rotation=Vector3.ZERO;game.pitch=0
  game.set_state("play")
 w.equip(0)
 game.flashlight.visible=not game.flashlight_fault_active()
 replenish()
 game.message="Testing ON. All equipment and keys; unlimited health, ammo and light. F10 turns it off."
func replenish():
 game.health=100;game.stamina=100;game.flashlight_charge=100
 game.town.inventory.medkit=maxi(game.town.inventory.medkit,1)
 game.town.inventory.battery=maxi(game.town.inventory.battery,1)
 for i in range(3):
  game.weapons.magazines[i]=game.weapons.LOADOUT[i].clip
  game.weapons.reserves[i]=game.weapons.LOADOUT[i].max_reserve
func _process(_delta):
 badge.visible=enabled and game.state!="backpack"
 if enabled and game.state=="play":replenish()
func finish(restore=true):
 if not enabled:return
 enabled=false;badge.hide()
 if not restore:
  saved.clear();return
 var w=game.weapons
 game.town.inventory=saved.inventory.duplicate(true)
 w.owned.assign(saved.owned);w.magazines.assign(saved.magazines);w.reserves.assign(saved.reserves)
 w.selected=saved.selected;w.reload_remaining=0;w.delay=0;w.flash_remaining=0
 w.melee.raised=false;w.melee.cancel();w.update_model(1)
 game.soundscape.weapon_stop_reload()
 game.health=saved.health;game.stamina=saved.stamina;game.flashlight_charge=saved.charge;game.flashlight.visible=saved.light and not game.flashlight_fault_active();game.invincible=0
 game.crash_site.has_backpack=saved.gear[0];game.crash_site.has_flashlight=saved.gear[1];game.crash_site.has_detour_sheet=saved.gear[2]
 game.crash_site.bag_visual.visible=not saved.gear[0];game.crash_site.light_visual.visible=not saved.gear[1];game.crash_site.detour_visual.visible=not saved.gear[2]
 game.crash_site.update_door_target()
 game.crash_site.update_hatch_target()
 game.crash_site.update_item_targets()
 game.backpack.saved_rotations=saved.rotations.duplicate(true)
 game.backpack.saved_cells=saved.cells.duplicate(true);game.backpack.dragging=""
 game.town.cemetery.unlocked=saved.locks[0]
 game.town.streetscape.church.basement.unlocked=saved.locks[1];game.town.streetscape.church.basement.padlock.visible=not saved.locks[1]
 w.lockbox.unlocked=saved.locks[2];w.lockbox.latch.visible=not saved.locks[2]
 game.hotel_basement.hotel_unlocked=saved.locks[3]
 for id in saved.actions:
  var data=game.town.actions[id];var old=saved.actions[id]
  data.taken=old.taken;data.area.visible=old.visible;data.area.collision_layer=old.layer
  data.area.get_child(0).set_deferred("disabled",old.disabled)
  if data.has("amount"):data.amount=old.amount
 for id in saved.containers:game.town.interiors.containers[id].searched=saved.containers[id]
 saved.clear()
 game.message="Testing OFF. Original equipment and normal limits restored. World events are not rewound."
