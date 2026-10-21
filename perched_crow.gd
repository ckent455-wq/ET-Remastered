extends Node3D
## The user's Living Birds crow, perched on the entrance sign.
var game
var model: Node3D
var animation: AnimationPlayer
var voice: AudioStreamPlayer3D
var calls: Array[AudioStream] = []
var rng = RandomNumberGenerator.new()
var greeted = false
var call_timer = 0.0
var idle_timer = 5.0
var calls_played = 0
var dead = false
var death_time = 0.0
var death_start = Vector3.ZERO
var death_end = Vector3.ZERO
var hit_shape: CollisionShape3D
var flight_state = "perched"
var flight_time = 0.0
var away_timer = 0.0
var flight_start = Vector3.ZERO
var flight_end = Vector3.ZERO
var flight_control_a = Vector3.ZERO
var flight_control_b = Vector3.ZERO
var landing_rotation = Quaternion.IDENTITY
const SCARE_DISTANCE = 3.3
const RETURN_CLEARANCE = 7.0
const FLIGHT_SECONDS = 3.8
const PERCH_POSITION = Vector3(-0.73,1.96,0.02)

func _ready():
	name = "BlackwoodSignCrow"
	position = PERCH_POSITION
	rotation.y = -0.65
	rng.seed = 72317
	model = preload("res://assets/crow/models/crow.fbx").instantiate()
	model.scale = Vector3.ONE*2.2
	model.position.y = -0.002
	add_child(model)
	prepare_materials(model)
	animation = AnimationPlayer.new()
	model.add_child(animation)
	animation.add_animation_library("",preload("res://assets/crow/perch_animations.res"))
	animation.animation_finished.connect(animation_finished)
	animation.play("watch")
	animation.advance(0)
	voice = AudioStreamPlayer3D.new()
	voice.name = "SignCrowCalls"
	voice.bus = game.soundscape.BUS
	voice.volume_db = -4
	voice.unit_size = 12
	voice.max_distance = 36
	voice.attenuation_filter_cutoff_hz = 10000
	add_child(voice)
	calls.append(preload("res://assets/crow/crow_1.wav"))
	calls.append(preload("res://assets/crow/crow_2.wav"))
	var hitbox = StaticBody3D.new()
	hitbox.name = "CrowHitbox"
	hitbox.add_to_group("CrowTargets")
	add_child(hitbox)
	hit_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.28,0.46,0.60)
	hit_shape.shape = shape
	hit_shape.position = Vector3(0,0.235,-0.09)
	hitbox.add_child(hit_shape)
	reset()

func prepare_materials(node: Node):
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in range(node.mesh.get_surface_count()):
			var material = StandardMaterial3D.new()
			material.albedo_texture = preload("res://assets/crow/Materials-Textures/crowDiffuse.png")
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			material.roughness = 1
			material.metallic_specular = 0
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			node.set_surface_override_material(surface,material)
	for child in node.get_children():
		prepare_materials(child)

func reset():
	dead = false
	flight_state = "perched"
	flight_time = 0
	away_timer = 0
	model.show()
	death_time = 0
	position = PERCH_POSITION
	rotation = Vector3(0,-0.65,0)
	hit_shape.set_deferred("disabled",false)
	animation.stop()
	model.get_node("Skeleton3D").reset_bone_poses()
	greeted = false
	calls_played = 0
	call_timer = 0
	idle_timer = 5
	voice.stop()
	voice.stream_paused = false
	animation.speed_scale = 1
	animation.play("watch")
	animation.seek(0,true)

func caw():
	if game.state not in ["play","title","intro"] or dead or flight_state!="perched" or voice.playing:
		return
	voice.stream = calls[calls_played%calls.size()]
	voice.pitch_scale = rng.randf_range(0.94,1.02)
	voice.play()
	calls_played += 1
	animation.play("call",0.12)
	call_timer = rng.randf_range(18,30)
	idle_timer = rng.randf_range(5,9)

func animation_finished(clip: StringName):
	if not dead and flight_state=="perched" and clip!="watch":
		animation.play("watch",0.18)

func _process(delta):
	var menu = game.state in ["title","intro"]
	var active = game.state=="play" or menu
	animation.speed_scale = 1 if active else 0
	voice.stream_paused = game.state not in ["play","dialogue","title","intro"]
	if dead:
		if active:
			death_time = minf(death_time+delta,1.2)
			var fall = clampf((death_time-0.3)/0.85,0,1)
			global_position = death_start.lerp(death_end,fall*fall)
		return
	if not active:
		return
	if menu:
		# The title crow stays on the sign even if an old play session left it flying.
		if flight_state!="perched":
			flight_state="perched";flight_time=0;away_timer=0
			position=PERCH_POSITION;rotation=Vector3(0,-0.65,0)
			model.show();hit_shape.set_deferred("disabled",false)
			animation.play("watch",0.18)
	elif update_flight(delta):
		return
	var distance = 8.0 if menu else game.player.global_position.distance_to(global_position)
	if distance>36:
		return
	call_timer = maxf(0,call_timer-delta)
	idle_timer = maxf(0,idle_timer-delta)
	if distance<18 and (not greeted or call_timer<=0):
		greeted = true
		caw()
	elif idle_timer<=0 and animation.current_animation=="watch":
		animation.play("ruffle",0.15)
		idle_timer = rng.randf_range(6,11)

func shoot() -> bool:
	if dead or flight_state=="away" or game.state!="play":
		return false
	dead = true
	death_time = 0
	death_start = global_position
	death_end = death_start+get_parent().global_basis.z*0.5+Vector3(-0.12,0,0)
	death_end.y = 0.10
	voice.stop()
	hit_shape.set_deferred("disabled",true)
	animation.play("die",0.05)
	game.achievements.unlock(game.achievements.CROW_ID,game.achievements.CROW_TITLE)
	return true

func perch_global() -> Vector3:
	return get_parent().to_global(PERCH_POSITION)

func player_perch_distance() -> float:
	var difference = game.player.global_position-perch_global()
	if absf(difference.y)>4.5:
		return INF
	return Vector2(difference.x,difference.z).length()

func take_flight():
	flight_state = "outbound"
	flight_time = 0
	flight_start = global_position
	# Escape above the open approach road rather than through the buildings.
	flight_end = Vector3(0,15,-10)
	flight_control_a = Vector3(-3,perch_global().y+0.8,perch_global().z+0.5) if flight_start.distance_to(perch_global())<6 else flight_start+(flight_end-flight_start)*0.3+Vector3.UP*2
	flight_control_b = Vector3(0,8,-20)
	voice.stop()
	animation.play("fly",0.12)
	model.show()
	hit_shape.set_deferred("disabled",false)

func begin_return():
	flight_state = "inbound"
	flight_time = 0
	flight_start = global_position
	flight_end = perch_global()
	flight_control_a = Vector3(0,8,-20)
	flight_control_b = Vector3(-3,flight_end.y+0.8,flight_end.z+0.5)
	model.show()
	hit_shape.set_deferred("disabled",false)
	animation.play("fly",0.12)

func update_flight(delta: float) -> bool:
	var clearance = player_perch_distance()
	if flight_state in ["perched","inbound","landing"] and clearance<SCARE_DISTANCE:
		take_flight()
	if flight_state=="perched":
		return false
	if flight_state=="away":
		away_timer = maxf(0,away_timer-delta)
		if away_timer<=0 and clearance>RETURN_CLEARANCE:
			begin_return()
		return true
	if flight_state=="landing":
		flight_time += delta
		var turn = smoothstep(0,animation.get_animation("landing").length,flight_time)
		quaternion = landing_rotation.slerp(Quaternion.from_euler(Vector3(0,-0.65,0)),turn)
		if flight_time>=animation.get_animation("landing").length:
			flight_state = "perched"
			position = PERCH_POSITION
			rotation = Vector3(0,-0.65,0)
			animation.play("watch",0.18)
			call_timer = 3.0
			idle_timer = 10
		return true
	flight_time = minf(flight_time+delta,FLIGHT_SECONDS)
	var t = flight_time/FLIGHT_SECONDS
	var before = global_position
	var a = flight_start.lerp(flight_control_a,t)
	var b = flight_control_a.lerp(flight_control_b,t)
	var c = flight_control_b.lerp(flight_end,t)
	global_position = a.lerp(b,t).lerp(b.lerp(c,t),t)
	var direction = global_position-before
	if direction.length_squared()>0.000001:
		look_at(global_position+direction,Vector3.UP,true)
	if t>=1:
		if flight_state=="outbound":
			flight_state = "away"
			away_timer = rng.randf_range(24,36)
			model.hide()
			voice.stop()
			hit_shape.set_deferred("disabled",true)
		else:
			flight_state = "landing"
			flight_time = 0
			position = PERCH_POSITION
			landing_rotation = quaternion
			animation.play("landing",0.12)
	return true
