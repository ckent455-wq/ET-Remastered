extends RefCounted
## Authored environmental storytelling; static, bounded and deterministic.
var kit
var town
var finishes
var stains = {}
var paper
var wood
var rng = RandomNumberGenerator.new()

func _init(owner, room_finishes):
	kit = owner
	town = owner.town
	finishes = room_finishes
	rng.seed = 783142
	paper = town.color_material(Color("9b9278"))
	wood = town.mats.furniture.duplicate()
	wood.albedo_color = Color("65523e")

func build():
	for i in range(town.BUILDINGS.size()):
		var data = town.BUILDINGS[i]
		water_damage(data,i)
		wear_furniture(data.id)
	house()
	ranger()
	clinic()
	store()
	workshop()
	radio()

func marker(room: String, kind: String, p: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Abandoned_"+kind
	root.set_meta("decay_kind",kind)
	root.set_meta("room",room)
	root.add_to_group("InteriorDecay")
	town.buildings[room].add_child(root)
	root.position = p
	return root

func stain(room: String, kind: String, p: Vector3, size: Vector2, rotation: Vector3, seed_value: float):
	var root = marker(room,kind,p)
	root.rotation = rotation
	var plane = MeshInstance3D.new()
	var mesh = QuadMesh.new()
	mesh.size = size
	plane.mesh = mesh
	var material = ShaderMaterial.new()
	material.shader = preload("res://interior_stains.gdshader")
	material.set_shader_parameter("variation",seed_value)
	material.set_shader_parameter("ceiling_ring",kind=="ceiling_leak")
	material.set_shader_parameter("runoff",kind=="wall_damp")
	material.set_shader_parameter("tint",Color("56533c") if kind!="puddle" else Color("343c33"))
	material.set_shader_parameter("opacity",0.76 if kind!="puddle" else 0.64)
	plane.material_override = material
	root.add_child(plane)
	stains[kind] = stains.get(kind,0)+1

func water_damage(data, index: int):
	var room: String = data.id
	var half: float = data.w/2
	# Damp travels down from a roof leak; mold and fallen plaster collect below.
	var z = [-2.2,-0.65,2.15,-0.1,0.2,2.0][index]
	stain(room,"wall_damp",Vector3(-half+0.235,1.97,z),Vector2(2.9,2.0),Vector3(0,PI/2,0),index*3.7)
	stain(room,"ceiling_leak",Vector3(-half+1.25,3.058,z),Vector2(3.1,2.4),Vector3(PI/2,0,0),index*3.7+0.2)
	stain(room,"rising_damp",Vector3(-half+0.285,0.46,z+0.2),Vector2(2.8,0.68),Vector3(0,PI/2,0),index+8)
	stain(room,"puddle",Vector3(-half+1.15,0.057,z+0.4),Vector2(2.0,1.25),Vector3(-PI/2,0.15,0),index+4)
	# A second, smaller patch around the rear wall's pipe-height seam.
	stain(room,"wall_damp",Vector3(0.1,2.26,-4.752),Vector2(1.5,1.35),Vector3.ZERO,index+13)
	var debris = marker(room,"fallen_plaster",Vector3(-half+0.75,0.06,z+0.3))
	for i in range(9):
		var chip = town.box(debris,Vector3(rng.randf_range(-0.25,0.6),0,rng.randf_range(-0.7,0.7)),Vector3(rng.randf_range(0.05,0.20),0.015,rng.randf_range(0.07,0.18)),finishes[room].paint,false)
		chip.rotation = Vector3(0,rng.randf_range(-PI,PI),rng.randf_range(-0.08,0.08))
	# Exposed patches in the plaster have irregular edges, rather than square decals.
	var exposed = marker(room,"peeling_plaster",Vector3(-half+0.24,1.7,z))
	exposed.rotation.y = PI/2
	for i in range(5):
		var p = Vector3(rng.randf_range(-0.5,0.5),rng.randf_range(-0.4,0.45),0)
		var tool = SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var radius = rng.randf_range(0.08,0.17)
		for segment in range(6):
			for vertex in [Vector3.ZERO,Vector3(cos(segment*TAU/6)*radius,sin(segment*TAU/6)*radius,0),Vector3(cos((segment+1)*TAU/6)*radius*0.65,sin((segment+1)*TAU/6)*radius,0)]:
				tool.set_normal(Vector3.BACK)
				tool.add_vertex(p+vertex)
		var chip = MeshInstance3D.new()
		chip.mesh = tool.commit()
		var bare = town.color_material(Color("756e5b"))
		bare.cull_mode = BaseMaterial3D.CULL_DISABLED
		chip.material_override = bare
		exposed.add_child(chip)

func wear_furniture(room: String):
	for item in kit.instances:
		if item.get_meta("room")!=room:
			continue
		var asset = item.get_meta("apartment_asset")
		if asset in ["sofa","bed","desk","counter","dresser","coffee_table","dining_table"]:
			for mesh in item.find_children("*","MeshInstance3D",true,false):
				for surface in range(mesh.mesh.get_surface_count()):
					var original = mesh.get_active_material(surface)
					if original is StandardMaterial3D:
						var aged = original.duplicate()
						aged.albedo_color *= Color(0.87,0.85,0.78)
						mesh.set_surface_override_material(surface,aged)

func papers(room: String, p: Vector3, count: int, spread = 0.8):
	var root = marker(room,"abandoned_papers",p)
	for i in range(count):
		var sheet = town.box(root,Vector3(rng.randf_range(-spread,spread),float(i%3)*0.002,rng.randf_range(-spread,spread)),Vector3(0.20,0.003,0.28),paper,false)
		sheet.rotation.y = rng.randf_range(-2,2)
		for line in range(3):
			town.box(sheet,Vector3(-0.015,0.003,-0.06+line*0.033),Vector3(0.13,0.002,0.005),town.mats.dark,false)

func bag(room: String, p: Vector3, yaw: float):
	var root = marker(room,"half_packed_bag",p)
	root.rotation.y = yaw
	var cloth = town.mats.fabric.duplicate()
	cloth.albedo_color = Color("605c48")
	# Open suitcase: low base, lifted lid, two folded garments left inside.
	town.box(root,Vector3(0,0.12,0),Vector3(0.72,0.19,0.48),cloth,false)
	town.box(root,Vector3(0,0.225,0),Vector3(0.63,0.025,0.38),town.mats.dark,false)
	var lid = town.box(root,Vector3(0,0.40,-0.30),Vector3(0.72,0.46,0.055),cloth,false)
	lid.rotation.x = -0.2
	for x in [-0.16,0.16]:
		town.box(root,Vector3(x,0.25,0.015),Vector3(0.25,0.07,0.30),finishes[room].paint,false)
	town.box(root,Vector3(0,0.13,0.275),Vector3(0.18,0.04,0.045),town.mats.metal,false)

func spilled_carton(room: String, p: Vector3, yaw: float):
	var root = marker(room,"spilled_supplies",p)
	root.rotation.y = yaw
	var box_model = town.interiors.prop("box",root,Vector3(0,0,0),Vector3(0.75,0.75,0.75),0.2)
	box_model.rotation.z = 0.16
	for i in range(5):
		var pack = town.box(root,Vector3(0.30+i*0.15,0.075,rng.randf_range(-0.30,0.30)),Vector3(0.14,0.12,0.19),finishes[room].paint,false)
		pack.rotation = Vector3(0,rng.randf_range(-2,2),0.18)
		town.box(pack,Vector3(0,0.063,0),Vector3(0.10,0.006,0.11),paper,false)

func fallen_chair(room: String, p: Vector3, yaw: float):
	var root = marker(room,"broken_chair",p)
	root.rotation.y = yaw
	var model = kit.scenes.chair.instantiate()
	root.add_child(model)
	kit.adapt(model)
	# This is a broken wooden chair, with the seat and splintered frame on the
	# floor. Omit the original intact legs instead of disguising it as a rock.
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		if "leg" in mesh.name.to_lower():
			mesh.hide()
		for surface in range(mesh.mesh.get_surface_count()):
			var material = mesh.get_active_material(surface).duplicate()
			material.albedo_color *= Color("8b7658")
			mesh.set_surface_override_material(surface,material)
	model.rotation.z = PI/2
	var bounds = AABB()
	var first = true
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		if not mesh.visible: continue
		var local_transform: Transform3D = root.global_transform.affine_inverse()*mesh.global_transform
		var box: AABB = local_transform*mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	model.position.y -= bounds.position.y
	for i in range(4):
		var splinter = town.box(root,Vector3(0.15+i*0.12,0.07,0.15+i*0.05),Vector3(0.04,0.035,0.35-i*0.035),wood,false)
		splinter.rotation.y = -0.4+i*0.6

func crooked_frame(room: String, p: Vector3, yaw: float):
	var root = marker(room,"crooked_picture",p)
	root.rotation.y = yaw
	var frame = Node3D.new()
	root.add_child(frame)
	frame.rotation.z = -0.13
	town.box(frame,Vector3.ZERO,Vector3(0.6,0.48,0.04),wood,false)
	town.box(frame,Vector3(0,0,0.027),Vector3(0.5,0.38,0.01),paper,false)
	var crack = town.box(frame,Vector3(0.07,0,0.035),Vector3(0.008,0.4,0.003),town.mats.dark,false)
	crack.rotation.z = 0.45

func house():
	remove_chair("house",Vector3(2.7,0.04,1.05))
	bag("house",Vector3(-2.0,0.06,-3.65),-0.3)
	papers("house",Vector3(1.9,0.06,1.0),4,0.45)
	fallen_chair("house",Vector3(4.4,0.06,1.45),0.3)
	# One place setting remains on the table; another has shattered underneath.
	ceramic_shards("house",Vector3(3.35,0.06,0.85))
	crooked_frame("house",Vector3(-3.2,1.92,-0.82),0)
	spilled_carton("house",Vector3(5.05,0.06,-2.65),-1.4)

func ranger():
	papers("ranger",Vector3(-2.35,0.06,1.95),7,0.7)
	spilled_carton("ranger",Vector3(3.9,0.06,-3.2),0.5)
	crooked_frame("ranger",Vector3(-5.18,1.9,2.6),PI/2)
	# An empty filing box and a dragged chair suggest a rushed evacuation.
	for item in kit.instances:
		if item.get_meta("room")=="ranger" and item.get_meta("apartment_asset")=="chair" and item.position.z>3.0:
			item.position.x -= 0.55
			item.rotation.y += 0.35

func clinic():
	remove_chair("clinic",Vector3(4.72,0.04,2.85))
	spilled_carton("clinic",Vector3(-3.8,0.06,2.75),0.4)
	papers("clinic",Vector3(-2.8,0.06,2.55),5,0.65)
	fallen_chair("clinic",Vector3(3.65,0.06,3.55),0.6)
	# A rumpled blanket has been pulled off the bed, without blocking its drawer.
	var root = marker("clinic","discarded_blanket",Vector3(-3.25,0.07,1.1))
	var fabric = town.mats.fabric.duplicate()
	fabric.albedo_color = Color("78877a")
	for i in range(4):
		var fold = town.box(root,Vector3(i*0.18,0.015,0),Vector3(0.20,0.025,0.70),fabric,false)
		fold.rotation.y = 0.10-i*0.03

func store():
	spilled_carton("store",Vector3(-3.9,0.06,0.8),0.5)
	papers("store",Vector3(-2.65,0.06,-2.1),5,0.6)
	fallen_chair("store",Vector3(-3.5,0.06,2.75),-0.4)
	ceramic_shards("store",Vector3(-3.4,0.06,3.15))
	# Dislodged shelf board lies below its rack with splinters, off the aisle.
	var root = marker("store","broken_shelf",Vector3(4.1,0.08,0.25))
	var board = town.box(root,Vector3.ZERO,Vector3(0.95,0.035,0.29),wood,false)
	board.rotation.y = -0.4

func workshop():
	remove_chair("workshop",Vector3(4.1,0.04,3.6))
	fallen_chair("workshop",Vector3(4.1,0.06,2.5),0.5)
	spilled_carton("workshop",Vector3(4.2,0.06,-2.75),-0.8)
	papers("workshop",Vector3(-2.7,0.06,-1.55),3,0.5)
	# The broken tabletop is beside the bench, not across the mechanic's route.
	var root = marker("workshop","broken_table",Vector3(-4.8,0.07,3.8))
	for x in [-0.3,0.3]:
		var plank = town.box(root,Vector3(x,0.1,0),Vector3(0.5,0.08,0.85),wood,false)
		plank.rotation = Vector3(0.1,0.25*x,0.18*x)
	var leg = town.box(root,Vector3(0.6,0.08,0.2),Vector3(0.07,0.06,0.65),wood,false)
	leg.rotation.y = -0.6

func radio():
	papers("radio",Vector3(-2.6,0.06,-1.7),6,0.6)
	bag("radio",Vector3(-3.8,0.06,3.45),0.5)
	ceramic_shards("radio",Vector3(3.15,0.06,1.0))
	crooked_frame("radio",Vector3(-5.18,1.9,3.5),PI/2)
	# The lounge's lamp lies on its side, leaving the radio desk's light intact.
	for item in kit.instances:
		if item.get_meta("room")=="radio" and item.get_meta("apartment_asset")=="floor_lamp":
			kit.hide_placeholder(item)
	var root = marker("radio","fallen_lamp",Vector3(4.55,0.07,0.15))
	var stem = town.box(root,Vector3(-0.45,0.10,0),Vector3(1.15,0.035,0.035),town.mats.metal,false)
	stem.rotation.y = -0.3
	town.box(root,Vector3(0.15,0.16,0),Vector3(0.28,0.25,0.25),finishes.radio.paint,false)

func ceramic_shards(room: String, p: Vector3):
	var root = marker(room,"broken_ceramics",p)
	for i in range(7):
		var tool = SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var a = rng.randf_range(-PI,PI)
		var center = Vector3(rng.randf_range(-0.3,0.3),0,rng.randf_range(-0.3,0.3))
		for v in [Vector3(-0.055,0,-0.025),Vector3(0.05,0,0),Vector3(0.01,0,0.09)]:
			tool.set_normal(Vector3.UP)
			tool.add_vertex(center+v.rotated(Vector3.UP,a))
		var mesh = MeshInstance3D.new()
		mesh.mesh = tool.commit()
		var material = paper.duplicate()
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.material_override = material
		root.add_child(mesh)

func remove_chair(room: String, p: Vector3):
	for item in kit.instances:
		if item.get_meta("room")==room and item.get_meta("apartment_asset")=="chair" and item.position.distance_to(p)<0.1:
			kit.hide_placeholder(item)
