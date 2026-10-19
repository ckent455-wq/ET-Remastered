extends RefCounted
## Photo-led room plans. Coordinates are in metres, in each building's space.
## Keep the central entrance aisle and the original interactive storage positions.
var kit
var town
var finishes = {}
var finish_cache = {}
const PALETTES = {
	"house":["98917f","544e42","655747"],
	"ranger":["939785","454e43","5e5140"],
	"clinic":["9ba89f","62776e","6f736a"],
	"store":["a2967c","5b5140","6e5942"],
	"workshop":["85877d","505850","58584f"],
	"radio":["8a9188","485650","625244"]
}

func _init(owner):
	kit = owner
	town = kit.town

func build():
	clear_old_dressing()
	for data in town.BUILDINGS:
		architecture(data)
	work_desks()
	house()
	ranger()
	clinic()
	store()
	workshop()
	radio()
	var decay = preload("res://interior_decay.gd").new(kit,finishes)
	decay.build()

func clear_old_dressing():
	for group in ["LegacyDesks","LegacyClinicBeds","LegacyHouseBeds","InteriorShelfBases","LegacyInteriorClutter"]:
		for old in kit.get_tree().get_nodes_in_group(group):
			kit.hide_placeholder(old)
	# Remove the repeated boxes, floating books and giant shelf assemblies.
	# Doors, curtains and the interactive kitchen sink retain their real function.
	for old in kit.get_tree().get_nodes_in_group("LocalInteriorProps"):
		if old.get_meta("source_asset") not in ["door","curtain","sink"]:
			kit.hide_placeholder(old)

func matte(color: String) -> StandardMaterial3D:
	return town.color_material(Color(color))

func block(room: String, p: Vector3, size: Vector3, material: Material, solid = false):
	return town.box(town.buildings[room],p,size,material,solid)

func architecture(data):
	var room: String = data.id
	var w: float = data.w
	var palette = PALETTES[room]
	var paint = town.mats.plaster.duplicate()
	paint.albedo_color = Color(palette[0])
	var trim = matte(palette[1])
	var wood = town.mats.furniture.duplicate()
	wood.albedo_color = Color(palette[2])
	finishes[room] = {"paint":paint,"trim":trim,"wood":wood}
	# Continuous plaster replaces the exposed brick inside; lower panels and a
	# lower ceiling establish a human-sized room rather than a warehouse shell.
	for side in [-1,1]:
		block(room,Vector3(side*(w/2-0.21),1.55,0),Vector3(0.035,3.08,9.64),paint)
		block(room,Vector3(side*(w/2-0.25),0.52,0),Vector3(0.045,0.99,9.60),trim)
		for y in [0.12,1.05,2.98]:
			block(room,Vector3(side*(w/2-0.29),y,0),Vector3(0.07,0.07,9.6),wood)
		for z in [-4,-2,0,2,4]:
			block(room,Vector3(side*(w/2-0.28),0.55,z),Vector3(0.06,0.86,0.035),wood)
		# Inside faces of the shopfront piers: keep the glazing and doorway open.
		var window: float = w*0.31
		for span in [Vector2(0.97,window-1.26),Vector2(window+1.26,w/2-0.22)]:
			var center = side*(span.x+span.y)/2
			block(room,Vector3(center,1.55,4.83),Vector3(span.y-span.x,3.05,0.035),paint)
		block(room,Vector3(side*(w/4+0.48),0.30,4.81),Vector3(w/2-0.98,0.56,0.04),trim)
		block(room,Vector3(side*(w/4+0.48),2.97,4.81),Vector3(w/2-0.98,0.27,0.04),paint)
		block(room,Vector3(side*window,0.61,4.78),Vector3(2.58,0.08,0.15),wood)
	block(room,Vector3(0,1.55,-4.78),Vector3(w-0.4,3.08,0.035),paint)
	block(room,Vector3(0,0.52,-4.74),Vector3(w-0.5,0.99,0.045),trim)
	for y in [0.12,1.05,2.98]:
		block(room,Vector3(0,y,-4.70),Vector3(w-0.5,0.07,0.07),wood)
	var ceiling = town.mats.plaster.duplicate()
	ceiling.albedo_color = Color("89897d")
	block(room,Vector3(0,3.10,0),Vector3(w-0.3,0.07,9.7),ceiling)
	for partition in kit.get_tree().get_nodes_in_group("InteriorPartitions"):
		if partition.get_parent()==town.buildings[room]:
			partition.get_child(0).material_override = paint
			block(room,Vector3(w/4,1.05,-1.505),Vector3(w/2-0.8,0.07,0.045),wood)
	# Distinct floor finishes: tile in the clinic, concrete in the workshop,
	# and dark timber in the domestic rooms and offices.
	var floor_finish = town.mats.floor.duplicate()
	floor_finish.albedo_color = Color("837563")
	if room=="clinic":
		floor_finish = tile_material()
	elif room=="workshop":
		floor_finish = town.mats.plaster.duplicate()
		floor_finish.albedo_color = Color("65685e")
	block(room,Vector3(0,0.029,0),Vector3(w-0.4,0.014,9.6),floor_finish)
	# Real ceiling fittings and restrained pools of light.
	if room=="house":
		pendant(room,Vector3(2.7,2.55,0))
	else:
		for x in [-2.8,2.8]:
			block(room,Vector3(x,3.02,0.7),Vector3(0.58,0.07,0.25),trim)
			block(room,Vector3(x,2.97,0.7),Vector3(0.46,0.025,0.17),matte("b1ad92"))
	# Refinish existing searchable storage to belong to its room.
	for storage in town.interiors.containers.values():
		if storage.root.get_parent()!=town.buildings[room]:
			continue
		var finish = trim if room in ["clinic","workshop","radio"] else wood
		for mesh in storage.root.find_children("*","MeshInstance3D",true,false):
			if mesh.material_override==town.mats.furniture or mesh.material_override==town.mats.plaster:
				mesh.material_override = finish
	clock(room,Vector3(w/2-0.32,2.3,1.1),-PI/2)
	# Small patches of damage collect at skirting and corners, not uniformly
	# scattered through every room. Flat decals have no collision or glow.
	for i in range(4):
		var z = -3.8+i*0.19
		block(room,Vector3(-w/2+0.236,0.3+i*0.09,z),Vector3(0.004,0.42-i*0.06,0.22),matte("5e6254"))
	if room in ["house","ranger","radio"]:
		var light = town.lamp(town.buildings[room],Vector3(-3.7 if room=="house" else 3.7,2.3,2.2),Color("c1aa7c"),0.22,4.2)
		light.light_bake_mode = Light3D.BAKE_DISABLED

func tile_material():
	var image = Image.create(64,64,false,Image.FORMAT_RGB8)
	for y in range(64):
		for x in range(64):
			var grout = x%16<1 or y%16<1
			var value = 0.53 if (x/16+y/16)%2==0 else 0.61
			if grout: value = 0.32
			value += float((x*13+y*7)%9)*0.002
			image.set_pixel(x,y,Color(value*0.92,value,value*0.94))
	var material = matte("ffffff")
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.uv1_triplanar = true
	material.uv1_scale = Vector3(0.5,0.5,0.5)
	return material

func furniture(asset: String, room: String, p: Vector3, yaw = 0.0, scale = Vector3.ONE, solid = true):
	var node = kit.place(asset,room,p,yaw,scale,solid)
	var color = Color.WHITE
	if asset in ["desk","coffee_table","side_table","dresser","wardrobe","chair","dining_table"]:
		color = Color("a28d6e")
	elif asset=="sofa":
		color = Color("737766") if room=="radio" else Color("8e7962")
	elif asset in ["counter","wall_cabinet"]:
		color = Color("b4af96")
	elif asset=="bed":
		color = Color("a6b3a7") if room=="clinic" else Color("a99c86")
	if color!=Color.WHITE:
		for mesh in node.find_children("*","MeshInstance3D",true,false):
			for surface in range(mesh.mesh.get_surface_count()):
				var original = mesh.get_active_material(surface)
				var key = str(original.get_instance_id())+asset+room
				if not finish_cache.has(key):
					var material = original.duplicate()
					material.albedo_color *= color
					finish_cache[key] = material
				mesh.set_surface_override_material(surface,finish_cache[key])
	return node

func books(room: String, p: Vector3, scale = 0.45, yaw = 0.0):
	return town.interiors.prop("books",town.buildings[room],p,Vector3.ONE*scale,yaw)

func shelving(room: String, p: Vector3, yaw = 0.0, stocked = false):
	var shelf = furniture("bookcase",room,p,yaw)
	# Sparse, aligned contents belong on shelves rather than scattered on floors.
	for y in [0.37,0.91,1.44]:
		if stocked:
			var assets=["bucket","plate","cutting_board"] if room=="clinic" else (["bucket","slate","sheet_metal"] if room=="workshop" else ["plate","burner","cutting_board"])
			for i in range(3):
				var item=kit.retro.place(assets[i],shelf,Vector3(-0.38+i*0.35,y,0),0,Vector3(0.23,0.12 if assets[i]=="bucket" else 0.035,0.23))
				kit.retro.replacements+=1
		else:
			var local_books = town.interiors.prop("books",shelf,Vector3(-0.19,y,0),Vector3.ONE*0.55)
			local_books.rotation.y = 0
	return shelf

func rug(room: String, p: Vector3, size: Vector2, yaw = 0.0):
	var node = furniture("rug",room,p,yaw,Vector3(size.x/2.4,1,size.y/1.79),false)
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var material = mesh.get_active_material(surface).duplicate()
			material.albedo_color *= Color("6c5b4c")
			mesh.set_surface_override_material(surface,material)

func work_desks():
	for old in kit.get_tree().get_nodes_in_group("LegacyDesks"):
		var room: String = old.get_parent().name
		var d = old.get_meta("desk_dimensions")
		if room=="house":
			furniture("dining_table",room,old.position,0,Vector3(1.35,0.88/0.78,1))
			furniture("chair",room,Vector3(2.7,0.04,1.05),PI)
			furniture("chair",room,Vector3(3.5,0.04,-0.9))
		elif room in ["store","workshop"]:
			# A continuous wood counter, not a computer desk stretched three metres.
			var supports=[]
			supports.append(block(room,old.position+Vector3(0,0.845,0),Vector3(d.x,0.09,1.1),finishes[room].wood,true))
			for x in [-d.x/2+0.16,d.x/2-0.16]:
				supports.append(block(room,old.position+Vector3(x,0.42,-0.20),Vector3(0.13,0.84,0.65),finishes[room].wood,true))
			supports.append(block(room,old.position+Vector3(0,0.4,-0.48),Vector3(d.x,0.7,0.07),finishes[room].trim))
			for support in supports:
				for mesh in support.find_children("*","MeshInstance3D",true,false): mesh.hide()
			kit.retro.room("table",room,old.position,0,Vector3(d.x,0.89,1.1))
			kit.retro.replacements+=supports.size()
		else:
			furniture("desk",room,old.position,0,Vector3(d.x/1.93,1,1.1/0.76))
			furniture("office_chair",room,old.position+Vector3(0,0.04,1.12),PI)

func house():
	# Bedroom behind a proper divider; living group along the left wall;
	# dining by the entrance and one continuous kitchen against the rear wall.
	var room = "house"
	block(room,Vector3(-3.8,1.51,-0.9),Vector3(4.0,2.96,0.12),finishes[room].paint,true)
	block(room,Vector3(-3.8,0.12,-0.815),Vector3(4,0.15,0.05),finishes[room].wood)
	furniture("bed",room,Vector3(-3.3,0.04,-3.25),0,Vector3(1.5,1,1))
	furniture("wardrobe",room,Vector3(-5.05,0.04,-4.27))
	furniture("dresser",room,Vector3(-2.8,0.04,-1.38),PI)
	# Keep the original searchable bedside drawer beside the bed.
	books(room,Vector3(-4.6,0.6,-2.6),0.3)
	rug(room,Vector3(-3.1,0.046,-2.75),Vector2(2.7,2.8))
	furniture("sofa",room,Vector3(-3.9,0.04,3.3),PI)
	furniture("coffee_table",room,Vector3(-3.9,0.04,1.8))
	rug(room,Vector3(-3.9,0.046,1.9),Vector2(3.3,3.0))
	furniture("chair",room,Vector3(-2.0,0.04,2.0),-PI/2)
	furniture("side_table",room,Vector3(-5.15,0.04,0.1))
	furniture("floor_lamp",room,Vector3(-5.2,0.04,2.0))
	books(room,Vector3(-4.2,0.58,1.8),0.38)
	furniture("bowl",room,Vector3(-3.65,0.58,1.98),0,Vector3.ONE,false)
	furniture("plate",room,Vector3(3.15,0.93,0.05),0,Vector3.ONE,false)
	furniture("bowl",room,Vector3(3.15,0.95,0.05),0,Vector3.ONE,false)
	furniture("fridge",room,Vector3(1.8,0.04,-4.14),PI/2)
	furniture("counter",room,Vector3(2.92,0.04,-4.1),0,Vector3(1.2/0.766563,0.94/0.9,0.74/0.653856))
	# Size to the cooking surface; the source height includes its raised control panel.
	furniture("stove",room,Vector3(4.05,0.04,-4.1),0,Vector3(0.84/0.586142,0.94/0.734713,0.74/0.546268))
	furniture("counter",room,Vector3(5.15,0.04,-4.1),0,Vector3(1.14/0.766563,0.94/0.9,0.74/0.653856))
	for x in [2.92,4.05,5.15]:
		furniture("wall_cabinet",room,Vector3(x,1.88,-4.40),0,Vector3.ONE,false)
	block(room,Vector3(3.65,1.26,-4.60),Vector3(3.7,0.55,0.035),finishes[room].trim)
	furniture("coffee_maker",room,Vector3(2.65,0.98,-4.15),0,Vector3.ONE,false)
	furniture("trash",room,Vector3(5.45,0.04,-3.27))
	landscape(room,Vector3(-5.69,1.94,1.7),PI/2,Vector2(1.35,0.7))
	landscape(room,Vector3(-3.3,2.0,-4.64),0,Vector2(1.2,0.55))
	plant(room,Vector3(5.15,0.04,3.9))
	entry_mat(room)

func ranger():
	var room = "ranger"
	furniture("monitor",room,Vector3(-2.8,0.90,-0.27),0,Vector3.ONE,false)
	furniture("keyboard",room,Vector3(-2.8,0.90,0.27),0,Vector3.ONE,false)
	books(room,Vector3(-3.62,0.9,-0.25),0.4)
	# The visitor chair is opposite the desk; waiting chairs sit against a wall.
	furniture("chair",room,Vector3(-1.3,0.04,1.0),PI-0.6)
	for z in [1.75,2.55,3.35]:
		furniture("chair",room,Vector3(4.72,0.04,z),-PI/2)
	furniture("side_table",room,Vector3(4.65,0.04,0.85))
	books(room,Vector3(4.65,0.74,0.85),0.4)
	shelving(room,Vector3(2.4,0.04,-4.43))
	shelving(room,Vector3(3.8,0.04,-4.43))
	furniture("dresser",room,Vector3(-3.7,0.04,-4.42))
	furniture("trash",room,Vector3(-4.45,0.04,0.0))
	furniture("floor_lamp",room,Vector3(4.7,0.04,4.1))
	bulletin(room,Vector3(4.68,1.95,2.6),-PI/2)
	landscape(room,Vector3(-5.19,1.95,-0.1),PI/2,Vector2(1.45,0.78))
	plant(room,Vector3(3.75,0.04,4.2))
	entry_mat(room)

func clinic():
	var room = "clinic"
	for x in [-3.3,3.3]:
		furniture("bed",room,Vector3(x,0.04,-0.15))
		# Head-wall medical rail and a folded blanket establish treatment bays.
		block(room,Vector3(x,1.14,-1.38),Vector3(1.3,0.12,0.07),finishes[room].trim)
		block(room,Vector3(x,0.7,0.25),Vector3(0.92,0.045,0.56),finishes[room].trim)
	# Match the reference: one tidy row facing into a defined waiting area.
	for z in [2.05,2.85,3.65]:
		furniture("chair",room,Vector3(4.72,0.04,z),-PI/2)
	furniture("side_table",room,Vector3(4.6,0.04,1.25))
	books(room,Vector3(4.6,0.74,1.25),0.35)
	furniture("trash",room,Vector3(-4.75,0.04,0.3))
	shelving(room,Vector3(-2.7,0.04,-4.1),0,true)
	# Note rests on a proper shelf, not inside the old oversize book mesh.
	town.actions.clinic_note.area.position = Vector3(-2.7,1.00,-3.77)
	bulletin(room,Vector3(4.68,2.05,2.75),-PI/2)
	# Short privacy return behind the left bed; the central nurse route is clear.
	block(room,Vector3(-4.05,1.15,-1.48),Vector3(2.35,2.25,0.055),finishes[room].paint)
	# A suspended privacy curtain separates the right treatment bay from the
	# waiting seats; the walking route stays along the middle of the room.
	block(room,Vector3(3.3,2.66,1.25),Vector3(2.5,0.035,0.035),town.mats.metal)
	var curtain = town.mats.fabric.duplicate()
	curtain.albedo_color = Color("7d948b")
	for i in range(15):
		block(room,Vector3(2.12+i*0.16,1.69,1.25+(0.025 if i%2==0 else -0.025)),Vector3(0.165,1.85,0.025),curtain)
	plant(room,Vector3(4.65,0.04,4.32))
	entry_mat(room)

func store():
	var room = "store"
	# Shelves form a recognisable shop aisle, with a staffed counter at the back.
	for x in [-4.75,4.75]:
		for z in [-0.3,1.15]:
			shelving(room,Vector3(x,0.04,z),PI/2 if x<0 else -PI/2,true)
	shelving(room,Vector3(-3.0,0.04,-4.4),0,true)
	furniture("fridge",room,Vector3(5.0,0.04,-4.25),PI/2)
	furniture("office_chair",room,Vector3(-2.8,0.04,-2.55),PI)
	furniture("coffee_maker",room,Vector3(-4.05,0.91,-3.85),0,Vector3.ONE,false)
	furniture("trash",room,Vector3(-5.1,0.04,-2.4))
	# A small display table is aligned with the window, away from the entry aisle.
	furniture("dining_table",room,Vector3(-3.6,0.04,3.65),0,Vector3(1,1,0.7))
	for x in [-4,-3.6,-3.2]:
		furniture("bowl",room,Vector3(x,0.83,3.65),0,Vector3.ONE,false)
	bulletin(room,Vector3(5.18,1.95,3.0),-PI/2)
	entry_mat(room)

func workshop():
	var room = "workshop"
	shelving(room,Vector3(4.05,0.04,-4.3),0,true)
	shelving(room,Vector3(5.35,0.04,-4.3),0,true)
	# Pegboard tools are grouped over the workbench, not apartment wall art.
	block(room,Vector3(-3.1,1.65,-3.43),Vector3(3.4,1.0,0.055),finishes[room].wood)
	# The supplied scythe and shovel below replace the twelve cuboid tool shapes.
	kit.retro.replacements+=12
	furniture("counter",room,Vector3(-5.25,0.04,3.45),PI/2)
	furniture("side_table",room,Vector3(4.95,0.04,3.6))
	furniture("coffee_maker",room,Vector3(4.95,0.74,3.6),0,Vector3.ONE,false)
	furniture("chair",room,Vector3(4.1,0.04,3.6),PI/2)
	furniture("trash",room,Vector3(-5.25,0.04,2.35))
	bulletin(room,Vector3(-5.68,1.95,1.5),PI/2)
	entry_mat(room)

func radio():
	var room = "radio"
	furniture("monitor",room,Vector3(-3.85,0.90,-3.65),0,Vector3.ONE,false)
	furniture("keyboard",room,Vector3(-3.85,0.90,-3.1),0,Vector3.ONE,false)
	books(room,Vector3(-1.62,0.9,-3.7),0.3)
	shelving(room,Vector3(-4.75,0.04,0),PI/2)
	shelving(room,Vector3(-4.75,0.04,1.45),PI/2)
	# Lounge against the wall leaves the route to the receiver unobstructed.
	furniture("sofa",room,Vector3(3.9,0.04,3.2),PI)
	furniture("coffee_table",room,Vector3(3.9,0.04,1.6))
	rug(room,Vector3(3.9,0.046,1.9),Vector2(3.0,3.1))
	furniture("side_table",room,Vector3(4.55,0.04,3.85))
	furniture("floor_lamp",room,Vector3(4.8,0.04,0.2))
	books(room,Vector3(3.9,0.58,1.6),0.4)
	furniture("trash",room,Vector3(-4.8,0.04,-2.5))
	landscape(room,Vector3(5.18,1.95,2),-PI/2,Vector2(1.5,0.75))
	bulletin(room,Vector3(-2.8,2.12,-4.65),0)
	entry_mat(room)

func entry_mat(room: String):
	kit.retro.room("entrance_mat",room,Vector3(0,0.044,4.15),0,Vector3(1.5,0.012,0.85))
	kit.retro.replacements+=1

func pendant(room: String, p: Vector3):
	block(room,p+Vector3(0,0.28,0),Vector3(0.018,0.56,0.018),finishes[room].trim)
	var shade = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.11
	mesh.bottom_radius = 0.30
	mesh.height = 0.22
	mesh.radial_segments = 12
	shade.mesh = mesh
	shade.material_override = matte("98917a")
	shade.position = p
	town.buildings[room].add_child(shade)
	town.lamp(town.buildings[room],p-Vector3(0,0.16,0),Color("c8b080"),0.32,3.0)

func plant(room: String, p: Vector3):
	var root = wall_group(room,p,0)
	var pot = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.23
	mesh.bottom_radius = 0.17
	mesh.height = 0.39
	mesh.radial_segments = 10
	pot.mesh = mesh
	pot.position.y = 0.195
	pot.material_override = matte("756151")
	root.add_child(pot)
	var foliage = load("res://assets/forest/bush_g.glb").instantiate()
	root.add_child(foliage)
	foliage.position.y = 0.36
	foliage.scale = Vector3(0.55,0.63,0.55)
	kit.adapt(foliage)

func wall_group(room: String, p: Vector3, yaw: float) -> Node3D:
	var node = Node3D.new()
	town.buildings[room].add_child(node)
	node.position = p
	node.rotation.y = yaw
	return node

func landscape(room: String, p: Vector3, yaw: float, size: Vector2):
	var root = wall_group(room,p,yaw)
	town.box(root,Vector3.ZERO,Vector3(size.x+0.10,size.y+0.1,0.045),finishes[room].wood,false)
	town.box(root,Vector3(0,0,0.03),Vector3(size.x,size.y,0.012),matte("a39d82"),false)
	# Faded, framed landscape silhouette, with a quiet palette instead of the
	# unrelated bright repeating canvas from the source demo apartment.
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for points in [
		[Vector3(-0.5,-0.45,0),Vector3(0.1,0.3,0),Vector3(0.5,-0.45,0)],
		[Vector3(-0.5,-0.45,0),Vector3(-0.25,0.15,0),Vector3(0.15,-0.45,0)]]:
		for v in points:
			tool.set_normal(Vector3.FORWARD)
			tool.add_vertex(Vector3(v.x*size.x,v.y*size.y,0.045))
	var mesh = MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var material = matte("59635a")
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = material
	root.add_child(mesh)

func bulletin(room: String, p: Vector3, yaw: float):
	var root = wall_group(room,p,yaw)
	town.box(root,Vector3.ZERO,Vector3(1.5,0.90,0.06),finishes[room].wood,false)
	town.box(root,Vector3(0,0,0.04),Vector3(1.38,0.78,0.02),matte("77715a"),false)
	for i in range(5):
		var note = town.box(root,Vector3(-0.51+(i%3)*0.43,0.18-(i/3)*0.38,0.06),Vector3(0.26,0.28,0.008),matte("b1ab91"),false)
		note.rotation.z = [-0.04,0.03,0,0.06,-0.03][i]
		for y in [-0.06,0,0.06]:
			town.box(note,Vector3(0,y,0.007),Vector3(0.17,0.006,0.003),matte("747568"),false)

func clock(room: String, p: Vector3, yaw: float):
	kit.retro.room("clock",room,p-Vector3(0,0.16,0),yaw)
	kit.retro.replacements+=1
