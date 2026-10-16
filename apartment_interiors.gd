extends Node3D
## Room-specific dressing from the user's Brick Project Studio Apartment Kit.
var town
var scenes = {}
var manifest = {}
var materials = {}
var instances: Array[Node3D] = []
var room_counts = {}

func _ready():
	name = "ApartmentKitInteriors"
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/apartment/manifest.json"))
	for row in data.assets:
		manifest[row.asset] = row
		scenes[row.asset] = load("res://assets/apartment/"+row.asset+".glb")
	var layout = preload("res://interior_layouts.gd").new(self)
	layout.build()

func adapt(node: Node):
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
	for child in node.get_children():
		adapt(child)

func place(asset: String, room: String, p: Vector3, yaw = 0.0, size = Vector3.ONE, solid = true) -> Node3D:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	root.name = "Apartment_"+asset+str(instances.size())
	root.set_meta("apartment_asset",asset)
	root.set_meta("room",room)
	root.add_to_group("ApartmentKitFurniture")
	town.buildings[room].add_child(root)
	root.position = p
	root.rotation.y = yaw
	root.scale = size
	var model = scenes[asset].instantiate()
	root.add_child(model)
	adapt(model)
	if asset == "wall_art":
		age_wall_art(model)
	if solid:
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		var d = manifest[asset].dimensions
		shape.size = Vector3(d[0]*0.95,d[1],d[2]*0.95)
		collision.position.y = d[1]/2
		collision.shape = shape
		root.add_child(collision)
	instances.append(root)
	room_counts[room] = room_counts.get(room,0)+1
	return root

func age_wall_art(node: Node):
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var material = node.get_active_material(surface)
			if material is StandardMaterial3D:
				var faded = material.duplicate()
				faded.albedo_color *= Color(0.36,0.29,0.22)
				node.set_surface_override_material(surface,faded)
	for child in node.get_children():
		age_wall_art(child)

func hide_placeholder(node: Node3D):
	node.hide()
	for collider in node.find_children("*","CollisionShape3D",true,false):
		collider.disabled = true
