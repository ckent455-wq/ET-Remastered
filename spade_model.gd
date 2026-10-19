extends RefCounted
static func build()->Node3D:
 var root=Node3D.new()
 var model=load("res://assets/tools/rusted_spade_01_1k.fbx").instantiate()
 root.add_child(model)
 var bounds=AABB();var first=true
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  var part: AABB=(model.transform.affine_inverse()*mesh.global_transform)*mesh.mesh.get_aabb() if mesh.is_inside_tree() else mesh.transform*mesh.mesh.get_aabb()
  bounds=part if first else bounds.merge(part);first=false
  var mat=StandardMaterial3D.new()
  mat.albedo_texture=preload("res://assets/tools/textures/rusted_spade_01_diff_1k.jpg")
  mat.roughness=1
  mat.albedo_color=Color(1.12,1.08,1.0)
  mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
  mesh.material_override=mat
 var factor=1.25/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
 model.scale*=factor
 model.position=-bounds.get_center()*factor+Vector3(0,0.625,0)
 root.scale.x=1.25
 return root
