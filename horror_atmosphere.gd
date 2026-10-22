extends Node
## Quiet, contextual accents from the user's Horror SFX Free download.
var game
var soundscape
var bed: AudioStreamPlayer
var radio: AudioStreamPlayer3D
var radio_voices: AudioStreamPlayer3D
var voice_timer = 0.0
var voice_dropout = false
var voice_pitch = 0.85
const VOICE_BUS = "RadioVoices"
var owns_voice_bus = false
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
	var station_static = load("res://assets/audio/radio_building_static.mp3").duplicate() as AudioStreamMP3
	station_static.loop = true
	radio = soundscape.spatial_voice(game,station_static,-60,18)
	radio.unit_size = 3
	radio.max_db = -6
	if AudioServer.get_bus_index(VOICE_BUS)<0:
		AudioServer.add_bus()
		var bus = AudioServer.bus_count-1
		AudioServer.set_bus_name(bus,VOICE_BUS)
		AudioServer.set_bus_send(bus,soundscape.BUS)
		var band = AudioEffectBandPassFilter.new()
		band.cutoff_hz = 1350
		band.resonance = 0.65
		AudioServer.add_bus_effect(bus,band)
		var distortion = AudioEffectDistortion.new()
		distortion.mode = AudioEffectDistortion.MODE_OVERDRIVE
		distortion.drive = 0.35
		distortion.post_gain = -5
		AudioServer.add_bus_effect(bus,distortion)
		owns_voice_bus = true
	radio_voices = soundscape.spatial_voice(game,soundscape.stream("radio_conspiracy_voices",true),-60,18)
	radio_voices.bus = VOICE_BUS
	radio_voices.unit_size = 3
	radio_voices.max_db = -9
	accent = soundscape.spatial_voice(game,soundscape.stream("horror/house_creak"),-22,38)
	accent.unit_size = 4
	for cue in ["house_creak","distant_call","metal_moan","bell","glass_tap"]:
		cues[cue] = soundscape.stream("horror/"+cue)
	bed.play()
	radio.play()
	radio_voices.play()
	reset()

func reset():
	event_timer = soundscape.rng.randf_range(30,45)
	entered_town = false
	visited_interiors.clear()
	current_interior = ""
	last_cue = ""
	events_played = 0
	voice_timer = 0.0
	voice_dropout = false
	voice_pitch = 0.85
	radio_voices.volume_db = -60
	radio.volume_db = -60
	accent.stop()
	bed.volume_db = -42

func interior_id() -> String:
	if game.hotel_basement and game.hotel_basement.contains(game.player.global_position): return "house"
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
	var active = game.state in ["play","dialogue"]
	var title = game.state=="title"
	bed.stream_paused = not (active or title)
	# MAIN ISOLATOR breaks the powered return loop feeding the anomalous station set.
	radio.stream_paused = not active or (game.story!=null and game.story.repeater_is_off())
	radio_voices.stream_paused = not active or (game.story!=null and game.story.repeater_is_off())
	if not active:
		accent.stop()
		if title:
			bed.volume_db = lerpf(bed.volume_db,-37,clampf(delta*0.7,0,1))
		return
	current_interior = interior_id()
	radio.global_position = game.town.actions.receiver.area.global_position
	var indoors = not current_interior.is_empty()
	bed.volume_db = lerpf(bed.volume_db,-30 if indoors else -34,clampf(delta*0.6,0,1))
	# The receiver is the source: approach brings up both level and harsh high frequencies.
	var distance = game.camera.global_position.distance_to(radio.global_position)
	var proximity = 1.0-smoothstep(0.8,12.0,distance)
	var target_volume = lerpf(-28.0,-8.0,proximity) if current_interior=="radio" else -60.0
	radio.volume_db = lerpf(radio.volume_db,target_volume,1.0-exp(-delta*5.0))
	radio.pitch_scale = lerpf(0.90,1.06,proximity)
	radio.attenuation_filter_cutoff_hz = lerpf(1800.0,18000.0,proximity)
	radio_voices.global_position = radio.global_position
	if not radio.stream_paused and current_interior=="radio":
		voice_timer -= delta
		if voice_timer<=0:
			voice_dropout = not voice_dropout
			voice_timer = soundscape.rng.randf_range(0.04,0.22) if voice_dropout else soundscape.rng.randf_range(0.12,1.1)
			voice_pitch = soundscape.rng.randf_range(0.72,1.03)
			# Occasionally jump into another phrase, like a failing receiver losing its signal.
			if not voice_dropout and soundscape.rng.randf()<0.28:
				radio_voices.seek(soundscape.rng.randf_range(0,maxf(0,radio_voices.stream.get_length()-0.5)))
	var voice_volume = lerpf(-34.0,-13.0,proximity) if current_interior=="radio" else -60.0
	if voice_dropout: voice_volume -= 32.0
	radio_voices.volume_db = lerpf(radio_voices.volume_db,voice_volume,1.0-exp(-delta*35.0))
	radio_voices.pitch_scale = lerpf(radio_voices.pitch_scale,voice_pitch,1.0-exp(-delta*12.0))
	radio_voices.attenuation_filter_cutoff_hz = lerpf(1400.0,4200.0,proximity)
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
		if current_interior=="church" and game.town.streetscape.church.basement.contains(game.player.global_position):
			anchor = game.town.streetscape.church.basement
		play_accent(cue,anchor.to_global(Vector3(3,2,-3)),-24)
	else:
		var cue = "metal_moan" if last_cue=="distant_call" or soundscape.rng.randf()<0.7 else "distant_call"
		var angle = soundscape.rng.randf_range(0,TAU)
		var p = game.player.global_position+Vector3(cos(angle)*17,2,sin(angle)*17)
		play_accent(cue,p,-23 if cue=="metal_moan" else -26)
	event_timer = soundscape.rng.randf_range(32,58)

func _exit_tree():
	if owns_voice_bus:
		var bus = AudioServer.get_bus_index(VOICE_BUS)
		if bus>=0: AudioServer.remove_bus(bus)
