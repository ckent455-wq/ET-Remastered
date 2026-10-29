extends SceneTree
func _initialize():call_deferred("run")
func strip(node:Node):
 node.set_script(null);node.scene_file_path=""
 for child in node.get_children():strip(child)
func own_all(node:Node,scene:Node):
 for child in node.get_children():child.owner=scene;own_all(child,scene)
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.enemies.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 var path="res://editing/hotel_layout.tscn";var scene=load(path).instantiate();root.add_child(scene)
 var shell=scene.get_node("RoomShell_REFERENCE");var furniture=scene.get_node("Furniture")
 var transforms={}
 for n in furniture.get_children():transforms[n.name]=n.transform
 # The moved bedroom remains mapped for compatibility, but is edited upstairs.
 for n in furniture.get_children():
  if str(n.get_meta("runtime_asset","")) in ["house_drawer","bed","wardrobe","dresser","books74","rug"] and int(n.get_meta("runtime_index",-1)) in [61,116,117,118,119,120]:
   n.hide();n.set_meta("_edit_lock_",true);n.set_meta("editor_description","Moved to floor 2. Edit this piece in hotel_second_floor_layout.tscn.")
 for n in shell.get_children():
  if not n is Node3D:continue
  if n.position.is_equal_approx(Vector3(-3.8,1.51,-.9)) or n.position.is_equal_approx(Vector3(-3.8,.12,-.815)) or n.name=="Abandoned_broken_chair":n.hide()
  if n.name in ["medkit_c","shotgun_key"]:n.hide()
  if n.name=="Abandoned_crooked_picture":
   n.position=g.town.buildings.house.get_node("Abandoned_crooked_picture").position;n.rotation.y=PI/2
  if n.name=="SaintGeorgeBrickFacade":
   for part in n.get_children():
    if part is Node3D:
     var bounds=g.surface_details.bounds_of(part)
     if bounds.end.y>3.55:part.hide()
 var old=shell.get_node_or_null("Elevator_REFERENCE")
 if old:old.free()
 var lift=Node3D.new();lift.name="Elevator_REFERENCE";lift.set_meta("_edit_lock_",true);shell.add_child(lift)
 var upper=g.hotel_upper
 for source in [upper.cab,upper.landing_doors[0][0].get_parent()]:
  var clone=source.duplicate(0);strip(clone);lift.add_child(clone);clone.set_meta("_edit_lock_",true)
  for audio in clone.find_children("*","AudioStreamPlayer3D",true,false):audio.free()
 var metal=g.town.color_material(Color("444843"))
 for x in [-1.5,1.5]:g.town.box(lift,upper.LIFT_ORIGIN+Vector3(x,1.55,0),Vector3(.15,3.1,2.85),metal)
 g.town.box(lift,upper.LIFT_ORIGIN+Vector3(0,1.55,-1.42),Vector3(3.1,3.1,.15),metal)
 for x in [-1.22,1.22]:g.town.box(lift,upper.LIFT_ORIGIN+Vector3(x,1.35,1.4),Vector3(.58,2.7,.18),upper.wallpaper)
 g.town.box(lift,upper.LIFT_ORIGIN+Vector3(0,2.95,1.4),Vector3(3,.8,.18),upper.wallpaper)
 own_all(scene,scene)
 for n in furniture.get_children():assert(n.transform.is_equal_approx(transforms[n.name]),"Existing furniture transforms must be preserved")
 var packed=PackedScene.new();assert(packed.pack(scene)==OK);assert(ResourceSaver.save(packed,path)==OK)
 print("PASS: current elevator added to downstairs reference; obsolete bedroom hidden; all ",transforms.size()," furniture transforms preserved")
 scene.free();g.queue_free();await process_frame;quit()
