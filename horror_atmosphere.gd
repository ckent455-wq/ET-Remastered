extends Node
## Quiet, contextual accents from the user's Horror SFX Free download.
var game
var soundscape
var bed: AudioStreamPlayer
var radio: AudioStreamPlayer3D
var accent: AudioStreamPlayer3D
var cues = {}
var event_timer = 35.0
var entered_town = false
var visited_interiors = {}
var current_interior = ""
var last_cue = ""
var events_played = 0

func _ready():
	bed = soundscape.voice(soundscape.stream("horror/eerie_bed",true),-42)
	radio = soundscape.spatial_voice(game,soundscape.stream("horror/radio_static",true),-25,12)
	radio.unit_size = 2
	accent = soundscape.spatial_voice(game,soundscape.stream("horror/house_creak"),-22,38)
	accent.unit_size = 4
	for cue in ["house_creak","distant_call","metal_moan","bell","glass_tap"]:
		cues[cue] = soundscape.stream("horror/"+cue)
	bed.play()
	radio.play()
	reset()

func reset():
	event_timer = soundscape.rng.randf_range(30,45)
	entered_town = false
	visited_interiors.clear()
	current_interior = ""
	last_cue = ""
	events_played = 0
	accent.stop()
	bed.volume_db = -42

func interior_id() -> String:
	if game.town.streetscape.church and game.town.streetscape.church.contains(game.player.global_position):
		return "church"
	for data in game.town.BUILDINGS:
		if game.town.player_inside_building(data.id):
			return data.id
	return ""

func play_accent(cue: String, p: Vector3, volume: float):
	if accent.playing:
		return
	accent.stream = cues[cue]
	accent.global_position = p
	accent.pitch_scale = soundscape.rng.randf_range(0.94,1.02)
	accent.volume_db = volume
	accent.max_distance = 85 if cue=="bell" else 38
	accent.unit_size = 14 if cue=="bell" else 4
	accent.play()
	last_cue = cue
	events_played += 1

func update_sound(delta: float):
	var active = game.state=="play"
	var title = game.state=="title"
	bed.stream_paused = not (active or title)
	radio.stream_paused = not active
	if not active:
		accent.stop()
		if title:
			bed.volume_db = lerpf(bed.volume_db,-37,clampf(delta*0.7,0,1))
		return
	current_interior = interior_id()
	radio.global_position = game.town.actions.receiver.area.global_position
	var indoors = not current_interior.is_empty()
	bed.volume_db = lerpf(bed.volume_db,-30 if indoors else -34,clampf(delta*0.6,0,1))
	radio.volume_db = -39 if game.town.radio_ready else -25
	if indoors and not visited_interiors.has(current_interior):
		visited_interiors[current_interior] = true
		event_timer = minf(event_timer,soundscape.rng.randf_range(8,15))
	if not entered_town and game.player.position.z< -38:
		entered_town = true
		play_accent("bell",game.town.streetscape.church.global_position+Vector3(0,12,0),-21)
		event_timer = soundscape.rng.randf_range(35,55)
	event_timer -= delta
	if event_timer>0 or accent.playing:
		return
	if indoors:
		var cue = "house_creak" if last_cue!="house_creak" else "glass_tap"
		var anchor = game.town.streetscape.church if current_interior=="church" else game.town.buildings[current_interior]
		play_accent(cue,anchor.to_global(Vector3(3,2,-3)),-24)
	else:
		var cue = "metal_moan" if last_cue=="distant_call" or soundscape.rng.randf()<0.7 else "distant_call"
		var angle = soundscape.rng.randf_range(0,TAU)
		var p = game.player.global_position+Vector3(cos(angle)*17,2,sin(angle)*17)
		play_accent(cue,p,-23 if cue=="metal_moan" else -26)
	event_timer = soundscape.rng.randf_range(32,58)
