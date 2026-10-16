extends Node3D
const START_POSITION = Vector3(-0.7,0.001,16.8)
const START_YAW = -0.60
var player: CharacterBody3D
var camera: Camera3D
var title_camera: Camera3D
var title_weather: Node
var flashlight: SpotLight3D
var hud: Control
var achievements: Node
var health = 100.0
var stamina = 100.0
var invincible = 0.0
var contact_progress = 0.0
var clock = 0.0
var state = "intro"
var intro_elapsed = 0.0
var message = "Explore Blackwood and speak to its remaining townspeople."
var dialogue_name = ""
var dialogue_text = ""
var pitch = 0.0
var crash_site: Node3D
var soundscape: Node
var arm_visual: Node3D
var weapons: Node3D
var town: Node3D
var fog_atmosphere: Node3D
var distant_landscape: Node3D
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
	var plane = BoxMesh.new()
	plane.size = Vector3(140,0.6,180)
	mesh_at(ground,plane,Vector3(0,-0.3,-25),ground_mat)
	var collision = CollisionShape3D.new()
	var ground_shape = BoxShape3D.new()
	ground_shape.size = plane.size
	collision.shape = ground_shape
	collision.position = Vector3(0,-0.3,-25)
	ground.add_child(collision)
	var forest = Node3D.new()
	forest.set_script(preload("res://forest.gd"))
	add_child(forest)
	player = CharacterBody3D.new()
	player.floor_snap_length = 0.15
	add_child(player)
	var col = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.5
	col.shape = capsule
	col.position.y = 0.75
	player.add_child(col)
	camera = Camera3D.new()
	camera.position.y = 1.25
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
	update_camera()

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
	achievements.clear_toast()
	player.position = START_POSITION
	player.velocity = Vector3.ZERO
	camera.position.y = 1.25
	player.rotation = Vector3(0,START_YAW,0)
	camera.rotation = Vector3.ZERO
	pitch = 0
	health = 100
	stamina = 100
	contact_progress = 0
	invincible = 0
	flashlight_charge = START_FLASHLIGHT_CHARGE
	flashlight.visible = true
	flashlight_raise = 1.0
	flashlight_model.position = FLASHLIGHT_UP
	flashlight_model.rotation = Vector3.ZERO
	flashlight_model.visible = true
	journal_page = 0
	message = "Your car is wrecked. Follow the road into Blackwood and find help."
	soundscape.reset()
	town.reset()
	weapons.reset()

func set_state(next: String):
	state = next
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if state=="play" else Input.MOUSE_MODE_VISIBLE
	update_camera()

func update_camera():
	if title_camera==null:
		return
	var active_camera = title_camera if state in ["intro","title"] else camera
	if not active_camera.current:
		active_camera.make_current()

func _unhandled_input(event):
	if state=="title" and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		hud.controls_open = false
		return
	if state=="intro":
		if event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER,KEY_SPACE,KEY_ESCAPE]:
			set_state("title")
		return
	if state=="dialogue":
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_E,KEY_ENTER,KEY_ESCAPE,KEY_TAB]:
			set_state("play")
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
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ENTER and state!="play":
			if state not in ["paused","journal"]:
				reset_game()
			set_state("play")
		elif event.keycode==KEY_ESCAPE:
			set_state("paused" if state=="play" else "play")
		if event.keycode==KEY_TAB and state in ["play","journal"]:
			journal_page = 0
			set_state("journal" if state=="play" else "play")
		if state=="journal" and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_A,KEY_D]:
			journal_page = wrapi(journal_page+(-1 if event.keycode in [KEY_LEFT,KEY_A] else 1),0,town.journal_entries.size()+2)
		if event.keycode==KEY_M:
			soundscape.toggle_mute()
		if event.keycode==KEY_F and state=="play":
			toggle_flashlight()
			soundscape.flashlight_click(flashlight.visible)
		if state=="play" and event.keycode==KEY_E:
			town.interact()
		if state=="play" and event.keycode==KEY_H:
			town.use_medkit()
		if state=="play" and event.keycode==KEY_Q:
			town.use_battery()
		if state=="play" and event.keycode in [KEY_0,KEY_1,KEY_2,KEY_3]:
			weapons.equip({KEY_0:-1,KEY_1:0,KEY_2:1,KEY_3:2}[event.keycode])
		if state=="play" and event.keycode==KEY_R:
			weapons.reload()

func _physics_process(delta):
	clock += delta
	if state!="play":
		hud.queue_redraw()
		return
	var movement = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).normalized()
	var sprint = Input.is_physical_key_pressed(KEY_SHIFT) and stamina>1 and movement.length()>0
	stamina = clampf(stamina+(-24 if sprint else 17)*delta,0,100)
	var vertical_speed = 0.0 if player.is_on_floor() else player.velocity.y-18.0*delta
	player.velocity = player.basis*Vector3(movement.x,0,movement.y)*(8.0 if sprint else 4.6)
	# Floor snapping maintains contact without forcing the capsule into the floor.
	player.velocity.y = vertical_speed
	var previous_position = player.position
	player.move_and_slide()
	# The shared world floor is flat at y=0. Prevent corner recovery from
	# sinking the capsule into that plane and bouncing it back next frame.
	if player.position.y<0.001 and not town.streetscape.church.basement.contains(player.global_position):
		player.position.y = 0.001
		player.velocity.y = 0.0
	player.position.x = clampf(player.position.x,-60,60)
	player.position.z = clampf(player.position.z,-160,47)
	var travelled = Vector2(player.position.x-previous_position.x,player.position.z-previous_position.z).length()
	soundscape.moved(travelled,sprint,player.is_on_floor())
	# Keep the view fixed, including when movement is blocked by furniture.
	camera.position.y = 1.25
	invincible = maxf(0,invincible-delta)
	update_flashlight_battery(delta)
	if health<=0:
		set_state("lost")
	town.update_arrival()
	town.refresh_focus()
	update_contact(delta,Input.is_physical_key_pressed(KEY_E))
	hud.queue_redraw()

func update_contact(delta: float, held: bool):
	if state!="play":
		return
	if rescue_available() and held:
		contact_progress += delta
		if contact_progress>=4:
			set_state("won")
	else:
		contact_progress = maxf(0,contact_progress-delta*0.5)

func rescue_available() -> bool:
	return town.radio_ready and town.player_inside_building("radio") and camera.global_position.distance_to(town.actions.receiver.area.global_position)<3.2

func _process(delta):
	update_camera()
	update_flashlight_visual(delta)
	if state=="intro":
		# Give the presentation its full screen time even after cold shader compilation.
		intro_elapsed += minf(delta,0.1)
		if intro_elapsed>=3.6:
			set_state("title")

func update_flashlight_visual(delta: float):
	if state!="play":
		return
	var wanted = 1.0 if flashlight.visible and weapons.selected<0 else 0.0
	flashlight_raise = move_toward(flashlight_raise,wanted,delta/FLASHLIGHT_ANIMATION_SECONDS)
	var eased = smoothstep(0.0,1.0,flashlight_raise)
	flashlight_model.position = FLASHLIGHT_DOWN.lerp(FLASHLIGHT_UP,eased)
	flashlight_model.rotation = Vector3(-0.28,0,0.06)*(1.0-eased)
	flashlight_model.visible = flashlight_raise>0.001

func toggle_flashlight():
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
