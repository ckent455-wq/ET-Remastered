extends Node
## Sparse, single soft flashes with a delayed roll of distant thunder.
var game
var rng = RandomNumberGenerator.new()
var light: DirectionalLight3D
var active = false
var intensity = 0.0
var next_strike = 5.0
var flash_age = -1.0
var thunder_delay = -1.0
var bolt = PackedVector2Array()
var branch = PackedVector2Array()
const FLASH_DURATION = 0.9

func _ready():
	rng.randomize()
	light = DirectionalLight3D.new()
	light.name = "DistantTitleLightning"
	light.rotation_degrees = Vector3(-32,-35,0)
	light.light_color = Color("a5b9cd")
	light.light_energy = 0
	light.light_cull_mask = 1
	light.shadow_enabled = false
	game.add_child(light)

func strike():
	flash_age = 0
	thunder_delay = rng.randf_range(1.5,2.9)
	next_strike = rng.randf_range(12,21)
	var start = Vector2(rng.randf_range(460,585),18)
	bolt = PackedVector2Array([start])
	for i in range(1,6):
		bolt.append(start+Vector2(rng.randf_range(-15,15),i*15))
	branch = PackedVector2Array([bolt[2],bolt[2]+Vector2(19,11),bolt[2]+Vector2(28,28)])

func clear():
	intensity = 0
	flash_age = -1
	thunder_delay = -1
	light.light_energy = 0
	game.soundscape.thunder.stop()

func _process(delta):
	if game.state!="title":
		if active:
			clear()
		active = false
		return
	delta = minf(delta,0.1)
	if not active:
		active = true
		next_strike = rng.randf_range(4,7)
	next_strike -= delta
	if next_strike<=0:
		strike()
	if flash_age>=0:
		flash_age += delta
		intensity = sin(clampf(flash_age/FLASH_DURATION,0,1)*PI)*0.7
		if flash_age>=FLASH_DURATION:
			flash_age = -1
			intensity = 0
	light.light_energy = intensity*0.65
	if thunder_delay>=0:
		thunder_delay -= delta
		if thunder_delay<=0:
			thunder_delay = -1
			game.soundscape.thunder.pitch_scale = rng.randf_range(0.88,1.02)
			game.soundscape.thunder.volume_db = rng.randf_range(-24,-21)
			game.soundscape.thunder.play()
