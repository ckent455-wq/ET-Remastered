extends Node3D
## Original geometry informed by Weston Main Street's street walls and shop proportions.
## Google imagery is reference only; all textures remain the project's local assets.
var town
var sebus:Node3D
var stone: StandardMaterial3D
var asphalt: StandardMaterial3D
var pavement: StandardMaterial3D
var glass: StandardMaterial3D
var dark_window: StandardMaterial3D
var lamps: Array[OmniLight3D] = []
var lantern_materials: Array[StandardMaterial3D] = []
var lantern_halos: Array[Sprite3D] = []
var emergency_lights: Array[OmniLight3D] = []
var emergency_lenses:Array[StandardMaterial3D]=[]
var emergency_halos:Array[Sprite3D]=[]
var material_cache = {}
var road_mesh: ArrayMesh
var approach_road_mesh: ArrayMesh
var church: Node3D
var chapel_hill: Node3D
const HEIGHTS = {"ranger":6.8,"clinic":7.4,"store":8.2,"house":10.1,"workshop":6.6,"radio":8.6}
const SIGNS = {"ranger":"RANGER OFFICE","clinic":"BLACKWOOD PHARMACY","store":"GENERAL STORE","house":"SAINT GEORGE HOTEL","workshop":"MILL REPAIR CO.","radio":"BLACKWOOD RADIO"}
const TINTS = {"ranger":Color("8c7964"),"clinic":Color("876a56"),"store":Color("9b715b"),"house":Color("b88b7c"),"workshop":Color("777b69"),"radio":Color("927361")}

func _ready():
	name = "HistoricMainStreet"
	stone = town.mats.plaster.duplicate()
	stone.albedo_color = Color("a19c87")
	asphalt = StandardMaterial3D.new()
	asphalt.albedo_texture = load("res://assets/roads_experiment/asphalt.jpg")
	asphalt.albedo_color = Color("b0b4ae")
	asphalt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	asphalt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	asphalt.cull_mode = BaseMaterial3D.CULL_DISABLED
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
		material_cache[id] = material
	return material_cache[id]

func build_street():
	# Flat collision comes from the shared world floor; curb detail is visual.
	build_downloaded_roads()
	# Use the same kit mesh, material and height across the old transition gap.
	var entry = MeshInstance3D.new()
	entry.name = "ContinuousTownEntryAsphalt"
	preload("res://footstep_surfaces.gd").visual(entry,"concrete")
	entry.mesh = road_mesh
	entry.material_override = asphalt
	entry.position = Vector3(0,0.035,-36.5)
	entry.scale.z = 3.0/11.0
	add_child(entry)
	var paint = town.color_material(Color("87835d"))
	town.box(self,Vector3(0,0.027,-36.5),Vector3(0.06,0.008,1.15),paint,false)
	for side in [-1,1]:
		var edge = town.box(self,Vector3(side*3.8,0.028,-36.5),Vector3(0.045,0.008,3.16),stone,false)
		edge.rotation.y = 0
	for side in [-1,1]:
		var sidewalk=town.box(self,Vector3(side*5.15,0.012,-64),Vector3(2.7,0.016,56),pavement,false)
		preload("res://footstep_surfaces.gd").visual(sidewalk.get_child(0),"concrete")
		town.box(self,Vector3(side*3.87,0.04,-64),Vector3(0.11,0.07,56),stone,false)
		for z in range(-39,-91,-3):
			town.box(self,Vector3(side*5.15,0.024,z),Vector3(2.6,0.008,0.025),town.mats.dark,false)
		for z in range(-44,-88,-5):
			var mark = town.box(self,Vector3(side*2.7,0.021,z),Vector3(1.85,0.008,0.045),stone,false)
			mark.rotation.y = side*0.45
		for z in [-43,-57,-76]:
			street_lamp(Vector3(side*4.35,0,z))
		for z in [-50,-65,-80]:
			planter(Vector3(side*6.0,0,z))
		sealed_shop(side,-85)
	church = Node3D.new()
	church.set_script(preload("res://blackwood_church.gd"))
	church.town = town
	add_child(church)
	chapel_hill = Node3D.new()
	chapel_hill.set_script(preload("res://chapel_hill.gd"))
	chapel_hill.town = town
	chapel_hill.church = church
	add_child(chapel_hill)
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
	parked_car(Vector3(-2.7,0.015,-52),0.18,0,"res://assets/vehicles/abandoned_pickup.glb",Vector3(2.0,1.4,4.4))
	parked_car(Vector3(2.7,0.015,-66),PI-0.24,1,"res://assets/vehicles/abandoned_police_openable.glb",Vector3(1.85,1.4,4.3))
	parked_car(Vector3(-2.7,0.015,-79),0.18,2,"res://assets/vehicles/abandoned_muscle.glb",Vector3(2.0,1.15,4.1))
	parked_car(Vector3(2.7,0.015,-48),PI-0.32,3,"res://assets/vehicles/abandoned_classic.glb",Vector3(1.8,1.25,4.2))
	parked_car(Vector3(-2.7,0.015,-61),0.20,4,"res://assets/vehicles/abandoned_van.glb",Vector3(2.0,1.55,4.5))
	weeds()
	# Main Street now opens onto the climb to the chapel.

func build_downloaded_roads():
	# User-downloaded Roads kit, baked to the existing route dimensions.
	for kind in ["approach","main_street"]:
		var source=load("res://assets/roads_experiment/"+kind+".glb").instantiate()
		road_mesh=ArrayMesh.new()
		extract_road_mesh(source)
		source.free()
		assert(road_mesh.get_surface_count()>0,"New road mesh is available")
		if kind=="approach":approach_road_mesh=road_mesh
	for i in range(5):
		road_segment(Vector3(0,-0.232,14.5-i*11),7.6)
		road_segment(Vector3(0,-0.232,-43.5-i*11),7.6)
	# Scenic continuation behind the crash, beyond the invisible travel limit.
	for i in range(7):
		road_segment(Vector3(0,-0.232,25.5+i*11),7.6)

func extract_road_mesh(node: Node):
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var original = node.mesh.surface_get_material(surface)
			if original and original.resource_name=="concrete":
				continue
			var arrays=node.mesh.surface_get_arrays(surface)
			var normals=PackedVector3Array()
			normals.resize(arrays[Mesh.ARRAY_VERTEX].size())
			normals.fill(Vector3.UP)
			arrays[Mesh.ARRAY_NORMAL]=normals
			road_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			var material = asphalt.duplicate() as StandardMaterial3D
			material.albedo_color = Color("c4c3b9")
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			material.roughness = 1
			material.metallic_specular = 0
			material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			road_mesh.surface_set_material(road_mesh.get_surface_count()-1,material)
	for child in node.get_children():
		extract_road_mesh(child)

func road_segment(p: Vector3, width: float):
	var segment = MeshInstance3D.new()
	segment.name = "DownloadedRoadSegment"
	preload("res://footstep_surfaces.gd").visual(segment,"concrete")
	segment.mesh = approach_road_mesh if width<4 else road_mesh
	segment.material_override = asphalt
	add_child(segment)
	segment.position = Vector3(p.x,0.035,p.z)
	# End exactly where the chapel incline starts; overlapping slopes flash pale.
	if is_equal_approx(p.z,-87.5):
		segment.position.z=-87.0
		segment.scale.z=10.0/11.0

func street_lamp(p: Vector3):
	var pole = Node3D.new()
	pole.name = "PulsingStreetLamp%d" % lamps.size()
	add_child(pole)
	pole.position = p
	town.game.mesh_at(pole,town.game.cylinder(0.14,0.10,0.30),Vector3(0,0.15,0),town.mats.dark)
	town.game.mesh_at(pole,town.game.cylinder(0.055,0.04,3.2),Vector3(0,1.8,0),town.mats.dark)
	var lantern = town.color_material(Color("b8a17c"),0.6)
	lantern.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	town.box(pole,Vector3(0,3.65,0),Vector3(0.28,0.39,0.28),lantern,false)
	lantern_materials.append(lantern)
	for x in [-1,1]:
		for z in [-1,1]:
			town.box(pole,Vector3(x*0.15,3.65,z*0.15),Vector3(0.03,0.48,0.03),town.mats.dark,false)
	town.game.mesh_at(pole,town.game.cylinder(0.29,0.02,0.30,4),Vector3(0,4.0,0),town.mats.dark)
	var lamp = town.lamp(pole,Vector3(0,3.5,0),Color("c3a274"),0.4,6)
	lamp.shadow_enabled = false
	lamps.append(lamp)
	var glow_image = Image.create(32,32,false,Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var radius = Vector2(x-15.5,y-15.5).length()/15.5
			glow_image.set_pixel(x,y,Color(1,1,1,pow(maxf(0,1-radius),2)))
	var halo = Sprite3D.new()
	halo.name = "SoftLanternGlow"
	halo.texture = ImageTexture.create_from_image(glow_image)
	halo.pixel_size = 0.035
	halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	halo.position.y = 3.65
	halo.modulate = Color(0.77,0.65,0.46,0.2)
	pole.add_child(halo)
	lantern_halos.append(halo)

func planter(p: Vector3):
	town.box(self,p+Vector3(0,0.22,0),Vector3(0.6,0.44,0.8),town.mats.furniture)
	town.box(self,p+Vector3(0,0.45,0),Vector3(0.52,0.02,0.72),town.mats.dark,false)

func parked_car(p: Vector3, yaw: float, index: int, model_path = "res://assets/vehicles/crashed_hatchback.glb", body_size = Vector3(1.85,1.25,3.7)):
	var body = StaticBody3D.new()
	body.name = "AbandonedParkedCar%d" % index
	add_child(body)
	body.position = p
	body.rotation.y = yaw
	body.set_meta("vehicle_model",model_path)
	body.set_meta("footstep_surface","metal")
	var model = load(model_path).instantiate()
	body.add_child(model)
	adapt_car(model,index)
	if "abandoned_police" in model_path:
		police_lightbar(body)
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = body_size
	collision.shape = shape
	collision.position.y = body_size.y/2+0.05
	body.add_child(collision)

func police_lightbar(body: Node3D):
	# Match the downloaded model's existing roof lightbar, rather than adding a beacon.
	var image = Image.create(32,32,false,Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var radius = Vector2(x-15.5,y-15.5).length()/15.5
			image.set_pixel(x,y,Color(1,1,1,pow(maxf(0,1-radius),2)))
	var halo_texture = ImageTexture.create_from_image(image)
	for side in [-1,1]:
		var color = Color("b72b37") if side<0 else Color("335ec2")
		var lens = town.color_material(color,0.65)
		lens.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		town.box(body,Vector3(side*0.27,1.422,0.29),Vector3(0.25,0.055,0.17),lens,false)
		var glow = OmniLight3D.new()
		glow.name = "EmergencyRedGlow" if side<0 else "EmergencyBlueGlow"
		glow.position = Vector3(side*0.3,1.54,0.29)
		glow.light_color = Color(1.0,0.045,0.07) if side<0 else Color(0.055,0.14,1.0)
		glow.light_energy = 0.8
		glow.omni_range = 5.5
		glow.omni_attenuation = 1.2
		glow.shadow_enabled = false
		glow.light_cull_mask = 1
		body.add_child(glow)
		var halo = Sprite3D.new()
		halo.name = "SoftLightbarHalo"
		halo.texture = halo_texture
		halo.pixel_size = 0.022
		halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		halo.modulate = Color(glow.light_color.r,glow.light_color.g,glow.light_color.b,0.28)
		halo.position = Vector3(side*0.27,1.48,0.29)
		body.add_child(halo)
		emergency_lights.append(glow)
		emergency_lenses.append(lens)
		emergency_halos.append(halo)

func adapt_car(node: Node, index: int):
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var original = node.mesh.surface_get_material(surface)
			if original is StandardMaterial3D:
				var material = original.duplicate() as StandardMaterial3D
				material.albedo_color = [Color("6c7067"),Color("6d5350"),Color("4e6060"),Color("958b70"),Color("7b8780")][index]
				material.albedo_color.a=original.albedo_color.a
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
				material.metallic_specular = 0
				material.roughness = 1
				node.set_surface_override_material(surface,material)
	for child in node.get_children():
		adapt_car(child,index)

func decorate_building(root: Node3D, data: Dictionary):
	if data.id=="house":
		decorate_saint_george(root,data)
		return
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
	sign.pixel_size = 0.0085 if data.id=="house" else 0.010
	sign.outline_size = 0
	sign.shaded = true
	var notice = town.sign_text(root,"CLOSED BY ORDER" if data.id!="house" else "NO VACANCY",Vector3(1.18,1.85,front+0.20),19,Color("a69d86"))
	notice.pixel_size = 0.005
	notice.shaded = true
	notice.outline_size = 0

func decorate_saint_george(root: Node3D, data: Dictionary):
	# Original PS2 geometry informed by the May 2025 Google Street View exterior in Weston.
	var w: float = data.w
	var d: float = data.d
	var front = d/2
	var trim = stone.duplicate()
	trim.albedo_color = Color("b7b09a")
	var brickwork = brick("house")
	var facade = Node3D.new()
	facade.name = "SaintGeorgeBrickFacade"
	root.add_child(facade)
	town.box(facade,Vector3(0,5.48,0),Vector3(w,3.76,d),brickwork,false)
	for y in [3.73,7.32]:
		town.box(facade,Vector3(0,y,0),Vector3(w+0.32,0.16,d+0.32),trim,false)
	# Tall rectangular sash windows replace the old generic arched hotel windows.
	for i in range(5):
		upper_window(facade,(i-2)*2.15,4.35,front,false,i==4)
	for side in [-1,1]:
		var wall = Node3D.new()
		facade.add_child(wall)
		wall.position.x = side*w/2
		wall.rotation.y = side*PI/2
		for i in range(3): upper_window(wall,(i-1)*2.7,4.35,0,false,i==2)
	# Broad ground-floor glazing and shallow transoms respect the existing room openings.
	for side in [-1,1]:
		var x = side*w*0.31
		town.box(facade,Vector3(x,1.65,front+0.14),Vector3(2.5,2.1,0.06),glass,false)
		for edge in [-1,1]:
			town.box(facade,Vector3(x+edge*1.29,1.65,front+0.21),Vector3(0.11,2.24,0.12),trim,false)
		for y in [0.57,2.35,2.76]:
			town.box(facade,Vector3(x,y,front+0.22),Vector3(2.65,0.09,0.14),trim,false)
		for offset in [-0.64,0,0.64]:
			town.box(facade,Vector3(x+offset,1.64,front+0.23),Vector3(0.045,2.14,0.08),trim,false)
		var board = town.box(facade,Vector3(x,1.15,front+0.28),Vector3(2.6,0.17,0.06),town.mats.wood,false)
		board.rotation.z = side*0.09
		# Pilasters flank the central doorway, leaving its swing and threshold clear.
		town.box(facade,Vector3(side*1.1,1.48,front+0.23),Vector3(0.16,2.96,0.22),trim,false)
		town.box(facade,Vector3(side*1.1,2.91,front+0.25),Vector3(0.29,0.17,0.28),trim,false)
	var blue = town.color_material(Color("293e49"))
	town.box(facade,Vector3(0,3.28,front+0.20),Vector3(w-0.45,0.65,0.18),blue,false)
	var title = town.sign_text(facade,"SAINT GEORGE HOTEL",Vector3(0,3.28,front+0.305),40,Color("dad2b9"))
	title.font = ThemeDB.fallback_font
	title.pixel_size = 0.012
	title.shaded = true
	title.outline_size = 0
	# Four low-poly slate slopes and three dormers create the characteristic roof silhouette.
	var slate = town.mats.roof.duplicate()
	slate.albedo_color = Color("4c5655")
	var roof = SurfaceTool.new()
	roof.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lower = [Vector3(-w/2-0.2,7.43,-d/2-0.2),Vector3(w/2+0.2,7.43,-d/2-0.2),Vector3(w/2+0.2,7.43,front+0.2),Vector3(-w/2-0.2,7.43,front+0.2)]
	var upper = [Vector3(-w/2+0.95,10.0,-d/2+0.95),Vector3(w/2-0.95,10.0,-d/2+0.95),Vector3(w/2-0.95,10.0,front-0.95),Vector3(-w/2+0.95,10.0,front-0.95)]
	for side in range(4):
		var next = (side+1)%4
		var vertices = [lower[side],lower[next],upper[side],upper[next]]
		var uvs = [Vector2(0,0),Vector2(6,0),Vector2(0,2),Vector2(6,2)]
		for i in [0,2,1,1,2,3]:
			roof.set_uv(uvs[i])
			roof.add_vertex(vertices[i])
	roof.generate_normals()
	var slopes = MeshInstance3D.new()
	slopes.name = "SlateMansardRoof"
	slopes.mesh = roof.commit()
	slate.cull_mode = BaseMaterial3D.CULL_DISABLED
	slopes.material_override = slate
	facade.add_child(slopes)
	town.box(facade,Vector3(0,10.02,0),Vector3(w-1.8,0.15,d-1.8),slate,false)
	for x in [-3.7,0,3.7]:
		town.box(facade,Vector3(x,8.5,front-0.45),Vector3(1.5,1.75,1.35),slate,false)
		upper_window(facade,x,7.74,front+0.24,false,false)
		# Small stepped caps distinguish this version from the real hotel's ornament.
		town.box(facade,Vector3(x,9.64,front-0.14),Vector3(1.78,0.13,1.95),trim,false)
		town.box(facade,Vector3(x,9.76,front-0.14),Vector3(1.46,0.12,1.75),slate,false)
	for x in [-w/2+0.3,w/2-0.3]:
		town.box(facade,Vector3(x,10.28,-1.7),Vector3(0.7,1.2,0.65),brickwork,false)
		town.box(facade,Vector3(x,10.90,-1.7),Vector3(0.9,0.12,0.82),trim,false)

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

func sealed_shop(side: int, z: float):
	var root = Node3D.new()
	root.name = "BoardedAntiques" if side<0 else "BoardedSebusHardware"
	add_child(root)
	root.position = Vector3(side*10.5,0,z)
	root.rotation.y = PI/2 if side<0 else -PI/2
	if side>0:
		sebus=preload("res://sebus_hardware.gd").new();sebus.town=town;root.add_child(sebus)
	else:town.box(root,Vector3(0,3.1,0),Vector3(10,6.2,8),brick("ranger"))
	for x in [-3,0,3]:
		upper_window(root,x,3.8,4,false,true)
		if side>0 and x==0:continue
		for i in range(5):
			town.box(root,Vector3(x,0.35+i*0.45,4.12),Vector3(2.7,0.38,0.12),town.mats.wood,false)
	town.box(root,Vector3(0,6.2,4.1),Vector3(10.3,0.22,0.3),stone,false)
	var label = town.sign_text(root,"ANTIQUES" if side<0 else "SEBUS HARDWARE",Vector3(0,2.85,4.2),38,Color("96917c"))
	label.pixel_size = 0.012 if side<0 else 0.009
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
	update_emergency_lights(town.game.clock)
	for i in range(lamps.size()):
		# Low, smooth breathing glow; each lamp drifts slightly out of phase.
		var pulse = 0.5+0.5*sin(town.game.clock*1.05+i*0.9)
		lamps[i].light_energy = lerpf(0.28,0.46,pulse)
		lantern_materials[i].emission_energy_multiplier = lerpf(0.35,0.65,pulse)
		lantern_materials[i].albedo_color = Color("b8a17c")*lerpf(0.65,0.85,pulse)
		lantern_halos[i].modulate.a = lerpf(0.13,0.22,pulse)


func update_emergency_lights(time:float):
	for i in range(emergency_lights.size()):
		var phase=fmod(time+i*0.6,1.2)
		var lit=phase<0.48
		emergency_lights[i].light_energy=0.95 if lit else 0.0
		emergency_lenses[i].emission_energy_multiplier=1.1 if lit else 0.0
		emergency_halos[i].modulate.a=0.30 if lit else 0.0
