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
const HATCH_OPEN_ANGLE=0.75
var elapsed = 0.0
var has_backpack = false
var has_flashlight = false
var has_detour_sheet = false
var detour_visual: Node3D
var wake_phase = ""
var wake_elapsed = 0.0
var wake_menu_texture: Texture2D
const MENU_FADE_SECONDS = 0.85
const DRIVER_EYE = Vector3(-0.43,1.17,0.12)
const EXIT_POSITION = Vector3(-1.70,0.01,0.6)
const STARTER_SECONDS = 1.70
const EXIT_SECONDS = 1.45
var ignition_attempts = 0
var seat_yaw = 0.0
var seat_pitch = -0.15
var exit_from = Transform3D.IDENTITY
var starter_voice: AudioStreamPlayer
var dashboard_light: OmniLight3D
var steering_wheel: MeshInstance3D
var body_materials: Array = []
var door_open = false
var door: Node3D
var door_closed = Vector3.ZERO
var bag_visual: Node3D
var backpack_model:Node3D
var light_visual: Node3D
var hatch:Node3D
var hatch_struts:Array[MeshInstance3D]=[]
var rear_quarter_windows:MeshInstance3D
var rear_quarter_mount=Transform3D.IDENTITY
var hatch_open=false
var hatch_closed=Vector3.ZERO
var hatch_tween:Tween
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
	var model = preload("res://assets/vehicles/crashed_hatchback_rear_hatch.glb").instantiate()
	wreck.add_child(model)
	# Reuse the original door, including its authored hinge and local geometry.
	# The hatch conversion baked that pivot into the mesh at the car origin.
	var broken_door=model.find_child("DriverDoor",true,false)
	broken_door.get_parent().remove_child(broken_door)
	broken_door.queue_free()
	var original_car=preload("res://assets/vehicles/crashed_hatchback_openable.glb").instantiate()
	door=original_car.find_child("DriverDoor",true,false).duplicate()
	original_car.free()
	model.add_child(door)
	repair_driver_window(model)
	prepare_cabin_windows(model)
	adapt(model)
	door_closed = door.rotation
	hatch=model.find_child("RearHatch",true,false)
	hatch_closed=hatch.rotation
	repair_rear_quarter_windows()
	build_car_interior()
	build_trunk()
	starter_voice=game.soundscape.voice(game.soundscape.stream("engine_starter"),-13)
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

func repair_driver_window(model:Node3D):
	# The same planar cut also put part of the windshield and its painted
	# support on the swinging door. Restore those pieces to the fixed shell.
	var door_mesh=ArrayMesh.new();var pillars=ArrayMesh.new()
	for surface in range(door.mesh.get_surface_count()):
		var material=door.get_active_material(surface)
		var arrays=door.mesh.surface_get_arrays(surface)
		var vertices=arrays[Mesh.ARRAY_VERTEX];var uvs=arrays[Mesh.ARRAY_TEX_UV];var indices=arrays[Mesh.ARRAY_INDEX]
		var fixed=PackedInt32Array();var moving=PackedInt32Array()
		for i in range(0,indices.size(),3):
			var uv=Vector2.ZERO;var center=Vector3.ZERO
			for k in range(3):
				uv+=uvs[indices[i+k]]/3.0
				center+=door.transform*vertices[indices[i+k]]/3.0
			var windshield=uv.distance_to(Vector2(0.161,0.543))<0.006
			var windshield_seal=uv.distance_to(Vector2(0.06756,0.03294))<0.006
			var painted_pillar=uv.distance_to(Vector2(0.855525,0.319231))<0.006 and center.y>1.0
			for k in range(3):
				if windshield or windshield_seal or painted_pillar:fixed.append(indices[i+k])
				else:moving.append(indices[i+k])
		for selection in [fixed,moving]:
			if selection.is_empty():continue
			var parts=arrays.duplicate();parts[Mesh.ARRAY_INDEX]=selection
			var target=pillars if selection==fixed else door_mesh
			target.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,parts)
			target.surface_set_material(target.get_surface_count()-1,material)
	door.mesh=door_mesh
	if pillars.get_surface_count()>0:
		var fixed_shell=MeshInstance3D.new();fixed_shell.name="RestoredWindshieldPillars";fixed_shell.mesh=pillars
		model.add_child(fixed_shell);fixed_shell.transform=door.transform
	# The source door was cut at x=-0.6, through the sloping window. Its
	# upper glass and seals remained on the body and must share the hinge.
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		if mesh==door or mesh.name!="Hatchback Car_15":continue
		var body=ArrayMesh.new();var upper=ArrayMesh.new()
		var to_car=wreck.global_transform.affine_inverse()*mesh.global_transform
		for surface in range(mesh.mesh.get_surface_count()):
			var material=mesh.get_active_material(surface)
			var arrays=mesh.mesh.surface_get_arrays(surface)
			var vertices=arrays[Mesh.ARRAY_VERTEX];var uvs=arrays[Mesh.ARRAY_TEX_UV];var indices=arrays[Mesh.ARRAY_INDEX]
			var image=material.albedo_texture.get_image()
			if image.is_compressed():image.decompress()
			var fixed=PackedInt32Array();var moving=PackedInt32Array()
			for i in range(0,indices.size(),3):
				var in_window=true;var uv=Vector2.ZERO
				for k in range(3):
					var p=to_car*vertices[indices[i+k]];uv+=uvs[indices[i+k]]/3.0
					var above_cut=p.y>1.28 or (p.z>=0.499 and p.y>1.0)
					in_window=in_window and p.x < -0.50 and above_cut and p.z> -0.18 and p.z<0.531
				var color=image.get_pixel(clampi(int(uv.x*image.get_width()),0,image.get_width()-1),clampi(int(uv.y*image.get_height()),0,image.get_height()-1))
				var glass=color.r>0.17 and color.r<0.43 and color.g-color.r>0.02 and color.b-color.r>0.035
				var seal=maxf(color.r,maxf(color.g,color.b))<0.22
				for k in range(3):
					if in_window and (glass or seal):moving.append(indices[i+k])
					else:fixed.append(indices[i+k])
			for selection in [fixed,moving]:
				if selection.is_empty():continue
				var parts=arrays.duplicate();parts[Mesh.ARRAY_INDEX]=selection
				var target=body if selection==fixed else upper
				target.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,parts)
				target.surface_set_material(target.get_surface_count()-1,material)
		mesh.mesh=body
		if upper.get_surface_count()>0:
			var window=MeshInstance3D.new();window.name="DriverDoorUpperWindow";window.mesh=upper
			mesh.add_child(window);window.reparent(door,true)

func prepare_cabin_windows(model:Node3D):
	var images={}
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		var rebuilt=ArrayMesh.new()
		var transform=wreck.global_transform.affine_inverse()*mesh.global_transform
		for surface in range(mesh.mesh.get_surface_count()):
			var material=mesh.get_active_material(surface)
			var arrays=mesh.mesh.surface_get_arrays(surface)
			var indices=arrays[Mesh.ARRAY_INDEX]
			var vertices=arrays[Mesh.ARRAY_VERTEX]
			var uvs=arrays[Mesh.ARRAY_TEX_UV]
			var image:Image=null
			if material is StandardMaterial3D and material.albedo_texture:
				var key=material.albedo_texture.get_instance_id()
				if not images.has(key):
					var source=material.albedo_texture.get_image()
					if source.is_compressed():source.decompress()
					images[key]=source
				image=images[key]
			var opaque=PackedInt32Array();var glass=PackedInt32Array()
			for i in range(0,indices.size(),3):
				var point=Vector3.ZERO;var uv=Vector2.ZERO
				for k in range(3):point+=transform*vertices[indices[i+k]]/3.0;uv+=uvs[indices[i+k]]/3.0
				var color=image.get_pixel(clampi(int(uv.x*image.get_width()),0,image.get_width()-1),clampi(int(uv.y*image.get_height()),0,image.get_height()-1)) if image else Color.WHITE
				# Only the source's blue-grey glass palette above the belt line;
				# painted frames, rubber seals, mirrors and lamps stay opaque.
				var is_glass=point.y>0.88 and color.r>0.17 and color.r<0.43 and color.g-color.r>0.02 and color.b-color.r>0.035
				for k in range(3):
					if is_glass:glass.append(indices[i+k])
					else:opaque.append(indices[i+k])
			for transparent in [false,true]:
				var selected=glass if transparent else opaque
				if selected.is_empty():continue
				var parts=arrays.duplicate();parts[Mesh.ARRAY_INDEX]=selected
				rebuilt.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,parts)
				var assigned=material
				if transparent:
					assigned=material.duplicate();assigned.resource_name="CabinWindowGlass"
					assigned.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
					assigned.albedo_color.a=0.12;assigned.roughness=0.5
					rebuilt.set_meta("has_cabin_glass",true)
				rebuilt.surface_set_material(rebuilt.get_surface_count()-1,assigned)
		mesh.mesh=rebuilt

func adapt(node: Node):
	if node is MeshInstance3D:
		for i in range(node.mesh.get_surface_count()):
			var original = node.mesh.surface_get_material(i)
			if original is StandardMaterial3D:
				var material = original.duplicate() as StandardMaterial3D
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
				material.roughness = 1
				material.albedo_color = Color(0.72,0.70,0.62,material.albedo_color.a)
				material.metallic_specular = 0
				node.set_surface_override_material(i,material)
				body_materials.append({"material":material,"cull":material.cull_mode})
	for child in node.get_children():
		adapt(child)

func _process(delta):
	update_backpack_model()
	if rear_quarter_windows:rear_quarter_windows.global_transform=wreck.global_transform*rear_quarter_mount
	update_hatch_struts()
	update_waking(delta)
	if door_tween and door_tween.is_valid():
		if game.state=="play" and not door_tween.is_running() and not is_equal_approx(door.rotation.y,door_closed.y-1.15 if door_open else door_closed.y): door_tween.play()
		elif game.state!="play": door_tween.pause()
	update_door_target()
	update_hatch_target()
	if hatch_tween and hatch_tween.is_valid():
		if game.state=="play" and not hatch_tween.is_running() and not is_equal_approx(hatch.rotation.x,hatch_closed.x-HATCH_OPEN_ANGLE if hatch_open else hatch_closed.x):hatch_tween.play()
		elif game.state!="play":hatch_tween.pause()
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
	bag_visual.name = "BackpackInTrunk"
	wreck.add_child(bag_visual)
	bag_visual.position = Vector3(-0.35,0.80,1.65)
	var canvas = game.mat(Color("666d4e"))
	town.box(bag_visual,Vector3.ZERO,Vector3(0.38,0.43,0.22),canvas,false)
	town.box(bag_visual,Vector3(-0.02,-0.08,0.14),Vector3(0.29,0.18,0.09),canvas,false)
	for x in [-0.13,0.13]:
		town.box(bag_visual,Vector3(x,0,0.19),Vector3(0.045,0.37,0.04),town.mats.dark,false)
		town.box(bag_visual,Vector3(x,-0.1,0.215),Vector3(0.065,0.065,0.025),town.mats.metal,false)
	town.box(bag_visual,Vector3(0,0.24,0),Vector3(0.18,0.04,0.08),town.mats.dark,false)
	# Keep the original container's saved tree stable; the new visual follows it.
	backpack_model=preload("res://assets/backpack_teal/backpack.glb").instantiate()
	backpack_model.name="TealBackpackInTrunk"
	game.add_child(backpack_model)
	for mesh in backpack_model.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var material=mesh.mesh.surface_get_material(i).duplicate() as StandardMaterial3D
			if material:
				material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				material.shading_mode=BaseMaterial3D.SHADING_MODE_PER_VERTEX
				material.roughness=1.0;material.metallic=0.0;material.metallic_specular=0.0
				mesh.set_surface_override_material(i,material)
	update_backpack_model()
	light_visual = preload("res://assets/flashlight/flashlight.glb").instantiate()
	wreck.add_child(light_visual)
	game.prepare_flashlight(light_visual)
	light_visual.position = Vector3(0.02,0.82,1.72)
	light_visual.scale = Vector3.ONE*0.65
	light_visual.rotation.z = PI/2
	# Seat the lowest point of the rotated flashlight on the cushion.
	var lowest = INF
	for part in light_visual.find_children("*","MeshInstance3D",true,false):
		var local_bounds: AABB = (wreck.global_transform.affine_inverse()*part.global_transform)*part.mesh.get_aabb()
		lowest = minf(lowest,local_bounds.position.y)
	if lowest<INF: light_visual.position.y += 0.588-lowest
	# The doorway has its own target; pickups are fitted to their visible models.
	for entry in [
		["crash_driver_door",Vector3(-1.04,1,0.15),Vector3(0.18,0.65,1.35),"Open driver's door"],
		["crash_backpack",Vector3(-1.04,0.95,0.1),Vector3(0.18,0.5,0.65),"Take backpack from trunk"],
		["crash_flashlight",Vector3(-1.04,0.95,-0.28),Vector3(0.18,0.45,0.42),"Take flashlight from trunk"]]:
		tutorial_areas[entry[0]] = town.action_area(wreck,entry[1],entry[2],entry[0],{"kind":"crash_tutorial","label":entry[3]})
	fit_pickup_targets()
	reset()

func reset():
	if game.camera.top_level: release_seated_camera()
	ignition_attempts=0;seat_yaw=0;seat_pitch=-0.15
	if starter_voice: starter_voice.stop()
	if dashboard_light: dashboard_light.hide()
	if steering_wheel: steering_wheel.rotation.z=0
	elapsed=0
	update_headlights()
	wake_phase = ""
	wake_elapsed = 0.0
	wake_menu_texture=null
	has_backpack = false
	has_flashlight = false
	has_detour_sheet = false
	retire_detour_sheet()
	door_open = false
	hatch_open=false
	if hatch_tween:hatch_tween.kill()
	hatch.rotation=hatch_closed
	if tutorial_areas.has("crash_rear_hatch"):
		tutorial_areas.crash_rear_hatch.collision_layer=2
		game.town.actions.crash_rear_hatch.label="Open rear hatch"
		update_hatch_target()
	if door_tween: door_tween.kill()
	door.rotation = door_closed
	bag_visual.show()
	light_visual.show()
	for id in tutorial_areas:
		tutorial_areas[id].collision_layer = 2 if id in ["crash_driver_door","crash_rear_hatch"] else 0
	game.town.actions.crash_driver_door.label="Open driver's door"
	update_door_target()

func start_opening():
	if DisplayServer.get_name()!="headless":
		wake_menu_texture=ImageTexture.create_from_image(get_viewport().get_texture().get_image())
	wake_phase="menu_fade";wake_elapsed=0;ignition_attempts=0
	seat_yaw=0;seat_pitch=-0.55
	game.player.velocity=Vector3.ZERO
	game.camera.top_level=true
	set_cabin_view(true)
	update_seated_camera()
	dashboard_light.show()
	game.set_state("waking")

func update_seated_camera():
	var tilt=0.07*(1.0-clampf(wake_elapsed/3.0,0,1)) if wake_phase=="blinking" else 0.0
	game.camera.global_transform=wreck.global_transform*Transform3D(Basis.from_euler(Vector3(seat_pitch,seat_yaw,tilt)),DRIVER_EYE)
	game.pitch=seat_pitch

func look_inside(relative:Vector2):
	if wake_phase not in ["ignition_ready","ignition_retry","door_ready"]:return
	seat_yaw=clampf(seat_yaw-relative.x*0.0026,-1.0,1.65)
	seat_pitch=clampf(seat_pitch-relative.y*0.0026,-0.65,0.40)
	update_seated_camera()

func waking_prompt()->String:
	match wake_phase:
		"ignition_ready":return "E TO TRY TO START THE CAR"
		"ignition_retry":return "It didn't start.
E TO TRY THE IGNITION AGAIN"
		"cranking":return "Trying the ignition..."
		"door_ready":return "E TO OPEN THE DRIVER'S DOOR AND GET OUT"
	return ""

func interact_waking():
	if wake_phase in ["ignition_ready","ignition_retry"]:
		ignition_attempts+=1
		wake_phase="cranking";wake_elapsed=0
		starter_voice.pitch_scale=1.0 if ignition_attempts==1 else 0.94
		starter_voice.stream_paused=false;starter_voice.play()
	elif wake_phase=="door_ready":
		wake_phase="door_opening";wake_elapsed=0
		door_open=true
		if door_tween:door_tween.kill()
		game.soundscape.storage_move(wreck.global_position,false,true)
		game.town.actions.crash_driver_door.label="Close driver's door"

func show_wake_dialogue():
	wake_phase="dialogue"
	game.dialogue_name=""
	game.dialogue_text="Come on... no. The engine's dead. And there's no phone signal.\n\nMy head... I'm bleeding. Something crossed the road. I swerved and hit that stump.\n\nThere are lights down the road. I need to reach town and find someone who can help."
	game.set_state("dialogue")

func set_cabin_view(_inside:bool):
	# Windows have their own transparent surfaces; retain the complete body shell.
	for entry in body_materials:entry.material.cull_mode=entry.cull

func release_seated_camera():
	set_cabin_view(false)
	game.camera.top_level=false
	game.camera.position=Vector3(0,game.STANDING_EYE,0)
	game.camera.rotation=Vector3.ZERO;game.pitch=0

func leave_seat_for_testing():
	if not game.camera.top_level:return
	game.player.global_position=wreck.to_global(EXIT_POSITION)
	game.player.rotation=Vector3(0,wreck.rotation.y+PI,0)
	release_seated_camera()
	starter_voice.stop();dashboard_light.hide();steering_wheel.rotation.z=0
	door_open=true;door.rotation.y=door_closed.y-1.15

func update_waking(delta:float):
	if starter_voice:starter_voice.stream_paused=game.state!="waking"
	if game.state!="waking":return
	wake_elapsed+=minf(delta,0.1)
	game.player.velocity=Vector3.ZERO;game.jump_queued=false
	if wake_phase=="menu_fade" and wake_elapsed>=MENU_FADE_SECONDS:
		wake_phase="blinking";wake_elapsed=0;wake_menu_texture=null;game.update_camera()
	elif wake_phase=="blinking":
		seat_pitch=lerpf(-0.55,-0.15,smoothstep(0,3,wake_elapsed))
		if wake_elapsed>=3:
			wake_phase="ignition_ready";wake_elapsed=0;seat_pitch=-0.15
	elif wake_phase=="cranking":
		dashboard_light.light_energy=0.12+absf(sin(wake_elapsed*39))*0.10
		steering_wheel.rotation.z=sin(wake_elapsed*32)*0.012
		if wake_elapsed>=STARTER_SECONDS:
			starter_voice.stop();steering_wheel.rotation.z=0;dashboard_light.light_energy=0.16
			if ignition_attempts<2:wake_phase="ignition_retry";wake_elapsed=0
			else:show_wake_dialogue()
	elif wake_phase=="door_opening":
		var t=smoothstep(0,0.7,wake_elapsed)
		door.rotation.y=lerpf(door_closed.y,door_closed.y-1.15,t)
		if t>=1:
			wake_phase="exiting";wake_elapsed=0;exit_from=game.camera.global_transform
	elif wake_phase=="exiting":
		var t=smoothstep(0,EXIT_SECONDS,wake_elapsed)
		var endpoint=wreck.to_global(EXIT_POSITION)+Vector3.UP*game.STANDING_EYE
		var control=wreck.to_global(Vector3(-1.30,1.38,0.3))
		var position=exit_from.origin.lerp(control,t).lerp(control.lerp(endpoint,t),t)
		var basis=Basis(Vector3.UP,wreck.rotation.y+PI)
		game.camera.global_transform=Transform3D(exit_from.basis.slerp(basis,t),position)
		if t>=1:
			game.player.global_position=wreck.to_global(EXIT_POSITION)
			game.player.rotation=Vector3(0,wreck.rotation.y+PI,0)
			release_seated_camera();dashboard_light.hide()
			wake_phase="";game.set_state("play")
			game.message=""
	if game.camera.top_level and wake_phase!="exiting":update_seated_camera()
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
	return has_backpack and has_flashlight

func tutorial_prompt() -> String:
	# The opening dialogue already explains the gear. Remind only after rescue.
	if not game.story.clinic_rescue_done:return ""
	if game.story.clinic_rescue_done and not tutorial_complete() and game.player.global_position.distance_to(wreck.global_position)>5:
		return game.clinic_rescue.missing_gear_prompt()
	if not hatch_open: return "Walk to the back of the car.\nE TO Open the rear hatch"
	if not has_backpack: return "E TO TAKE YOUR BACKPACK FROM THE TRUNK"
	if not has_flashlight: return "E TO TAKE YOUR FLASHLIGHT FROM THE TRUNK"
	return ""

func interact_tutorial(id: String):
	if wake_phase!="": return
	if id=="crash_rear_hatch":
		hatch_open=not hatch_open
		if hatch_tween:hatch_tween.kill()
		hatch_tween=create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		hatch_tween.tween_property(hatch,"rotation:x",hatch_closed.x-HATCH_OPEN_ANGLE if hatch_open else hatch_closed.x,0.7)
		game.town.actions.crash_rear_hatch.label="Close rear hatch" if hatch_open else "Open rear hatch"
		game.soundscape.storage_move(wreck.global_position,false,hatch_open)
		update_item_targets()
		return
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
		game.message = "Driver's door opened. Your gear is in the trunk." if door_open else "Driver's door closed."
	elif id=="crash_backpack" and hatch_open and not has_backpack:
		has_backpack = true
		if game.story.clinic_rescue_done:game.town.inventory.bandage+=1
		bag_visual.hide()
		tutorial_areas.crash_backpack.collision_layer = 0
		update_item_targets()
		game.soundscape.feedback("pickup")
		game.message = "Backpack collected. H uses the spare bandage, or I opens your backpack." if game.story.clinic_rescue_done else "Backpack collected."
	elif id=="crash_flashlight" and hatch_open and not has_flashlight:
		has_flashlight = true
		light_visual.hide()
		tutorial_areas.crash_flashlight.collision_layer = 0
		game.soundscape.feedback("pickup")
		update_item_targets()
		game.message = "Flashlight collected. F switches it on."

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
		var available=not has_backpack if id=="crash_backpack" else (not has_flashlight if id=="crash_flashlight" else false)
		tutorial_areas[id].collision_layer=2 if hatch_open and available else 0

func build_car_interior():
	var cabin = Node3D.new()
	cabin.name = "LowPolyCabin"
	wreck.add_child(cabin)
	var town = game.town
	var fabric = town.mats.fabric.duplicate()
	fabric.albedo_color = Color("53594f")
	fabric.albedo_texture=null
	var carpet = game.mat(Color("292d29"))
	var plastic = game.mat(Color("3b403a"))
	var pale = game.mat(Color("8a8b73"))
	# A fitted headliner sits below the native roof. Native pillars and door
	# frames remain intact and visible from both sides.
	var headliner=town.box(cabin,Vector3(0,1.39,0.55),Vector3(0.90,0.018,0.84),carpet,false)
	headliner.name="CabinHeadliner"
	# Visual-only cabin geometry stays inside the car's existing collision shell.
	town.box(cabin,Vector3(0,0.30,0.1),Vector3(1.55,0.06,2.6),carpet,false)
	for x in [-0.43,0.43]:
		town.box(cabin,Vector3(x,0.405,-0.1),Vector3(0.55,0.13,0.78),plastic,false)
		town.box(cabin,Vector3(x,0.50,-0.1),Vector3(0.64,0.14,0.95),fabric,false)
		var back = town.box(cabin,Vector3(x,0.79,0.43),Vector3(0.63,0.65,0.16),fabric,false)
		back.rotation.x = -0.12
		for seam in [-0.16,0,0.16]:town.box(back,Vector3(seam,0,-0.084),Vector3(0.006,0.52,0.004),carpet,false)
		town.box(cabin,Vector3(x,1.19,0.48),Vector3(0.35,0.22,0.13),fabric,false)
		var belt = town.box(cabin,Vector3(x+0.17,0.83,0.325),Vector3(0.045,0.57,0.02),carpet,false)
		belt.rotation.z = -0.22
		town.box(cabin,Vector3(x*0.44,0.62,0.27),Vector3(0.055,0.10,0.06),plastic,false)
	town.box(cabin,Vector3(0,0.50,1.10),Vector3(1.42,0.16,0.48),fabric,false)
	town.box(cabin,Vector3(0,0.79,1.34),Vector3(1.42,0.47,0.14),fabric,false)
	preload("res://car_cabin_details.gd").build(self,cabin,plastic,fabric,carpet,pale)
	dashboard_light=OmniLight3D.new();dashboard_light.name="DashboardGlow"
	dashboard_light.position=Vector3(-0.43,1.02,-0.45);dashboard_light.light_color=Color("b29453")
	dashboard_light.light_energy=0.16;dashboard_light.omni_range=1.6
	cabin.add_child(dashboard_light);dashboard_light.hide()
	build_crash_blood(cabin)

func build_crash_blood(cabin:Node3D):
	var blood=game.mat(Color("54231f"))
	blood.cull_mode=BaseMaterial3D.CULL_DISABLED
	var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points=[Vector2(-0.10,-0.025),Vector2(-0.025,-0.045),Vector2(0.07,-0.02),Vector2(0.12,0.015),Vector2(0.03,0.028),Vector2(-0.08,0.016)]
	for i in range(1,points.size()-1):
		for index in [0,i,i+1]:
			var p=points[index]
			tool.add_vertex(Vector3(p.x+0.05,0.917-p.y*0.048,p.y-0.76))
	tool.generate_normals()
	var smear=MeshInstance3D.new();smear.name="CrashBloodSmear";smear.mesh=tool.commit();smear.material_override=blood;cabin.add_child(smear)
	for i in range(4):
		var drop=game.mesh_at(wreck,game.cylinder(0.035+i*0.008,0.035+i*0.008,0.002,7),Vector3(-1.12-i*0.10,0.006+0.025*(-1.12-i*0.10),0.25+i*0.12),blood)
		drop.name="CrashBloodDrop";drop.scale.z=0.65


func build_detour_sheet():
	detour_visual = Node3D.new()
	detour_visual.name = "DetourSheetInTrunk"
	wreck.add_child(detour_visual)
	detour_visual.position = Vector3(0.37,0.588,1.65)
	detour_visual.rotation.y = PI/2-0.14
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
	fit_pickup_targets()
	retire_detour_sheet()

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
			if image.is_compressed(): image.decompress()
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

func pickup_bounds(visual:Node3D)->AABB:
	if visual==bag_visual and backpack_model:
		update_backpack_model()
		visual=backpack_model
	var bounds=AABB()
	var first=true
	for mesh in visual.find_children("*","MeshInstance3D",true,false):
		var part=(wreck.global_transform.affine_inverse()*mesh.global_transform)*mesh.mesh.get_aabb()
		bounds=part if first else bounds.merge(part)
		first=false
	return bounds
func fit_pickup_targets():
	for pair in [["crash_backpack",bag_visual],["crash_flashlight",light_visual],["crash_record",detour_visual]]:
		if pair[1]==null or not tutorial_areas.has(pair[0]):continue
		var bounds=pickup_bounds(pair[1])
		var target=tutorial_areas[pair[0]]
		target.position=bounds.get_center()
		# Small padding makes the paper and narrow flashlight comfortable to aim at.
		target.get_child(0).shape.size=bounds.size+Vector3(0.045,0.06,0.045)
func pickup_focus(start:Vector3,finish:Vector3)->String:
	if not hatch_open or wake_phase!="":return ""
	var a=wreck.to_local(start)
	var b=wreck.to_local(finish)
	# Reach only through the open rear hatch, not through the cabin or sides.
	if a.z<=1.8 or b.z>=a.z:return ""
	var t=(1.8-a.z)/(b.z-a.z)
	if t<0 or t>1:return ""
	var opening=a.lerp(b,t)
	if opening.y<0.52 or opening.y>1.65 or absf(opening.x)>0.76:return ""
	var query=PhysicsRayQueryParameters3D.create(start,finish,2)
	query.collide_with_areas=true
	query.collide_with_bodies=false
	query.exclude=[tutorial_areas.crash_driver_door.get_rid(),tutorial_areas.crash_rear_hatch.get_rid()]
	var hit=get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():return ""
	var id=hit.collider.get_meta("action_id","")
	if id not in ["crash_backpack","crash_flashlight","crash_record"]:return ""
	var obstacle=PhysicsRayQueryParameters3D.create(start,hit.position,1,[game.player.get_rid(),wreck.get_rid()])
	if not get_world_3d().direct_space_state.intersect_ray(obstacle).is_empty():return ""
	return id

func build_trunk():
	var liner=game.mat(Color("292d29"))
	game.town.box(wreck,Vector3(0,0.56,1.32),Vector3(1.28,0.045,1.1),liner,false)
	for side in [-1,1]:
		game.town.box(wreck,Vector3(side*0.65,0.73,1.33),Vector3(0.04,0.34,1.05),liner,false)
	# The dark backing and inner panel prevent seeing through the body.
	game.town.box(wreck,Vector3(0,0.76,0.83),Vector3(1.3,0.42,0.045),liner,false)
	var hatch_liner=game.town.box(hatch,Vector3(0,-0.40,0.58),Vector3(1.22,0.035,0.62),liner,false)
	fit_hatch_liner(hatch_liner)
	build_hatch_struts()
	tutorial_areas.crash_rear_hatch=game.town.action_area(wreck,Vector3(0,1.03,2.02),Vector3(1.05,0.38,0.28),"crash_rear_hatch",{"kind":"crash_tutorial","label":"Open rear hatch"})
func update_hatch_target():
	if not tutorial_areas.has("crash_rear_hatch"):return
	var target=tutorial_areas.crash_rear_hatch
	target.collision_layer=2
	target.global_position=hatch.to_global(Vector3(0,-0.32,0.65)) if hatch_open else wreck.to_global(Vector3(0,1.03,2.02))

func retire_detour_sheet():
	# Retain the old nodes only to keep saved scene trees compatible.
	if detour_visual:detour_visual.hide()
	if tutorial_areas.has("crash_record"):
		var area=tutorial_areas.crash_record
		area.hide();area.collision_layer=0
		area.get_child(0).set_deferred("disabled",true)
		game.town.actions.crash_record.taken=true

func update_backpack_model():
	if not backpack_model or not bag_visual:return
	for child in bag_visual.get_children():
		if child is Node3D:child.hide()
	backpack_model.global_transform=bag_visual.global_transform*Transform3D(Basis.IDENTITY,Vector3(0,-0.215,-0.20))
	backpack_model.visible=bag_visual.is_visible_in_tree() and not has_backpack

func fit_hatch_liner(holder:Node3D):
	var panel=holder.get_child(0) as MeshInstance3D
	# Follow the actual lower hatch skin instead of a flat shelf hanging below it.
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var to_panel=(holder.transform*panel.transform).affine_inverse()
	for surface in range(hatch.mesh.get_surface_count()):
		var material=hatch.get_active_material(surface)
		if material is StandardMaterial3D and material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:continue
		var a=hatch.mesh.surface_get_arrays(surface)
		var vertices=a[Mesh.ARRAY_VERTEX];var indices=a[Mesh.ARRAY_INDEX]
		for i in range(0,indices.size(),3):
			var center=(vertices[indices[i]]+vertices[indices[i+1]]+vertices[indices[i+2]])/3.0
			if center.y> -0.30:continue
			for j in [2,1,0]:
				var v:Vector3=vertices[indices[i+j]]+Vector3(0,-0.012,-0.018)
				tool.add_vertex(to_panel*v)
	tool.generate_normals()
	panel.mesh=tool.commit()
	var trim=game.mat(Color("323631"))
	trim.cull_mode=BaseMaterial3D.CULL_DISABLED
	trim.shading_mode=BaseMaterial3D.SHADING_MODE_PER_VERTEX
	panel.material_override=trim

func build_hatch_struts():
	# Visual-only gas supports; mounted outside saved scene roots for compatibility.
	for side in [-1,1]:
		for piece in range(2):
			var shape=CylinderMesh.new()
			shape.top_radius=0.011 if piece==0 else 0.006
			shape.bottom_radius=shape.top_radius
			shape.height=1;shape.radial_segments=6
			var rod=game.mesh_at(game,shape,Vector3.ZERO,game.mat(Color("202724") if piece==0 else Color("777f7a")))
			rod.name="HatchGasStrut"+str(side)+"_"+str(piece)
			hatch_struts.append(rod)
	update_hatch_struts()

func update_hatch_struts():
	if hatch_struts.size()!=4:return
	for i in range(2):
		var side=-1 if i==0 else 1
		var fixed=wreck.to_global(Vector3(side*0.62,1.02,1.29))
		var moving=hatch.to_global(Vector3(side*0.60,-0.32,0.82))
		var axis=moving-fixed
		var length=axis.length()
		if length<0.001:continue
		var basis=Basis(Quaternion(Vector3.UP,axis/length))
		for piece in range(2):
			var rod=hatch_struts[i*2+piece]
			rod.global_transform=Transform3D(basis*Basis.from_scale(Vector3(1,length*(0.56 if piece==0 else 0.50),1)),fixed+axis*(0.28 if piece==0 else 0.75))

func repair_rear_quarter_windows():
	# The old rectangular hatch cut captured the rear tips of the side glazing.
	# Return side-facing glass and its upper trim to the stationary body.
	var moving=ArrayMesh.new();var fixed=ArrayMesh.new()
	for surface in range(hatch.mesh.get_surface_count()):
		var a=hatch.mesh.surface_get_arrays(surface)
		var vertices=a[Mesh.ARRAY_VERTEX];var indices=a[Mesh.ARRAY_INDEX]
		var keep=PackedInt32Array();var restore=PackedInt32Array()
		for i in range(0,indices.size(),3):
			var v0:Vector3=vertices[indices[i]];var v1:Vector3=vertices[indices[i+1]];var v2:Vector3=vertices[indices[i+2]]
			var center=(v0+v1+v2)/3.0
			var normal=(v1-v0).cross(v2-v0).normalized()
			var side_window=absf(center.x)>0.46 and center.y> -0.30 and absf(normal.x)>0.65 and center.y<0.26-0.62*center.z-0.06
			for j in range(3):
				if side_window:restore.append(indices[i+j])
				else:keep.append(indices[i+j])
		for selection in [keep,restore]:
			if selection.is_empty():continue
			var arrays=a.duplicate();arrays[Mesh.ARRAY_INDEX]=selection
			var target=fixed if selection==restore else moving
			target.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			target.surface_set_material(target.get_surface_count()-1,hatch.get_active_material(surface))
	hatch.mesh=moving
	if fixed.get_surface_count()>0:
		rear_quarter_windows=MeshInstance3D.new()
		rear_quarter_windows.name="FixedRearQuarterWindows"
		rear_quarter_windows.mesh=fixed
		game.add_child(rear_quarter_windows)
		rear_quarter_mount=wreck.global_transform.affine_inverse()*hatch.global_transform
		rear_quarter_windows.global_transform=wreck.global_transform*rear_quarter_mount

