extends Node3D
## Uses the user's downloaded hatchback; all set dressing remains simple PS2 geometry.
var game
var wreck: Node3D
var steam: Array[MeshInstance3D] = []
var elapsed = 0.0
const WRECK_POSITION = Vector3(3.8,0.01,13)

func _ready():
	name = "OldMillRoadCrash"
	wreck = StaticBody3D.new()
	wreck.name = "CrashedHatchback"
	wreck.position = WRECK_POSITION
	wreck.rotation = Vector3(0,-0.6,-0.025)
	add_child(wreck)
	var model = preload("res://assets/vehicles/crashed_hatchback.glb").instantiate()
	wreck.add_child(model)
	adapt(model)
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.85,1.35,3.6)
	collision.shape = shape
	collision.position.y = 0.72
	wreck.add_child(collision)
	var headlight = SpotLight3D.new()
	headlight.position = Vector3(0.65,0.55,-1.75)
	headlight.rotation.x = -0.12
	headlight.light_color = Color("d6cda0")
	headlight.light_energy = 1.2
	headlight.spot_range = 10
	headlight.spot_angle = 32
	wreck.add_child(headlight)
	var rear_glow = OmniLight3D.new()
	rear_glow.position = Vector3(0,0.6,1.9)
	rear_glow.light_color = Color("ad4333")
	rear_glow.light_energy = 0.35
	rear_glow.omni_range = 2.8
	wreck.add_child(rear_glow)
	game.town.action_area(wreck,Vector3(-0.7,1,0.4),Vector3(1.1,1.0,2.4),"crash_wreck",{"kind":"crash","label":"Inspect wrecked car"})
	# The car has run off the lane into a broken roadside stump.
	var stump = game.mesh_at(self,game.cylinder(0.42,0.3,0.9),wreck.to_global(Vector3(0,0.45,-2.05)),game.town.mats.wood)
	stump.rotation.z = 0.15
	var hood = game.town.box(wreck,Vector3(0,0.83,-1.30),Vector3(1.25,0.045,0.55),game.mat(Color("787543")),false)
	hood.rotation = Vector3(-0.20,0,-0.045)
	var bumper = game.town.box(wreck,Vector3(0.05,0.30,-1.82),Vector3(1.6,0.12,0.10),game.town.mats.dark,false)
	bumper.rotation.z = 0.13
	for i in range(8):
		var start = Vector3(-0.65,0.025,20-i*0.75)
		start.x += i*0.35
		for side in [-1,1]:
			var skid = game.town.box(self,start+Vector3(side*0.55,0,0),Vector3(0.16,0.012,0.85),game.town.mats.dark,false)
			skid.rotation.y = -0.4
	for i in range(6):
		var fragment = game.town.box(wreck,Vector3(-1.0+i*0.34,0.035,-2.1-fmod(i*0.37,0.9)),Vector3(0.15,0.035,0.12),game.town.mats.metal,false)
		fragment.rotation.y = i*1.7
	var vapor = game.mat(Color(0.35,0.40,0.40,0.12))
	vapor.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vapor.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(4):
		var puff = SphereMesh.new()
		puff.radius = 0.15
		puff.height = 0.25
		puff.radial_segments = 6
		puff.rings = 3
		var visual = game.mesh_at(wreck,puff,Vector3.ZERO,vapor)
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		steam.append(visual)

func adapt(node: Node):
	if node is MeshInstance3D:
		for i in range(node.mesh.get_surface_count()):
			var original = node.mesh.surface_get_material(i)
			if original is StandardMaterial3D:
				var material = original.duplicate() as StandardMaterial3D
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
				material.roughness = 1
				material.albedo_color = Color(0.72,0.70,0.62)
				material.metallic_specular = 0
				node.set_surface_override_material(i,material)
	for child in node.get_children():
		adapt(child)

func _process(delta):
	if game.state!="play":
		return
	elapsed += delta
	for i in range(steam.size()):
		var phase = fmod(elapsed*0.28+i*0.25,1)
		steam[i].position = Vector3(sin(phase*4+i)*0.10,0.85+phase*0.8,-1.35)
		steam[i].scale = Vector3.ONE*(0.45+sin(phase*PI)*0.7)
