extends Node3D
## Low-poly scenery beyond the playable floor; no added movement collision.
var game
var environment: Environment
var ridges: Array[MeshInstance3D] = []
var sky_material: ShaderMaterial

func _ready():
	name = "BlackwoodDistantLandscape"
	var noise = FastNoiseLite.new()
	noise.seed = 84531
	noise.frequency = 0.028
	noise.fractal_octaves = 5
	var clouds = NoiseTexture2D.new()
	clouds.width = 256
	clouds.height = 256
	clouds.seamless = true
	clouds.noise = noise
	sky_material = ShaderMaterial.new()
	sky_material.shader = preload("res://cloud_sky.gdshader")
	sky_material.set_shader_parameter("panorama",load("res://assets/atmosphere/overcast_sky.png"))
	sky_material.set_shader_parameter("cloud_noise",clouds)
	var sky = Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	sky.sky_material = sky_material
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.fog_sky_affect = 0.18
	# Colour-source ambient lighting stays unchanged; the sky adds no daylight.
	build_ridge(0,Vector3(56,84,116),Color(0.245,0.285,0.255))
	build_ridge(1,Vector3(99,136,172),Color(0.277,0.312,0.288))
	game.camera.far = 250
	game.title_camera.far = 250

func height_at(angle: float, layer: int) -> float:
	var rolling = sin(angle*3+layer*1.8)*7.0+sin(angle*7-0.8)*4.5+sin(angle*11+0.7)*2.2
	if layer==0:
		# A lower saddle ahead of Main Street reveals the second ridge at normal eye level.
		var north_distance = wrapf(angle+PI/2,-PI,PI)
		rolling -= 14.0*exp(-pow(north_distance/0.42,2))
	return (23.0 if layer==0 else 43.0)+rolling

func build_ridge(layer: int, radii: Vector3, color: Color):
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var slices = 96
	for band in range(2):
		for i in range(slices):
			var corners: Array[Vector3] = []
			for v in [Vector2i(i,band),Vector2i(i+1,band),Vector2i(i,band+1),Vector2i(i+1,band+1)]:
				var angle = float(v.x)*TAU/slices
				var radius = radii[v.y]
				var height = height_at(angle,layer) if v.y==1 else -3.0
				corners.append(Vector3(cos(angle)*radius,height,-30+sin(angle)*radius))
			for triangle in [[0,2,1],[1,2,3]]:
				var vertices: Array[Vector3] = [corners[triangle[0]],corners[triangle[1]],corners[triangle[2]]]
				add_ridge_triangle(tool,vertices)
	var material = ShaderMaterial.new()
	material.shader = preload("res://distant_hills.gdshader")
	material.set_shader_parameter("ground_texture",preload("res://assets/forest/ground_ps2.png"))
	material.set_shader_parameter("crest_color",Vector3(color.r,color.g,color.b))
	var ridge = MeshInstance3D.new()
	ridge.name = "NearHills" if layer==0 else "FarHills"
	ridge.mesh = tool.commit()
	ridge.material_override = material
	ridge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ridge)
	ridges.append(ridge)

func add_ridge_triangle(tool: SurfaceTool, vertices: Array[Vector3]):
	# Backdrop scenery must stay outside the Victorian house and its approach.
	var cutout = PackedVector2Array([Vector2(-22,-109),Vector2(-2,-109),Vector2(-2,-87),Vector2(-22,-87)])
	var projected = PackedVector2Array()
	for vertex in vertices: projected.append(Vector2(vertex.x,vertex.z))
	var pieces = Geometry2D.clip_polygons(projected,cutout)
	var normal = (vertices[1]-vertices[0]).cross(vertices[2]-vertices[0]).normalized()
	for polygon in pieces:
		var indices = Geometry2D.triangulate_polygon(polygon)
		for index in indices:
			var point: Vector2 = polygon[index]
			var a: Vector2 = projected[0]
			var b: Vector2 = projected[1]
			var c: Vector2 = projected[2]
			var denominator = (b-a).cross(c-a)
			var u = (point-a).cross(c-a)/denominator
			var v = (b-a).cross(point-a)/denominator
			var height = vertices[0].y+u*(vertices[1].y-vertices[0].y)+v*(vertices[2].y-vertices[0].y)
			tool.set_normal(normal)
			tool.add_vertex(Vector3(point.x,height,point.y))
