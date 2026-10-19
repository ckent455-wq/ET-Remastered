extends Control
## Inventory is derived from the actual supply/weapon counts; there is no second ledger.
var game
var selected = 0
var notice = "Select an item to equip, use or examine."
var discard_pending = ""
var saved_cells: Dictionary = {}
var dragging = ""
var drag_offset = Vector2.ZERO
var drag_mouse = Vector2.ZERO
var icons: Dictionary = {}
const ORIGIN = Vector2(38,104)
const CELL = 44
const FONT = preload("res://assets/font.ttf")
const INK = Color("ddd8bf")
const DIM = Color("88998a")
const GOLD = Color("d4ad70")
const STACKS = [12,20,6]
const OBJECTIVES = ["station_key","workshop_fuse","coil","chapel_key","tuner","shotgun_key","antenna","mausoleum_key","shovel"]
const OBJECTIVE_LABELS = {"shovel":"RUSTED SHOVEL","mausoleum_key":"MAUSOLEUM KEY","antenna":"ANTENNA COUPLER","station_key":"RADIO STATION KEY","workshop_fuse":"WORKSHOP FUSE","coil":"SIGNAL COIL","chapel_key":"CHAPEL CELLAR KEY","tuner":"RADIO TUNING UNIT","shotgun_key":"SHOTGUN BOX KEY"}
const OBJECTIVE_DETAILS = {"shovel":"A battered spade. Hold interact at the freshly disturbed grave in Old Mill Cemetery to dig. Other graves stay untouched.","mausoleum_key":"Old iron key for the Whitcomb mausoleum in Old Mill Cemetery. Used automatically at its door.","antenna":"Spare aerial coupling from Old Mill Cemetery. Bring it to the radio receiver with the signal coil and tuning unit.","station_key":"Unlocks the radio station door. Used automatically at the door.","workshop_fuse":"Fit inside the workshop's high-voltage cabinet, then flip the switch to restore power.","coil":"Bring this signal coil and the tuning unit to the radio receiver.","chapel_key":"Unlocks the chapel cellar. Used automatically at the cellar door.","tuner":"Bring this tuning unit and the signal coil to the radio receiver.","shotgun_key":"Unlocks the ranger's shotgun box. Used automatically at the box."}

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("build_icons")

func _process(_delta):
	visible = game.state == "backpack"
	if not visible: dragging = ""
	if visible: queue_redraw()

func counts() -> Dictionary:
	var result = {"flashlight":int(game.crash_site.has_flashlight),"medkit":game.town.inventory.medkit,"battery":game.town.inventory.battery}
	for id in OBJECTIVES: result[id]=game.town.inventory[id]
	for i in range(3):
		result["gun%d" % i] = int(game.weapons.owned[i])
		result["ammo%d" % i] = game.weapons.reserves[i]
	return result

func fits(cell: Vector2i, dimensions: Vector2i, entries: Array, except_key = "") -> bool:
	if cell.x<0 or cell.y<0 or cell.x+dimensions.x>6 or cell.y+dimensions.y>4: return false
	var target = Rect2i(cell,dimensions)
	for entry in entries:
		if entry.key!=except_key and target.intersects(Rect2i(entry.cell,entry.size)): return false
	return true

func pack(values: Dictionary) -> Array:
	var requested: Array = []
	for id in ["gun1","gun2","coil","tuner","gun0","medkit","antenna","flashlight","battery","ammo0","ammo1","ammo2","station_key","workshop_fuse","chapel_key","shotgun_key","mausoleum_key","shovel"]:
		var amount: int = values.get(id,0)
		var dims = Vector2i(1,1)
		var limit = 1
		if id=="shovel": dims=Vector2i(1,3)
		if id in ["gun1","gun2"]: dims = Vector2i(4,1)
		if id in ["coil","tuner"]: dims = Vector2i(2,2)
		if id in ["gun0","medkit","antenna"]: dims = Vector2i(2,1)
		if id == "flashlight": dims = Vector2i(1,2)
		if id == "battery": limit = 2
		if id.begins_with("ammo"): limit = STACKS[int(id.right(1))]
		var stack = 0
		while amount>0:
			requested.append({"id":id,"key":id+":"+str(stack),"amount":mini(amount,limit),"cell":Vector2i(-1,-1),"size":dims})
			amount-=limit
			stack+=1
	var placed: Array = []
	# Preserve the player's layout first. New pickups use remaining free rectangles.
	for entry in requested:
		if saved_cells.has(entry.key) and fits(saved_cells[entry.key],entry.size,placed):
			entry.cell=saved_cells[entry.key]
			placed.append(entry)
	for entry in requested:
		if entry.cell.x>=0: continue
		var found = false
		for y in range(5-entry.size.y):
			for x in range(7-entry.size.x):
				if fits(Vector2i(x,y),entry.size,placed):
					entry.cell=Vector2i(x,y)
					placed.append(entry)
					found=true
					break
			if found: break
		if not found: return []
	return requested

func remember(entries: Array):
	saved_cells.clear()
	for entry in entries: saved_cells[entry.key]=entry.cell

func drop_cell() -> Vector2i:
	return Vector2i(((drag_mouse-drag_offset-ORIGIN)/CELL).round())

func room_for(id: String, amount: int = 1) -> bool:
	var values = counts()
	values[id] = values.get(id,0)+amount
	return not pack(values).is_empty()

func label(id: String) -> String:
	if OBJECTIVE_LABELS.has(id): return OBJECTIVE_LABELS[id]
	if id.begins_with("gun"): return ["PISTOL","SERVICE RIFLE","SHOTGUN"][int(id.right(1))]
	if id.begins_with("ammo"): return ["PISTOL ROUNDS","RIFLE ROUNDS","SHOTGUN SHELLS"][int(id.right(1))]
	return {"flashlight":"FLASHLIGHT","medkit":"FIRST AID","battery":"BATTERY"}.get(id,id)

func rect(entry: Dictionary) -> Rect2:
	return Rect2(ORIGIN+Vector2(entry.cell)*CELL+Vector2(2,2),Vector2(entry.size)*CELL-Vector2(4,4))

func write(value: String, point: Vector2, size = 12, color = INK):
	draw_string(FONT,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _draw():
	draw_rect(Rect2(0,0,640,400),Color("111813"))
	write("BLACKWOOD / BACKPACK",Vector2(38,35),23)
	write("24 SLOTS / MOVE TO ARRANGE" if game.controller.using_controller else "24 SLOTS / DRAG TO ARRANGE",Vector2(38,88),11,DIM)
	for i in range(3):
		var box = Rect2(38+i*187,48,176,25)
		draw_rect(box,Color("394335") if i==0 else Color("202b22"))
		write((["BACKPACK","JOURNAL","MAP"] if game.controller.using_controller else ["I  BACKPACK","J  JOURNAL","M  MAP"])[i],box.position+Vector2(10,17),12)
	for y in range(4):
		for x in range(6):
			draw_rect(Rect2(ORIGIN+Vector2(x,y)*CELL,Vector2(CELL-1,CELL-1)),Color("293126"))
	var entries = pack(counts())
	remember(entries)
	selected = clampi(selected,0,maxi(0,entries.size()-1))
	var used = 0
	for i in range(entries.size()):
		var item: Dictionary = entries[i]
		used += item.size.x*item.size.y
		var box = rect(item)
		draw_rect(box,Color("48523a") if i==selected else Color("323d30"))
		draw_rect(box,GOLD if i==selected else DIM,false,1)
		if item.key!=dragging: draw_icon(item.id,box)
		if item.amount>1: write("x%d" % item.amount,box.end-Vector2(23,5),11,GOLD)
	write("%d / 24 OCCUPIED" % used,Vector2(38,295),11,GOLD)
	write("OBJECTIVE ITEMS SHARE BACKPACK SPACE",Vector2(38,321),11,DIM)
	paragraph("Coil / tuning unit: 2 x 2 each. Coupler: 2 slots. Keys: 1 slot. Workshop fuse: 2 slots. Installed parts free space.",Vector2(38,339),555)
	write("HEALTH %d / LIGHT %d%%" % [game.health,game.flashlight_charge],Vector2(330,88),12,DIM)
	if not entries.is_empty():
		var item: Dictionary = entries[selected]
		write(label(item.id),Vector2(330,121),19,GOLD)
		write("%d x %d slots" % [item.size.x,item.size.y],Vector2(330,143),11,DIM)
		var detail = ""
		if item.id.begins_with("gun"):
			var index = int(item.id.right(1))
			detail = "Loaded %d / %d. Reserve %d." % [game.weapons.magazines[index],game.weapons.LOADOUT[index].clip,game.weapons.reserves[index]]
		else: detail = {"flashlight":"Your light. Equipped on your shoulder strap.","medkit":"Restores 45 health. One kit per space.","battery":"Refills flashlight charge. Stacks of two."}.get(item.id,"Combine with its weapon to reload.")
		if OBJECTIVE_DETAILS.has(item.id): detail=OBJECTIVE_DETAILS[item.id]
		paragraph(detail,Vector2(330,163),270)
		for i in range(4):
			var box = Rect2(330+(i%2)*139,207+(i/2)*31,130,25)
			draw_rect(box,Color("3d4734"))
			var actions=["ENTER  USE","X  EXAMINE","C  COMBINE","DEL  DISCARD"]
			if game.controller.using_controller: actions=[game.controller.label("south")+"  USE",game.controller.label("north")+"  EXAMINE",game.controller.label("lb")+"  COMBINE",game.controller.label("rb")+"  DISCARD"]
			write(actions[i],box.position+Vector2(6,17),11)
	paragraph(notice,Vector2(330,286),270)
	var footer="DRAG  Move items     ARROWS  Select     I / ESC  Close"
	if game.controller.using_controller:footer=game.controller.label("west")+"  Move / place    D-PAD / LS  Select    "+game.controller.label("east")+"  Back"
	write(footer,Vector2(38,383),11,DIM)

	if dragging!="":
		for entry in entries:
			if entry.key!=dragging: continue
			var target = drop_cell()
			var valid = fits(target,entry.size,entries,dragging)
			var target_box = Rect2(ORIGIN+Vector2(target)*CELL,Vector2(entry.size)*CELL)
			draw_rect(target_box,Color(0.4,0.7,0.4,0.35) if valid else Color(0.8,0.2,0.15,0.4))
			var ghost = Rect2(drag_mouse-drag_offset,Vector2(entry.size)*CELL-Vector2(4,4))
			draw_rect(ghost,Color(0.12,0.17,0.12,0.9))
			draw_icon(entry.id,ghost)
			draw_rect(ghost,GOLD,false,1)

func paragraph(value: String, start: Vector2, width: float):
	var line = ""
	var y = start.y
	for word in value.split(" "):
		if FONT.get_string_size(line+word,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x>width:
			write(line,Vector2(start.x,y),11,DIM)
			y += 14
			line = ""
		line += word+" "
	write(line,Vector2(start.x,y),11,DIM)

func copy_meshes(source: Node, parent: Node3D, accumulated = Transform3D.IDENTITY):
	var current: Transform3D = accumulated
	if source is Node3D: current=accumulated*source.transform
	if source is MeshInstance3D and source.mesh:
		var part = MeshInstance3D.new()
		part.mesh=source.mesh
		part.transform=current
		part.material_override=source.material_override
		for i in range(source.mesh.get_surface_count()):
			part.set_surface_override_material(i,source.get_surface_override_material(i))
		parent.add_child(part)
	for child in source.get_children(): copy_meshes(child,parent,current)

func build_icons():
	for id in ["gun0","gun1","gun2","ammo0","ammo1","ammo2","flashlight","medkit","battery"]+OBJECTIVES:
		var viewport = SubViewport.new()
		viewport.size=Vector2i(256,128) if id.begins_with("gun") or id=="medkit" else Vector2i(128,384) if id=="shovel" else Vector2i(128,192) if id=="flashlight" else Vector2i(128,128)
		viewport.transparent_bg=true
		viewport.own_world_3d=true
		viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
		add_child(viewport)
		var model = Node3D.new()
		viewport.add_child(model)
		if id=="shovel":
			var source=preload("res://spade_model.gd").build()
			copy_meshes(source,model)
			source.free()
		elif id in ["battery","medkit","workshop_fuse","coil"]:
			var source=preload("res://supply_models.gd").build(id)
			copy_meshes(source,model)
			source.free()
		elif id.ends_with("_key"):
			var source = preload("res://assets/lockbox/key.glb").instantiate()
			copy_meshes(source,model)
			source.free()
		elif id in ["medkit","battery"] or id in OBJECTIVES:
			# These supplies are procedural world models; reuse their exact mesh/materials.
			var source_id = {"medkit":"medkit_a","battery":"battery_a","tuner":"radio_tuner","chapel_key":"shotgun_key","antenna":"cemetery_coupler"}.get(id,id)
			var source = game.town.actions[source_id].area
			for child in source.get_children(): copy_meshes(child,model)
		else:
			var path = "res://assets/flashlight/flashlight.glb"
			if id.begins_with("gun"): path="res://assets/weapons/"+["pistol","rifle","shotgun"][int(id.right(1))]+".glb"
			if id.begins_with("ammo"): path="res://assets/ammo/"+["pistol","rifle","shotgun"][int(id.right(1))]+".glb"
			var source = load(path).instantiate()
			copy_meshes(source,model)
			source.free()
		var bounds = AABB()
		var first = true
		for child in model.get_children():
			var part: AABB = child.transform*child.mesh.get_aabb()
			bounds=part if first else bounds.merge(part)
			first=false
		var center = bounds.get_center()
		var factor = 1.0/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
		for child in model.get_children():
			child.position=(child.position-center)*factor
			child.scale*=factor
		if id=="coil": model.rotation.y=0.65
		# Face the key's broad side toward the inventory camera, not its thin edge.
		if id.ends_with("_key"):
			if bounds.size.y<=bounds.size.x and bounds.size.y<=bounds.size.z: model.rotation.x=PI/2
			elif bounds.size.x<=bounds.size.z: model.rotation.y=PI/2
		if id.begins_with("gun") and bounds.size.z>bounds.size.x: model.rotation.y=PI/2
		if id=="flashlight" and bounds.size.z>bounds.size.y: model.rotation.x=PI/2
		var world = WorldEnvironment.new()
		var env = Environment.new()
		env.background_mode=Environment.BG_CLEAR_COLOR
		env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color=Color.WHITE
		env.ambient_light_energy=0.8
		world.environment=env
		viewport.add_child(world)
		var light = DirectionalLight3D.new()
		light.rotation_degrees=Vector3(-35,-25,0)
		light.light_energy=1.5
		viewport.add_child(light)
		var camera = Camera3D.new()
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL
		camera.size=1.1 if id=="shovel" else 1.4
		camera.position=Vector3(0,0.65,3)
		viewport.add_child(camera)
		camera.look_at(Vector3.ZERO)
		icons[id]=viewport.get_texture()

func draw_icon(id: String, box: Rect2):
	if not icons.has(id): return
	var texture: Texture2D = icons[id]
	var available = box.size-Vector2(8,8)
	var dimensions = texture.get_size()
	var scale_factor = minf(available.x/dimensions.x,available.y/dimensions.y)
	var drawn_size = dimensions*scale_factor
	draw_texture_rect(texture,Rect2(box.get_center()-drawn_size/2,drawn_size),false)

func handle(event):
	var entries = pack(counts())
	remember(entries)
	if event is InputEventMouseMotion and dragging!="":
		drag_mouse=event.position
		return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and dragging!="":
		drag_mouse=event.position
		for entry in entries:
			if entry.key!=dragging: continue
			var target=drop_cell()
			if fits(target,entry.size,entries,dragging):
				saved_cells[entry.key]=target
				notice="Item moved."
			else: notice="That space is blocked. Item returned to its original slot."
		dragging=""
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_I,KEY_ESCAPE: game.set_state("play")
			KEY_J: game.journal_page=0; game.journal_casefile=false; game.set_state("journal")
			KEY_M: game.journal_page=1; game.journal_casefile=false; game.set_state("journal")
			KEY_LEFT,KEY_UP: selected=wrapi(selected-1,0,maxi(1,entries.size())); discard_pending=""
			KEY_RIGHT,KEY_DOWN: selected=wrapi(selected+1,0,maxi(1,entries.size())); discard_pending=""
			KEY_ENTER: act("use")
			KEY_X: act("examine")
			KEY_C: act("combine")
			KEY_DELETE: act("discard")
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position
		for i in range(3):
			if Rect2(38+i*187,48,176,25).has_point(p):
				if i>0:
					game.journal_page=0 if i==1 else 1
					game.journal_casefile=false
					game.set_state("journal")
				return
		for i in range(entries.size()):
			if rect(entries[i]).has_point(p):
				selected=i
				discard_pending=""
				dragging=entries[i].key
				drag_offset=p-(ORIGIN+Vector2(entries[i].cell)*CELL)
				drag_mouse=p
				notice="Drag to a free space. Release to place."
				return
		for i in range(4):
			if Rect2(330+(i%2)*139,207+(i/2)*31,130,25).has_point(p): act(["use","examine","combine","discard"][i])

func act(action: String):
	var entries = pack(counts())
	if entries.is_empty(): return
	selected = clampi(selected,0,entries.size()-1)
	var item: Dictionary = entries[selected]
	var id: String = item.id
	if action=="discard":
		if id in OBJECTIVES: notice="Required objective item. Use it at its matching door, panel or receiver."; return
		if id=="flashlight": notice="Keep your flashlight. It cannot be discarded."; return
		if discard_pending!=id: discard_pending=id; notice="Discard this stack permanently? Press DISCARD again to confirm."; return
		if id.begins_with("gun"):
			notice="Weapons stay with you. Free space by using or discarding supplies."
		elif id.begins_with("ammo"): game.weapons.reserves[int(id.right(1))]-=item.amount; notice="Ammo stack discarded."
		else: game.town.inventory[id]-=item.amount; notice="Supply discarded."
		discard_pending=""
		return
	discard_pending=""
	if id in OBJECTIVES:
		notice=OBJECTIVE_DETAILS[id]
		return
	if action=="examine": notice=label(id)+" / "+("Keep ammunition for this weapon." if id.begins_with("gun") else "Select USE for supplies, COMBINE to load ammunition."); return
	if action=="combine":
		if id.begins_with("ammo") or id.begins_with("gun"):
			var index = int(id.right(1))
			if not game.weapons.owned[index]: notice="Find the matching weapon first."; return
			var added = mini(game.weapons.LOADOUT[index].clip-game.weapons.magazines[index],game.weapons.reserves[index])
			game.weapons.magazines[index]+=added
			game.weapons.reserves[index]-=added
			game.weapons.reload_remaining=0
			notice="Loaded %d rounds." % added if added>0 else "Magazine full or no matching ammunition."
		else: notice="No matching combination. Supplies can be used directly."
		return
	if id.begins_with("gun") or id=="flashlight":
		game.state="play"
		game.weapons.equip(-1 if id=="flashlight" else int(id.right(1)))
		game.set_state("backpack")
		notice=label(id)+" equipped."
	elif id=="medkit": game.town.use_medkit(); notice=game.message
	elif id=="battery": game.town.use_battery(); notice=game.message
	else: notice="Select COMBINE to load this ammunition."

func controller_move(direction: Vector2i):
	var entries=pack(counts())
	if entries.is_empty():return
	selected=clampi(selected,0,entries.size()-1)
	if dragging!="":
		var item=entries[selected]
		var target=drop_cell()+direction
		target.x=clampi(target.x,0,6-item.size.x)
		target.y=clampi(target.y,0,4-item.size.y)
		drag_mouse=ORIGIN+Vector2(target)*CELL
	else:
		selected=wrapi(selected+(-1 if direction.x<0 or direction.y<0 else 1),0,entries.size())
	discard_pending=""

func controller_button(id:int):
	if id in [JOY_BUTTON_B,JOY_BUTTON_BACK,JOY_BUTTON_START]:
		if dragging!="":dragging="";notice="Move cancelled."
		else:game.set_state("play")
		return
	var d=game.controller.direction(id)
	if d!=Vector2i.ZERO:controller_move(d);return
	var entries=pack(counts())
	if entries.is_empty():return
	selected=clampi(selected,0,entries.size()-1)
	if id==JOY_BUTTON_X:
		var item=entries[selected]
		if dragging=="":
			remember(entries)
			dragging=item.key
			drag_offset=Vector2.ZERO
			drag_mouse=ORIGIN+Vector2(item.cell)*CELL
			notice="D-pad / left stick to move. Press "+game.controller.label("west")+" to place."
		elif fits(drop_cell(),item.size,entries,dragging):
			saved_cells[dragging]=drop_cell()
			dragging=""
			notice="Item moved."
		else:notice="That space is blocked. Choose a free space."
	elif dragging=="":
		if id==JOY_BUTTON_A:act("use")
		elif id==JOY_BUTTON_Y:act("examine")
		elif id==JOY_BUTTON_LEFT_SHOULDER:act("combine")
		elif id==JOY_BUTTON_RIGHT_SHOULDER:act("discard")
