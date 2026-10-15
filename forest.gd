extends Node3D
## Reuses reduced local meshes and textures. Keep routes and pickup sites clear.
const TARGETS = [Vector3(-27,0,-29),Vector3(30,0,-23),Vector3(19,0,31)]
var rng = RandomNumberGenerator.new()
var tree_positions: Array[Vector3] = []
var tree_count = 0
var bush_count = 0
var rock_count = 0
var shared_materials = {}
var crowns: Array[ArrayMesh] = []
var needle_material: StandardMaterial3D
var pine_scenes = [preload("res://assets/forest/pine_b.glb"),preload("res://assets/forest/pine_c.glb")]
var bush_scenes = [preload("res://assets/forest/bush_e.glb"),preload("res://assets/forest/bush_f.glb"),preload("res://assets/forest/bush_g.glb")]
var rock_scenes = [preload("res://assets/forest/rock_0.glb"),preload("res://assets/forest/rock_1.glb"),preload("res://assets/forest/rock_2.glb")]

func _ready():
	rng.seed = 41983
	name = "DetailedForest"
	needle_material = StandardMaterial3D.new()
	needle_material.albedo_texture = preload("res://assets/forest/pine_tree_01_twig.png")
	needle_material.albedo_color = Color(0.72,0.83,0.69)
	needle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	needle_material.alpha_scissor_threshold = 0.45
	needle_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	needle_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	needle_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	needle_material.roughness = 1
	needle_material.metallic_specular = 0
	crowns = [make_crown(33),make_crown(77)]
	make_paths()
	for attempt in range(1800):
		if tree_count>=180:
			break
		var p = random_point()
		if not can_place(p,2.0,7.5):
			continue
		var crowded = false
		for other in tree_positions:
			if other.distance_to(p)<3.2:
				crowded = true
		if crowded:
			continue
		var size = rng.randf_range(0.72,1.26)
		var tree = place(pine_scenes[tree_count%2],p,Vector3(size*rng.randf_range(0.9,1.15),size,size),"Trees")
		var foliage = MeshInstance3D.new()
		foliage.mesh = crowns[tree_count%2]
		foliage.material_override = needle_material
		foliage.visibility_range_end = 64
		tree.add_child(foliage)
		add_collision(tree,0.25,5.5)
		tree_positions.append(p)
		tree_count += 1
	# Shrubs collect around tree bases rather than evenly covering every path.
	for attempt in range(1100):
		if bush_count>=210:
			break
		var anchor = tree_positions[rng.randi_range(0,tree_positions.size()-1)]
		var angle = rng.randf_range(0,TAU)
		var p = anchor+Vector3(cos(angle),0,sin(angle))*rng.randf_range(1,3.5)
		if not can_place(p,1.7,6.2):
			continue
		var size = rng.randf_range(0.55,1.15)
		place(bush_scenes[bush_count%3],p,Vector3(size*rng.randf_range(1,1.5),size,size),"Bushes")
		bush_count += 1
	for attempt in range(1000):
		if rock_count>=85:
			break
		var p = random_point()
		if not can_place(p,2,6.5):
			continue
		var size = rng.randf_range(0.35,1.25)
		var rock = place(rock_scenes[rock_count%3],p-Vector3(0,0.12,0),Vector3(size*rng.randf_range(0.8,1.3),size,size),"Rocks")
		if size>0.65:
			add_collision(rock,0.65,0.8)
		rock_count += 1

func make_crown(variant: int) -> ArrayMesh:
	var random = RandomNumberGenerator.new()
	random.seed = variant
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for level in range(8):
		var height = 3.2+level*0.74
		var reach = (1.0-height/10.7)*3.8
		for arm in range(8):
			var angle = arm*TAU/8+level*0.9+random.randf_range(-0.2,0.2)
			var radial = Vector3(cos(angle),0,sin(angle))
			for tuft in range(4):
				var center = radial*reach*(0.22+tuft*0.23)+Vector3(0,height+random.randf_range(-0.22,0.22),0)
				var axis = (radial+Vector3(0,random.randf_range(0.2,0.6),0)).normalized()
				var side = Vector3(-radial.z,0,radial.x)
				for crossed in range(2):
					var across = side.rotated(axis,crossed*PI/2)*random.randf_range(0.28,0.42)
					var tip = center+axis*random.randf_range(0.85,1.25)
					var points = [center-across,center+across,tip-across,tip+across]
					# Select only the needle sprig in the top-left of the source atlas.
					var uvs = [Vector2(0.005,0.44),Vector2(0.225,0.44),Vector2(0.005,0.005),Vector2(0.225,0.005)]
					for idx in [0,1,2,1,3,2]:
						tool.set_normal(Vector3.UP)
						tool.set_uv(uvs[idx])
						tool.add_vertex(points[idx])
	return tool.commit()

func random_point() -> Vector3:
	return Vector3(rng.randf_range(-46,46),0,rng.randf_range(-46,46))

func can_place(p: Vector3, path_clearance: float, clearing: float) -> bool:
	# Clear the accident scene and the continuous walking lane into town.
	if Vector2(p.x-3.8,p.z-13).length()<6.0 or (p.z<21 and p.z> -56 and absf(p.x)<2.6):
		return false
	# Keep the roadside sign and its sightline free of trunks and branches.
	if Vector2(p.x-4.4,p.z+35).length()<6.0:
		return false
	# Reserve the town footprint and its approach road before scattering vegetation.
	if (p.z< -36 and absf(p.x)<40) or (p.z<0 and absf(p.x)<2.2):
		return false
	if absf(p.x)>46 or absf(p.z)>46 or p.length()<clearing:
		return false
	var point = Vector2(p.x,p.z)
	for target in TARGETS:
		if p.distance_to(target)<3.4:
			return false
		var nearest = Geometry2D.get_closest_point_to_segment(point,Vector2.ZERO,Vector2(target.x,target.z))
		if point.distance_to(nearest)<path_clearance:
			return false
	return true

func prepare_meshes(node: Node):
	if node is MeshInstance3D:
		node.visibility_range_end = 64
		node.lod_bias = 0.8
		for i in range(node.mesh.get_surface_count()):
			var original = node.mesh.surface_get_material(i)
			if not original is StandardMaterial3D:
				continue
			var key = original.get_instance_id()
			if not shared_materials.has(key):
				var material = original.duplicate() as StandardMaterial3D
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
				material.normal_enabled = false
				material.roughness = 1
				material.metallic = 0
				material.metallic_specular = 0
				material.albedo_color = Color(0.80,0.88,0.80)
				if "twig" in original.resource_name or "leaves" in original.resource_name:
					material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					material.alpha_scissor_threshold = 0.42
					material.cull_mode = BaseMaterial3D.CULL_DISABLED
				shared_materials[key] = material
			node.set_surface_override_material(i,shared_materials[key])
	for child in node.get_children():
		prepare_meshes(child)

func place(scene: PackedScene, p: Vector3, size: Vector3, group: String) -> Node3D:
	var object = StaticBody3D.new()
	object.name = group.trim_suffix("s")+str(get_child_count())
	object.position = p
	object.rotation.y = rng.randf_range(0,TAU)
	object.scale = size
	add_child(object)
	object.add_to_group(group)
	var visual = scene.instantiate()
	object.add_child(visual)
	prepare_meshes(visual)
	return object

func add_collision(object: Node3D, radius: float, height: float):
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	collision.position.y = height/2
	object.add_child(collision)

func make_paths():
	var material = StandardMaterial3D.new()
	material.albedo_texture = preload("res://assets/forest/ground_ps2.png")
	material.albedo_color = Color("8a8067")
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.roughness = 1
	material.metallic_specular = 0
	for target in TARGETS:
		var direction = target.normalized()
		var side = Vector3(-direction.z,0,direction.x)
		var tool = SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(16):
			var start = direction*(target.length()*i/16.0)
			var finish = direction*(target.length()*(i+1)/16.0)
			var width = 1.1+sin(i*0.8)*0.17
			var points = [start-side*width,start+side*width,finish-side*width,finish+side*width]
			for idx in [0,2,1,1,2,3]:
				tool.set_uv(Vector2(points[idx].x,points[idx].z)*0.3)
				tool.set_normal(Vector3.UP)
				tool.add_vertex(points[idx]+Vector3(0,0.015,0))
		var mesh = MeshInstance3D.new()
		mesh.mesh = tool.commit()
		mesh.material_override = material
		add_child(mesh)
