extends SceneTree
func key(g,code):
 var e=InputEventKey.new();e.keycode=code;e.pressed=true;g._unhandled_input(e)
func mouse(b,p,pressed):
 var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=p;e.pressed=pressed;b.handle(e)
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false)
 g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.crash_site.has_flashlight=false
 for id in g.town.inventory:g.town.inventory[id]=0
 g.weapons.owned.assign([false,true,false]);g.weapons.reserves.assign([0,0,0]);g.weapons.selected=1
 g.weapons.magazines[1]=0;g.state="backpack"
 var b=g.backpack;b.set_process(false);b.saved_cells.clear();b.saved_rotations.clear()
 key(g,KEY_R)
 var entries=b.pack(b.counts());b.remember(entries)
 assert(entries[0].size==Vector2i(1,4) and entries[0].rotated)
 assert(g.weapons.reload_remaining==0,"Inventory R cannot reload gun")
 g.state="play";key(g,KEY_R)
 assert(g.weapons.reload_remaining==0,"No reserve ammo available")
 g.weapons.reserves[1]=5;key(g,KEY_R)
 assert(g.weapons.reload_remaining>0,"Gameplay R still reloads")
 g.weapons.reload_remaining=0;g.weapons.reserves[1]=0;g.state="backpack"
 g.town.inventory.medkit=1;b.saved_cells["medkit:0"]=Vector2i(1,0)
 key(g,KEY_R)
 assert(b.saved_rotations["gun1:0"],"Blocked in-place rotation preserves orientation")
 mouse(b,b.ORIGIN+Vector2(10,10),true)
 key(g,KEY_R)
 assert(b.held_size(b.pack(b.counts())[0])==Vector2i(4,1))
 mouse(b,b.ORIGIN+Vector2(5,3)*b.CELL,false)
 assert(b.saved_rotations["gun1:0"] and b.saved_cells["gun1:0"]==Vector2i.ZERO,"Invalid drag restores original footprint and cell")
 b.controller_button(JOY_BUTTON_X);b.controller_button(JOY_BUTTON_Y)
 assert(not b.drag_rotated)
 b.drag_mouse=b.ORIGIN+Vector2(1,2)*b.CELL;b.controller_button(JOY_BUTTON_X)
 assert(b.dragging=="" and not b.saved_rotations["gun1:0"])
 entries=b.pack(b.counts());assert(entries[0].size==Vector2i(4,1) and entries[0].cell==Vector2i(1,2))
 b.controller_button(JOY_BUTTON_X);b.controller_button(JOY_BUTTON_Y);b.controller_button(JOY_BUTTON_B)
 assert(not b.saved_rotations["gun1:0"],"Cancelled controller rotation is not committed")
 var data=g.saves.backend.capture()
 assert(data.rotations.has("gun1:0"))
 b.saved_rotations.clear();g.saves.backend.apply(data)
 assert(b.saved_rotations.has("gun1:0"),"Orientation restored from save")
 data.erase("rotations");g.saves.backend.apply(data)
 assert(b.saved_rotations.is_empty(),"Older saves default to unrotated")
 print("PASS: rotate footprints, collision rejection, mouse rollback, controller rotate/place/cancel, R reload separation, new/old save rotation")
 g.queue_free();await process_frame;quit()
func _initialize():call_deferred("run")
