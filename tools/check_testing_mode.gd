extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false)
 await process_frame
 var m=g.testing_mode
 assert(not m.enabled and not m.badge.visible)
 var inventory=g.town.inventory.duplicate(true)
 var e=InputEventKey.new();e.keycode=KEY_F10;e.pressed=true
 m._input(e)
 assert(m.enabled and g.state=="play" and g.crash_site.wake_phase=="")
 assert(g.weapons.owned==[true,true,true] and g.crash_site.has_flashlight)
 assert(g.town.inventory.workshop_fuse==1 and g.town.inventory.shovel==1)
 assert(g.town.cemetery.unlocked and g.town.streetscape.church.basement.unlocked and g.hotel_basement.hotel_unlocked)
 assert(g.backpack.room_for("coil",100),"Testing bypasses inventory capacity")
 assert(not g.take_damage(200) and g.health==100)
 g.weapons.magazines[0]=0;g.stamina=0;g.flashlight_charge=0;m._process(1)
 assert(g.weapons.magazines[0]==8 and g.stamina==100 and g.flashlight_charge==100)
 e.echo=true;m._input(e);assert(m.enabled,"Key repeat cannot flicker toggle")
 g.set_state("backpack");g.backpack.queue_redraw();await process_frame
 var select=InputEventKey.new();select.keycode=KEY_3;select.pressed=true;g.backpack.handle(select)
 assert(g.state=="play" and g.weapons.selected==2,"Testing inventory weapon shortcut")
 g.set_state("backpack")
 e.echo=false;m._input(e)
 assert(not m.enabled and not m.badge.visible and g.town.inventory==inventory)
 assert(g.weapons.owned==[false,false,false] and g.weapons.selected==-1)
 assert(not g.crash_site.has_flashlight and not g.town.cemetery.unlocked and not g.hotel_basement.hotel_unlocked)
 assert(not g.backpack.room_for("coil",100),"Normal bag limits restored")
 g.state="play";assert(g.take_damage(10) and g.health==90,"Damage restored")
 g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true
 g.town.inventory.medkit=1;g.weapons.owned[0]=true;g.weapons.magazines[0]=3;g.weapons.reserves[0]=6;g.weapons.equip(0)
 m.begin();g.set_state("paused");g.hud.pause_buttons[2].pressed.emit()
 assert(not m.enabled and g.state=="paused" and g.weapons.owned==[true,false,false])
 assert(g.weapons.magazines[0]==3 and g.weapons.reserves[0]==6 and g.health==90 and g.town.inventory.medkit==1)
 m.begin();g.reset_game()
 assert(not m.enabled and g.weapons.owned==[false,false,false] and g.town.inventory.medkit==0,"New journey defaults to normal")
 print("PASS: F10 and pause button, skipped intro, gear/keys, bag bypass and readable inventory, immunity, refills, echo suppression, original loadout restoration, normal damage/capacity and reset")
 quit()
