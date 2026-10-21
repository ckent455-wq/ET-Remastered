extends Node
## Sparse, single soft flashes with a delayed roll of distant thunder.
var game
var rng = RandomNumberGenerator.new()
var light: DirectionalLight3D
var window_glows:Node3D
var windows:Array[Dictionary]=[]
var window_clock=0.0
var next_window_change=5.0
var lit_window_order:Array[int]=[]
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
	build_window_glows()

func build_window_glows():
	window_glows=Node3D.new()
	window_glows.name="TitleWindowLights"
	game.add_child(window_glows)
	for room in ["house","ranger","workshop"]:
		var mount=Node3D.new()
		window_glows.add_child(mount)
		mount.transform=game.town.buildings[room].transform
		var offsets=[-4.3,-2.15,0.0,2.15,4.3] if room=="house" else [0.0]
		for x in offsets:add_window_glow(mount,x,4.35 if room=="house" else 4.15,5.0)
	# Match the three sash windows on each hotel side wall.
	for side in [-1,1]:
		var hotel_mount=Node3D.new()
		window_glows.add_child(hotel_mount)
		hotel_mount.transform=game.town.buildings.house.transform
		var wall=Node3D.new()
		hotel_mount.add_child(wall)
		wall.position.x=side*6.0
		wall.rotation.y=side*PI/2
		for x in [-2.7,0.0,2.7]:add_window_glow(wall,x,4.35,0.0)
	var first=rng.randi_range(0,4)
	lit_window_order.append(first)
	windows[first].on=true
	windows[first].level=0.72
	window_glows.hide()

func add_window_glow(mount:Node3D,x:float,base:float,front:float):
	var material=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled=true
	material.disable_fog=true
	material.emission=Color(0.8,0.65,0.28)
	material.emission_energy_multiplier=0.0
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color=Color(0.68,0.57,0.29,0.0)
	var glow=game.town.box(mount,Vector3(x,base+0.82,front+0.108),Vector3(1.12,1.63,0.008),material,false)
	glow.hide()
	var spill=game.town.lamp(mount,Vector3(x,base+0.85,front+0.38),Color(1.0,0.78,0.36),0.048,1.9)
	spill.shadow_enabled=false
	windows.append({"material":material,"spill":spill,"wait":rng.randf_range(3.0,9.0),"on":false,"level":0.0,"glow":glow,"flicker":-1.0})

func update_window_glows(delta):
	var show_windows=game.state in ["intro","title"]
	window_glows.visible=show_windows
	if not show_windows:return
	window_clock+=delta
	next_window_change-=delta
	if next_window_change<=0:
		next_window_change=rng.randf_range(5.0,9.0)
		var candidates:Array[int]=[]
		for i in range(windows.size()):
			if not windows[i].on:candidates.append(i)
		if not candidates.is_empty():
			if lit_window_order.size()>=2:
				var oldest=lit_window_order.pop_front()
				windows[oldest].on=false
			var chosen=candidates[rng.randi_range(0,candidates.size()-1)]
			windows[chosen].on=true
			lit_window_order.append(chosen)
	for window in windows:

		var target=0.72 if window.on else 0.0
		window.level=target

		window.glow.visible=window.level>0.001
		window.material.albedo_color=Color(0.68,0.57,0.29,window.level)
		window.material.emission_energy_multiplier=0.30*window.level
		window.spill.light_energy=0.17*window.level

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
	update_window_glows(minf(delta,0.1))
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
