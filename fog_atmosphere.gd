extends Node3D
## Compatibility/ANGLE-friendly particle fog; no Forward+ volumetric dependency.
var game
var environment: Environment
var cellar_environment: Environment
var surface_ambient_energy = 0.52
var surface_directionals: Array[DirectionalLight3D] = []
var emitters: Array[CPUParticles3D] = []
var material: ShaderMaterial
var elapsed = 0.0
var indoors = false

func _ready():
	name = "BlackwoodDriftingFog"
	for light in game.find_children("*","DirectionalLight3D",true,false):
		surface_directionals.append(light)
	surface_ambient_energy = environment.ambient_light_energy
	cellar_environment = environment.duplicate()
	cellar_environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	cellar_environment.ambient_light_energy = 0.0
	cellar_environment.ambient_light_color = Color("737e7a")
	cellar_environment.fog_enabled = false
	cellar_environment.fog_density = 0.007
	cellar_environment.fog_light_energy = 0.025
	cellar_environment.background_color = Color("030505")
	var noise = FastNoiseLite.new()
	noise.seed = 14503
	noise.frequency = 0.065
	noise.fractal_octaves = 3
	var texture = NoiseTexture2D.new()
	texture.width = 64
	texture.height = 64
	texture.seamless = true
	texture.noise = noise
	material = ShaderMaterial.new()
	material.shader = preload("res://mist.gdshader")
	material.set_shader_parameter("noise_texture",texture)
	make_emitter(Vector3(0,0.9,12),Vector3(5,0.7,10),24)
	make_emitter(Vector3(0,1.0,-16),Vector3(4,0.8,18),32)
	make_emitter(Vector3(0,1.0,-49),Vector3(5,0.8,12),32)
	make_emitter(Vector3(0,1.0,-76),Vector3(5,0.8,15),32)

	make_emitter(Vector3(10,3.8,-109),Vector3(7,1,9),20)
	make_emitter(Vector3(29,9.8,-130),Vector3(8,0.8,12),24)

func make_emitter(p: Vector3, extents: Vector3, count: int):
	var particles = CPUParticles3D.new()
	particles.name = "DriftingMist%d" % emitters.size()
	particles.amount = count
	particles.lifetime = 20
	particles.preprocess = 20
	particles.fixed_fps = 24
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = extents
	particles.direction = Vector3(1,0.035,-0.3)
	particles.spread = 24
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = 0.14
	particles.initial_velocity_max = 0.32
	particles.scale_amount_min = 0.85
	particles.scale_amount_max = 1.45
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0,0.2,0.75,1])
	gradient.colors = PackedColorArray([Color(1,1,1,0),Color(1,1,1,0.21),Color(1,1,1,0.16),Color(1,1,1,0)])
	particles.color_ramp = gradient
	var quad = QuadMesh.new()
	quad.size = Vector2(8,3.2)
	quad.material = material
	particles.mesh = quad
	particles.draw_order = CPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	particles.visibility_aabb = AABB(-extents-Vector3(12,4,12),extents*2+Vector3(24,8,24))
	add_child(particles)
	particles.position = p
	emitters.append(particles)

func update_fog(delta: float):
	var in_cellar = game.state not in ["intro","title"] and game.town.streetscape.church.basement.contains(game.player.global_position)
	for light in surface_directionals:
		light.visible = not in_cellar
	game.camera.environment = cellar_environment if in_cellar else null
	# Compatibility uses world ambient for some mesh lighting even with a camera override.
	environment.ambient_light_energy = 0.004 if in_cellar else surface_ambient_energy
	var active = game.state in ["play","title","intro"]
	for particles in emitters:
		particles.speed_scale = 1 if active else 0
	if not active:
		return
	elapsed += delta
	indoors = false
	if game.state=="play":
		for data in game.town.BUILDINGS:
			if game.town.player_inside_building(data.id):
				indoors = true
				break
		if game.town.streetscape.church and game.town.streetscape.church.contains(game.player.global_position):
			indoors = true
	var density = 0.018 if indoors else (0.070+sin(elapsed*0.065)*0.005)
	environment.fog_density = lerpf(environment.fog_density,density,clampf(delta*1.5,0,1))
	var view = game.title_camera if game.state in ["intro","title"] else game.camera
	if view:
		material.set_shader_parameter("eye_position",view.global_position)
	material.set_shader_parameter("opacity",0.35 if indoors else 1.0)

func _process(delta):
	update_fog(delta)
