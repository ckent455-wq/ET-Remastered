extends Node3D
const START_POSITION = Vector3(-0.7,0.001,16.8)
const START_YAW = -0.60
const STANDING_HEIGHT = 1.85
const CROUCH_HEIGHT = 0.9
const STANDING_EYE = 1.65
const CROUCH_EYE = 0.68
const JUMP_VELOCITY = 5.2
const GRAVITY = 18.0
var saves: Node
var updater: Node
var testing_mode: Node
var controller: Node
var crouching = false
var jump_queued = false
var player_collider: CollisionShape3D
var standing_probe: CapsuleShape3D
var player: CharacterBody3D
var camera: Camera3D
var title_camera: Camera3D
var title_weather: Node
var flashlight: SpotLight3D
var hud: Control
var achievements: Node
const CRASH_HEALTH = 25.0
var health = CRASH_HEALTH
var stamina = 100.0
var invincible = 0.0
var hurt_flash = 0.0
var town_changes:Node3D
var workshop_layout:Node
var hotel_staff:Node3D
var hotel_reception:Node3D
var hotel_upper_layout:Node
var hotel_upper:Node3D
var hotel_layout:Node
var clinic_layout:Node
var ranger_layout:Node
var knife:Node3D
var contact_progress = 0.0
var clock = 0.0
var state = "intro"
var intro_elapsed = 0.0
var message = "Explore Blackwood and speak to its remaining townspeople."
var dialogue_name = ""
var dialogue_text = ""
var dialogue_pages: Array[String] = []
var dialogue_page = 0
var dialogue_view = {}

var pitch = 0.0
var crash_site: Node3D
var soundscape: Node
var arm_visual: Node3D
var weapons: Node3D
var enemies: Node3D
var clinic_rescue: Node
var story: Node
var backpack
var journal_casefile = false
var town: Node3D
var fog_atmosphere: Node3D
var distant_landscape: Node3D
var falling_tree: Node3D
var surface_details: Node
var grave_dig: Node3D
var hotel_window_figure: Node3D
var cemetery_shadow: Node3D
var hotel_basement: Node3D
var victorian_house: Node3D
var forest_boundary: Node3D
var flashlight_model: Node3D
var flashlight_raise = 1.0
const FLASHLIGHT_UP = Vector3(0.30,-0.19,-0.77)
const FLASHLIGHT_DOWN = Vector3(0.34,-0.72,-0.57)
const FLASHLIGHT_ANIMATION_SECONDS = 0.30
const START_FLASHLIGHT_CHARGE = 45.0
const FLASHLIGHT_DRAIN_PER_SECOND = 0.5
var flashlight_charge = START_FLASHLIGHT_CHARGE
var journal_page = 0

func mat(color: Color, texture: Texture2D = null, emission = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = texture
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 1.0
	if emission > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

func mesh_at(parent: Node3D, mesh: Mesh, pos: Vector3, material: Material) -> MeshInstance3D:
	var obj = MeshInstance3D.new()
	obj.mesh = mesh
	obj.position = pos
	obj.material_override = material
	parent.add_child(obj)
	return obj

func cylinder(bottom: float, top: float, height: float, segments = 7) -> CylinderMesh:
	var mesh = CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = segments
	return mesh

func _ready():
	seed(83)
	var world = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("343d3b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9a9e91")
	env.ambient_light_energy = 0.52
	env.fog_enabled = true
	env.fog_light_color = Color("626e68")
	env.fog_light_energy = 0.65
	env.fog_density = 0.070
	world.environment = env
	add_child(world)
	var moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48,-35,0)
	moon.light_color = Color("b4b9ab")
	moon.light_energy = 0.5
	# The sealed cellar uses its own light layer; moonlight cannot reach it.
	moon.light_cull_mask = 1
	add_child(moon)
	var ground_mat = mat(Color("8d9a91"),preload("res://assets/forest/ground_ps2.png"))
	ground_mat.uv1_scale = Vector3(30,30,30)
	var ground = StaticBody3D.new()
	add_child(ground)
	preload("res://grave_ground.gd").build(ground,ground_mat)
	var forest = Node3D.new()
	forest.set_script(preload("res://forest.gd"))
	add_child(forest)
	player = CharacterBody3D.new()
	player.floor_snap_length = 0.15
	add_child(player)
	var col = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = STANDING_HEIGHT
	col.shape = capsule
	col.position.y = STANDING_HEIGHT/2
	player_collider = col
	standing_probe = capsule.duplicate()
	player.add_child(col)
	camera = Camera3D.new()
	camera.position.y = STANDING_EYE
	camera.fov = 76
	camera.far = 85
	player.add_child(camera)
	flashlight = SpotLight3D.new()
	flashlight.light_color = Color("b9e1cc")
	flashlight.light_energy = 2.5
	flashlight.spot_range = 17
	flashlight.spot_angle = 39
	flashlight.position = Vector3(0.15,-0.15,0)
	camera.add_child(flashlight)
	arm_visual = Node3D.new()
	arm_visual.name = "FlashlightHolder"
	camera.add_child(arm_visual)
	flashlight_model = load("res://assets/flashlight/flashlight.glb").instantiate()
	flashlight_model.name = "LocalFlashlightModel"
	arm_visual.add_child(flashlight_model)
	flashlight_model.position = FLASHLIGHT_UP
	prepare_flashlight(flashlight_model)
	var canvas = CanvasLayer.new()
	add_child(canvas)
	hud = Control.new()
	hud.set_script(load("res://hud.gd"))
	hud.game = self
	canvas.add_child(hud)
	achievements = Node.new()
	achievements.set_script(preload("res://achievements.gd"))
	add_child(achievements)
	make_audio()
	town = Node3D.new()
	town.set_script(preload("res://town.gd"))
	town.game = self
	add_child(town)
	weapons = Node3D.new()
	weapons.set_script(preload("res://weapons.gd"))
	weapons.game = self
	add_child(weapons)
	crash_site = Node3D.new()
	crash_site.set_script(preload("res://crash_site.gd"))
	crash_site.game = self
	add_child(crash_site)
	story = Node.new()
	story.set_script(preload("res://blackwood_story.gd"))
	story.game = self
	add_child(story)
	enemies = Node3D.new()
	enemies.set_script(preload("res://enemies.gd"))
	enemies.game = self
	add_child(enemies)
	falling_tree = preload("res://falling_tree.gd").new()
	falling_tree.game = self
	add_child(falling_tree)
	clinic_rescue = preload("res://clinic_rescue.gd").new()
	clinic_rescue.game = self
	add_child(clinic_rescue)
	reset_game()
	title_camera = Camera3D.new()
	title_camera.name = "BlackwoodTitleCamera"
	title_camera.fov = 62
	title_camera.far = 85
	add_child(title_camera)
	title_camera.position = Vector3(-1,1.65,-30)
	title_camera.look_at(Vector3(4.4,1.4,-38))
	title_weather = Node.new()
	title_weather.set_script(preload("res://title_weather.gd"))
	title_weather.game = self
	add_child(title_weather)
	var enclosure = Node3D.new()
	enclosure.set_script(preload("res://world_enclosure.gd"))
	enclosure.game = self
	add_child(enclosure)
	fog_atmosphere = Node3D.new()
	fog_atmosphere.set_script(preload("res://fog_atmosphere.gd"))
	fog_atmosphere.game = self
	fog_atmosphere.environment = env
	add_child(fog_atmosphere)
	distant_landscape = Node3D.new()
	distant_landscape.set_script(preload("res://distant_landscape.gd"))
	distant_landscape.game = self
	distant_landscape.environment = env
	add_child(distant_landscape)
	forest_boundary = Node3D.new()
	forest_boundary.set_script(preload("res://forest_boundary.gd"))
	forest_boundary.game = self
	add_child(forest_boundary)
	victorian_house = preload("res://victorian_house.gd").new()
	victorian_house.game = self
	add_child(victorian_house)
	town.apartment_interiors.retro.decorate_house(victorian_house)
	hotel_basement=preload("res://hotel_basement.gd").new()
	hotel_basement.game=self
	add_child(hotel_basement)
	hotel_window_figure=preload("res://hotel_window_figure.gd").new()
	hotel_window_figure.game=self
	add_child(hotel_window_figure)
	cemetery_shadow=preload("res://cemetery_shadow.gd").new()
	cemetery_shadow.game=self
	add_child(cemetery_shadow)
	grave_dig=preload("res://grave_dig.gd").new()
	grave_dig.game=self
	add_child(grave_dig)
	backpack = preload("res://backpack.gd").new()
	backpack.game = self
	canvas.add_child(backpack)
	surface_details = preload("res://surface_details.gd").new()
	surface_details.game = self
	add_child(surface_details)
	controller=preload("res://controller_input.gd").new()
	controller.game=self
	add_child(controller)
	testing_mode = preload("res://testing_mode.gd").new()
	testing_mode.game = self
	add_child(testing_mode)
	saves=preload("res://save_screen.gd").new();saves.game=self;add_child(saves)
	updater = preload("res://release_updater.gd").new()
	updater.game = self
	add_child(updater)
	update_camera()
	town_changes=preload("res://town_progression.gd").new();town_changes.game=self;add_child(town_changes)
	workshop_layout=preload("res://workshop_layout.gd").new();workshop_layout.game=self;add_child(workshop_layout)
	hotel_layout=preload("res://hotel_layout.gd").new();hotel_layout.game=self;add_child(hotel_layout)
	clinic_layout=preload("res://clinic_layout.gd").new();clinic_layout.game=self;add_child(clinic_layout)
	ranger_layout=preload("res://ranger_layout.gd").new();ranger_layout.game=self;add_child(ranger_layout)
	knife=preload("res://hotel_knife.gd").new();knife.game=self;add_child(knife)
	hotel_upper=preload("res://hotel_upper_floor.gd").new();hotel_upper.game=self;add_child(hotel_upper)
	hotel_upper_layout=preload("res://hotel_upper_layout.gd").new();hotel_upper_layout.game=self;add_child(hotel_upper_layout)
	hotel_reception=preload("res://hotel_reception_bell.gd").new();hotel_reception.game=self;add_child(hotel_reception)
	hotel_staff=preload("res://hotel_staff_partition.gd").new();hotel_staff.game=self;add_child(hotel_staff)
	call_deferred("load_requested_slot")

func load_requested_slot():
	if "--preview-zombie" in OS.get_cmdline_user_args():
		while not surface_details.completed:await get_tree().process_frame
		reset_game();crash_site.wake_phase="";crash_site.release_seated_camera()
		crash_site.has_backpack=true;crash_site.has_flashlight=true
		story.clinic_rescue_done=true;story.crash_wound_treated=true;town.reached_town=true;health=100;hurt_flash=0
		player.global_position=Vector3(0,0.02,-51);player.rotation=Vector3.ZERO
		camera.look_at(Vector3(0,1.1,-54));pitch=camera.rotation.x
		set_state("play");flashlight.show();camera.make_current()
		var preview=preload("res://local_zombie_preview.gd").new();preview.game=self;add_child(preview)
		return
	if "--preview-ranger-layout" in OS.get_cmdline_user_args() or "--preview-workshop-layout" in OS.get_cmdline_user_args():
		while not surface_details.completed:await get_tree().process_frame
		reset_game();crash_site.wake_phase="";crash_site.release_seated_camera()
		crash_site.has_backpack=true;crash_site.has_flashlight=true
		story.clinic_rescue_done=true;story.crash_wound_treated=true;health=100;hurt_flash=0
		player.rotation=Vector3.ZERO
		var room=town.buildings.workshop if "--preview-workshop-layout" in OS.get_cmdline_user_args() else town.buildings.ranger
		player.global_position=room.to_global(Vector3(0,0.02,3.3))
		camera.look_at(room.to_global(Vector3(-1.0,1.2,-1.0)))
		player.rotation.y=camera.rotation.y;camera.rotation.y=0;pitch=camera.rotation.x
		set_state("play");flashlight.show()
		return
	if "--preview-hotel-elevator" in OS.get_cmdline_user_args() or "--preview-hotel-second-floor" in OS.get_cmdline_user_args():
		while not surface_details.completed or not hotel_upper.ready_layout:await get_tree().process_frame
		reset_game();crash_site.wake_phase="";crash_site.release_seated_camera()
		crash_site.has_backpack=true;crash_site.has_flashlight=true;story.clinic_rescue_done=true;story.crash_wound_treated=true;town.reached_town=true
		health=100;hurt_flash=0;player.global_position=town.buildings.house.to_global(Vector3(-2.2,.04,-.9))
		camera.look_at(hotel_upper.to_global(hotel_upper.LIFT_ORIGIN+Vector3(0,1.45,1.3)))
		if "--preview-hotel-second-floor" in OS.get_cmdline_user_args():
			hotel_upper.floor_index=1;hotel_upper.target_floor=1;hotel_upper.cab.position.y=hotel_upper.UPPER;hotel_upper.sync_doors()
			player.global_position=hotel_upper.to_global(Vector3(0,hotel_upper.UPPER+.02,-1.15))
			camera.look_at(hotel_upper.to_global(Vector3(-3.35,hotel_upper.UPPER+1.25,-.55)))
		player.rotation.y=camera.rotation.y;camera.rotation.y=0;pitch=camera.rotation.x
		set_state("play");flashlight.show();return
	if "--preview-hotel-reception" in OS.get_cmdline_user_args() or "--preview-hotel-staff" in OS.get_cmdline_user_args():
		while not surface_details.completed or not hotel_upper.ready_layout:await get_tree().process_frame
		reset_game();crash_site.wake_phase="";crash_site.release_seated_camera()
		crash_site.has_backpack=true;crash_site.has_flashlight=true;story.clinic_rescue_done=true;story.crash_wound_treated=true;town.reached_town=true;health=100;hurt_flash=0
		player.global_position=town.buildings.house.to_global(Vector3(.25,.04,3.6))
		camera.look_at(town.buildings.house.to_global(Vector3(3.7,1.35,.1)))
		if "--preview-hotel-staff" in OS.get_cmdline_user_args():
			player.global_position=town.buildings.house.to_global(Vector3(0,.04,1.2));camera.look_at(town.buildings.house.to_global(Vector3(-1.1625,1.4,-1.6)))
		player.rotation.y=camera.rotation.y;camera.rotation.y=0;pitch=camera.rotation.x
		set_state("play");flashlight.show();return
	if "--preview-hotel-knife" in OS.get_cmdline_user_args():
		while not surface_details.completed:await get_tree().process_frame
		reset_game();crash_site.wake_phase="";crash_site.release_seated_camera()
		crash_site.has_backpack=true;crash_site.has_flashlight=true
		story.clinic_rescue_done=true;story.crash_wound_treated=true;health=100;hurt_flash=0
		player.global_position=knife.source.global_position+Vector3(-0.25,-1.0,1.0)
		camera.look_at(knife.source.global_position)
		pitch=camera.rotation.x
		set_state("play");flashlight.show()
		return
	if "--preview-town" in OS.get_cmdline_user_args():
		while not surface_details.completed:await get_tree().process_frame
		reset_game();crash_site.wake_phase="";crash_site.release_seated_camera()
		crash_site.has_backpack=true;crash_site.has_flashlight=true
		story.clinic_rescue_done=true;story.crash_wound_treated=true;health=65
		var terminal=town.actions.battery_panel.area.get_node("HighVoltageTerminal")
		terminal.installed=true;terminal.opened=true;terminal.activate_power()
		for id in ["ranger","nurse","mechanic"]:town.townspeople.conversation.greetings[id]=true
		player.global_position=town.buildings.workshop.to_global(Vector3(0,0.02,3.8))
		set_state("play");town.townspeople.talk("mechanic")
		return
	# Explicit local playtest shortcut. Normal launches and saved journeys are untouched.
	if "--preview-collapse" in OS.get_cmdline_user_args() or "--preview-clinic" in OS.get_cmdline_user_args() or "--preview-missing-gear" in OS.get_cmdline_user_args():
		while not surface_details.completed:await get_tree().process_frame
		reset_game()
		crash_site.wake_phase=""
		crash_site.release_seated_camera()
		player.global_position=Vector3(0,0.02,-14.8)
		player.rotation=Vector3.ZERO
		if "--preview-clinic" in OS.get_cmdline_user_args() or "--preview-missing-gear" in OS.get_cmdline_user_args():
			clinic_rescue.place_in_bed()
			clinic_rescue.begin_explanation()
			if "--preview-missing-gear" in OS.get_cmdline_user_args():set_state("play")
		else:
			set_state("paused")
			message="Resume and run toward town to test the collapse."
		return
	# Optional launcher shortcut; uses the same validated load as the menu.
	var slot=0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--load-slot="):slot=argument.trim_prefix("--load-slot=").to_int()
	if slot<1 or slot>3:return
	while not surface_details.completed:await get_tree().process_frame
	if saves.backend.load_slot(slot):print("LOADED JOURNEY / SLOT ",slot)
	else:
		print("LOAD JOURNEY FAILED / SLOT ",slot)
		set_state("title");saves.open(true)

func prepare_flashlight(node: Node):
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in range(node.mesh.get_surface_count()):
			var original = node.mesh.surface_get_material(surface)
			if original is StandardMaterial3D:
				var material = original.duplicate() as StandardMaterial3D
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
				material.roughness = 1
				material.metallic = 0
				material.metallic_specular = 0
				node.set_surface_override_material(surface,material)
	for child in node.get_children():
		prepare_flashlight(child)

func make_audio():
	soundscape = Node.new()
	soundscape.set_script(preload("res://soundscape.gd"))
	soundscape.game = self
	add_child(soundscape)

func reset_game():
	if has_node("LocalZombiePreview"):get_node("LocalZombiePreview").queue_free()
	if hud and hud.objectives:hud.objectives.reset()
	if clinic_rescue: clinic_rescue.reset()
	if testing_mode: testing_mode.finish(false)
	achievements.clear_toast()
	player.position = START_POSITION
	player.velocity = Vector3.ZERO
	crouching = false
	jump_queued = false
	player_collider.shape.height = STANDING_HEIGHT
	player_collider.position.y = STANDING_HEIGHT/2
	camera.position.y = STANDING_EYE
	player.rotation = Vector3(0,START_YAW,0)
	camera.rotation = Vector3.ZERO
	pitch = 0
	health = CRASH_HEALTH
	stamina = 100
	contact_progress = 0
	invincible = 0
	hurt_flash = 0.0
	flashlight_charge = START_FLASHLIGHT_CHARGE
	flashlight.visible = false
	flashlight_raise = 0.0
	flashlight_model.position = FLASHLIGHT_UP
	flashlight_model.rotation = Vector3.ZERO
	flashlight_model.visible = false
	journal_page = 0
	if backpack:
		backpack.selected = 0
		backpack.saved_cells.clear()
		backpack.saved_rotations.clear()
		backpack.dragging = ""
		backpack.discard_pending = ""
		backpack.notice = "Select an item to equip, use or examine."
	message = "Find the rear hatch. Look at it and press E to retrieve your gear."
	soundscape.reset()
	town.reset()
	weapons.reset()
	if enemies: enemies.reset()
	if story: story.reset()
	if falling_tree: falling_tree.reset()
	if crash_site: crash_site.reset()
	if hotel_basement: hotel_basement.reset()
	if hotel_upper:hotel_upper.reset()
	if hotel_reception:hotel_reception.reset()
	if hotel_staff:hotel_staff.reset()
	if cemetery_shadow: cemetery_shadow.reset()
	if hotel_window_figure: hotel_window_figure.reset()
	if knife:knife.reset()
	if grave_dig: grave_dig.reset()
	if town_changes:town_changes.reset()

func set_state(next: String):
	if next!="dialogue" and town and town.townspeople and town.townspeople.conversation:
		town.townspeople.conversation.cancel()
	if crash_site and next=="play" and crash_site.wake_phase!="":
		if crash_site.wake_phase=="dialogue": crash_site.wake_phase="door_ready"
		next="waking"
	if next=="dialogue" and state!="dialogue":
		dialogue_page=0
		dialogue_pages=preload("res://dialogue_style.gd").pages(dialogue_text)
		dialogue_view={"yaw":player.rotation.y,"pitch":pitch,"fov":camera.fov}
		for person in town.townspeople.characters.values():
			if person.name==dialogue_name:
				var facing: Vector3=person.parent.global_basis.inverse()*(player.global_position-person.actor.global_position)
				person.actor.rotation.y=atan2(facing.x,facing.z)
				var toward=person.actor.global_position+Vector3(0,1.45,0)-camera.global_position
				player.rotation.y=atan2(-toward.x,-toward.z)
				pitch=atan2(toward.y,Vector2(toward.x,toward.z).length())
				camera.rotation.x=pitch
				camera.fov=66
	if state=="dialogue" and next!="dialogue" and not dialogue_view.is_empty():
		player.rotation.y=dialogue_view.yaw
		pitch=dialogue_view.pitch
		camera.rotation.x=pitch
		camera.fov=dialogue_view.fov
		dialogue_view.clear()
	state = next
	if hud:hud.queue_redraw()
	if clinic_rescue and clinic_rescue.phase=="bed" and next=="play":clinic_rescue.leave_bed()
	if state!="play": jump_queued = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if state in ["play","waking"] else Input.MOUSE_MODE_VISIBLE
	update_camera()

func update_camera():
	if title_camera==null:
		return
	var active_camera = title_camera if state in ["intro","title"] or (crash_site and crash_site.wake_phase=="menu_fade") else camera
	if not active_camera.current:
		active_camera.make_current()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode==KEY_F11 or (event.keycode==KEY_ENTER and event.alt_pressed)):
		get_window().mode=Window.MODE_WINDOWED if get_window().mode==Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
		return
	if state=="clinic_faint":return
	if saves and saves.opened():return
	if state=="lost" and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		set_state("title");return
	if state=="lost" and event is InputEventKey and event.pressed and event.keycode==KEY_L:
		saves.open(true);return
	if state=="waking":
		if event is InputEventMouseMotion: crash_site.look_inside(event.relative)
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode==KEY_E: crash_site.interact_waking()
			elif event.keycode==KEY_ESCAPE: set_state("paused")
			elif event.keycode==KEY_M: soundscape.toggle_mute()
		return
	if state=="backpack":
		backpack.handle(event)
		return
	if state=="journal" and event is InputEventKey and event.pressed and event.keycode==KEY_I:
		open_backpack()
		return
	if state=="title" and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		hud.controls_open = false
		return
	if state=="intro":
		if event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER,KEY_SPACE,KEY_ESCAPE]:
			set_state("title")
		return
	if state=="dialogue":
		if town.townspeople.conversation.active:
			town.townspeople.conversation.handle(event)
			return
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_ESCAPE,KEY_TAB]: set_state("play")
			elif event.keycode in [KEY_E,KEY_ENTER,KEY_SPACE]: advance_dialogue()
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			if preload("res://dialogue_style.gd").BOX.has_point(event.position): advance_dialogue()
		return
	if event is InputEventMouseMotion and state=="play" and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.relative.x*0.0026)
		pitch = clampf(pitch-event.relative.y*0.0026,-1.35,1.35)
		camera.rotation.x = pitch
	if event is InputEventMouseButton and event.pressed and state=="play":
		var captured = Input.mouse_mode==Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if captured and event.button_index==MOUSE_BUTTON_LEFT:
			weapons.fire()
		elif event.button_index==MOUSE_BUTTON_WHEEL_UP:
			weapons.cycle(-1)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			weapons.cycle(1)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ENTER and state!="play":
			if state not in ["paused","journal"]:
				reset_game()
				set_state("play")
				crash_site.start_opening()
			else: set_state("play")
		elif event.keycode==KEY_ESCAPE:
			set_state("paused" if state=="play" else "play")
		if event.keycode==KEY_I and state=="play":
			open_backpack()
		if event.keycode==KEY_TAB and state in ["play","journal"]:
			journal_page = 0
			journal_casefile = false
			set_state("journal" if state=="play" else "play")
		if state=="journal" and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_A,KEY_D]:
			journal_casefile = false
			journal_page = wrapi(journal_page+(-1 if event.keycode in [KEY_LEFT,KEY_A] else 1),0,town.journal_entries.size()+2)
		if event.keycode==KEY_M:
			soundscape.toggle_mute()
		if state=="journal" and event.keycode==KEY_C:
			journal_casefile = not journal_casefile
		if event.keycode==KEY_F and state=="play":
			toggle_flashlight()
			if crash_site.has_flashlight: soundscape.flashlight_click(flashlight.visible)
		if state=="play" and event.keycode==KEY_E:
			town.interact()
		if state=="play" and event.keycode==KEY_H:
			town.use_healing()
		if state=="play" and event.keycode==KEY_Q:
			town.use_battery()
		if state=="play" and event.keycode in [KEY_0,KEY_1,KEY_2,KEY_3,KEY_4]:
			if event.keycode==KEY_0 and weapons.selected==-1:
				weapons.melee.toggle()
			else:
				weapons.equip({KEY_0:-1,KEY_1:0,KEY_2:1,KEY_3:2,KEY_4:-2}[event.keycode])
		if state=="play" and event.keycode==KEY_R:
			weapons.reload()
		if state=="play" and event.keycode==KEY_V:
			weapons.cycle(1)
		if state=="play" and event.keycode==KEY_SPACE:
			jump_queued = true

func _physics_process(delta):
	clock += delta
	if state!="play":
		jump_queued = false
		hud.queue_redraw()
		return
	if hotel_upper and hotel_upper.rider and hotel_upper.busy():
		jump_queued=false;player.velocity=Vector3.ZERO;town.focus_action=""
		update_flashlight_battery(delta);hud.queue_redraw();return
	if clinic_rescue:
		clinic_rescue.update_approach(delta)
		if state!="play":return
	var movement = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).normalized()
	if controller: movement=(movement+controller.movement()).limit_length(1.0)
	if grave_dig and grave_dig.digging: movement=Vector2.ZERO; jump_queued=false
	if clinic_rescue and clinic_rescue.phase=="dimming":jump_queued=false
	update_stance(delta)
	var sprint = not (clinic_rescue and clinic_rescue.phase=="dimming") and not crouching and (Input.is_physical_key_pressed(KEY_SHIFT) or (controller and controller.down(JOY_BUTTON_LEFT_STICK))) and stamina>1 and movement.length()>0
	stamina = clampf(stamina+(-24 if sprint else 17)*delta,0,100)
	var vertical_speed = 0.0 if player.is_on_floor() else player.velocity.y-GRAVITY*delta
	if jump_queued and player.is_on_floor(): vertical_speed = JUMP_VELOCITY
	jump_queued = false
	var speed = 2.1 if crouching else (8.0 if sprint else 4.6)
	if clinic_rescue:speed*=clinic_rescue.movement_scale()
	player.velocity = player.basis*Vector3(movement.x,0,movement.y)*speed
	# Floor snapping maintains contact without forcing the capsule into the floor.
	player.velocity.y = vertical_speed
	var previous_position = player.position
	player.move_and_slide()
	# The shared world floor is flat at y=0. Prevent corner recovery from
	# sinking the capsule into that plane and bouncing it back next frame.
	if player.position.y<0.001 and not town.streetscape.church.basement.contains(player.global_position) and not victorian_house.cellar_contains(player.global_position) and not hotel_basement.contains(player.global_position) and not (grave_dig and grave_dig.contains_pit(player.global_position)):
		player.position.y = 0.001
		player.velocity.y = 0.0
	player.position.x = clampf(player.position.x,-60,60)
	player.position.z = clampf(player.position.z,-160,47)
	var travelled = Vector2(player.position.x-previous_position.x,player.position.z-previous_position.z).length()
	soundscape.moved(travelled,sprint,player.is_on_floor())
	# Stance height is controlled above; collisions never add camera shake.
	invincible = maxf(0,invincible-delta)
	update_flashlight_battery(delta)
	if health<=0:
		set_state("lost")
	town.update_arrival()
	town.refresh_focus()
	update_contact(delta,Input.is_physical_key_pressed(KEY_E) or (controller and controller.interact_held()))
	hud.queue_redraw()

func can_stand() -> bool:
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = standing_probe
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	query.transform = player.global_transform
	# Lift the query 2cm to ignore the supporting floor and leave headroom.
	query.transform.origin += Vector3.UP*(STANDING_HEIGHT/2+0.02)
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func update_stance(delta: float):
	var held = Input.is_physical_key_pressed(KEY_CTRL) or (controller and controller.down(JOY_BUTTON_B))
	crouching = held or ((crouching or player_collider.shape.height<STANDING_HEIGHT-0.001) and not can_stand())
	var wanted = CROUCH_HEIGHT if crouching else STANDING_HEIGHT
	var height = move_toward(player_collider.shape.height,wanted,5.5*delta)
	if not is_equal_approx(player_collider.shape.height,height):
		player_collider.shape.height = height
		player_collider.position.y = height/2
	var eye = CROUCH_EYE if crouching else STANDING_EYE
	camera.position.y = minf(move_toward(camera.position.y,eye,4.8*delta),height-0.20)

func take_damage(amount: float, hurt_clip = -1) -> bool:
	if state!="play" or health<=0 or amount<=0 or invincible>0 or (testing_mode and testing_mode.enabled): return false
	health = maxf(0,health-amount)
	invincible = 0.9
	hurt_flash = 0.20
	soundscape.player_hurt(hurt_clip)
	if health<=0: set_state("lost")
	return true

func update_contact(delta: float, held: bool):
	if state!="play":
		return
	if rescue_available() and held:
		contact_progress += delta
		message = story.rescue_line(contact_progress)
		if contact_progress>=4:
			set_state("won")
	else:
		if held and town.radio_ready and town.player_inside_building("radio") and camera.global_position.distance_to(town.actions.receiver.area.global_position)<3.2:
			message="Shut down the chapel basement repeater before calling for rescue." if not story.repeater_is_off() else "The chapel repeater is off. Set BYPASS to GREEN / direct county; the amber route is dead."
		contact_progress = maxf(0,contact_progress-delta*0.5)

func rescue_available() -> bool:
	return town.radio_ready and story.repeater_is_off() and story.direct_channel_selected() and town.focus_action!="radio_bypass" and town.player_inside_building("radio") and camera.global_position.distance_to(town.actions.receiver.area.global_position)<3.2

func _process(delta):
	if hurt_flash>0 and state in ["play","dialogue","lost"]:
		hurt_flash=maxf(0,hurt_flash-delta)
		hud.queue_redraw()
	update_camera()
	update_flashlight_visual(delta)
	if state=="intro":
		# Give the presentation its full screen time even after cold shader compilation.
		intro_elapsed += minf(delta,0.1)
		if intro_elapsed>=3.6:
			set_state("title")

func update_flashlight_visual(delta: float):
	if not crash_site.has_flashlight:
		flashlight_model.hide()
		return
	if state!="play":
		return
	var wanted = 1.0 if flashlight.visible and weapons.selected==-1 and not weapons.melee.raised else 0.0
	flashlight_raise = move_toward(flashlight_raise,wanted,delta/FLASHLIGHT_ANIMATION_SECONDS)
	var eased = smoothstep(0.0,1.0,flashlight_raise)
	flashlight_model.position = FLASHLIGHT_DOWN.lerp(FLASHLIGHT_UP,eased)
	flashlight_model.rotation = Vector3(-0.28,0,0.06)*(1.0-eased)
	flashlight_model.visible = flashlight_raise>0.001

func flashlight_fault_active()->bool:
	return hotel_basement and hotel_basement.has_node("CellarCoffinStacks") and hotel_basement.get_node("CellarCoffinStacks").blackout_active

func toggle_flashlight():
	if flashlight_fault_active():
		flashlight.hide()
		message="The switch isn't responding."
		return
	if not crash_site.has_flashlight:
		message = "Your flashlight is still in the trunk. Open the rear hatch and collect your gear."
		return
	if flashlight_charge<=0:
		flashlight.visible = false
		message = "Flashlight battery is empty. Find batteries in town; Q fits a spare."
	else:
		flashlight.visible = not flashlight.visible

func update_flashlight_battery(delta: float):
	if state!="play" or not flashlight.visible:
		return
	var previous_charge = flashlight_charge
	flashlight_charge = maxf(0,flashlight_charge-delta*FLASHLIGHT_DRAIN_PER_SECOND)
	if previous_charge>15 and flashlight_charge<=15:
		message = "Flashlight battery running low. Q fits a spare; check your journal."
	if flashlight_charge<=0:
		flashlight.visible = false
		message = "Flashlight battery exhausted. Find batteries in town; Q fits a spare."

func advance_dialogue():
	if town.townspeople.conversation.active:
		town.townspeople.conversation.advance()
		return
	if dialogue_page+1<dialogue_pages.size(): dialogue_page+=1
	else: set_state("play")

func open_backpack():
	if not crash_site.has_backpack:
		message = "Your backpack is still in the trunk. Open the rear hatch and collect it."
		return
	set_state("backpack")
