extends Node3D
const HOME = Vector3.ZERO
var player: CharacterBody3D
var camera: Camera3D
var flashlight: SpotLight3D
var hud: Control
var health = 100.0
var stamina = 100.0
var cooldown = 0.0
var pulse = 0.0
var invincible = 0.0
var contact_progress = 0.0
var clock = 0.0
var state = "intro"
var intro_elapsed = 0.0
var message = "Explore Blackwood and speak to its remaining townspeople."
var dialogue_name = ""
var dialogue_text = ""
var pitch = 0.0
var beam: MeshInstance3D
var soundscape: Node
var town: Node3D
var flashlight_charge = 100.0
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
	env.background_color = Color("172b37")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("879fa9")
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color("2b444e")
	env.fog_light_energy = 0.7
	env.fog_density = 0.024
	world.environment = env
	add_child(world)
	var moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48,-35,0)
	moon.light_color = Color("a1b6d0")
	moon.light_energy = 0.7
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
	var stone = mat(Color("596a6b"))
	for i in range(12):
		var a = i*TAU/12
		mesh_at(self,cylinder(0.22,0.18,0.5),Vector3(cos(a)*5,0.25,sin(a)*5),mat(Color("63978d"),null,0.5))
	mesh_at(self,cylinder(1.2,1.2,0.12,12),Vector3(0,0.06,0),mat(Color("344f52")))
	mesh_at(self,cylinder(0.35,0.20,0.7),Vector3(0,0.45,0),stone)
	var beam_mat = mat(Color("82e6c5"),null,0.8)
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.albedo_color.a = 0.15
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam = mesh_at(self,cylinder(0.7,2,45),Vector3(0,22.5,0),beam_mat)
	beam.visible = false
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
	flashlight.spot_range = 24
	flashlight.spot_angle = 39
	flashlight.position = Vector3(0.15,-0.15,0)
	camera.add_child(flashlight)
	var hand = mesh_at(camera,cylinder(0.055,0.045,0.48),Vector3(0.30,-0.35,-0.45),mat(Color("7eaa8c")))
	hand.rotation_degrees = Vector3(-65,0,0)
	var palm = SphereMesh.new()
	palm.radius = 0.07
	palm.height = 0.12
	palm.radial_segments = 8
	palm.rings = 4
	mesh_at(camera,palm,Vector3(0.30,-0.23,-0.69),mat(Color("8bb99a")))
	for i in range(3):
		var finger = mesh_at(camera,cylinder(0.018,0.012,0.14,5),Vector3(0.25+i*0.05,-0.17,-0.73),mat(Color("8bb99a")))
		finger.rotation_degrees.x = -30
	var canvas = CanvasLayer.new()
	add_child(canvas)
	hud = Control.new()
	hud.set_script(load("res://hud.gd"))
	hud.game = self
	canvas.add_child(hud)
	make_audio()
	town = Node3D.new()
	town.set_script(preload("res://town.gd"))
	town.game = self
	add_child(town)
	reset_game()

func make_audio():
	soundscape = Node.new()
	soundscape.set_script(preload("res://soundscape.gd"))
	soundscape.game = self
	add_child(soundscape)

func reset_game():
	player.position = Vector3(0,0.1,4)
	player.velocity = Vector3.ZERO
	camera.position.y = 1.25
	player.rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	pitch = 0
	health = 100
	stamina = 100
	cooldown = 0
	contact_progress = 0
	invincible = 0
	flashlight_charge = 100
	flashlight.visible = true
	journal_page = 0
	message = "Explore Blackwood. TAB opens your journal and objectives."
	beam.visible = false
	soundscape.reset()
	town.reset()

func set_state(next: String):
	state = next
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if state=="play" else Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event):
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
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
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
			flashlight.visible = not flashlight.visible and flashlight_charge>0
			soundscape.flashlight_click(flashlight.visible)
		if state=="play" and event.keycode==KEY_E:
			town.interact()
		if state=="play" and event.keycode==KEY_H:
			town.use_medkit()
		if state=="play" and event.keycode==KEY_Q:
			town.use_battery()
		if event.keycode==KEY_SPACE and state=="play":
			activate_pulse()

func activate_pulse():
	if cooldown>0:
		return
	cooldown = 6
	pulse = 1

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
	if player.position.y<0.001:
		player.position.y = 0.001
		player.velocity.y = 0.0
	player.position.x = clampf(player.position.x,-60,60)
	player.position.z = clampf(player.position.z,-100,47)
	var travelled = Vector2(player.position.x-previous_position.x,player.position.z-previous_position.z).length()
	soundscape.moved(travelled,sprint,player.is_on_floor())
	# Keep the view fixed, including when movement is blocked by furniture.
	camera.position.y = 1.25
	cooldown = maxf(0,cooldown-delta)
	pulse = maxf(0,pulse-delta*1.6)
	invincible = maxf(0,invincible-delta)
	if flashlight.visible:
		flashlight_charge = maxf(0,flashlight_charge-delta*0.22)
		if flashlight_charge<=0:
			flashlight.visible = false
	if health<=0:
		set_state("lost")
	update_contact(delta,Input.is_physical_key_pressed(KEY_E))
	town.refresh_focus()
	hud.queue_redraw()

func update_contact(delta: float, held: bool):
	if state!="play":
		return
	if town.radio_ready and player.position.distance_to(HOME)<5.5 and held:
		contact_progress += delta
		if contact_progress>=4:
			set_state("won")
	else:
		contact_progress = maxf(0,contact_progress-delta*0.5)

func _process(delta):
	if state=="intro":
		# Give the presentation its full screen time even after cold shader compilation.
		intro_elapsed += minf(delta,0.1)
		if intro_elapsed>=3.6:
			set_state("title")
