extends Node3D
## Local model dressing and animated, one-loot-per-run storage.
var town
var containers = {}
var material_cache = {}
var scenes = {}
var manifest = {}
var prop_count = 0
var animations_active = false
const LOOT_NAMES = {"station_key":"radio-station key","fuse":"workshop fuse","coil":"signal coil","medkit_a":"first-aid kit","medkit_b":"first-aid kit","medkit_c":"first-aid kit","battery_a":"flashlight battery","battery_b":"flashlight battery","battery_c":"flashlight battery"}

func _ready():
	name = "InteriorDetails"
	for row in JSON.parse_string(FileAccess.get_file_as_string("res://assets/interiors/manifest.json")):
		manifest[row.asset] = row
	for asset in ["shelf","lamp","books","curtain","door","box","teapot","sink"]:
		scenes[asset] = load("res://assets/interiors/%s.glb" % asset)
	dress_buildings()
	make_storage()

func adapt(node: Node):
	if node is MeshInstance3D:
		node.visibility_range_end = 55
		for surface in range(node.mesh.get_surface_count()):
			var original = node.mesh.surface_get_material(surface)
			if not original is StandardMaterial3D:
				continue
			var key = original.get_instance_id()
			if not material_cache.has(key):
				var material = original.duplicate() as StandardMaterial3D
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
				material.normal_enabled = false
				material.roughness = 1
				material.metallic = 0
				material.metallic_specular = 0
				material.cull_mode = BaseMaterial3D.CULL_DISABLED
				material_cache[key] = material
			node.set_surface_override_material(surface,material_cache[key])
	for child in node.get_children():
		adapt(child)

func prop(asset: String, parent: Node3D, p: Vector3, size = Vector3.ONE, angle = 0.0) -> Node3D:
	var node = scenes[asset].instantiate() as Node3D
	node.name = asset+str(prop_count)
	parent.add_child(node)
	node.position = p
	node.scale = size
	node.rotation.y = angle
	node.add_to_group("LocalInteriorProps")
	node.set_meta("source_asset",asset)
	adapt(node)
	prop_count += 1
	return node

func dress_buildings():
	var paint_colors = {"ranger":Color("85917c"),"clinic":Color("9aaea5"),"store":Color("ac9f7b"),"workshop":Color("737c72"),"radio":Color("7e8b86"),"house":Color("aaa18e")}
	for data in town.BUILDINGS:
		var root = town.buildings[data.id]
		var paint = town.mats.plaster.duplicate()
		paint.albedo_color = paint_colors[data.id]
		var w: float = data.w
		var d: float = data.d
		# Paint, wood skirting, and exposed rafters add interior structure.
		town.box(root,Vector3(0,2.27,-d/2+0.14),Vector3(w-0.3,2.3,0.025),paint,false)
		for side in [-1,1]:
			town.box(root,Vector3(side*(w/2-0.14),2.27,0),Vector3(0.025,2.3,d-0.3),paint,false)
			town.box(root,Vector3(side*(w/2-0.16),0.18,0),Vector3(0.07,0.20,d-0.25),town.mats.furniture,false)
			town.box(root,Vector3(side*(w/2-0.16),1.13,0),Vector3(0.07,0.09,d-0.25),town.mats.furniture,false)
			town.box(root,Vector3(side*1.0,1.4,d/2+0.14),Vector3(0.13,2.8,0.13),town.mats.furniture,false)
			var window = side*w*0.31
			town.box(root,Vector3(window,0.98,d/2+0.16),Vector3(1.95,0.10,0.4),town.mats.furniture,false)
			town.box(root,Vector3(window,2.42,d/2+0.12),Vector3(1.9,0.10,0.1),town.mats.furniture,false)
			for edge in [-1,1]:
				town.box(root,Vector3(window+edge*0.88,1.7,d/2+0.12),Vector3(0.09,1.4,0.10),town.mats.furniture,false)
			town.box(root,Vector3(side*(w/2-0.55),1.55,d/2+0.75),Vector3(0.13,3.1,0.13),town.mats.furniture)
			if data.id in ["house","clinic","ranger"]:
				prop("curtain",root,Vector3(window-0.56,1.0,d/2-0.26),Vector3(1.7,1,1))
		for z in [-3.1,0,3.1]:
			town.box(root,Vector3(0,3.49,z),Vector3(w-0.2,0.16,0.16),town.mats.furniture,false)
		town.box(root,Vector3(0,0.18,-d/2+0.16),Vector3(w-0.25,0.20,0.07),town.mats.furniture,false)
		town.box(root,Vector3(0,3.52,d/2+0.8),Vector3(w-0.4,0.16,0.14),town.mats.furniture,false)
		town.box(root,Vector3(-w/2+0.18,1.65,d/2+0.23),Vector3(0.07,3.3,0.07),town.mats.metal,false)
		var door = town.doors[data.id]
		door.body.get_child(0).visible = false
		door.body.get_child(2).visible = false
		prop("door",door.body,Vector3(0,-1.35,0),Vector3(1.8/manifest.door.dimensions[0],1,1))
		prop("lamp",root,Vector3(w/2-0.7,0.02,3.4))
		if data.id in ["house","ranger","radio"]:
			town.lamp(root,Vector3(w/2-0.7,1.45,3.4),Color("c7ac7b"),0.48,5)
		# Local packing boxes and loose books sit along edges, away from entrances.
		prop("box",root,Vector3(-w/2+0.65,0.02,2.8),Vector3(1,1,1),0.22)
		prop("box",root,Vector3(-w/2+0.65,0.5,2.8),Vector3(0.75,0.75,0.75),-0.1)
		prop("books",root,Vector3(w/2-1.0,0.025,2.3),Vector3(0.6,0.6,0.6),-0.3)
		# Paper litter is intentionally flat and does not obstruct movement.
		for i in range(4):
			var paper = town.box(root,Vector3(-1.1+i*0.7,0.022,1.6+sin(i)*0.4),Vector3(0.22,0.005,0.3),town.mats.paper,false)
			paper.rotation.y = i*0.71
		poster(root,data.id,Vector3(-1.9,2.45,-d/2+0.18))
	for shelf in get_tree().get_nodes_in_group("InteriorShelfBases"):
		prop("shelf",shelf,Vector3.ZERO,Vector3(2.2/manifest.shelf.dimensions[0],1,1))
		for y in [0.24,0.96,1.68]:
			prop("books",shelf,Vector3(-0.25,y,0.03),Vector3(0.8,0.8,0.8))
	# Counters and familiar household clutter help distinguish room functions.
	prop("teapot",town.buildings.house,Vector3(3.1,0.89,0),Vector3.ONE,0.5)
	prop("teapot",town.buildings.ranger,Vector3(-3.3,0.89,0),Vector3.ONE,-0.5)
	prop("books",town.buildings.ranger,Vector3(-3.6,0.89,-0.2),Vector3(0.65,0.65,0.65))
	prop("books",town.buildings.radio,Vector3(-3.5,0.89,-3.5),Vector3(0.6,0.6,0.6))
	prop("box",town.buildings.store,Vector3(4.9,0.02,-2.7),Vector3(1.2,1.2,1.2),0.2)
	prop("box",town.buildings.workshop,Vector3(5.1,0.02,2.6),Vector3(1.2,1.2,1.2),-0.3)
	# Low-poly bed frames, blankets, and radiator pipes.
	for x in [-3.3,3.3]:
		var clinic = town.buildings.clinic
		for side in [-1,1]:
			town.box(clinic,Vector3(x+side*0.6,0.55,-1.18),Vector3(0.07,1.1,0.07),town.mats.metal,false)
			town.box(clinic,Vector3(x+side*0.6,0.35,1.18),Vector3(0.07,0.7,0.07),town.mats.metal,false)
		town.box(clinic,Vector3(x,0.88,0.3),Vector3(1.25,0.05,1.5),town.mats.fabric,false)
		town.box(clinic,Vector3(x,1.0,-1.18),Vector3(1.25,0.07,0.07),town.mats.metal,false)
	for i in range(9):
		town.box(town.buildings.clinic,Vector3(4.7-i*0.13,0.55,4.68),Vector3(0.065,0.8,0.12),town.mats.metal,false)

func poster(root: Node3D, id: String, p: Vector3):
	town.box(root,p,Vector3(1.1,0.76,0.016),town.mats.paper,false)
	var titles = {"ranger":"BLACKWOOD\nFOREST SERVICE","clinic":"EVACUATION\nKEEP CALM","store":"CLOSED\nUNTIL FURTHER NOTICE","radio":"EMERGENCY\nCHANNEL 06","workshop":"DANGER\nISOLATE POWER","house":"BLACKWOOD\nHOME IS HERE"}
	var text = town.sign_text(root,titles[id],p+Vector3(0,0,0.014),24,Color("4a5146"))
	text.pixel_size = 0.006

func make_storage():
	drawer("ranger","ranger_drawer",Vector3(-3.25,0.12,0.08),"ranger desk drawer",["station_key"])
	cabinet("ranger","ranger_cabinet",Vector3(-0.6,0,-4.45),"ranger supply cabinet",[],{"battery":1})
	cabinet("clinic","clinic_cabinet",Vector3(2.4,0,-4.45),"medicine cabinet",["medkit_a","medkit_b"],{},false,Vector3(1.4,1.8,0.7),"plaster")
	drawer("clinic","clinic_drawer",Vector3(-4.6,0,1.6),"bedside drawer",[],{},"Only empty blister packs and old receipts.")
	drawer("store","store_drawer",Vector3(-3.85,0.12,-3.65),"store counter drawer",["fuse"])
	cabinet("store","store_cabinet",Vector3(3.5,0,-4.45),"stock cabinet",["battery_a","battery_b"])
	cabinet("workshop","workshop_cabinet",Vector3(-4.6,0,0.6),"signal-coil cabinet",["coil"],{},true,Vector3(1.25,1.75,0.7),"metal")
	drawer("workshop","workshop_drawer",Vector3(-4.0,0.12,-2.6),"spare-parts drawer",[],{"battery":1})
	drawer("house","house_drawer",Vector3(-4.6,0,-2.6),"bedside drawer",["medkit_c"])
	cabinet("house","house_cabinet",Vector3(3.7,0,-4.45),"kitchen cabinet",["battery_c"],{},false,Vector3(1.5,0.9,0.7))
	prop("sink",town.buildings.house,Vector3(3.7,0.92,-4.45))
	cabinet("radio","radio_cabinet",Vector3(3.5,0,-4.45),"archive cabinet",[],{},false,Vector3(1.4,1.75,0.7),"metal")
	containers.radio_cabinet.empty_text = "Only water-damaged maps and empty file folders."
	drawer("radio","radio_drawer",Vector3(3.8,0,0.2),"equipment drawer",[],{"battery":1})
	# These items now live inside storage and are granted by the first search.
	for id in containers:
		for item_id in containers[id].loot_ids:
			town.actions[item_id]["container_id"] = id
	# Move the clinic note to the accessible front edge of its local-asset shelf.
	town.actions.clinic_note.area.position = Vector3(-2.7,1.08,-3.48)

func register_storage(id: String, root: Node3D, area: Area3D, moving: Array, label: String, loot_ids: Array, extras: Dictionary, needs_power: bool, mode: String, empty_text = "Nothing useful remains."):
	containers[id] = {"root":root,"area":area,"moving":moving,"label":label,"loot_ids":loot_ids,"extras":extras,"needs_power":needs_power,"mode":mode,"empty_text":empty_text,"open":false,"searched":false,"tweens":[]}

func drawer(building: String, id: String, p: Vector3, label: String, loot_ids: Array, extras = {}, empty_text = "Nothing useful remains."):
	var root = Node3D.new()
	town.buildings[building].add_child(root)
	root.position = p
	root.name = id
	var material = town.mats.furniture
	# The static carcass retains collision; the visible tray can slide freely.
	var body = town.box(root,Vector3(0,0.28,0),Vector3(0.9,0.56,0.8),material)
	body.get_child(0).visible = false
	for side in [-1,1]:
		town.box(root,Vector3(side*0.43,0.28,0),Vector3(0.05,0.56,0.8),material,false)
	town.box(root,Vector3(0,0.56,0),Vector3(0.9,0.05,0.8),material,false)
	town.box(root,Vector3(0,0.025,0),Vector3(0.9,0.05,0.8),material,false)
	var tray = Node3D.new()
	root.add_child(tray)
	tray.position.y = 0.28
	town.box(tray,Vector3(0,-0.18,0),Vector3(0.8,0.045,0.71),material,false)
	for side in [-1,1]:
		town.box(tray,Vector3(side*0.38,0,0),Vector3(0.035,0.37,0.70),material,false)
	town.box(tray,Vector3(0,0,0.42),Vector3(0.87,0.5,0.07),material,false)
	town.box(tray,Vector3(0,0,0.48),Vector3(0.26,0.045,0.06),town.mats.metal,false)
	var paper = town.box(tray,Vector3(-0.1,-0.14,-0.07),Vector3(0.31,0.015,0.22),town.mats.paper,false)
	paper.rotation.y = 0.16
	var area = town.action_area(tray,Vector3(0,0,0.51),Vector3(0.88,0.5,0.15),id,{"kind":"container","container":id,"label":"Search "+label})
	register_storage(id,root,area,[tray],label,loot_ids,extras,false,"drawer",empty_text)

func cabinet(building: String, id: String, p: Vector3, label: String, loot_ids: Array, extras = {}, needs_power = false, size = Vector3(1.3,1.8,0.7), finish = "furniture"):
	var root = Node3D.new()
	root.name = id
	town.buildings[building].add_child(root)
	root.position = p
	var material = town.mats[finish]
	var body = town.box(root,Vector3(0,size.y/2,0),size,material)
	body.get_child(0).visible = false
	for side in [-1,1]:
		town.box(root,Vector3(side*size.x/2,size.y/2,0),Vector3(0.055,size.y,size.z),material,false)
	town.box(root,Vector3(0,size.y/2,-size.z/2),Vector3(size.x,size.y,0.05),material,false)
	for y in [0.04,size.y*0.48,size.y]:
		town.box(root,Vector3(0,y,0),Vector3(size.x,0.06,size.z),material,false)
	var panels: Array = []
	for side in [-1,1]:
		var pivot = Node3D.new()
		root.add_child(pivot)
		pivot.position = Vector3(side*size.x/2,0,size.z/2+0.025)
		pivot.set_meta("side",side)
		town.box(pivot,Vector3(-side*size.x/4,size.y/2,0),Vector3(size.x/2-0.025,size.y-0.045,0.06),material,false)
		town.box(pivot,Vector3(-side*(size.x/2-0.10),size.y*0.53,0.07),Vector3(0.045,0.20,0.06),town.mats.metal,false)
		panels.append(pivot)
	# Dusty contents remain visible after the search, without collectible duplicates.
	prop("box",root,Vector3(-size.x*0.22,0.08,0),Vector3(0.45,0.45,0.45))
	if size.y>1.2:
		prop("books",root,Vector3(0,size.y*0.5+0.04,0),Vector3(0.65,0.65,0.65))
	var area = town.action_area(root,Vector3(0,size.y*0.52,size.z/2+0.12),Vector3(size.x,size.y*0.85,0.18),id,{"kind":"container","container":id,"label":"Search "+label})
	register_storage(id,root,area,panels,label,loot_ids,extras,needs_power,"cabinet")

func prompt(id: String) -> String:
	var data = containers[id]
	if data.needs_power and not town.powered:
		return "E / Locked coil cabinet - restore workshop power"
	if data.open:
		return "E / Close "+data.label+" (searched)"
	return "E / "+("Open "+data.label+" (searched)" if data.searched else "Search "+data.label)

func toggle(id: String):
	var data = containers[id]
	if data.needs_power and not town.powered:
		town.game.message = "The coil cabinet is locked. Restore power at the outside panel."
		return
	data.open = not data.open
	for tween in data.tweens:
		if tween.is_valid():
			tween.kill()
	data.tweens.clear()
	for part in data.moving:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		if data.mode=="drawer":
			tween.tween_property(part,"position:z",0.48 if data.open else 0.0,0.35)
		else:
			tween.tween_property(part,"rotation:y",float(part.get_meta("side"))*1.65 if data.open else 0.0,0.4)
		data.tweens.append(tween)
		tween.finished.connect(_animation_finished.bind(id,tween.get_instance_id()),CONNECT_ONE_SHOT)
	town.game.soundscape.storage_move(data.root.global_position,data.mode=="drawer",data.open)
	if not data.open:
		return
	if data.searched:
		town.game.message = "Already searched. Nothing else in the "+data.label+"."
		return
	data.searched = true
	var found: Array[String] = []
	for item_id in data.loot_ids:
		if not town.actions[item_id].taken:
			town.perform(item_id)
			found.append(LOOT_NAMES[item_id])
	for key in data.extras:
		town.inventory[key] += data.extras[key]
		found.append("flashlight battery" if key=="battery" else "first-aid kit")
	town.game.message = "Found: "+", ".join(found)+"." if not found.is_empty() else data.empty_text
	if not found.is_empty():
		town.game.soundscape.feedback("pickup")
	town.focus_action = ""

func reset():
	for data in containers.values():
		for tween in data.tweens:
			if tween.is_valid():
				tween.kill()
		data.tweens.clear()
		data.open = false
		data.searched = false
		for part in data.moving:
			if data.mode=="drawer":
				part.position.z = 0
			else:
				part.rotation.y = 0
		for item_id in data.loot_ids:
			var item = town.actions[item_id]
			item.area.visible = false
			item.area.get_child(0).set_deferred("disabled",true)
	animations_active = town.game.state=="play"

func _animation_finished(id: String, instance_id: int):
	containers[id].tweens = containers[id].tweens.filter(func(tween): return tween.get_instance_id()!=instance_id)

func _process(_delta):
	var active = town.game.state=="play"
	if active==animations_active:
		return
	animations_active = active
	for data in containers.values():
		for tween in data.tweens:
			if not tween.is_valid():
				continue
			if active and not tween.is_running():
				tween.play()
			elif not active:
				tween.pause()
