extends Node3D
## The supplied PSX arm rig retains its original guard and alternating jab clips.
const DAMAGE = 12.0
const REACH = 1.8
const HIT_TIME = 0.28
const RECOVERY = 0.70
var game
var weapons
var model: Node3D
var animation: AnimationPlayer
var clips = {}
var elapsed = -1.0
var struck = false
var right_hand = false
var raised = false

func _ready():
	model = preload("res://assets/arms/arms.glb").instantiate()
	game.camera.add_child(model)
	model.position = Vector3(0,-1.74,0)
	model.rotation.y = PI
	weapons.adapt(model)
	animation = model.find_child("AnimationPlayer",true,false)
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animation.speed_scale = 1.6
	for clip in animation.get_animation_list():
		clips[String(clip).get_slice("/",String(clip).get_slice_count("/")-1)] = clip
	animation.get_animation(clips.guard_idle).loop_mode = Animation.LOOP_LINEAR
	for clip in ["jab_L","jab_R"]:
		animation.get_animation(clips[clip]).loop_mode = Animation.LOOP_NONE
	animation.play(clips.guard_idle)
	animation.advance(0)
	reset()

func reset():
	raised = false
	elapsed = -1
	struck = false
	right_hand = false
	if animation:
		animation.play(clips.guard_idle)
		animation.advance(0)
	update_visual(0)

func attack() -> bool:
	if not raised: return false
	if game.state!="play" or weapons.selected>=0 or weapons.delay>0 or elapsed>=0: return false
	if game.crash_site.wake_phase!="": return false
	if game.grave_dig and game.grave_dig.digging: return false
	elapsed = 0
	struck = false
	right_hand = not right_hand
	animation.play(clips["jab_R" if right_hand else "jab_L"],0.06)
	animation.advance(0)
	weapons.delay = RECOVERY
	return true

func cancel():
	if elapsed>=0:
		elapsed = -1
		animation.play(clips.guard_idle,0.10)

func toggle():
	if game.state!="play" or game.crash_site.wake_phase!="": return
	if game.grave_dig and game.grave_dig.digging: return
	raised = not raised
	cancel()
	if raised:
		animation.play(clips.guard_draw,0.06)
		animation.queue(clips.guard_idle)
	update_visual(0)

func update(delta: float):
	if weapons.selected>=0:
		raised = false
		cancel()
	if game.state=="play":
		if elapsed>=0:
			elapsed += delta
			if elapsed>=HIT_TIME and not struck:
				struck = true
				strike()
			if elapsed>=RECOVERY:
				cancel()
		animation.advance(delta)
	update_visual(delta)

func update_visual(_delta: float):
	model.visible = raised and weapons.selected<0 and game.state in ["play","paused"] and game.crash_site.wake_phase==""
	# Fists occupy both hands; retain the beam without a floating held model.
	game.arm_visual.visible = weapons.selected<0 and not raised
	model.position.y = -1.74

func strike():
	# Resolve at contact time, so stepping away or moving behind a wall avoids it.
	var origin: Vector3 = game.camera.global_position
	var query = PhysicsRayQueryParameters3D.create(origin,origin-game.camera.global_basis.z*REACH,1,[game.player.get_rid()])
	var hit = game.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return
	var body = hit.collider as Node3D
	if body.is_in_group("HostileEnemies"):
		if game.enemies.shoot(int(body.get_meta("enemy_index")),DAMAGE):
			weapons.hit_feedback = 0.18
	elif body.has_meta("shooting_target"):
		body.set_meta("hits",int(body.get_meta("hits",0))+1)
		body.rotation.x = -0.25
		weapons.hit_feedback = 0.18
