extends Node3D
## Abandoned Blackwood: furnished, enterable buildings and a resettable item quest.
const BUILDINGS = [
	{"id":"ranger","label":"RANGER CABIN","p":Vector3(-23,0,-69),"w":11.0,"d":10.0,"r":0.0,"wall":"wood"},
	{"id":"clinic","label":"BLACKWOOD CLINIC","p":Vector3(-8,0,-69),"w":11.0,"d":10.0,"r":0.0,"wall":"plaster"},
	{"id":"store","label":"GENERAL STORE","p":Vector3(8,0,-69),"w":12.0,"d":10.0,"r":0.0,"wall":"wood"},
	{"id":"radio","label":"RADIO STATION","p":Vector3(25,0,-69),"w":11.0,"d":10.0,"r":0.0,"wall":"brick"},
	{"id":"workshop","label":"MILL WORKSHOP","p":Vector3(21,0,-46),"w":12.0,"d":10.0,"r":PI,"wall":"metal"},
	{"id":"house","label":"MILLKEEPER'S HOUSE","p":Vector3(-21,0,-46),"w":12.0,"d":10.0,"r":PI,"wall":"wood"}]
var game
var buildings = {}
var doors = {}
var actions = {}
var inventory = {"medkit":0,"battery":0,"station_key":0,"fuse":0,"coil":0}
var journal_entries: Array[Dictionary] = []
var powered = false
var radio_ready = false
var focus_action = ""
var mats = {}
var powered_lights: Array[OmniLight3D] = []
var coil_visual: Node3D
var receiver_light: OmniLight3D
var discovered = {}
var interiors: Node3D
var townspeople: Node3D

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
	build_street()
	for data in BUILDINGS:
		build_house(data)
	furnish()
	interiors = Node3D.new()
	interiors.set_script(preload("res://interiors.gd"))
	interiors.town = self
	add_child(interiors)
	townspeople = Node3D.new()
	townspeople.set_script(preload("res://townspeople.gd"))
	townspeople.town = self
	add_child(townspeople)
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
	box(self,Vector3(0,0.008,-56),Vector3(78,0.012,7),mats["dark"],false)
	box(self,Vector3(0,0.012,-28),Vector3(3.2,0.014,56),mats["floor"],false)
	for x in range(-34,36,8):
		box(self,Vector3(x,0.024,-56),Vector3(2.6,0.01,0.13),mats["amber"],false)
	for x in [-34,0,35]:
		box(self,Vector3(x,2.2,-60),Vector3(0.13,4.4,0.13),mats["metal"])
		box(self,Vector3(x,4.3,-59.6),Vector3(0.75,0.1,0.7),mats["dark"],false)
		lamp(self,Vector3(x,4,-59.6),Color("bda079"),0.55,10)
	# A roadside landmark makes the town discoverable from the forest.
	box(self,Vector3(2.3,1.1,-35),Vector3(0.15,2.2,0.15),mats["wood"])
	box(self,Vector3(2.3,1.9,-35),Vector3(4.8,0.85,0.16),mats["wood"],false)
	sign_text(self,"BLACKWOOD  /  OLD MILL ROAD",Vector3(2.3,1.93,-34.9),24)
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
	var wall: Material = mats[data.wall]
	# Floors meet the outside ground; no invisible step at the entrance.
	# Visual flooring sits above the shared ground to avoid z-fighting.
	box(root,Vector3(0,-0.05,0),Vector3(w,0.13,d),mats["floor"],false)
	box(root,Vector3(0,1.8,-d/2),Vector3(w,3.6,0.22),wall)
	for side in [-1,1]:
		box(root,Vector3(side*w/2,1.8,0),Vector3(0.22,3.6,d),wall)
		var low = -w/2 if side<0 else 0.95
		var high = -0.95 if side<0 else w/2
		var window = side*w*0.31
		box(root,Vector3((low+window-0.85)/2,1.8,d/2),Vector3(window-0.85-low,3.6,0.22),wall)
		box(root,Vector3((window+0.85+high)/2,1.8,d/2),Vector3(high-window-0.85,3.6,0.22),wall)
		box(root,Vector3(window,0.5,d/2),Vector3(1.7,1,0.22),wall)
		box(root,Vector3(window,3.0,d/2),Vector3(1.7,1.2,0.22),wall)
		# Broken window boards leave gaps to see through.
		var board = box(root,Vector3(window,1.6,d/2+0.13),Vector3(1.9,0.16,0.07),mats["wood"],false)
		board.rotation.z = side*0.16
	box(root,Vector3(0,3.15,d/2),Vector3(1.9,0.9,0.22),wall)
	box(root,Vector3(0,3.50,d/2+0.16),Vector3(w*0.86,0.55,0.12),mats["dark"],false)
	var title = sign_text(root,data.label,Vector3(0,3.49,d/2+0.24),38)
	title.pixel_size = 0.012
	# Two sloping roof panels and triangular gable ends.
	var angle = atan2(1.35,w/2+0.4)
	for side in [-1,1]:
		var roof = box(root,Vector3(side*(w/4+0.2),4.24,0),Vector3(sqrt(pow(w/2+0.4,2)+1.35*1.35),0.15,d+1),mats["roof"])
		roof.rotation.z = -side*angle
	var gable = SurfaceTool.new()
	gable.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in [-d/2,d/2]:
		for v in [Vector3(-w/2,3.6,z),Vector3(w/2,3.6,z),Vector3(0,4.95,z)]:
			gable.set_uv(Vector2(v.x,v.y)*0.3)
			gable.add_vertex(v)
	gable.generate_normals()
	var triangle = MeshInstance3D.new()
	triangle.mesh = gable.commit()
	var gable_mat = wall.duplicate()
	gable_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	triangle.material_override = gable_mat
	root.add_child(triangle)
	make_door(root,data.id,d/2)
	lamp(root,Vector3(0,2.8,1),Color("b2b29c"),0.45,7)
	# Interior partition with a generous side passage to a rear storage nook.
	box(root,Vector3(w/4,1.5,-1.6),Vector3(w/2-0.8,3,0.14),wall)
	box(root,Vector3(-w/2+0.5,0.35,-d/2+0.6),Vector3(0.8,0.7,0.7),mats["wood"])

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
	box(area,Vector3.ZERO,Vector3(0.35,0.22,0.25),color_material(color,0.45),false)
	if key=="medkit":
		box(area,Vector3(0,0.12,0),Vector3(0.23,0.02,0.06),mats["plaster"],false)
		box(area,Vector3(0,0.12,0),Vector3(0.06,0.02,0.18),mats["plaster"],false)
	lamp(area,Vector3(0,0.15,0),color,0.22,1.5)
	return area

func note(building: String, p: Vector3, id: String, title: String, body: String):
	var area = action_area(buildings[building],p,Vector3(0.55,0.16,0.5),id,{"kind":"note","label":"Read "+title,"title":title,"text":body})
	box(area,Vector3.ZERO,Vector3(0.42,0.025,0.32),color_material(Color("d4c49e")),false)
	for i in range(3):
		box(area,Vector3(0,0.015,-0.09+i*0.06),Vector3(0.29,0.006,0.012),mats["dark"],false)

func desk(root: Node3D, p: Vector3, wide = 2.6):
	box(root,p+Vector3(0,0.8,0),Vector3(wide,0.16,1.1),mats.furniture)
	for x in [-wide/2+0.15,wide/2-0.15]:
		box(root,p+Vector3(x,0.4,0),Vector3(0.15,0.8,0.8),mats.furniture)
	box(root,p+Vector3(0,0.52,1.1),Vector3(0.65,0.09,0.65),mats.furniture)
	for x in [-0.27,0.27]:
		for z in [0.84,1.36]:
			box(root,p+Vector3(x,0.25,z),Vector3(0.065,0.5,0.065),mats.furniture,false)
		box(root,p+Vector3(x,0.84,1.4),Vector3(0.06,0.8,0.06),mats.furniture,false)
	for y in [0.75,0.95,1.15]:
		box(root,p+Vector3(0,y,1.4),Vector3(0.62,0.08,0.06),mats.furniture,false)

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
	note("ranger",Vector3(-1.9,0.91,0),"ranger_note","Ranger's log","The radio station is locked. Search my desk drawer for\nthe brass key. The store's counter drawer holds a spare\nfuse. Fit it at the workshop's outside panel, then search\nthe powered cabinet for a signal coil. Bring the coil to\nthe station receiver and calibrate it. Signal from the\nclearing once the uplink is ready. E searches storage.")
	for x in [-3.3,3.3]:
		box(buildings.clinic,Vector3(x,0.6,0),Vector3(1.3,0.4,2.5),mats["plaster"])
		box(buildings.clinic,Vector3(x,0.9,-0.8),Vector3(1.1,0.2,0.5),mats["wood"],false)
	shelf(buildings.clinic,Vector3(-2.7,0,-4))
	item("clinic",Vector3(-3.3,0.95,0),"medkit_a","medkit","Take first-aid kit",Color("a56a58"))
	item("clinic",Vector3(3.3,0.95,0),"medkit_b","medkit","Take first-aid kit",Color("a56a58"))
	note("clinic",Vector3(-2.7,1.08,-3.9),"clinic_note","Evacuation notice","BLACKWOOD EVACUATION ORDER\nLeave supplies for those still coming through the forest.\nThe search machines track movement. Solid walls break\ntheir sight lines. Keep quiet and use the buildings as cover.\nFirst-aid kits: H. Spare flashlight batteries: Q.")
	for x in [-4,4]:
		shelf(buildings.store,Vector3(x,0,0))
	desk(buildings.store,Vector3(-2.8,0,-3.7),3.5)
	item("store",Vector3(-3,1.04,-3.7),"fuse","fuse","Take workshop fuse",Color("e5bd78"))
	item("store",Vector3(-4,1.13,0),"battery_a","battery","Take flashlight battery",Color("89b9b1"))
	item("store",Vector3(4,1.13,0),"battery_b","battery","Take flashlight battery",Color("89b9b1"))
	note("store",Vector3(-2,0.91,-3.7),"store_note","Shopkeeper's note","The millkeeper took the last signal coil to the workshop.\nIts cabinet only releases when power is restored.\nThe spare fuse is in this counter's drawer. Search it with E.\nThe workshop fuse panel is outside, beside its door.\nSpare flashlight cells are in the stock cabinet.")
	desk(buildings.workshop,Vector3(-3.1,0,-2.7),3.6)
	shelf(buildings.workshop,Vector3(4,0,-3.8))
	coil_visual = item("workshop",Vector3(-3.1,1.08,-2.7),"coil","coil","Recover signal coil",Color("dda967"))
	var panel = action_area(buildings.workshop,Vector3(2,1.25,5.2),Vector3(0.85,0.95,0.35),"fuse_panel",{"kind":"panel","label":"Install workshop fuse"})
	box(panel,Vector3.ZERO,Vector3(0.7,0.8,0.20),mats["metal"],false)
	box(panel,Vector3(0,0.2,0.13),Vector3(0.24,0.09,0.03),mats["amber"],false)
	powered_lights.append(lamp(buildings.workshop,Vector3(0,2.7,-0.5),Color("d4be85"),1.8,9))
	desk(buildings.radio,Vector3(-2.7,0,-3.4),3.2)
	var receiver = action_area(buildings.radio,Vector3(-2.7,1.20,-3.4),Vector3(1.2,0.7,0.65),"receiver",{"kind":"receiver","label":"Repair and calibrate receiver"})
	box(receiver,Vector3.ZERO,Vector3(1.05,0.65,0.55),mats["metal"],false)
	box(receiver,Vector3(0,0.09,0.3),Vector3(0.55,0.23,0.03),mats["green"],false)
	receiver_light = lamp(receiver,Vector3(0,0.15,0.5),Color("8ed6b4"),0.4,3)
	for x in [-0.36,0.35]:
		box(receiver,Vector3(x,-0.16,0.31),Vector3(0.12,0.12,0.06),mats["amber"],false)
	note("radio",Vector3(-1.5,0.91,-3.4),"radio_note","Operator's instructions","EMERGENCY UPLINK\nFit a SIGNAL COIL from the mill workshop to this receiver.\nThe workshop cabinet requires restored power.\nOnce calibration is complete, return to the landing clearing\nand hold E at the beacon for four seconds.\nSomeone out there might still be listening.")
	# A low-poly antenna rises over the radio station.
	box(buildings.radio,Vector3(2.6,7.5,-2),Vector3(0.18,8.3,0.18),mats["metal"],false)
	for y in [6.5,8.5,10.5]:
		box(buildings.radio,Vector3(2.6,y,-2),Vector3(3.2,0.10,0.10),mats["metal"],false)
	lamp(buildings.radio,Vector3(2.6,11.7,-2),Color("bf5545"),0.5,3)
	box(buildings.house,Vector3(-3,0.5,-2.5),Vector3(1.8,0.7,3),mats["floor"])
	desk(buildings.house,Vector3(2.7,0,0))
	item("house",Vector3(2.7,1.04,0),"battery_c","battery","Take flashlight battery",Color("89b9b1"))
	item("house",Vector3(-3,1,-2.5),"medkit_c","medkit","Take first-aid kit",Color("a56a58"))
	note("house",Vector3(2,0.91,0),"house_note","Last letter","If you are reading this, the town is already empty.\nI left what I could in the clinic and the general store.\nThe lights in the workshop haven't worked for weeks.\nI used to hear owls beyond the road. Now all I hear\nis that low humming above the trees.")

func reset():
	inventory = {"medkit":0,"battery":0,"station_key":0,"fuse":0,"coil":0}
	journal_entries.clear()
	discovered.clear()
	powered = false
	radio_ready = false
	focus_action = ""
	for data in actions.values():
		data.taken = false
		data.area.visible = true
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
	interiors.reset()
	townspeople.reset()

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
		return "E / Recharge flashlight at powered panel"
	if data.kind=="receiver" and radio_ready:
		return "Uplink calibrated. Return to the clearing."
	return "E / "+data.label

func interact():
	refresh_focus()
	if focus_action!="" and game.state=="play":
		perform(focus_action)

func perform(id: String):
	var data = actions[id]
	if data.taken:
		return
	match data.kind:
		"npc":
			townspeople.talk(data.npc)
		"container":
			interiors.toggle(data.container)
		"door":
			var door = doors[data.building]
			if data.building=="radio" and inventory.station_key==0:
				game.message = "Locked. Search the ranger cabin for the station key."
				return
			var doorway = buildings[data.building].to_global(Vector3(0,0,5))
			if door.open and (player_inside_building(data.building) or game.player.global_position.distance_to(doorway)<1.4):
				game.message = "This door stays open while you are inside. Step outside to close it."
				return
			if door.tween!=null and door.tween.is_valid():
				door.tween.kill()
			door.open = not door.open
			door.collision.set_deferred("disabled",door.open)
			door.tween = create_tween()
			door.tween.tween_property(door.hinge,"rotation:y",-1.75 if door.open else 0.0,0.45)
			game.soundscape.door_move(doorway,door.open)
			discovered[data.building] = true
		"item":
			if data.has("container_id") and not interiors.containers[data.container_id].searched:
				game.message = "Search the "+interiors.containers[data.container_id].label+" first."
				return
			if id=="coil" and not powered:
				game.message = "The coil cabinet needs power. Find and install the fuse."
				return
			inventory[data.item] += 1
			data.taken = true
			data.area.visible = false
			data.area.get_child(0).set_deferred("disabled",true)
			game.message = data.label.replace("Take ","Collected: ").replace("Recover ","Recovered: ")
			game.soundscape.feedback("pickup")
		"note":
			var seen = journal_entries.any(func(entry): return entry.id==id)
			if not seen:
				journal_entries.append({"id":id,"title":data.title,"text":data.text})
			game.journal_page = journal_entries.find(journal_entries.filter(func(entry): return entry.id==id)[0])+2
			game.set_state("journal")
		"panel":
			if powered:
				game.flashlight_charge = 100
				game.message = "Flashlight recharged at the workshop panel."
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
				game.message = "Uplink calibrated. Return to the landing clearing."
			elif inventory.coil==0:
				game.message = "Receiver needs a signal coil from the powered workshop."
			else:
				inventory.coil -= 1
				radio_ready = true
				receiver_light.light_energy = 2
				game.beam.visible = true
				game.message = "Contact established! Return to the clearing and hold E to call home."
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
	if radio_ready:
		return "Return to the clearing. Hold E to call home."
	if inventory.station_key==0:
		return "Search the ranger cabin for the radio-station key."
	if not powered:
		return "Install the fuse at the workshop panel." if inventory.fuse>0 else "Search the general store for a workshop fuse."
	if inventory.coil==0:
		return "Recover the signal coil from the powered workshop."
	return "Bring the coil to the radio-station receiver."

func navigation_target() -> Vector3:
	var building = "radio"
	if inventory.station_key==0:
		building = "ranger"
	elif not powered:
		building = "workshop" if inventory.fuse>0 else "store"
	elif inventory.coil==0:
		building = "workshop"
	return buildings[building].to_global(Vector3(0,0,7))

func location_name() -> String:
	for data in BUILDINGS:
		var p = buildings[data.id].to_local(game.player.global_position)
		if absf(p.x)<data.w/2 and absf(p.z)<data.d/2:
			return data.label
	return "OLD MILL ROAD" if game.player.position.z< -37 else "BLACKWOOD FOREST"

func player_inside_building(id: String) -> bool:
	for data in BUILDINGS:
		if data.id==id:
			var p = buildings[id].to_local(game.player.global_position)
			return absf(p.x)<data.w/2+0.3 and absf(p.z)<data.d/2+0.3 and p.y> -0.3 and p.y<4
	return false
