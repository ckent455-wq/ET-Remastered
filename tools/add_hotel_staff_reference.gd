extends SceneTree
var g
func _initialize():call_deferred("run")
func strip(n:Node):
 n.scene_file_path="";n.set_script(null)
 for child in n.get_children():strip(child)
func own(n:Node,scene:Node):
 for child in n.get_children():child.owner=scene;own(child,scene)
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.enemies.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 var scene=load("res://editing/hotel_layout.tscn").instantiate();root.add_child(scene);var shell=scene.get_node("RoomShell_REFERENCE")
 var old=shell.get_node_or_null("Employees_Wall_REFERENCE")
 if old:old.free()
 var wall=g.hotel_staff.duplicate(0);strip(wall);shell.add_child(wall);wall.name="Employees_Wall_REFERENCE";wall.transform=Transform3D.IDENTITY;wall.set_meta("_edit_lock_",true)
 own(scene,scene);var packed=PackedScene.new();assert(packed.pack(scene)==OK);assert(ResourceSaver.save(packed,"res://editing/hotel_layout.tscn")==OK)
 print("PASS: staff wall and locked door included in the downstairs editor reference")
 scene.free();g.queue_free();await process_frame;quit()
