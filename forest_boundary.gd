extends Node3D
## A closed, rising belt of trees and tangled undergrowth around the playable routes.
var game
var forest
var tree_count = 0
var collision_sections = 0
var crown_mesh: ArrayMesh
var trunk_mesh: CylinderMesh
var crown_material: StandardMaterial3D
var trunk_material: StandardMaterial3D
var shrub_mesh: Mesh
var shrub_material: Material
const OUTLINE = [Vector3(-42,0,42),Vector3(42,0,42),Vector3(44,0,10),Vector3(42,0,-27),Vector3(26,0,-40),Vector3(23,0,-84),Vector3(17,0,-96),Vector3(-21,0,-98),Vector3(-27,0,-88),Vector3(-26,0,-40),Vector3(-42,0,-27),Vector3(-44,0,10)]
const ROW_DEPTHS = [0.0,3.1,6.4,10.5,16.0]

func _ready():
	name = "ImpenetrableForest"
	forest = game.get_node("DetailedForest")
	crown_mesh = make_crown()
	crown_material = forest.needle_material.duplicate()
	crown_material.albedo_color = Color("64765d")
	crown_material.vertex_color_use_as_albedo = true
	trunk_mesh = game.cylinder(0.24,0.10,10.5,7)
	trunk_material = game.town.mats.wood.duplicate()
	trunk_material.albedo_color = Color("4a5142")
	trunk_material.vertex_color_use_as_albedo = true
	var shrub = forest.bush_scenes[0].instantiate()
	find_shrub(shrub)
	shrub.free()
	for i in range(OUTLINE.size()):
		build_section(OUTLINE[i],OUTLINE[(i+1)%OUTLINE.size()],i)

func find_shrub(node: Node):
	if node is MeshInstance3D and shrub_mesh==null:
		shrub_mesh = node.mesh.duplicate()
		for surface in range(shrub_mesh.get_surface_count()):
			var material = shrub_mesh.surface_get_material(surface).duplicate()
			material.albedo_color = Color("647153")
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			material.vertex_color_use_as_albedo = true
			shrub_mesh.surface_set_material(surface,material)
	for child in node.get_children():
		find_shrub(child)

func outward_for(a: Vector3, b: Vector3) -> Vector3:
	var direction = (b-a).normalized()
	var outward = Vector3(-direction.z,0,direction.x)
	if outward.dot(Vector3(0,0,-25)-(a+b)/2)>0:
		outward = -outward
	return outward

func rise(depth: float, distance_along: float) -> float:
	return maxf(0,depth)*0.29*(1.0+0.25*sin(distance_along*0.16))

func build_section(a: Vector3, b: Vector3, index: int):
	var outward = outward_for(a,b)
	var rng = RandomNumberGenerator.new()
	rng.seed = 9031+index*117
	var count = int(ceil(a.distance_to(b)/2.8))+1
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for row in range(ROW_DEPTHS.size()):
		for i in range(count):
			var t = clampf((i+0.48*(row%2))/float(count-1),0,1)
			var p = a.lerp(b,t)+outward*(ROW_DEPTHS[row]+rng.randf_range(-0.45,0.45))
			p.y = rise(ROW_DEPTHS[row],t*a.distance_to(b)+index*20)
			var size = rng.randf_range(0.86,1.3)
			var basis = Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(size,size*rng.randf_range(0.9,1.2),size))
			transforms.append(Transform3D(basis,p))
			colors.append(Color(1,1,1)*rng.randf_range(0.72,1.05))
	add_instances("TreeCrowns",crown_mesh,crown_material,transforms,colors,Vector3.ZERO)
	add_instances("TreeTrunks",trunk_mesh,trunk_material,transforms,colors,Vector3(0,5.25,0))
	var shrubs: Array[Transform3D] = []
	var shrub_colors: Array[Color] = []
	for row in range(2):
		for i in range(count*2):
			var t = clampf((i+0.5*row)/float(count*2-1),0,1)
			var depth = -0.7+row*1.5
			var p = a.lerp(b,t)+outward*depth
			p.y = rise(depth,t*a.distance_to(b)+index*20)+0.35
			var size = rng.randf_range(0.9,1.25)
			shrubs.append(Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(size*3.0,size*1.7,size*3.0)),p))
			shrub_colors.append(Color(1,1,1,1))
	if shrub_mesh:
		add_instances("TangledShrubs",shrub_mesh,shrub_material,shrubs,shrub_colors,Vector3.ZERO)
	tree_count += transforms.size()
	build_bank(a,b,outward,index)
	# Overlapping sections form a closed collision belt within visible undergrowth.
	var body = StaticBody3D.new()
	body.name = "DenseThicketCollision%d" % index
	add_child(body)
	body.position = (a+b)/2+outward*1.25+Vector3(0,4,0)
	body.look_at(b+outward*1.25+Vector3(0,4,0))
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(3.2,8,a.distance_to(b)+2.0)
	collision.shape = shape
	body.add_child(collision)
	collision_sections += 1

func add_instances(label: String, mesh: Mesh, material: Material, transforms: Array[Transform3D], colors: Array[Color], offset: Vector3):
	var multi = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		var pose = transforms[i]
		pose.origin += pose.basis*offset
		multi.set_instance_transform(i,pose)
		multi.set_instance_color(i,colors[i])
	var instance = MultiMeshInstance3D.new()
	instance.name = label
	instance.multimesh = multi
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)

func make_crown() -> ArrayMesh:
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for level in range(8):
		var height = 2.0+level*1.05
		var reach = 3.3*(1.0-height/11.5)
		for arm in range(6):
			var angle = arm*TAU/6+level*0.7
			var radial = Vector3(cos(angle),0,sin(angle))
			var side = Vector3(-radial.z,0,radial.x)
			for tuft in range(3):
				var center = radial*reach*(0.1+tuft*0.28)+Vector3(0,height,0)
				var tip = center+radial*1.1+Vector3(0,0.55,0)
				var points = [center-side*0.5,center+side*0.5,tip-side*0.35,tip+side*0.35]
				var uvs = [Vector2(0.005,0.44),Vector2(0.225,0.44),Vector2(0.005,0.005),Vector2(0.225,0.005)]
				for vertex in [0,1,2,1,3,2]:
					tool.set_normal(Vector3.UP)
					tool.set_uv(uvs[vertex])
					tool.add_vertex(points[vertex])
	return tool.commit()

func build_bank(a: Vector3, b: Vector3, outward: Vector3, index: int):
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps = int(ceil(a.distance_to(b)/2.0))
	var depths = [-2.0,0.0,3.1,6.4,10.5,18.0]
	for band in range(depths.size()-1):
		for i in range(steps):
			var points: Array[Vector3] = []
			for pair in [Vector2i(i,band),Vector2i(i+1,band),Vector2i(i,band+1),Vector2i(i+1,band+1)]:
				var t = float(pair.x)/steps
				var d = depths[pair.y]
				var p = a.lerp(b,t)+outward*d
				p.y = rise(d,t*a.distance_to(b)+index*20)+ (0.75 if d>=0 else 0.01)
				points.append(p)
			for vertex in [0,2,1,1,2,3]:
				tool.set_normal(Vector3.UP)
				tool.set_uv(Vector2(points[vertex].x,points[vertex].z)*0.22)
				tool.add_vertex(points[vertex])
	var material = game.town.mats.wood.duplicate()
	material.albedo_texture = preload("res://assets/forest/ground_ps2.png")
	material.albedo_color = Color("586044")
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var bank = MeshInstance3D.new()
	bank.name = "RootAndBrambleBank"
	bank.mesh = tool.commit()
	bank.material_override = material
	add_child(bank)
