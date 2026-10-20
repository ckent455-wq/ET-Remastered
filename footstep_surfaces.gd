extends RefCounted
## Sample the physical floor, then thin visual paving that shares its collision.
static func material_kind(material:Material)->String:
 if material is StandardMaterial3D and material.albedo_texture:
  var path=material.albedo_texture.resource_path.to_lower()
  if "ground" in path:return "grass"
  if "wood" in path or "floor" in path or "shelf" in path:return "wood"
  if "brick" in path or "slate" in path or "plaster" in path:return "stone"
  if "metal" in path:return "metal"
 return "concrete"
static func visual(node:MeshInstance3D,kind:String):
 node.set_meta("footstep_surface",kind);node.add_to_group("FootstepVisual")
static func sample(game)->String:
 var feet:Vector3=game.player.global_position
 var start=feet+Vector3(0,0.35,0);var finish=feet-Vector3(0,0.55,0)
 var query=PhysicsRayQueryParameters3D.create(start,finish,1,[game.player.get_rid()])
 var hit=game.get_world_3d().direct_space_state.intersect_ray(query)
 if hit.is_empty():return "grass"
 var kind=str(hit.collider.get_meta("footstep_surface","grass"))
 # Road and sidewalk meshes intentionally share the world's flat collider.
 # Test their real triangles instead of guessing from broad street rectangles.
 var height:float=hit.position.y
 for node in game.get_tree().get_nodes_in_group("FootstepVisual"):
  if not node.is_visible_in_tree():continue
  var a:Vector3=node.to_local(start);var b:Vector3=node.to_local(finish)
  var bounds:AABB=node.get_aabb().grow(0.02)
  if not bounds.intersects_segment(a,b):continue
  var faces:PackedVector3Array=node.mesh.get_faces()
  for i in range(0,faces.size(),3):
   var point=Geometry3D.segment_intersects_triangle(a,b,faces[i],faces[i+1],faces[i+2])
   if point==null:continue
   var y:float=node.to_global(point).y
   if y>=height-0.015 and absf(y-hit.position.y)<0.15:
    kind=str(node.get_meta("footstep_surface"));height=y
 return kind
