extends Node3D
## One authored road scare. Animation pauses with menus and resets for a new journey.
const BASE = Vector3(-4.2,0.32,-31)
const FALL_SECONDS = 1.35
const SCREAM_LEAD = 0.65
const HIT_DAMAGE = 8.0
const REACTION_LINE = "WHOA, that could have killed me!"
var game
var tree: Node3D
var trunk_collision: CollisionShape3D
var sound: AudioStreamPlayer3D
var scream: AudioStreamPlayer3D
var fall_started = false
var hit_player = false
var last_player_position = Vector3.ZERO
var triggered = false
var landed = false
var reaction_shown = false
var elapsed = 0.0
var previous_z = 0.0
var shake_left = 0.0
var collision_pending = false
var stump: MeshInstance3D

func _ready():
	name = "FallingRoadPine"
	var forest = game.get_node("DetailedForest")
	tree = forest.place(forest.pine_scenes[0],BASE,Vector3.ONE,"RoadScareTree")
	# Move the existing forest asset into this event without inheriting random yaw.
	tree.reparent(self)
	tree.rotation = Vector3.ZERO
	var crown = MeshInstance3D.new()
	crown.mesh = forest.crowns[0]
	crown.material_override = forest.needle_material
	tree.add_child(crown)
	var body = StaticBody3D.new()
	body.name = "TrunkBody"
	tree.add_child(body)
	trunk_collision = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.22
	capsule.height = 8.5
	trunk_collision.shape = capsule
	trunk_collision.position.y = 4.25
	body.add_child(trunk_collision)
	stump = game.mesh_at(self,game.cylinder(0.31,0.23,0.34),Vector3(BASE.x,0.17,BASE.z),game.mat(Color("78634b")))
	sound = game.soundscape.spatial_voice(self,game.soundscape.stream("tree_fall_recorded"),-8,42)
	sound.unit_size = 8
	scream = game.soundscape.spatial_voice(self,load("res://assets/audio/tree_scream.mp3"),-12,45)
	scream.unit_size = 12
	scream.position = Vector3(-7,2,-30)
	reset()

func reset():
	hit_player = false
	last_player_position = game.player.position
	triggered = false
	fall_started = false
	landed = false
	reaction_shown = false
	elapsed = 0.0
	shake_left = 0.0
	collision_pending = false
	previous_z = game.player.position.z
	tree.rotation = Vector3.ZERO
	tree.position = BASE
	stump.visible = false
	trunk_collision.set_deferred("disabled",false)
	scream.stop()
	scream.stream_paused = false
	sound.stop()
	sound.stream_paused = false
	game.camera.h_offset = 0
	game.camera.v_offset = 0

func begin_fall():
	if triggered: return
	triggered = true
	scream.play()

func start_tree_motion():
	fall_started = true
	trunk_collision.set_deferred("disabled",true)
	stump.visible = true
	shake_left = 0.13
	sound.position = BASE+Vector3(0,1.5,0)
	sound.play()

func _physics_process(delta):
	var p: Vector3 = game.player.position
	var previous_p = last_player_position
	last_player_position = p
	var active: bool = game.state=="play"
	sound.stream_paused = not active
	scream.stream_paused = not active
	if not active:
		game.camera.h_offset = 0
		game.camera.v_offset = 0
		previous_z = p.z
		return
	# Cross the trigger toward town on the road, rather than firing from the cemetery or a menu.
	if not triggered and previous_z> -21 and p.z<= -21 and p.z> -26 and absf(p.x)<3.8:
		begin_fall()
	previous_z = p.z
	if not triggered: return
	elapsed += delta
	if elapsed<SCREAM_LEAD: return
	if not fall_started: start_tree_motion()
	var fall_elapsed = elapsed-SCREAM_LEAD
	if not landed:
		var previous_angle = tree.rotation.z
		var t = clampf(fall_elapsed/FALL_SECONDS,0,1)
		# A quick splinter, then accelerating weight; no camera turn or control lock.
		tree.rotation.z = -PI/2*pow(t,1.65)
		check_falling_hit(previous_angle,tree.rotation.z,previous_p,p)
		sound.position = BASE.lerp(Vector3(0,0.6,-31),t)
		if fall_elapsed>=FALL_SECONDS:
			landed = true
			collision_pending = true
			shake_left = 0.34
	else:
		var settle = fall_elapsed-FALL_SECONDS
		tree.rotation.z = -PI/2+0.025*sin(settle*28)*exp(-settle*12)
	# Never enable a fallen collider inside the player's capsule. The low trunk can be jumped.
	if collision_pending and (absf(p.z-BASE.z)>0.8 or p.x<BASE.x-0.7 or p.x>4.8 or p.y>0.65):
		trunk_collision.set_deferred("disabled",false)
		collision_pending = false
	shake_left = maxf(0,shake_left-delta)
	var strength = 0.018*minf(1,shake_left/0.16)
	game.camera.h_offset = sin(elapsed*103)*strength
	game.camera.v_offset = sin(elapsed*137)*strength*0.65
	if landed and not reaction_shown and fall_elapsed>=FALL_SECONDS+0.55 and game.health>0:
		reaction_shown = true
		shake_left = 0
		game.camera.h_offset = 0
		game.camera.v_offset = 0
		game.dialogue_name = "You"
		game.dialogue_text = REACTION_LINE
		game.set_state("dialogue")


func check_falling_hit(from_angle: float, to_angle: float, from_player: Vector3, to_player: Vector3):
	if hit_player or game.state!="play": return
	# Sweep both bodies so sprinting across the trunk between frames still counts.
	var samples = clampi(maxi(ceili(absf(to_angle-from_angle)/0.035),ceili(from_player.distance_to(to_player)/0.15)),1,96)
	var player_radius: float = game.player_collider.shape.radius
	var player_height: float = game.player_collider.shape.height
	for i in range(samples+1):
		var blend = float(i)/samples
		var angle = lerpf(from_angle,to_angle,blend)
		var axis = Vector3.UP.rotated(Vector3.FORWARD,-angle)
		var foot = from_player.lerp(to_player,blend)
		var nearest = Geometry3D.get_closest_points_between_segments(
			BASE+axis*0.22,BASE+axis*8.28,
			foot+Vector3.UP*player_radius,foot+Vector3.UP*(player_height-player_radius))
		if nearest[0].distance_squared_to(nearest[1])<=pow(0.22+player_radius,2):
			hit_player = true
			game.take_damage(HIT_DAMAGE,2)
			return
