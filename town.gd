extends Node3D
## Abandoned Blackwood: furnished, enterable buildings and a resettable item quest.
const BUILDINGS = [
	{"id":"ranger","label":"RANGER OFFICE","p":Vector3(-11.5,0,-46),"w":11.0,"d":10.0,"r":PI/2,"wall":"brick"},
	{"id":"clinic","label":"BLACKWOOD PHARMACY","p":Vector3(-11.5,0,-59),"w":11.0,"d":10.0,"r":PI/2,"wall":"brick"},
	{"id":"store","label":"GENERAL STORE","p":Vector3(-11.5,0,-72),"w":12.0,"d":10.0,"r":PI/2,"wall":"brick"},
	{"id":"radio","label":"RADIO STATION","p":Vector3(11.5,0,-72),"w":11.0,"d":10.0,"r":-PI/2,"wall":"brick"},
	{"id":"workshop","label":"MILL REPAIR SHOP","p":Vector3(11.5,0,-59),"w":12.0,"d":10.0,"r":-PI/2,"wall":"brick"},
	{"id":"house","label":"MILLKEEPER'S ROOMS","p":Vector3(11.5,0,-46),"w":12.0,"d":10.0,"r":-PI/2,"wall":"plaster"}]
var game
var buildings = {}
var doors = {}
var actions = {}
var inventory = {"medkit":0,"battery":0,"station_key":0,"fuse":0,"coil":0,"chapel_key":0,"tuner":0,"shotgun_key":0,"antenna":0,"mausoleum_key":0}
var journal_entries: Array[Dictionary] = []
var powered = false
var radio_ready = false
var reached_town = false
var focus_action = ""
var mats = {}
var powered_lights: Array[OmniLight3D] = []
var coil_visual: Node3D
var receiver_light: OmniLight3D
var discovered = {}
var apartment_interiors: Node3D
var interiors: Node3D
var townspeople: Node3D
var sign_crow: Node3D
var streetscape: Node3D
var cemetery: Node3D

func _ready():
	name = "AbandonedTown"
	for key in ["wood","brick","plaster","floor","roof","metal"]:
		var material = StandardMaterial3D.new()
		material.albedo_texture = load("res://assets/town/%s.png" % key)
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		material.roughness = 1
		material.metallic_specular = 0
		material.albedo_color = Color("afb1a2")
		material.uv1_triplanar = true
		material.uv1_scale = Vector3(0.5,0.5,0.5)
		mats[key] = material
	mats["dark"] = color_material(Color("343e3e"))
	mats["amber"] = color_material(Color("dfb970"),0.4)
	mats["green"] = color_material(Color("79b49d"),0.4)
	mats["furniture"] = mats.wood.duplicate()
	mats.furniture.albedo_texture = load("res://assets/interiors/shelf_diffuse.png")
	mats.furniture.albedo_color = Color("a89b7c")
	mats["fabric"] = mats.plaster.duplicate()
	mats.fabric.albedo_texture = load("res://assets/interiors/curtain_diffuse.png")
	mats.fabric.albedo_color = Color("89998d")
	mats["paper"] = color_material(Color("b8b098"))
	streetscape = Node3D.new()
	streetscape.set_script(preload("res://town_streetscape.gd"))
	streetscape.town = self
	add_child(streetscape)
	build_street()
	for data in BUILDINGS:
		build_house(data)
	furnish()
	interiors = Node3D.new()
	interiors.set_script(preload("res://interiors.gd"))
	interiors.town = self
	add_child(interiors)
	apartment_interiors = Node3D.new()
	apartment_interiors.set_script(preload("res://apartment_interiors.gd"))
	apartment_interiors.town = self
	add_child(apartment_interiors)
	streetscape.church.basement.dress()
	townspeople = Node3D.new()
	townspeople.set_script(preload("res://townspeople.gd"))
	townspeople.town = self
	add_child(townspeople)
	cemetery = preload("res://cemetery.gd").new()
	cemetery.town = self
	add_child(cemetery)
	reset()

func color_material(color: Color, emission = 0.0) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1
	if emission>0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material

func box(parent: Node3D, p: Vector3, size: Vector3, material: Material, solid = true) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	parent.add_child(node)
	node.position = p
	var mesh = BoxMesh.new()
	mesh.size = size
	var visual = MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	node.add_child(visual)
	if solid:
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		node.add_child(collision)
	return node

func sign_text(parent: Node3D, words: String, p: Vector3, size = 28, color = Color("d3c7a3")):
	var label = Label3D.new()
	label.text = words
	label.font = preload("res://assets/font.ttf")
	label.font_size = size
	label.pixel_size = 0.009
	label.modulate = color
	label.outline_size = 2
	label.no_depth_test = false
	label.position = p
	parent.add_child(label)
	return label

func lamp(parent: Node3D, p: Vector3, color: Color, energy: float, distance: float) -> OmniLight3D:
	var light = OmniLight3D.new()
	light.position = p
	light.light_color = color
	light.light_energy = energy
	light.omni_range = distance
	parent.add_child(light)
	return light

func build_street():
	streetscape.build_street()
	# Small, fixed wooden roadside sign: fully off the lane, with grounded posts.
	var town_sign = Node3D.new()
	town_sign.name = "BlackwoodRoadSign"
	town_sign.position = Vector3(4.4,0,-35)
	town_sign.rotation_degrees = Vector3(0,-12,-2)
	add_child(town_sign)
	for x in [-1.08,1.08]:
		box(town_sign,Vector3(x,0.92,0),Vector3(0.14,1.84,0.16),mats.wood)
	var weathered = mats.wood.duplicate()
	weathered.albedo_color = Color("736a4d")
	box(town_sign,Vector3(0,1.51,0.02),Vector3(2.65,0.88,0.12),weathered,false)
	for y in [1.12,1.89]:
		box(town_sign,Vector3(0,y,0.095),Vector3(2.7,0.055,0.055),mats.dark,false)
	for x in [-1.08,1.08]:
		for y in [1.20,1.82]:
			box(town_sign,Vector3(x,y,0.09),Vector3(0.045,0.045,0.025),mats.metal,false)
	var title = sign_text(town_sign,"Blackwood",Vector3(0,1.64,0.09),48,Color("bdb58f"))
	title.font = ThemeDB.fallback_font
	title.pixel_size = 0.006
	title.shaded = true
	title.outline_size = 0
	var road = sign_text(town_sign,"Population 3",Vector3(0,1.32,0.09),26,Color("a69f7d"))
	road.font = ThemeDB.fallback_font
	road.pixel_size = 0.005
	road.shaded = true
	road.outline_size = 0
	sign_crow = Node3D.new()
	sign_crow.set_script(preload("res://perched_crow.gd"))
	sign_crow.game = game
	town_sign.add_child(sign_crow)
	# Collapsed fence sections and crates give the street an abandoned silhouette.
	for x in [-34,-30,31,35]:
		for z in [-42,-78]:
			box(self,Vector3(x,0.65,z),Vector3(0.13,1.3,0.13),mats["wood"])
			box(self,Vector3(x+1.5,0.85,z),Vector3(3.0,0.14,0.10),mats["wood"],false)
	for p in [Vector3(-32,0.4,-61),Vector3(34,0.35,-51),Vector3(14,0.4,-77)]:
		box(self,p,Vector3(0.8,0.8,0.8),mats["wood"])

func build_house(data: Dictionary):
	var root = Node3D.new()
	root.name = data.id
	root.position = data.p
	root.rotation.y = data.r
	add_child(root)
	buildings[data.id] = root
	root.set_meta("building_id",data.id)
	var w: float = data.w
	var d: float = data.d
	var wall: Material = streetscape.brick(data.id)
	# Floors meet the outside ground; no invisible step at the entrance.
	# Visual flooring sits above the shared ground to avoid z-fighting.
	box(root,Vector3(0,-0.05,0),Vector3(w,0.13,d),mats["floor"],false)
	box(root,Vector3(0,1.8,-d/2),Vector3(w,3.6,0.22),wall)
	for side in [-1,1]:
		box(root,Vector3(side*w/2,1.8,0),Vector3(0.22,3.6,d),wall)
		var low = -w/2 if side<0 else 0.95
		var high = -0.95 if side<0 else w/2
		var window = side*w*0.31
		box(root,Vector3((low+window-1.25)/2,1.8,d/2),Vector3(window-1.25-low,3.6,0.22),wall)
		box(root,Vector3((window+1.25+high)/2,1.8,d/2),Vector3(high-window-1.25,3.6,0.22),wall)
		box(root,Vector3(window,0.3,d/2),Vector3(2.5,0.6,0.22),wall)
		box(root,Vector3(window,3.2,d/2),Vector3(2.5,0.8,0.22),wall)
		# Broken window boards leave gaps to see through.
		var board = box(root,Vector3(window,1.6,d/2+0.13),Vector3(1.9,0.16,0.07),mats["wood"],false)
		board.rotation.z = side*0.16
	box(root,Vector3(0,3.15,d/2),Vector3(1.9,0.9,0.22),wall)
	streetscape.decorate_building(root,data)
	make_door(root,data.id,d/2)
	lamp(root,Vector3(0,2.8,1),Color("b2b29c"),0.45,7)
	# Interior partition with a generous side passage to a rear storage nook.
	var partition = box(root,Vector3(w/4,1.5,-1.6),Vector3(w/2-0.8,3,0.14),wall)
	partition.add_to_group("InteriorPartitions")
	var crate = box(root,Vector3(-w/2+0.5,0.35,-d/2+0.6),Vector3(0.8,0.7,0.7),mats["wood"])
	crate.add_to_group("LegacyInteriorClutter")

func make_door(root: Node3D, id: String, z: float):
	var hinge = Node3D.new()
	hinge.position = Vector3(-0.9,0,z)
	root.add_child(hinge)
	var body = box(hinge,Vector3(0.9,1.35,0),Vector3(1.8,2.7,0.12),mats["wood"])
	box(body,Vector3(0.65,-0.15,0.1),Vector3(0.12,0.12,0.12),mats["amber"],false)
	var area = action_area(body,Vector3.ZERO,Vector3(1.85,2.7,0.2),id+"_door",{"kind":"door","building":id,"label":"Open door"})
	doors[id] = {"hinge":hinge,"body":body,"collision":body.get_child(1),"open":false,"tween":null,"area":area}

func action_area(parent: Node3D, p: Vector3, size: Vector3, id: String, data: Dictionary) -> Area3D:
	var area = Area3D.new()
	area.name = id
	area.position = p
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = false
	area.set_meta("action_id",id)
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	parent.add_child(area)
	data["area"] = area
	data["taken"] = false
	actions[id] = data
	return area

func item(building: String, p: Vector3, id: String, key: String, label: String, color: Color):
	var area = action_area(buildings[building],p,Vector3(0.55,0.4,0.5),id,{"kind":"item","item":key,"label":label})
	if key in ["battery","medkit","fuse","coil"]:
		area.add_child(preload("res://supply_models.gd").build(key))
	else:
		box(area,Vector3.ZERO,Vector3(0.35,0.22,0.25),color_material(color,0.45),false)
	lamp(area,Vector3(0,0.15,0),color,0.22,1.5)
	return area

func note(building: String, p: Vector3, id: String, title: String, body: String):
	var area = action_area(buildings[building],p,Vector3(0.55,0.16,0.5),id,{"kind":"note","label":"Read "+title,"title":title,"text":body})
	box(area,Vector3.ZERO,Vector3(0.42,0.025,0.32),color_material(Color("d4c49e")),false)
	for i in range(3):
		box(area,Vector3(0,0.015,-0.09+i*0.06),Vector3(0.29,0.006,0.012),mats["dark"],false)

func desk(root: Node3D, p: Vector3, wide = 2.6):
	var base = Node3D.new()
	root.add_child(base)
	base.position = p
	base.add_to_group("LegacyDesks")
	base.set_meta("desk_dimensions",Vector3(wide,0.88,1.1))
	box(base,Vector3(0,0.8,0),Vector3(wide,0.16,1.1),mats.furniture)
	for x in [-wide/2+0.15,wide/2-0.15]:
		box(base,Vector3(x,0.4,0),Vector3(0.15,0.8,0.8),mats.furniture)
	box(base,Vector3(0,0.52,1.1),Vector3(0.65,0.09,0.65),mats.furniture)
	for x in [-0.27,0.27]:
		for z in [0.84,1.36]:
			box(base,Vector3(x,0.25,z),Vector3(0.065,0.5,0.065),mats.furniture,false)
		box(base,Vector3(x,0.84,1.4),Vector3(0.06,0.8,0.06),mats.furniture,false)
	for y in [0.75,0.95,1.15]:
		box(base,Vector3(0,y,1.4),Vector3(0.62,0.08,0.06),mats.furniture,false)

func shelf(root: Node3D, p: Vector3):
	var rack = Node3D.new()
	root.add_child(rack)
	rack.position = p
	rack.add_to_group("InteriorShelfBases")
	for x in [-1.1,1.1]:
		var upright = box(rack,Vector3(x,1.05,0),Vector3(0.12,2.1,0.7),mats.furniture)
		upright.get_child(0).visible = false
	for y in [0.2,1.0,1.8]:
		var board = box(rack,Vector3(0,y,0),Vector3(2.2,0.10,0.7),mats.furniture)
		board.get_child(0).visible = false

func furnish():
	desk(buildings.ranger,Vector3(-2.6,0,0))
	shelf(buildings.ranger,Vector3(2.5,0,-3.9))
	item("ranger",Vector3(-2.7,1.04,0),"station_key","station_key","Take radio-station key",Color("e4c479"))
	note("ranger",Vector3(-1.9,0.91,0),"ranger_note","Ranger's log","The radio station is locked. Search my desk drawer for\nthe brass key. The store's counter drawer holds a spare\nfuse. Fit it at the workshop's outside panel, then search\nthe powered cabinet for a signal coil. Take the cellar key from the same cabinet. Follow Chapel\nRoad uphill and unlock the chapel cellar for a spare\ntuning unit. Bring all three parts to the radio receiver. Stay near the radio\nand hold E to call emergency services. E searches storage.")
	for x in [-3.3,3.3]:
		var old_bed = box(buildings.clinic,Vector3(x,0.6,0),Vector3(1.3,0.4,2.5),mats["plaster"])
		old_bed.add_to_group("LegacyClinicBeds")
		var old_pillow = box(buildings.clinic,Vector3(x,0.9,-0.8),Vector3(1.1,0.2,0.5),mats["wood"],false)
		old_pillow.add_to_group("LegacyClinicBeds")
	shelf(buildings.clinic,Vector3(-2.7,0,-4))
	item("clinic",Vector3(-3.3,0.95,0),"medkit_a","medkit","Take first-aid kit",Color("a56a58"))
	item("clinic",Vector3(3.3,0.95,0),"medkit_b","medkit","Take first-aid kit",Color("a56a58"))
	note("clinic",Vector3(-2.7,1.08,-3.9),"clinic_note","Evacuation notice","BLACKWOOD EVACUATION ORDER\nLeave supplies for those still coming through the forest.\nOld Mill Road is closed beyond the forest bend.\nThe phone lines are down. Use the town radio for help.\nFirst-aid kits: H. Spare flashlight batteries: Q.")
	for x in [-4,4]:
		shelf(buildings.store,Vector3(x,0,0))
	desk(buildings.store,Vector3(-2.8,0,-3.7),3.5)
	item("store",Vector3(-3,1.04,-3.7),"fuse","fuse","Take workshop fuse",Color("e5bd78"))
	item("store",Vector3(-4,1.13,0),"battery_a","battery","Take flashlight battery",Color("89b9b1"))
	item("store",Vector3(4,1.13,0),"battery_b","battery","Take flashlight battery",Color("89b9b1"))
	note("store",Vector3(-2,0.91,-3.7),"store_note","Shopkeeper's note","The millkeeper took the last signal coil to the workshop.\nIts cabinet only releases when power is restored.\nThe spare fuse is in this counter's drawer. The cemetery mausoleum holds the spare aerial coupling. Search it with E.\nThe workshop fuse panel is outside, beside its door.\nSpare flashlight cells are in the stock cabinet.")
	desk(buildings.workshop,Vector3(-3.1,0,-2.7),3.6)
	shelf(buildings.workshop,Vector3(4,0,-3.8))
	coil_visual = item("workshop",Vector3(-3.1,1.08,-2.7),"coil","coil","Recover signal coil",Color("dda967"))
	var panel = action_area(buildings.workshop,Vector3(2,1.25,5.2),Vector3(0.85,0.95,0.35),"fuse_panel",{"kind":"panel","label":"Install workshop fuse"})
	box(panel,Vector3.ZERO,Vector3(0.7,0.8,0.20),mats["metal"],false)
	box(panel,Vector3(0,0.2,0.13),Vector3(0.24,0.09,0.03),mats["amber"],false)
	powered_lights.append(lamp(buildings.workshop,Vector3(0,2.7,-0.5),Color("d4be85"),1.8,9))
	desk(buildings.radio,Vector3(-2.7,0,-3.4),3.2)
	var receiver = action_area(buildings.radio,Vector3(-2.7,1.20,-3.4),Vector3(1.2,0.7,0.65),"receiver",{"kind":"receiver","label":"Repair emergency radio"})
	box(receiver,Vector3.ZERO,Vector3(1.05,0.65,0.55),mats["metal"],false)
	box(receiver,Vector3(0,0.09,0.3),Vector3(0.55,0.23,0.03),mats["green"],false)
	receiver_light = lamp(receiver,Vector3(0,0.15,0.5),Color("8ed6b4"),0.4,3)
	for x in [-0.36,0.35]:
		box(receiver,Vector3(x,-0.16,0.31),Vector3(0.12,0.12,0.06),mats["amber"],false)
	note("radio",Vector3(-1.5,0.91,-3.4),"radio_note","Operator's instructions","EMERGENCY RADIO\nFit a SIGNAL COIL from the mill workshop to this receiver.\nThe workshop cabinet requires restored power.\nAfter repairs, stay here and hold E for four seconds\nto call emergency services. Report a car accident\non Old Mill Road, outside Blackwood.")
	# A low-poly antenna rises over the radio station.
	box(buildings.radio,Vector3(2.6,7.5,-2),Vector3(0.18,8.3,0.18),mats["metal"],false)
	for y in [6.5,8.5,10.5]:
		box(buildings.radio,Vector3(2.6,y,-2),Vector3(3.2,0.10,0.10),mats["metal"],false)
	lamp(buildings.radio,Vector3(2.6,11.7,-2),Color("bf5545"),0.5,3)
	var old_bed = box(buildings.house,Vector3(-3,0.5,-2.5),Vector3(1.8,0.7,3),mats["floor"])
	old_bed.add_to_group("LegacyHouseBeds")
	desk(buildings.house,Vector3(2.7,0,0))
	item("house",Vector3(2.7,1.04,0),"battery_c","battery","Take flashlight battery",Color("89b9b1"))
	item("house",Vector3(-3,1,-2.5),"medkit_c","medkit","Take first-aid kit",Color("a56a58"))
	note("house",Vector3(2,0.91,0),"house_note","Last letter","If you are reading this, the town is already empty.\nI left what I could in the clinic and the general store.\nThe lights in the workshop haven't worked for weeks.\nI used to hear traffic beyond the trees. Now the road\nis silent. If you need help, try the radio station.")

func reset():
	inventory = {"medkit":0,"battery":0,"station_key":0,"fuse":0,"coil":0,"chapel_key":0,"tuner":0,"shotgun_key":0,"antenna":0,"mausoleum_key":0}
	journal_entries.clear()
	discovered.clear()
	powered = false
	radio_ready = false
	reached_town = false
	focus_action = ""
	for data in actions.values():
		data.taken = false
		if data.kind=="ammo": data.amount = data.initial_amount
		data.area.visible = true
		data.area.collision_layer = 2
		data.area.get_child(0).set_deferred("disabled",false)
	for door in doors.values():
		if door.tween!=null and door.tween.is_valid():
			door.tween.kill()
		door.hinge.rotation.y = 0
		door.open = false
		door.collision.set_deferred("disabled",false)
	for light in powered_lights:
		light.visible = false
	receiver_light.light_energy = 0.4
	sign_crow.reset()
	streetscape.church.reset_doors()
	streetscape.church.basement.reset()
	interiors.reset()
	townspeople.reset()
	if cemetery: cemetery.reset()

func refresh_focus():
	focus_action = ""
	var start = game.camera.global_position
	var finish = start-game.camera.global_basis.z*3.2
	var query = PhysicsRayQueryParameters3D.create(start,finish,3,[game.player.get_rid()])
	query.collide_with_areas = true
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_meta("action_id"):
		var id: String = hit.collider.get_meta("action_id")
		if actions.has(id) and not actions[id].taken and actions[id].area.is_visible_in_tree():
			focus_action = id

func prompt() -> String:
	if focus_action=="":
		return ""
	var data = actions[focus_action]
	if data.kind=="mausoleum_door": return cemetery.door_prompt()
	if data.kind=="ammo":
		return "E / Take %d %s" % [data.amount,["pistol rounds","rifle rounds","shotgun shells"][data.weapon_index]]
	if data.kind=="radio_bypass":
		return "E / Set bypass to "+("AMBER - chapel repeater" if game.story.county_bypass else "GREEN - direct county")
	if data.kind=="cellar_door":
		return "E / Open cellar door" if streetscape.church.basement.unlocked else ("E / Unlock and open cellar door" if inventory.chapel_key>0 else "E / Locked cellar - inspect")
	if data.kind=="chapel_door":
		return "E / "+("Close chapel doors" if streetscape.church.doors_open else "Open chapel doors")
	if data.kind=="shotgun_lockbox":
		return game.weapons.lockbox.prompt()
	if data.kind=="container":
		return interiors.prompt(data.container)
	if data.kind=="npc":
		return "E / Talk to "+data.label
	if data.kind=="door":
		if data.building=="radio" and inventory.station_key==0:
			return "E / Locked - ranger's key needed"
		if doors[data.building].open and player_inside_building(data.building):
			return "Door stays open while you are inside"
		return "E / "+("Close door" if doors[data.building].open else "Open door")
	if focus_action=="coil" and not powered:
		return "E / Coil cabinet - restore workshop power"
	if data.kind=="panel" and powered:
		return "E / Inspect powered panel"
	if data.kind=="receiver" and radio_ready:
		return "Hold E / Call for rescue"
	return "E / "+data.label

func interact():
	refresh_focus()
	if focus_action!="" and game.state=="play":
		perform(focus_action)

func perform(id: String):
	var data = actions[id]
	if data.taken:
		return
	if data.kind!="crash" and id!="crash_record" and not id.begins_with("cemetery_"):
		reached_town = true
	match data.kind:
		"mausoleum_door":
			cemetery.interact_door()
		"ammo":
			var added = game.weapons.add_ammo(data.weapon_index,data.amount)
			if added==0:
				game.message = "Backpack or ammo reserve full. Free space to collect more." if game.state=="play" else game.message
				return
			data.amount -= added
			if data.amount==0:
				data.taken = true
				data.area.hide()
				data.area.collision_layer = 0
			game.message = "Collected %d %s. R reloads." % [added,["pistol rounds","rifle rounds","shotgun shells"][data.weapon_index]]
			game.soundscape.feedback("pickup")
		"shotgun_lockbox":
			game.weapons.lockbox.interact()
		"radio_bypass":
			game.story.toggle_bypass()
		"crash":
			game.message = "The engine is dead. A detour notice is caught in the glovebox. Inspect the paper."
			perform("crash_record")
		"weapon":
			if data.weapon_index==2 and not game.weapons.lockbox.can_take():
				game.message = "Open the ranger shotgun lockbox first."
				return
			if data.weapon_index==1 and (not streetscape.church.basement.unlocked or not streetscape.church.basement.contains(game.player.global_position)):
				game.message = "The service rifle is secured in the chapel cellar."
				return
			if game.weapons.collect(data.weapon_index):
				data.taken = true
				data.area.visible = false
				data.area.collision_layer = 0
				game.message = "Found "+game.weapons.LOADOUT[data.weapon_index].label.to_lower()+". Wheel / V cycles guns. R reloads."
				if data.weapon_index==0: game.message = "Pistol: 3 rounds loaded. Search buildings for ammo boxes. R reloads."
				game.soundscape.feedback("pickup")
		"cellar_door":
			streetscape.church.basement.interact()
		"cellar_exit":
			streetscape.church.basement.leave()
		"cellar_part":
			if streetscape.church.basement.unlocked and streetscape.church.basement.contains(game.player.global_position):
				if game.backpack and not game.backpack.room_for("tuner"):
					game.message = "Make a 2 x 2 space in your backpack for the tuning unit. It stays here."
					return
				inventory.tuner += 1
				data.taken = true
				data.area.hide()
				data.area.collision_layer = 0
				game.message = "Recovered radio tuning unit. Bring it, the coil and the cemetery coupler to the radio station."
				game.soundscape.feedback("pickup")
		"chapel_door":
			streetscape.church.toggle_doors()
		"npc":
			townspeople.talk(data.npc)
		"container":
			interiors.toggle(data.container)
		"door":
			var door = doors[data.building]
			if data.building=="radio" and inventory.station_key==0:
				game.message = "Locked. Search the ranger office for the station key."
				return
			if not set_building_door(data.building,not door.open):
				game.message = "The doorway must stay clear. Step outside before closing it."
			else:
				discovered[data.building] = true
		"item":
			if id=="cemetery_coupler" and not cemetery.can_take():
				game.message="The radio spare is inside the locked mausoleum."
				return
			if data.has("container_id") and not interiors.containers[data.container_id].searched:
				game.message = "Search the "+interiors.containers[data.container_id].label+" first."
				return
			if id=="coil" and not powered:
				game.message = "The coil cabinet needs power. Find and install the fuse."
				return
			if game.backpack and not game.backpack.room_for(data.item):
				game.message = "Backpack full. This item stays here. Open inventory with I to make room."
				return
			inventory[data.item] += 1
			data.taken = true
			data.area.visible = false
			data.area.get_child(0).set_deferred("disabled",true)
			game.message = data.label.replace("Take ","Collected: ").replace("Recover ","Recovered: ")
			game.soundscape.feedback("pickup")
		"note":
			if game.story: game.story.read_evidence(id)
			var seen = journal_entries.any(func(entry): return entry.id==id)
			if not seen:
				journal_entries.append({"id":id,"title":data.title,"text":data.text})
			game.journal_page = journal_entries.find(journal_entries.filter(func(entry): return entry.id==id)[0])+2
			game.journal_casefile = false
			game.set_state("journal")
		"panel":
			if powered:
				game.message = "Workshop power is on. The flashlight takes disposable batteries; Q fits a spare."
			elif inventory.fuse>0:
				inventory.fuse -= 1
				powered = true
				for light in powered_lights:
					light.visible = true
				game.message = "Workshop power restored. The signal-coil cabinet is released."
				game.soundscape.feedback("power")
			else:
				game.message = "A fuse is missing. Search the general store's counter drawer."
		"receiver":
			if radio_ready:
				game.message = "The radio has power. Hold E nearby to call for rescue."
			elif inventory.coil==0:
				game.message = "Receiver needs a signal coil from the powered workshop."
			elif inventory.tuner==0:
				game.message = "Receiver also needs the tuning unit in the locked chapel cellar. Key: workshop cabinet."
			elif inventory.antenna==0:
				game.message = "Receiver needs an antenna coupler. Search inside the locked cemetery mausoleum."
			else:
				inventory.antenna -= 1
				inventory.coil -= 1
				inventory.tuner -= 1
				radio_ready = true
				receiver_light.light_energy = 2
				game.message = "Radio repaired. Set the desk bypass to green, then hold E at the receiver."
				game.soundscape.feedback("radio")

func use_medkit():
	if inventory.medkit<=0:
		game.message = "No first-aid kits. Search the clinic's medicine cabinet."
	elif game.health>=100:
		game.message = "Vitality is full. First-aid kit saved."
	else:
		inventory.medkit -= 1
		game.health = minf(100,game.health+45)
		game.message = "Used first-aid kit. Vitality restored."
		game.soundscape.feedback("pickup")

func use_battery():
	if inventory.battery<=0:
		game.message = "No spare batteries. Search cabinets and drawers in town."
	elif game.flashlight_charge>=99:
		game.message = "Flashlight is charged. Battery saved."
	else:
		inventory.battery -= 1
		game.flashlight_charge = 100
		game.message = "Fresh flashlight battery fitted. Press F to switch it on."
		game.soundscape.feedback("pickup")

func objective() -> String:
	if not radio_ready and inventory.antenna==0:
		return "Unlock the cemetery mausoleum. Read the gatepost notice for a clue."
	if radio_ready:
		return "Warn county at radio. Hold E; no sirens." if game.story.direct_channel_selected() else "Set the desk bypass to GREEN / direct county."
	if not reached_town:
		return "Reach Blackwood. Find a way to call for help."
	if inventory.station_key==0:
		return "Search the ranger office for the radio-station key."
	if not powered:
		return "Install the fuse at the workshop panel." if inventory.fuse>0 else "Search the general store for a workshop fuse."
	if inventory.coil==0:
		return "Recover the signal coil from the powered workshop."
	if inventory.tuner==0:
		if inventory.chapel_key==0:
			return "Find the chapel key in the workshop coil cabinet."
		return "Find the isolated tuning unit in the cellar."
	return "Bring the coil, tuning unit and antenna coupler to the radio receiver."

func navigation_target() -> Vector3:
	if not radio_ready and inventory.antenna==0:
		return actions.cemetery_door.area.global_position
	if not reached_town:
		return Vector3(0,0,-42)
	if radio_ready:
		return actions.receiver.area.global_position
	var building = "radio"
	if inventory.station_key==0:
		building = "ranger"
	elif not powered:
		building = "workshop" if inventory.fuse>0 else "store"
	elif inventory.coil==0:
		building = "workshop"
	if inventory.coil>0 and inventory.tuner==0 and inventory.chapel_key>0:
		if streetscape.church.basement.contains(game.player.global_position):
			return actions.radio_tuner.area.global_position
		return actions.cellar_door.area.global_position
	return buildings[building].to_global(Vector3(0,0,7))

func location_name() -> String:
	if cemetery and cemetery.contains(game.player.global_position): return "OLD MILL CEMETERY"
	if streetscape.church.basement.contains(game.player.global_position):
		return "BLACKWOOD CHAPEL / CELLAR"
	if streetscape.church and streetscape.church.contains(game.player.global_position):
		return "BLACKWOOD CHAPEL"
	if game.player.global_position.distance_to(game.START_POSITION)<9:
		return "OLD MILL ROAD / CRASH SITE"
	for data in BUILDINGS:
		var p = buildings[data.id].to_local(game.player.global_position)
		if absf(p.x)<data.w/2 and absf(p.z)<data.d/2:
			return data.label
	return "BLACKWOOD / MAIN STREET" if game.player.position.z< -37 else "BLACKWOOD FOREST"

func update_arrival():
	if not reached_town and game.player.position.z< -37 and absf(game.player.position.x)<40:
		reached_town = true
		game.message = "Blackwood. Find supplies and a working radio. TAB opens your journal."

func player_inside_building(id: String) -> bool:
	for data in BUILDINGS:
		if data.id==id:
			var p = buildings[id].to_local(game.player.global_position)
			return absf(p.x)<data.w/2+0.3 and absf(p.z)<data.d/2+0.3 and p.y> -0.3 and p.y<4
	return false

# Shared by player interaction and NPC routines so both obey the same safety checks.
func doorway_position(id: String) -> Vector3:
	return buildings[id].to_global(Vector3(0,0,5))

func doorway_occupied(id: String) -> bool:
	var doorway=doorway_position(id)
	var player_offset=game.player.global_position-doorway
	player_offset.y=0
	if player_offset.length()<1.55: return true
	if townspeople:
		for person in townspeople.characters.values():
			if person.dead: continue
			var offset=person.actor.global_position-doorway
			offset.y=0
			if offset.length()<1.55: return true
	return false

func set_building_door(id: String, next_open: bool) -> bool:
	if not doors.has(id): return false
	var door=doors[id]
	if door.open==next_open: return true
	if next_open and id=="radio" and inventory.station_key==0: return false
	if not next_open and (player_inside_building(id) or doorway_occupied(id)): return false
	if door.tween!=null and door.tween.is_valid(): door.tween.kill()
	door.open=next_open
	door.collision.set_deferred("disabled",next_open)
	door.tween=create_tween()
	door.tween.tween_property(door.hinge,"rotation:y",-1.75 if next_open else 0.0,0.55)
	game.soundscape.door_move(doorway_position(id),next_open)
	return true
