extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.enemies.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 var scene=load("res://editing/hotel_layout.tscn").instantiate()
 for n in scene.get_node("Furniture").get_children():
  print("FURN ",n.name," ",n.position," index ",n.get_meta("runtime_index",-1)," asset ",n.get_meta("runtime_asset","") )
  for mesh in n.find_children("*","MeshInstance3D",true,false):
   if mesh.position.length()>.5:print("OFFSET ",n.name," ",mesh.name," ",mesh.position)
 var shell=scene.get_node("RoomShell_REFERENCE")
 print("SHELLCOUNT ",shell.get_child_count())
 quit()
