extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.enemies.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 await process_frame;g.hotel_layout.apply_layout()
 for n in g.town.buildings.house.get_children():
  if n is Node3D and n.visible and n.position.x< -2 and n.position.z<0:print(n.get_index()," ",n.name," ",n.position," ",n.get_class())
 quit()
