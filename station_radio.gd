extends RefCounted
## John's vintage radio, adapted to the same matte retro materials as the room props.
static func build() -> Node3D:
 var model = preload("res://assets/radio/blackwood_radio.glb").instantiate()
 model.name = "BlackwoodVintageRadio"
 adapt(model,{})
 return model

static func adapt(node: Node, materials: Dictionary):
 if node is MeshInstance3D:
  node.visibility_range_end = 55
  for surface in range(node.mesh.get_surface_count()):
   var original = node.mesh.surface_get_material(surface)
   if original is StandardMaterial3D:
    var key = original.get_instance_id()
    if not materials.has(key):
     var material = original.duplicate()
     material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
     material.roughness = 1
     material.metallic = 0
     material.metallic_specular = 0
     material.emission_enabled = false
     material.albedo_color *= Color(0.83,0.84,0.79)
     materials[key] = material
    node.set_surface_override_material(surface,materials[key])
 for child in node.get_children():adapt(child,materials)
