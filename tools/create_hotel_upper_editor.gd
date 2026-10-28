extends SceneTree
func _initialize():call_deferred("run")
func strip(node:Node):
 node.set_script(null);node.scene_file_path=""
 for child in node.get_children():strip(child)
func own_all(node:Node,scene:Node):
 for child in node.get_children():child.owner=scene;own_all(child,scene)
func run():
 var path="res://editing/hotel_second_floor_layout.tscn"
 if FileAccess.file_exists(path):print("Keeping existing second-floor edits");quit();return
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 var h=g.hotel_upper;h.set_physics_process(false)
 var scene=Node3D.new();scene.name="HotelSecondFloorLayout";root.add_child(scene)
 var shell=Node3D.new();shell.name="BuildingShell_REFERENCE";shell.set_meta("_edit_lock_",true);scene.add_child(shell)
 var furniture=Node3D.new();furniture.name="Furniture";scene.add_child(furniture)
 var pickups=Node3D.new();pickups.name="Pickups";scene.add_child(pickups)
 var count=0
 for scope in ["hotel","upper"]:
  var parent=g.town.buildings.house if scope=="hotel" else h
  for n in parent.get_children():
   if not n is Node3D or not n.visible:continue
   var editable=n.name in g.hotel_upper_layout.ORIGINALS if scope=="hotel" else n.has_meta("upper_furniture")
   if editable:
    var clone=n.duplicate(0);strip(clone);furniture.add_child(clone);clone.position.y-=h.UPPER
    var asset=str(n.get_meta("upper_furniture",n.get_meta("apartment_asset",n.name)))
    clone.name=("Room201_" if scope=="hotel" else "GuestRoom_")+asset.capitalize().replace(" ","_")+"_%02d"%count
    clone.set_meta("_edit_group_",true);clone.set_meta("runtime_scope",scope);clone.set_meta("runtime_index",n.get_index());clone.set_meta("runtime_name",str(n.name))
    count+=1
   elif scope=="upper":
    if n is AudioStreamPlayer3D or n==h.cab or n.position.y>=7:continue
    var bounds=g.surface_details.bounds_of(n)
    if bounds.end.y<h.UPPER-.15:continue
    var clone=n.duplicate(0);strip(clone);shell.add_child(clone);clone.position.y-=h.UPPER;clone.set_meta("_edit_lock_",true)
 for id in ["shotgun_key","medkit_c"]:
  var clone=g.town.actions[id].area.duplicate(0);strip(clone);pickups.add_child(clone);clone.position.y-=h.UPPER;clone.show();clone.set_meta("_edit_group_",true)
 var environment=WorldEnvironment.new();environment.name="EditorLighting";environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("30383e");environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("d0d4cf");environment.environment.ambient_light_energy=.8;scene.add_child(environment)
 var sun=DirectionalLight3D.new();sun.name="EditorLight";sun.rotation_degrees=Vector3(-60,-25,0);sun.light_energy=.8;scene.add_child(sun)
 own_all(scene,scene);var packed=PackedScene.new();assert(packed.pack(scene)==OK);assert(ResourceSaver.save(packed,path)==OK)
 print("PASS: second-floor editor created with ",count," movable furniture roots, pickups and locked cutaway shell")
 scene.free();g.queue_free();await process_frame;quit()
