extends Node3D
## Uses the user's downloaded hatchback; all set dressing remains simple PS2 geometry.
var game
var wreck: Node3D
var steam: Array[MeshInstance3D] = []
var headlight_beams:Array[SpotLight3D]=[]
var headlight_lens:MeshInstance3D
var headlight_material:StandardMaterial3D
var tail_material:StandardMaterial3D
var tail_lens:MeshInstance3D
var tail_glows:Array[OmniLight3D]=[]
const HEADLIGHT_PERIOD=1.25
var elapsed = 0.0
var has_backpack = false
var has_flashlight = false
var has_detour_sheet = false
var detour_visual: Node3D
var wake_phase = ""
var wake_elapsed = 0.0
var wake_menu_texture: Texture2D
const MENU_FADE_SECONDS = 0.85
const WAKE_EYE = 0.23
const WAKE_PITCH = 1.28
const STAND_SECONDS = 1.25
var door_open = false
var door: Node3D
var door_closed = Vector3.ZERO
var bag_visual: Node3D
var light_visual: Node3D
var door_tween: Tween
var tutorial_areas: Dictionary = {}
const WRECK_POSITION = Vector3(3.8,0.01,13)

func _ready():
	name = "OldMillRoadCrash"
	wreck = StaticBody3D.new()
	wreck.name = "CrashedHatchback"
	wreck.position = WRECK_POSITION
	wreck.rotation = Vector3(0,-0.6,-0.025)
	add_child(wreck)
	var model = preload("res://assets/vehicles/crashed_hatchback_openable.glb").instantiate()
	wreck.add_child(model)
	adapt(model)
	door = model.find_child("DriverDoor",true,false)
	door_closed = door.rotation
	build_car_interior()
	build_tutorial_items()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.85,1.35,3.6)
	collision.shape = shape
	collision.position.y = 0.72
	wreck.add_child(collision)
	build_blinking_headlights(model)
	game.town.action_area(wreck,Vector3(0,1.1,-1.5),Vector3(1.0,0.4,0.3),"crash_wreck",{"kind":"crash","label":"Inspect wrecked car"})
	# The car has run off the lane into a broken roadside stump.
	var stump = game.mesh_at(self,game.cylinder(0.42,0.3,0.9),wreck.to_global(Vector3(0,0.45,-2.05)),game.town.mats.wood)
	stump.rotation.z = 0.15
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
	update_waking(delta)
	if door_tween and door_tween.is_valid():
		if game.state=="play" and not door_tween.is_running() and not is_equal_approx(door.rotation.y,door_closed.y-1.15 if door_open else door_closed.y): door_tween.play()
		elif game.state!="play": door_tween.pause()
	update_door_target()
	if game.state!="play":
		return
	elapsed += delta
	update_headlights()
	for i in range(steam.size()):
		var phase = fmod(elapsed*0.28+i*0.25,1)
		steam[i].position = Vector3(sin(phase*4+i)*0.10,0.85+phase*0.8,-1.35)
		steam[i].scale = Vector3.ONE*(0.45+sin(phase*PI)*0.7)

func build_tutorial_items():
	var town = game.town
	bag_visual = Node3D.new()
	bag_visual.name = "BackpackOnSeat"
	wreck.add_child(bag_visual)
	bag_visual.position = Vector3(-0.47,0.79,0.1)
	var canvas = game.mat(Color("666d4e"))
	town.box(bag_visual,Vector3.ZERO,Vector3(0.38,0.43,0.22),canvas,false)
	town.box(bag_visual,Vector3(-0.02,-0.08,0.14),Vector3(0.29,0.18,0.09),canvas,false)
	for x in [-0.13,0.13]:
		town.box(bag_visual,Vector3(x,0,0.19),Vector3(0.045,0.37,0.04),town.mats.dark,false)
		town.box(bag_visual,Vector3(x,-0.1,0.215),Vector3(0.065,0.065,0.025),town.mats.metal,false)
	town.box(bag_visual,Vector3(0,0.24,0),Vector3(0.18,0.04,0.08),town.mats.dark,false)
	light_visual = preload("res://assets/flashlight/flashlight.glb").instantiate()
	wreck.add_child(light_visual)
	game.prepare_flashlight(light_visual)
	light_visual.position = Vector3(-0.65,0.82,-0.34)
	light_visual.scale = Vector3.ONE*0.65
	light_visual.rotation.z = PI/2
	# Seat the lowest point of the rotated flashlight on the cushion.
	var lowest = INF
	for part in light_visual.find_children("*","MeshInstance3D",true,false):
		var local_bounds: AABB = (wreck.global_transform.affine_inverse()*part.global_transform)*part.mesh.get_aabb()
		lowest = minf(lowest,local_bounds.position.y)
	if lowest<INF: light_visual.position.y += 0.575-lowest
	# The full-body car collider remains solid; interaction targets sit at the open window.
	for entry in [
		["crash_driver_door",Vector3(-1.04,1,0.15),Vector3(0.18,0.65,1.35),"Open driver's door"],
		["crash_backpack",Vector3(-1.04,0.95,0.1),Vector3(0.18,0.5,0.65),"Take backpack from car"],
		["crash_flashlight",Vector3(-1.04,0.95,-0.28),Vector3(0.18,0.45,0.42),"Take flashlight from car"]]:
		tutorial_areas[entry[0]] = town.action_area(wreck,entry[1],entry[2],entry[0],{"kind":"crash_tutorial","label":entry[3]})
	reset()

func reset():
	elapsed=0
	update_headlights()
	wake_phase = ""
	wake_elapsed = 0.0
	wake_menu_texture=null
	has_backpack = false
	has_flashlight = false
	has_detour_sheet = false
	if detour_visual: detour_visual.show()
	door_open = false
	if door_tween: door_tween.kill()
	door.rotation = door_closed
	bag_visual.show()
	light_visual.show()
	for id in tutorial_areas:
		tutorial_areas[id].collision_layer = 2 if id=="crash_driver_door" else 0
	game.town.actions.crash_driver_door.label="Open driver's door"
	update_door_target()

func start_opening():
	# Retain the last rendered menu, including buttons, during the fade.
	if DisplayServer.get_name()!="headless":
		wake_menu_texture=ImageTexture.create_from_image(get_viewport().get_texture().get_image())
	wake_phase="menu_fade"
	wake_elapsed=0.0
	game.player.velocity=Vector3.ZERO
	game.pitch=WAKE_PITCH
	game.camera.position.y=WAKE_EYE
	game.camera.rotation=Vector3(WAKE_PITCH,0,0.08)
	game.set_state("waking")

func show_wake_dialogue():
	wake_phase="dialogue"
	game.dialogue_name = ""
	game.dialogue_text = "My head... I must have blacked out. Something crossed the road. I swerved, and the car hit that stump.\n\nThe engine's dead. No phone signal. My backpack and flashlight are still in the car. I need to get up and collect them before I look for help."
	game.set_state("dialogue")

func stand_up():
	if wake_phase!="ground": return
	wake_phase="standing"
	wake_elapsed=0.0
	game.jump_queued=false

func update_waking(delta: float):
	if game.state!="waking": return
	wake_elapsed+=minf(delta,0.1)
	game.player.velocity=Vector3.ZERO
	game.jump_queued=false
	if wake_phase=="menu_fade" and wake_elapsed>=MENU_FADE_SECONDS:
		wake_phase="blinking"
		wake_elapsed=0.0
		wake_menu_texture=null
		game.update_camera()
	elif wake_phase=="blinking" and wake_elapsed>=3.0:
		show_wake_dialogue()
	elif wake_phase=="standing":
		var t=smoothstep(0.0,1.0,clampf(wake_elapsed/STAND_SECONDS,0,1))
		game.camera.position.y=lerpf(WAKE_EYE,game.STANDING_EYE,t)
		game.pitch=lerpf(WAKE_PITCH,0,t)
		game.camera.rotation=Vector3(game.pitch,0,0.08*(1-t))
		if t>=1:
			wake_phase=""
			game.set_state("play")
			game.message="Find the driver's door. Press E to open it and collect your things."
	game.hud.queue_redraw()

func eye_opening() -> float:
	if wake_phase=="menu_fade": return 0.0
	if wake_phase!="blinking": return 1.0
	var times=[0.0,0.35,0.85,1.05,1.65,1.90,2.60,3.0]
	var openings=[0.0,0.0,0.75,0.0,0.95,0.10,1.0,1.0]
	for i in range(times.size()-1):
		if wake_elapsed<=times[i+1]:
			return lerpf(openings[i],openings[i+1],smoothstep(times[i],times[i+1],wake_elapsed))
	return 1.0

func tutorial_complete() -> bool:
	return has_backpack and has_flashlight and has_detour_sheet

func tutorial_prompt() -> String:
	if not door_open: return "WASD / MOVE   MOUSE / LOOK   E / OPEN THE DRIVER'S DOOR"
	if not has_backpack: return "E / TAKE YOUR BACKPACK FROM THE OPEN CAR"
	if not has_flashlight: return "E / TAKE YOUR FLASHLIGHT FROM THE CAR"
	if not has_detour_sheet: return "E / TAKE THE DETOUR SHEET FROM THE SEAT"
	return ""

func interact_tutorial(id: String):
	if wake_phase!="": return
	if id=="crash_driver_door":
		door_open = not door_open
		if door_tween: door_tween.kill()
		door_tween = create_tween()
		door_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		door_tween.tween_property(door,"rotation:y",door_closed.y-1.15 if door_open else door_closed.y,0.65)
		game.soundscape.storage_move(wreck.global_position,false,door_open)
		game.town.actions.crash_driver_door.label="Close driver's door" if door_open else "Open driver's door"
		update_item_targets()
		update_door_target()
		game.message = "The door opens. Look at your belongings and press E." if door_open and not tutorial_complete() else ("Driver's door opened." if door_open else "Driver's door closed.")
	elif id=="crash_backpack" and door_open and not has_backpack:
		has_backpack = true
		bag_visual.hide()
		tutorial_areas.crash_backpack.collision_layer = 0
		tutorial_areas.crash_flashlight.collision_layer = 2
		game.soundscape.feedback("pickup")
		game.message = "Backpack collected. Now take the flashlight beside it."
	elif id=="crash_flashlight" and door_open and has_backpack and not has_flashlight:
		has_flashlight = true
		light_visual.hide()
		tutorial_areas.crash_flashlight.collision_layer = 0
		game.soundscape.feedback("pickup")
		tutorial_areas.crash_record.collision_layer = 2
		game.message = "Flashlight collected. F switches it on. Take the detour sheet from the seat before you leave."
	elif id=="crash_record" and door_open and has_flashlight and not has_detour_sheet:
		has_detour_sheet = true
		detour_visual.hide()
		tutorial_areas.crash_record.collision_layer = 0
		game.town.actions.crash_record.taken = true
		game.soundscape.feedback("pickup")
		game.message = "Detour sheet collected in your journal. TAB closes it. Follow the road to find help."
		game.story.collect_detour_sheet()

func update_door_target():
	if not tutorial_areas.has("crash_driver_door"): return
	var target=tutorial_areas.crash_driver_door
	if door_open:
		target.global_position=door.to_global(Vector3(0.09,0.12,0.28))
		target.get_child(0).shape.size=Vector3(0.32,0.4,0.4)
	else:
		target.position=Vector3(-1.04,1,0.15)
		target.get_child(0).shape.size=Vector3(0.18,0.65,1.35)
	target.collision_layer=0 if door_open and absf(door.rotation.y-(door_closed.y-1.15))>0.15 else 2

func update_item_targets():
	for id in ["crash_backpack","crash_flashlight","crash_record"]:
		if not tutorial_areas.has(id): continue
		var available=not has_backpack if id=="crash_backpack" else (has_backpack and not has_flashlight if id=="crash_flashlight" else has_flashlight and not has_detour_sheet)
		tutorial_areas[id].collision_layer=2 if door_open and available else 0

func build_car_interior():
	var cabin = Node3D.new()
	cabin.name = "LowPolyCabin"
	wreck.add_child(cabin)
	var town = game.town
	var fabric = town.mats.fabric.duplicate()
	fabric.albedo_color = Color("53594f")
	var carpet = game.mat(Color("292d29"))
	var plastic = game.mat(Color("3b403a"))
	var pale = game.mat(Color("8a8b73"))
	# Visual-only cabin geometry stays inside the car's existing collision shell.
	town.box(cabin,Vector3(0,0.30,0.1),Vector3(1.55,0.06,2.6),carpet,false)
	for x in [-0.43,0.43]:
		town.box(cabin,Vector3(x,0.405,-0.1),Vector3(0.55,0.13,0.78),plastic,false)
		town.box(cabin,Vector3(x,0.50,-0.1),Vector3(0.64,0.14,0.95),fabric,false)
		var back = town.box(cabin,Vector3(x,0.79,0.43),Vector3(0.63,0.65,0.16),fabric,false)
		back.rotation.x = -0.12
		town.box(cabin,Vector3(x,1.19,0.48),Vector3(0.35,0.22,0.13),fabric,false)
		for seam in [-0.16,0,0.16]:
			town.box(cabin,Vector3(x+seam,0.574,-0.11),Vector3(0.012,0.009,0.76),plastic,false)
		var belt = town.box(cabin,Vector3(x+0.17,0.83,0.325),Vector3(0.045,0.57,0.02),carpet,false)
		belt.rotation.z = -0.22
		town.box(cabin,Vector3(x*0.44,0.62,0.27),Vector3(0.055,0.10,0.06),plastic,false)
	town.box(cabin,Vector3(0,0.50,1.10),Vector3(1.42,0.16,0.48),fabric,false)
	town.box(cabin,Vector3(0,0.79,1.34),Vector3(1.42,0.47,0.14),fabric,false)
	# Dashboard and instruments fit below the windshield; seats and gear keep their positions.
	# Dashboard, glovebox, center console, and a simple steering wheel.
	town.box(cabin,Vector3(0,0.70,-0.66),Vector3(1.28,0.16,0.22),plastic,false)
	town.box(cabin,Vector3(0.4,0.72,-0.535),Vector3(0.48,0.16,0.02),carpet,false)
	town.box(cabin,Vector3(0.4,0.76,-0.52),Vector3(0.13,0.02,0.015),pale,false)
	town.box(cabin,Vector3(-0.43,0.86,-0.67),Vector3(0.36,0.10,0.035),carpet,false)
	for x in [-0.51,-0.35]:
		town.box(cabin,Vector3(x,0.88,-0.645),Vector3(0.09,0.04,0.01),pale,false)
	town.box(cabin,Vector3(0,0.47,-0.22),Vector3(0.16,0.24,0.76),plastic,false)
	town.box(cabin,Vector3(0,0.67,-0.37),Vector3(0.04,0.22,0.04),carpet,false)
	town.box(cabin,Vector3(0,0.79,-0.37),Vector3(0.07,0.05,0.07),plastic,false)
	var wheel_mesh = TorusMesh.new()
	wheel_mesh.inner_radius = 0.12
	wheel_mesh.outer_radius = 0.16
	wheel_mesh.rings = 10
	wheel_mesh.ring_segments = 6
	var wheel = game.mesh_at(cabin,wheel_mesh,Vector3(-0.43,0.97,-0.60),carpet)
	wheel.rotation.x = PI/2-0.3
	town.box(cabin,Vector3(-0.43,0.97,-0.60),Vector3(0.26,0.035,0.035),plastic,false)
	# The door lining and handle move with the opened door.
	town.box(door,Vector3(0.04,-0.02,0.64),Vector3(0.035,0.40,1.10),plastic,false)
	town.box(door,Vector3(0.085,0.02,0.55),Vector3(0.08,0.06,0.35),carpet,false)
	town.box(door,Vector3(0.09,0.12,0.28),Vector3(0.04,0.035,0.16),pale,false)


func build_detour_sheet():
	detour_visual = Node3D.new()
	detour_visual.name = "DetourSheetOnSeat"
	wreck.add_child(detour_visual)
	detour_visual.position = Vector3(-0.43,0.585,-0.3)
	detour_visual.rotation.y = -0.14
	var shader = Shader.new()
	shader.code = "shader_type spatial; render_mode cull_disabled; uniform sampler2D paper_texture : source_color, filter_nearest_mipmap; void fragment(){ ALBEDO=mix(vec3(0.86,0.83,0.74),texture(paper_texture,UV).rgb,0.24); ROUGHNESS=1.0; }"
	var paper = ShaderMaterial.new()
	paper.shader = shader
	paper.set_shader_parameter("paper_texture",load("res://assets/interiors/detour_paper.jpg"))
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Two creased halves and a lifted corner give the sheet a paper-thin silhouette.
	var points = [Vector3(-0.145,0,-0.195),Vector3(0,0.006,-0.195),Vector3(0.145,0.013,-0.195),Vector3(-0.145,0,0.195),Vector3(0,0.006,0.195),Vector3(0.145,0,0.195)]
	for i in [0,3,1,1,3,4,1,4,2,2,4,5]:
		tool.set_normal(Vector3.UP)
		tool.set_uv(Vector2((points[i].x+0.145)/0.29,(points[i].z+0.195)/0.39))
		tool.add_vertex(points[i])
	var mesh = MeshInstance3D.new()
	mesh.mesh = tool.commit()
	mesh.material_override = paper
	detour_visual.add_child(mesh)
	var ink = game.mat(Color("343a35"))
	for row in [["DETOUR",-0.12,28],["BRIDGE CLOSED",-0.065,14],["VIA BLACKWOOD",0.11,16]]:
		var label = game.town.sign_text(detour_visual,row[0],Vector3(0,0.018,row[1]),row[2],Color("343a35"))
		label.rotation.x = -PI/2
		label.pixel_size = 0.001
		label.outline_size = 0
		label.shaded = true
	game.town.box(detour_visual,Vector3(0,0.019,-0.015),Vector3(0.18,0.001,0.005),ink,false)
	game.town.box(detour_visual,Vector3(0,0.019,0.045),Vector3(0.13,0.001,0.012),ink,false)
	for side in [-1,1]:
		var head = game.town.box(detour_visual,Vector3(-0.04,0.019,0.045+side*0.019),Vector3(0.06,0.001,0.01),ink,false)
		head.rotation.y = -side*0.7
	tutorial_areas.crash_record = game.town.action_area(wreck,Vector3(-1.04,0.95,-0.28),Vector3(0.18,0.45,0.50),"crash_record",{"kind":"crash_tutorial","label":"Pick up detour sheet"})
	tutorial_areas.crash_record.collision_layer = 0

func build_blinking_headlights(model:Node3D):
	# Copy only the original front lamp faces. The body and cabin stay untouched.
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rear_tool=SurfaceTool.new()
	rear_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rear_count=0
	var count=0
	for part in model.find_children("*","MeshInstance3D",true,false):
		var pose=wreck.global_transform.affine_inverse()*part.global_transform
		for surface in range(part.mesh.get_surface_count()):
			var original=part.mesh.surface_get_material(surface)
			if not original is StandardMaterial3D or not original.albedo_texture:continue
			var image=original.albedo_texture.get_image()
			var arrays=part.mesh.surface_get_arrays(surface)
			var vertices=arrays[Mesh.ARRAY_VERTEX]
			var uv=arrays[Mesh.ARRAY_TEX_UV]
			var indices=arrays[Mesh.ARRAY_INDEX]
			for i in range(0,indices.size(),3):
				var center=Vector3.ZERO
				var sample=Vector2.ZERO
				for j in range(3):
					center+=pose*vertices[indices[i+j]]/3
					sample+=uv[indices[i+j]]/3
				var color=image.get_pixel(clampi(int(sample.x*image.get_width()),0,image.get_width()-1),clampi(int(sample.y*image.get_height()),0,image.get_height()-1))
				var front=center.z< -1.44 and center.y>0.57 and center.y<0.78 and absf(center.x)>0.28 and absf(center.x)<0.88 and color.r>0.85 and absf(color.r-color.g)<0.04 and absf(color.g-color.b)<0.04
				var rear=center.z>1.7 and center.y>0.70 and center.y<1.15 and absf(center.x)>0.45 and color.r>0.4 and color.r>color.g*1.7 and color.r>color.b*1.7
				if not front and not rear:continue
				var output=tool if front else rear_tool
				for j in range(3):output.add_vertex(pose*vertices[indices[i+j]]+Vector3(0,0,-0.004 if front else 0.004))
				if front:count+=1
				else:rear_count+=1
	assert(count>0,"Original headlight faces identified")
	tool.generate_normals()
	headlight_lens=MeshInstance3D.new()
	headlight_lens.name="BlinkingOriginalHeadlightLenses"
	headlight_lens.mesh=tool.commit()
	headlight_lens.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	headlight_material=StandardMaterial3D.new()
	headlight_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	headlight_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	headlight_material.emission_enabled=true
	headlight_material.emission=Color("ffc238")
	headlight_lens.material_override=headlight_material
	wreck.add_child(headlight_lens)
	assert(rear_count>0,"Original rear lamp faces identified")
	rear_tool.generate_normals()
	tail_lens=MeshInstance3D.new()
	tail_lens.name="BlinkingOriginalTailLenses"
	tail_lens.mesh=rear_tool.commit()
	tail_lens.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tail_material=headlight_material.duplicate()
	tail_material.emission=Color("f33422")
	tail_lens.material_override=tail_material
	wreck.add_child(tail_lens)
	for side in [-1,1]:
		var light=SpotLight3D.new()
		light.name="BlinkingYellowHeadlight"+str(side)
		light.position=Vector3(side*0.60,0.65,-1.78)
		light.rotation.x=-0.12
		light.light_color=Color("ffcb46")
		light.light_energy=1.0
		light.spot_range=10
		light.spot_angle=32
		wreck.add_child(light)
		headlight_beams.append(light)
		var glow=OmniLight3D.new()
		glow.name="BlinkingRedTailLight"+str(side)
		glow.position=Vector3(side*0.65,0.9,1.96)
		glow.light_color=Color("f33422")
		glow.light_energy=0.4
		glow.omni_range=2.8
		wreck.add_child(glow)
		tail_glows.append(glow)
	update_headlights()

func update_headlights():
	if not headlight_material:return
	var lit=fmod(elapsed,HEADLIGHT_PERIOD)<0.52
	headlight_material.albedo_color=Color("ffcb46") if lit else Color("655d44")
	headlight_material.emission_energy_multiplier=1.0 if lit else 0.0
	for light in headlight_beams:light.visible=lit
	if tail_material:
		tail_material.albedo_color=Color("f33422") if lit else Color("552d26")
		tail_material.emission_energy_multiplier=1.0 if lit else 0.0
	for glow in tail_glows:glow.visible=lit
