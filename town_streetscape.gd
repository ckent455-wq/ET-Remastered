extends Node3D
## Original geometry informed by Weston Main Street's street walls and shop proportions.
## Google imagery is reference only; all textures remain the project's local assets.
var town
var stone: StandardMaterial3D
var asphalt: StandardMaterial3D
var pavement: StandardMaterial3D
var glass: StandardMaterial3D
var dark_window: StandardMaterial3D
var lamps: Array[OmniLight3D] = []
var material_cache = {}
var road_mesh: ArrayMesh
const HEIGHTS = {"ranger":6.8,"clinic":7.4,"store":8.2,"house":10.1,"workshop":6.6,"radio":8.6}
const SIGNS = {"ranger":"RANGER OFFICE","clinic":"BLACKWOOD PHARMACY","store":"GENERAL STORE","house":"BLACKWOOD HOTEL","workshop":"MILL REPAIR CO.","radio":"BLACKWOOD RADIO"}
const TINTS = {"ranger":Color("8c7964"),"clinic":Color("876a56"),"store":Color("9b715b"),"house":Color("bbb8a2"),"workshop":Color("777b69"),"radio":Color("927361")}

func _ready():
	name = "HistoricMainStreet"
	stone = town.mats.plaster.duplicate()
	stone.albedo_color = Color("a19c87")
	asphalt = StandardMaterial3D.new()
	asphalt.albedo_texture = load("res://assets/roads/asphalt.png")
	asphalt.albedo_color = Color("b0b4ae")
	asphalt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	asphalt.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	asphalt.roughness = 1
	asphalt.metallic_specular = 0
	pavement = town.mats.plaster.duplicate()
	pavement.albedo_color = Color("787b6f")
	glass = town.color_material(Color(0.10,0.14,0.14,0.38))
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	dark_window = town.color_material(Color("182626"))

func brick(id: String) -> StandardMaterial3D:
	if not material_cache.has(id):
		var material = town.mats.brick.duplicate() as StandardMaterial3D
		material.albedo_color = TINTS.get(id,Color("8c7964"))
		material.uv1_scale = Vector3(0.7,0.7,0.7)
		if id=="house":
			material.albedo_texture = town.mats.plaster.albedo_texture
		material_cache[id] = material
	return material_cache[id]

func build_street():
	# Flat collision comes from the shared world floor; curb detail is visual.
	build_downloaded_roads()
	var flare = SurfaceTool.new()
	flare.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners = [Vector3(-1.6,0.016,-35),Vector3(1.6,0.016,-35),Vector3(-3.8,0.016,-38),Vector3(3.8,0.016,-38)]
	for index in [0,1,2,1,3,2]:
		flare.set_normal(Vector3.UP)
		flare.set_uv(Vector2(corners[index].x/3.2,corners[index].z/4))
		flare.add_vertex(corners[index])
	var entry = MeshInstance3D.new()
	entry.mesh = flare.commit()
	entry.material_override = asphalt
	add_child(entry)
	for side in [-1,1]:
		town.box(self,Vector3(side*5.15,0.012,-64),Vector3(2.7,0.016,56),pavement,false)
		town.box(self,Vector3(side*3.87,0.04,-64),Vector3(0.11,0.07,56),stone,false)
		for z in range(-39,-91,-3):
			town.box(self,Vector3(side*5.15,0.024,z),Vector3(2.6,0.008,0.025),town.mats.dark,false)
		for z in range(-44,-88,-5):
			var mark = town.box(self,Vector3(side*2.7,0.021,z),Vector3(1.85,0.008,0.045),stone,false)
			mark.rotation.y = side*0.45
		for z in [-43,-57,-76]:
			street_lamp(Vector3(side*4.35,0,z),side== -1 and z!= -57)
		for z in [-50,-65,-80]:
			planter(Vector3(side*6.0,0,z))
		sealed_shop(side,-85)
	# Random scars and patching interrupt the road without changing collision.
	var rng = RandomNumberGenerator.new()
	rng.seed = 68410
	for i in range(28):
		var scar = town.box(self,Vector3(rng.randf_range(-3.4,3.4),0.024,rng.randf_range(-88,-39)),Vector3(rng.randf_range(0.3,1.1),0.008,0.045),town.mats.dark,false)
		scar.rotation.y = rng.randf_range(-PI,PI)
	for i in range(18):
		var side = -1 if i%2==0 else 1
		var paper = town.box(self,Vector3(side*rng.randf_range(4.1,6.1),0.03,rng.randf_range(-87,-39)),Vector3(0.18,0.008,0.26),town.mats.paper,false)
		paper.rotation.y = rng.randf_range(-PI,PI)
	for i in range(3):
		parked_car(Vector3(-2.7 if i%2==0 else 2.7,0.015,[-52,-66,-79][i]),0.40 if i%2==0 else PI-0.4,i)
	weeds()
	# The far junction disappears into fog behind a temporary road closure.
	for x in [-3.0,0.0,3.0]:
		var barrier = town.box(self,Vector3(x,0.65,-91),Vector3(2.6,0.16,0.12),town.mats.wood)
		barrier.rotation.z = 0.04*x
		for leg in [-1,1]:
			town.box(self,Vector3(x+leg*0.9,0.32,-91),Vector3(0.12,0.64,0.35),town.mats.dark)

func build_downloaded_roads():
	# Reuse the asset's original asphalt geometry, UVs and painted markings.
	# Omit its raised sidewalk surface and automatic -col collision so the
	# existing level's flat floor and accessible entrances remain authoritative.
	var source = load("res://assets/roads/road_straight.glb").instantiate()
	road_mesh = ArrayMesh.new()
	extract_road_mesh(source)
	source.free()
	assert(road_mesh.get_surface_count()>0,"Downloaded road mesh is available")
	for i in range(5):
		road_segment(Vector3(0,-0.232,14.5-i*11),3.2)
		road_segment(Vector3(0,-0.232,-43.5-i*11),7.6)

func extract_road_mesh(node: Node):
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var original = node.mesh.surface_get_material(surface)
			if original and original.resource_name=="concrete":
				continue
			road_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,node.mesh.surface_get_arrays(surface))
			var material = original.duplicate() as StandardMaterial3D
			material.albedo_color = Color("b0b4ae")
			material.roughness = 1
			material.metallic_specular = 0
			material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			road_mesh.surface_set_material(road_mesh.get_surface_count()-1,material)
	for child in node.get_children():
		extract_road_mesh(child)

func road_segment(p: Vector3, width: float):
	var segment = MeshInstance3D.new()
	segment.name = "DownloadedRoadSegment"
	segment.mesh = road_mesh
	add_child(segment)
	segment.position = p
	segment.rotation.y = PI/2
	segment.scale = Vector3(1.1,1,width/6.166667)

func street_lamp(p: Vector3, lit: bool):
	var pole = Node3D.new()
	add_child(pole)
	pole.position = p
	town.game.mesh_at(pole,town.game.cylinder(0.14,0.10,0.30),Vector3(0,0.15,0),town.mats.dark)
	town.game.mesh_at(pole,town.game.cylinder(0.055,0.04,3.2),Vector3(0,1.8,0),town.mats.dark)
	town.box(pole,Vector3(0,3.65,0),Vector3(0.32,0.43,0.32),stone,false)
	for x in [-1,1]:
		for z in [-1,1]:
			town.box(pole,Vector3(x*0.15,3.65,z*0.15),Vector3(0.03,0.48,0.03),town.mats.dark,false)
	town.game.mesh_at(pole,town.game.cylinder(0.29,0.02,0.30,4),Vector3(0,4.0,0),town.mats.dark)
	if lit:
		var lamp = town.lamp(pole,Vector3(0,3.5,0),Color("c3a274"),0.85,7)
		lamps.append(lamp)

func planter(p: Vector3):
	town.box(self,p+Vector3(0,0.22,0),Vector3(0.6,0.44,0.8),town.mats.furniture)
	town.box(self,p+Vector3(0,0.45,0),Vector3(0.52,0.02,0.72),town.mats.dark,false)

func parked_car(p: Vector3, yaw: float, index: int):
	var body = StaticBody3D.new()
	body.name = "AbandonedParkedCar%d" % index
	add_child(body)
	body.position = p
	body.rotation.y = yaw
	var model = preload("res://assets/vehicles/crashed_hatchback.glb").instantiate()
	body.add_child(model)
	adapt_car(model,index)
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.85,1.25,3.7)
	collision.shape = shape
	collision.position.y = 0.7
	body.add_child(collision)

func adapt_car(node: Node, index: int):
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var original = node.mesh.surface_get_material(surface)
			if original is StandardMaterial3D:
				var material = original.duplicate() as StandardMaterial3D
				material.albedo_color = [Color("6c7067"),Color("6d5350"),Color("4e6060")][index]
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
				material.metallic_specular = 0
				material.roughness = 1
				node.set_surface_override_material(surface,material)
	for child in node.get_children():
		adapt_car(child,index)

func decorate_building(root: Node3D, data: Dictionary):
	var height: float = HEIGHTS[data.id]
	var w: float = data.w
	var front: float = data.d/2
	var material = brick(data.id)
	town.box(root,Vector3(0,(height+3.6)/2,0),Vector3(w,height-3.6,data.d),material,false)
	town.box(root,Vector3(0,height-0.1,0),Vector3(w+0.28,0.18,data.d+0.2),town.mats.dark,false)
	for y in [3.72,height-0.42,height]:
		town.box(root,Vector3(0,y,front+0.13),Vector3(w+0.23,0.15,0.35),stone,false)
	for x in [-w/2+0.13,w/2-0.13]:
		town.box(root,Vector3(x,height/2,front+0.09),Vector3(0.24,height,0.17),stone,false)
	for i in range(9):
		town.box(root,Vector3(-w/2+0.6+i*(w-1.2)/8,height-0.23,front+0.19),Vector3(0.14,0.23,0.26),stone,false)
	var upper_rows = [4.15,7.05] if data.id=="house" else [4.15]
	for base in upper_rows:
		for i in range(3):
			upper_window(root,(i-1)*w*0.29,base,front,data.id in ["house","store","radio"],(i+int(height))%3==0)
	# Original shop fronts: broad glazing, lower panels, and a central door.
	for side in [-1,1]:
		var x = side*w*0.31
		town.box(root,Vector3(x,1.7,front+0.045),Vector3(2.5,2.2,0.055),glass)
		for edge in [-1,1]:
			town.box(root,Vector3(x+edge*1.28,1.7,front+0.12),Vector3(0.075,2.3,0.12),stone,false)
		for y in [0.60,2.8]:
			town.box(root,Vector3(x,y,front+0.12),Vector3(2.63,0.10,0.15),stone,false)
		town.box(root,Vector3(x,1.7,front+0.1),Vector3(0.045,2.1,0.07),town.mats.dark,false)
		for plank in range(2 if data.id!="clinic" else 1):
			var board = town.box(root,Vector3(x,1.2+plank*0.7,front+0.19),Vector3(2.72,0.20,0.08),town.mats.wood,false)
			board.rotation.z = side*(0.14 if plank==0 else -0.19)
		awning(root,x,front,data.id,side)
	var fascia = town.mats.wood.duplicate()
	fascia.albedo_color = Color("645b4c")
	town.box(root,Vector3(0,3.28,front+0.16),Vector3(w-0.6,0.65,0.16),fascia,false)
	var sign = town.sign_text(root,SIGNS[data.id],Vector3(0,3.28,front+0.255),40,Color("b8b09a"))
	sign.font = ThemeDB.fallback_font
	sign.pixel_size = 0.010
	sign.outline_size = 0
	sign.shaded = true
	blade_sign(root,w/2-0.65,front,SIGNS[data.id].split(" ")[0])
	var notice = town.sign_text(root,"CLOSED BY ORDER" if data.id!="house" else "NO VACANCY",Vector3(1.18,1.85,front+0.20),19,Color("a69d86"))
	notice.pixel_size = 0.005
	notice.shaded = true
	notice.outline_size = 0

func upper_window(root: Node3D, x: float, base: float, front: float, arched: bool, boarded: bool):
	var top = base+1.25
	town.box(root,Vector3(x,base+0.64,front+0.045),Vector3(1.15,1.3,0.08),dark_window,false)
	if arched:
		var tool = SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(8):
			var a = i*PI/8
			var b = (i+1)*PI/8
			for vertex in [Vector3(x,top,front+0.09),Vector3(x+cos(a)*0.58,top+sin(a)*0.58,front+0.09),Vector3(x+cos(b)*0.58,top+sin(b)*0.58,front+0.09)]:
				tool.set_normal(Vector3(0,0,1))
				tool.add_vertex(vertex)
		var pane = MeshInstance3D.new()
		pane.mesh = tool.commit()
		pane.material_override = dark_window
		root.add_child(pane)
		for i in range(9):
			var angle = i*PI/8
			var voussoir = town.box(root,Vector3(x+cos(angle)*0.66,top+sin(angle)*0.66,front+0.13),Vector3(0.20,0.12,0.16),stone,false)
			voussoir.rotation.z = angle+PI/2
	else:
		town.box(root,Vector3(x,base+1.48,front+0.05),Vector3(1.15,0.4,0.08),dark_window,false)
		town.box(root,Vector3(x,base+1.72,front+0.13),Vector3(1.46,0.14,0.17),stone,false)
	for edge in [-1,1]:
		town.box(root,Vector3(x+edge*0.65,base+0.66,front+0.12),Vector3(0.12,1.45,0.16),stone,false)
	town.box(root,Vector3(x,base-0.06,front+0.16),Vector3(1.48,0.13,0.28),stone,false)
	town.box(root,Vector3(x,base+0.7,front+0.13),Vector3(1.15,0.055,0.10),town.mats.dark,false)
	town.box(root,Vector3(x,base+0.65,front+0.13),Vector3(0.055,1.30,0.10),town.mats.dark,false)
	if boarded:
		for i in range(2):
			var board = town.box(root,Vector3(x,base+0.45+i*0.5,front+0.22),Vector3(1.4,0.17,0.065),town.mats.wood,false)
			board.rotation.z = 0.19 if i==0 else -0.13

func awning(root: Node3D, x: float, front: float, id: String, side: int):
	var cloth = town.mats.fabric.duplicate()
	cloth.albedo_color = Color("5d4a49") if id in ["store","house"] else Color("49594f")
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(7):
		if i==(2 if side<0 else 5):
			continue
		var left = x-1.45+i*0.414
		var right = left+0.414
		var dip = 0.08 if i%3==0 else 0.0
		var points = [Vector3(left,2.98,front+0.15),Vector3(right,2.98,front+0.15),Vector3(left,2.57-dip,front+1.12),Vector3(right,2.57-dip,front+1.12)]
		for index in [0,2,1,1,2,3]:
			tool.set_normal(Vector3(0,1,0.4).normalized())
			tool.set_uv(Vector2(float(index%2),float(index/2)))
			tool.add_vertex(points[index])
		var valance = town.box(root,Vector3((left+right)/2,2.48-dip,front+1.12),Vector3(0.40,0.18,0.025),cloth,false)
		valance.rotation.z = -side*0.04
	var mesh = MeshInstance3D.new()
	mesh.mesh = tool.commit()
	mesh.material_override = cloth
	root.add_child(mesh)

func blade_sign(root: Node3D, x: float, front: float, text: String):
	town.box(root,Vector3(x,3.05,front+0.80),Vector3(0.06,0.06,1.60),town.mats.dark,false)
	var sign = Node3D.new()
	root.add_child(sign)
	sign.position = Vector3(x,2.52,front+1.05)
	sign.rotation.y = PI/2
	town.box(sign,Vector3.ZERO,Vector3(1.15,0.60,0.09),town.mats.furniture,false)
	for side in [-1,1]:
		var label = town.sign_text(sign,text,Vector3(0,0,side*0.06),25,Color("b4ac92"))
		label.pixel_size = 0.006
		label.rotation.y = PI if side<0 else 0.0
		label.shaded = true
		label.outline_size = 0

func sealed_shop(side: int, z: float):
	var root = Node3D.new()
	root.name = "BoardedAntiques" if side<0 else "BoardedDryGoods"
	add_child(root)
	root.position = Vector3(side*10.5,0,z)
	root.rotation.y = PI/2 if side<0 else -PI/2
	town.box(root,Vector3(0,3.1,0),Vector3(10,6.2,8),brick("ranger"))
	for x in [-3,0,3]:
		upper_window(root,x,3.8,4,false,true)
		for i in range(5):
			town.box(root,Vector3(x,0.35+i*0.45,4.12),Vector3(2.7,0.38,0.12),town.mats.wood,false)
	town.box(root,Vector3(0,6.2,4.1),Vector3(10.3,0.22,0.3),stone,false)
	var label = town.sign_text(root,"ANTIQUES" if side<0 else "DRY GOODS",Vector3(0,2.85,4.2),38,Color("96917c"))
	label.pixel_size = 0.012
	label.shaded = true
	label.outline_size = 0

func weeds():
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in [Vector3(0.12,0,0),Vector3(0,0,0.12)]:
		for vertex in [-axis,axis,Vector3(0,0.38,0)]:
			tool.set_normal(Vector3.UP)
			tool.add_vertex(vertex)
	var multi = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = tool.commit()
	multi.instance_count = 48
	var node = MultiMeshInstance3D.new()
	node.multimesh = multi
	var material = town.color_material(Color("52604a"))
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = material
	add_child(node)
	for i in range(48):
		var side = -1 if i%2==0 else 1
		multi.set_instance_transform(i,Transform3D(Basis(Vector3.UP,i*1.3),Vector3(side*(3.8 if i%3==0 else 6.23),0.025,-39-i*1.02)))

func _process(_delta):
	for i in range(lamps.size()):
		var flicker = 0.93+0.07*sin(town.game.clock*1.7+i)
		lamps[i].light_energy = 0.85*flicker
