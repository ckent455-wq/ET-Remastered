extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.enemies.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 var inverse=g.town.buildings.house.global_transform.affine_inverse()
 var rooms=AABB(Vector3(-5.9,3.7,-4.9),Vector3(11.8,3.5,9.8))
 for mesh in g.find_children("*","MeshInstance3D",true,false):
  if not mesh.is_visible_in_tree() or not mesh.mesh:continue
  var label=mesh.mesh.resource_path
  for surface in mesh.mesh.get_surface_count():
   var mat=mesh.get_active_material(surface)
   if mat is StandardMaterial3D and mat.albedo_texture:label+=" "+mat.albedo_texture.resource_path
  if not ("bush" in label or "pine" in label or "twig" in label or "leaf" in label):continue
  var bounds=(inverse*mesh.global_transform)*mesh.get_aabb()
  if rooms.intersects(bounds):print("PLANT ",mesh.get_path()," ",bounds," ",label.left(150))
 quit()
