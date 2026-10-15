extends Node2D

const WORLD = Vector2(2600, 2000)
const HOME = Vector2(1300, 1000)
var font = preload("res://assets/font.ttf")
var ground = preload("res://assets/forest.jpg")
var player = HOME
var trees: Array[Vector3] = []
var motes: Array[Vector2] = []
var parts: Array[Vector2] = [Vector2(350, 400), Vector2(2250, 500), Vector2(1850, 1700)]
var found: Array[bool] = [false, false, false]
var drones: Array[Vector2] = []
var stun: Array[float] = []
var clock = 0.0
var health = 100.0
var stamina = 100.0
var cooldown = 0.0
var pulse = 0.0
var invincible = 0.0
var contact_progress = 0.0
var state = "title"
var camera_pos = Vector2.ZERO
var message = "Find the scattered transmitter parts."
var facing = Vector2.DOWN
var audio: AudioStreamPlayer

func _ready():
	seed(83)
	for i in range(190):
		var p = Vector2(randf_range(60, 2540), randf_range(60, 1940))
		if p.distance_to(HOME) > 170 and p.distance_to(parts[0]) > 90 and p.distance_to(parts[1]) > 90 and p.distance_to(parts[2]) > 90:
			trees.append(Vector3(p.x, p.y, randf_range(0.8, 1.6)))
	for i in range(150):
		motes.append(Vector2(randf_range(0, WORLD.x), randf_range(0, WORLD.y)))
	reset_game()
	audio = AudioStreamPlayer.new()
	add_child(audio)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var samples = PackedByteArray()
	for i in range(22050 * 4):
		var t = float(i) / 22050.0
		var value = int((sin(t * TAU * 65.4) * 0.35 + sin(t * TAU * 98.0) * 0.15) * 2200)
		samples.append_array(PackedByteArray([value & 255, (value >> 8) & 255]))
	wav.data = samples
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = 22050 * 4
	audio.stream = wav
	audio.volume_db = -12
	audio.play()

func reset_game():
	player = HOME
	health = 100
	stamina = 100
	cooldown = 0
	contact_progress = 0
	found = [false, false, false]
	drones = [Vector2(600, 650), Vector2(1950, 450), Vector2(1800, 1450), Vector2(600, 1600)]
	stun = [0.0, 0.0, 0.0, 0.0]
	message = "Find the scattered transmitter parts."

func _unhandled_key_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER and state != "play":
			reset_game()
			state = "play"
		if event.keycode == KEY_ESCAPE:
			state = "title" if state == "play" else "play"
		if event.keycode == KEY_M:
			audio.stream_paused = not audio.stream_paused
		if event.keycode == KEY_SPACE and state == "play" and cooldown <= 0:
			cooldown = 6
			pulse = 1
			for i in range(drones.size()):
				if drones[i].distance_to(player) < 300:
					stun[i] = 3.5

func _process(delta):
	clock += delta
	if state == "play":
		var movement = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).normalized()
		var sprint = Input.is_physical_key_pressed(KEY_SHIFT) and stamina > 1 and movement.length() > 0
		stamina = clampf(stamina + (-24 if sprint else 17) * delta, 0, 100)
		var next = player + movement * (260 if sprint else 155) * delta
		for tree in trees:
			var diff = next - Vector2(tree.x, tree.y)
			if diff.length() < 19 * tree.z:
				next = Vector2(tree.x, tree.y) + diff.normalized() * 19 * tree.z
		player = next.clamp(Vector2(30, 30), WORLD - Vector2(30, 30))
		if movement.length() > 0:
			facing = movement
		cooldown = maxf(0, cooldown - delta)
		pulse = maxf(0, pulse - delta * 1.7)
		invincible = maxf(0, invincible - delta)
		for i in range(parts.size()):
			if not found[i] and player.distance_to(parts[i]) < 45:
				found[i] = true
				health = minf(100, health + 18)
				message = "Transmitter recovered. %d / 3" % found.count(true)
				if found.count(true) == 3:
					message = "Return to the clearing. Hold E to phone home."
		for i in range(drones.size()):
			stun[i] = maxf(0, stun[i] - delta)
			if stun[i] > 0:
				continue
			var diff = player - drones[i]
			if diff.length() < (420 if sprint else 290):
				drones[i] += diff.normalized() * 108 * delta
			else:
				drones[i] += Vector2(cos(clock * 0.4 + i * 2), sin(clock * 0.5 + i)) * 65 * delta
			drones[i] = drones[i].clamp(Vector2(60, 60), WORLD - Vector2(60, 60))
			if diff.length() < 36 and invincible <= 0:
				health -= 22
				invincible = 1.4
				message = "They found you! Use SPACE to repel the drones."
		if health <= 0:
			state = "lost"
		if found.count(true) == 3 and player.distance_to(HOME) < 110 and Input.is_physical_key_pressed(KEY_E):
			contact_progress += delta
			if contact_progress >= 4:
				state = "won"
		else:
			contact_progress = maxf(0, contact_progress - delta * 0.5)
	camera_pos = player - Vector2(640, 400)
	queue_redraw()

func label_at(text: String, pos: Vector2, size: int, color = Color("c8e2df")):
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func glow(pos: Vector2, radius: float, color: Color):
	for i in range(6, 0, -1):
		draw_circle(pos, radius * i / 3.0, Color(color, 0.025 * (7 - i)))

func _draw():
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 800)), Color("07151c"))
	draw_set_transform(-camera_pos)
	for x in range(0, 2600, 512):
		for y in range(0, 2000, 512):
			draw_texture_rect(ground, Rect2(x, y, 512, 512), false, Color(0.095, 0.19, 0.20))
	draw_rect(Rect2(Vector2.ZERO, WORLD), Color(0.015, 0.05, 0.08, 0.48))
	# The winding trail connects all three salvage sites.
	var trail = PackedVector2Array([parts[0], Vector2(700, 820), HOME, Vector2(1850, 850), parts[1], Vector2(2100, 1100), parts[2], Vector2(1250, 1550), HOME])
	draw_polyline(trail, Color(0.23, 0.31, 0.30, 0.18), 70, true)
	glow(HOME, 110, Color("62e8ca"))
	draw_arc(HOME, 95, 0, TAU, 80, Color("336e71"), 2, true)
	for i in range(12):
		var a = i * TAU / 12
		draw_line(HOME + Vector2.from_angle(a) * 92, HOME + Vector2.from_angle(a) * 102, Color("67a49b"), 2)
	label_at("LANDING CLEARING", HOME + Vector2(-75, 135), 17, Color("7cb9af"))
	for i in range(parts.size()):
		if not found[i]:
			var p = parts[i] + Vector2(0, sin(clock * 2 + i) * 5)
			glow(p, 35, Color("ffc57e"))
			draw_arc(p, 27, clock, clock + 4.8, 30, Color("ac8c60"), 1.5, true)
			draw_style_box(part_box(), Rect2(p - Vector2(13, 11), Vector2(26, 22)))
			draw_line(p + Vector2(-7, 0), p + Vector2(7, 0), Color("ffda99"), 3)
			label_at("0%d" % (i + 1), p + Vector2(-8, -36), 16, Color("e4b677"))
	for p in motes:
		var offset = Vector2(sin(clock * 0.5 + p.x), cos(clock * 0.6 + p.y)) * 12
		draw_circle(p + offset, 1.5, Color(0.5, 0.9, 0.73, 0.3 + sin(clock + p.x) * 0.2))
	for tree in trees:
		var p = Vector2(tree.x, tree.y)
		draw_circle(p + Vector2(13, 10), 33 * tree.z, Color(0, 0, 0, 0.22))
		draw_line(p, p + Vector2(0, -42 * tree.z), Color("142c31"), 9 * tree.z)
		for j in range(3):
			var base = p + Vector2(0, -j * 22 * tree.z)
			var w = (39 - j * 8) * tree.z
			draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(0, -66 * tree.z), base + Vector2(w, 0)]), Color("123137") if int(tree.x) % 2 == 0 else Color("102b32"))
			draw_line(base + Vector2(0, -60 * tree.z), base + Vector2(w * 0.8, -5), Color(0.15, 0.29, 0.29, 0.35), 1)
	for i in range(drones.size()):
		var p = drones[i]
		var col = Color("72dce3") if stun[i] > 0 else Color("f58c7f")
		glow(p, 38, col)
		if stun[i] <= 0:
			var angle = (player - p).angle() if player.distance_to(p) < 350 else clock * 0.7 + i
			draw_colored_polygon(PackedVector2Array([p, p + Vector2.from_angle(angle - 0.35) * 180, p + Vector2.from_angle(angle + 0.35) * 180]), Color(0.9, 0.57, 0.40, 0.065))
		draw_circle(p, 13, Color("27383f"))
		draw_line(p - Vector2(23, 0), p + Vector2(23, 0), col.darkened(0.4), 4)
		draw_circle(p, 5, col)
	glow(player, 32, Color("8bffd6"))
	if pulse > 0:
		draw_arc(player, (1 - pulse) * 300, 0, TAU, 100, Color(0.5, 1, 0.85, pulse), 4, true)
	if invincible <= 0 or int(clock * 12) % 2 == 0:
		draw_circle(player + Vector2(0, 12), 15, Color(0, 0, 0, 0.4))
		draw_style_box(alien_box(), Rect2(player + Vector2(-10, -3), Vector2(20, 24)))
		draw_circle(player + Vector2(-6, 20), 5, Color("70b5a0"))
		draw_circle(player + Vector2(6, 20), 5, Color("70b5a0"))
		draw_set_transform(player + Vector2(0, -12), 0, Vector2(1.35, 0.85))
		draw_circle(Vector2.ZERO, 14, Color("93cfad"))
		draw_circle(Vector2(-6, -1) + facing * 2, 4.8, Color("10282b"))
		draw_circle(Vector2(6, -1) + facing * 2, 4.8, Color("10282b"))
		draw_set_transform(-camera_pos)
	if contact_progress > 0:
		glow(HOME, 150 + contact_progress * 20, Color("b6ffdf"))
		draw_line(HOME, HOME + Vector2(0, -1000), Color(0.6, 1, 0.8, contact_progress * 0.1), 45 + contact_progress * 10)
	draw_set_transform(Vector2.ZERO)
	# Soft horizontal fog banks.
	for i in range(7):
		var y = fposmod(i * 151 + clock * 7, 950) - 75
		draw_rect(Rect2(0, y, 1280, 42), Color(0.36, 0.55, 0.6, 0.018))
	draw_rect(Rect2(0, 0, 1280, 105), Color(0.02, 0.06, 0.09, 0.91))
	label_at("FAR FROM HOME", Vector2(34, 42), 29, Color("e3eee4"))
	label_at("BLACKWOOD FOREST  /  02:17 AM", Vector2(35, 70), 14, Color("739494"))
	label_at("TRANSMITTER", Vector2(525, 33), 14, Color("739494"))
	for i in range(3):
		draw_circle(Vector2(541 + i * 38, 59), 9, Color("b5e8b5") if found[i] else Color("30434c"))
	label_at("VITALITY", Vector2(762, 34), 14, Color("739494"))
	draw_rect(Rect2(762, 49, 160, 5), Color("293c45"))
	draw_rect(Rect2(762, 49, health * 1.6, 5), Color("9bd3b4"))
	label_at("PULSE  " + ("READY" if cooldown <= 0 else "%.1fs" % cooldown), Vector2(1010, 38), 19, Color("b4d3ce"))
	draw_rect(Rect2(1010, 55, stamina * 1.7, 3), Color("739494"))
	draw_rect(Rect2(0, 739, 1280, 61), Color(0.02, 0.06, 0.09, 0.94))
	label_at(message, Vector2(34, 777), 21)
	label_at("WASD  move    SHIFT  sprint    SPACE  pulse", Vector2(790, 777), 17, Color("739494"))
	# Compact map with objective beacons.
	draw_rect(Rect2(1090, 567, 155, 142), Color(0.02, 0.07, 0.1, 0.85))
	label_at("SIGNAL MAP", Vector2(1103, 590), 13, Color("739494"))
	var origin = Vector2(1102, 600)
	draw_circle(origin + HOME * 0.05, 4, Color("73b9b0"))
	for i in range(3):
		if not found[i]:
			draw_circle(origin + parts[i] * 0.05, 3, Color("ebbb7a"))
	draw_circle(origin + player * 0.05, 3, Color("d6ffe1"))
	if found.count(true) == 3 and player.distance_to(HOME) < 110:
		label_at("HOLD E  /  PHONE HOME", Vector2(477, 650), 28, Color("d6ffe1"))
		draw_rect(Rect2(480, 667, contact_progress * 80, 4), Color("d6ffe1"))
	if state != "play":
		draw_rect(Rect2(0, 0, 1280, 800), Color(0.015, 0.045, 0.065, 0.88))
		label_at("A SMALL VISITOR. A VERY LONG WAY HOME.", Vector2(340, 225), 22, Color("83b4a6"))
		var title = "FAR FROM HOME" if state == "title" else ("YOU MADE CONTACT" if state == "won" else "SIGNAL LOST")
		label_at(title, Vector2(640 - font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 72).x / 2, 330), 72, Color("e1f0de"))
		var sub = "Your ship is gone. The forest is listening. Find a way back."
		if state == "won":
			sub = "Across the stars, someone heard you. You're going home."
		if state == "lost":
			sub = "The search drones caught your contact_progress. Try another route."
		label_at(sub, Vector2(640 - font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 23).x / 2, 390), 23)
		label_at("01   Follow the amber beacons. Collect all three parts.", Vector2(365, 460), 21)
		label_at("02   Stay clear of drones. Your pulse stuns them briefly.", Vector2(365, 497), 21)
		label_at("03   Return to the clearing. Hold E to call your ship.", Vector2(365, 534), 21)
		draw_style_box(part_box(), Rect2(470, 585, 340, 58))
		label_at("ENTER  /  " + ("BEGIN JOURNEY" if state == "title" else "PLAY AGAIN"), Vector2(510, 623), 25, Color("f1d1a0"))
		label_at("WASD / ARROWS    MOVE       SHIFT    SPRINT       SPACE    PULSE       M    SOUND", Vector2(270, 707), 16, Color("739494"))

func part_box() -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = Color("243a3b")
	box.border_color = Color("bda475")
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	return box

func alien_box() -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = Color("72ab90")
	box.set_corner_radius_all(9)
	return box

