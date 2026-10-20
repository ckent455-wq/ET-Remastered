extends Node
## All game audio uses a private bus so M never changes other applications.
var game
var muted = false
var bus_index = -1
var owns_bus = false
var rng = RandomNumberGenerator.new()
var wind: AudioStreamPlayer
var leaves: AudioStreamPlayer
var click: AudioStreamPlayer
var thunder: AudioStreamPlayer
var steps: Array[AudioStreamPlayer] = []
var animals: Array[AudioStreamPlayer3D] = []
var step_streams: Array[AudioStream] = []
var step_banks={}
var last_surface_steps={}
var last_step_surface="grass"
var animal_streams: Array[AudioStream] = []
var step_distance = 0.0
var next_step = 0
var last_step = -1
var animal_timer = 8.0
var previous_state = ""
var interaction_voices = {}
var door_voice: AudioStreamPlayer3D
var weapon_voices: Array[AudioStreamPlayer] = []
var weapon_streams = {}
var hurt_voice: AudioStreamPlayer
var hurt_streams: Array[AudioStream] = []
var hurt_bag: Array[int] = []
var last_hurt = -1
var reload_voice: AudioStreamPlayer
var next_shot = 0
var storage_voice: AudioStreamPlayer3D
var atmosphere: Node
var storage_streams = {}
var flashlight_streams = {}
const BUS = "ForestAudio"

func stream(name: String, looped = false) -> AudioStream:
	var wav = load("res://assets/audio/%s.wav" % name).duplicate() as AudioStreamWAV
	if looped:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length()*wav.mix_rate)
	return wav

func voice(sound: AudioStream, volume: float) -> AudioStreamPlayer:
	var node = AudioStreamPlayer.new()
	node.stream = sound
	node.volume_db = volume
	node.bus = BUS
	add_child(node)
	return node

func spatial_voice(parent: Node3D, sound: AudioStream, volume: float, max_range: float) -> AudioStreamPlayer3D:
	var node = AudioStreamPlayer3D.new()
	node.stream = sound
	node.volume_db = volume
	node.bus = BUS
	node.unit_size = 10
	node.max_distance = max_range
	parent.add_child(node)
	return node

func _ready():
	rng.randomize()
	bus_index = AudioServer.get_bus_index(BUS)
	if bus_index<0:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count-1
		AudioServer.set_bus_name(bus_index,BUS)
		AudioServer.set_bus_send(bus_index,"Master")
		owns_bus = true
	wind = voice(stream("wind",true),-12)
	leaves = voice(stream("leaves",true),-17)
	flashlight_streams = {true:stream("horror/flashlight_on"),false:stream("horror/flashlight_off")}
	click = voice(flashlight_streams[true],-12)
	thunder = voice(stream("thunder"),-23)
	for cue in ["pickup","power","radio"]:
		interaction_voices[cue] = voice(stream(cue),-12)
	door_voice = spatial_voice(game,stream("horror/door_creak"),-20,20)
	storage_voice = spatial_voice(game,stream("horror/drawer_open"),-17,10)
	for cue in ["drawer_open","drawer_close","cabinet_open","cabinet_close"]:
		storage_streams[cue] = stream("horror/"+cue)
	for weapon in ["pistol","rifle","shotgun","empty"]:
		weapon_streams[weapon] = stream("gun_"+weapon)
	for i in range(3):
		weapon_voices.append(voice(weapon_streams.pistol,-15))
	reload_voice = voice(stream("gun_reload"),-13)
	for i in range(3): hurt_streams.append(stream("player/hurt_%d" % i))
	hurt_voice = voice(hurt_streams[0],-5)
	wind.play()
	leaves.play(3.0)
	for kind in {"concrete":5,"dirt":5,"grass":6,"gravel":5,"metal":5,"stairs":5,"stone":4,"wood":5}:
		step_banks[kind]=[]
		for i in {"concrete":5,"dirt":5,"grass":6,"gravel":5,"metal":5,"stairs":5,"stone":4,"wood":5}[kind]:
			step_banks[kind].append(load("res://assets/audio/footsteps/%s_%d.ogg" % [kind,i]))
	step_streams.assign(step_banks.grass)
	for i in range(3):
		steps.append(voice(step_streams[0],-8))
	for name in ["owl","night_bird","insects"]:
		animal_streams.append(stream(name))
	animal_streams.append(stream("horror/frogs"))
	for i in range(2):
		animals.append(spatial_voice(game,animal_streams[0],-12,45))
	atmosphere = Node.new()
	atmosphere.set_script(preload("res://horror_atmosphere.gd"))
	atmosphere.game = game
	atmosphere.soundscape = self
	add_child(atmosphere)
	reset()

func reset():
	hurt_voice.stop()
	hurt_voice.stream_paused = false
	hurt_bag.clear()
	last_hurt = -1
	if atmosphere:
		atmosphere.reset()
	thunder.stop()
	step_distance = 0
	last_surface_steps.clear();last_step=-1;last_step_surface="grass"
	animal_timer = rng.randf_range(7,13)
	for node in steps:
		node.stop()
	for node in animals:
		node.stop()
	for node in interaction_voices.values():
		node.stop()
	door_voice.stop()
	storage_voice.stop()
	weapon_stop_reload()
	for node in weapon_voices:
		node.stop()

func player_hurt(fixed_clip = -1):
	if game.state!="play": return
	var chosen: int = fixed_clip
	if chosen<0 or chosen>=hurt_streams.size():
		if hurt_bag.is_empty(): hurt_bag.assign([0,1,2])
		var choices = hurt_bag.filter(func(index): return index!=last_hurt)
		chosen = choices[rng.randi_range(0,choices.size()-1)]
		hurt_bag.erase(chosen)
	last_hurt = chosen
	# One dry, centered voice belongs to the player: successive hits replace
	# the previous grunt instead of stacking several recordings.
	hurt_voice.stream = hurt_streams[chosen]
	hurt_voice.stream_paused = false
	hurt_voice.play()

func weapon_stop_reload():
	if reload_voice:
		reload_voice.stop()

func weapon_sound(cue: String):
	if cue=="reload":
		reload_voice.play()
		return
	var node = weapon_voices[next_shot]
	next_shot = (next_shot+1)%weapon_voices.size()
	node.stream = weapon_streams[cue]
	node.pitch_scale = rng.randf_range(0.96,1.04)
	node.play()

func storage_move(p: Vector3, sliding: bool, opening = true):
	storage_voice.global_position = p+Vector3(0,0.8,0)
	storage_voice.stream = storage_streams[("drawer" if sliding else "cabinet")+("_open" if opening else "_close")]
	storage_voice.pitch_scale = rng.randf_range(0.94,1.03)
	storage_voice.play()

func feedback(cue: String):
	interaction_voices[cue].play()

func door_move(p: Vector3, opening: bool):
	door_voice.global_position = p+Vector3.UP
	door_voice.pitch_scale = 1.05 if opening else 0.88
	door_voice.play()

func toggle_mute():
	muted = not muted
	AudioServer.set_bus_mute(bus_index,muted)

func flashlight_click(enabled: bool):
	click.stream = flashlight_streams[enabled]
	click.pitch_scale = rng.randf_range(0.98,1.02)
	click.play()

func moved(distance: float, sprinting: bool, grounded: bool):
	if game.state!="play" or not grounded or distance<=0.001:
		step_distance = 0
		return
	step_distance += distance
	var stride = 2.5 if sprinting else 2.0
	if step_distance<stride:
		return
	step_distance = fmod(step_distance,stride)
	last_step_surface=preload("res://footstep_surfaces.gd").sample(game)
	step_streams.assign(step_banks.get(last_step_surface,step_banks.grass))
	last_step=last_surface_steps.get(last_step_surface,-1)
	var variation = rng.randi_range(0,step_streams.size()-2)
	if variation>=last_step:
		variation += 1
	last_step = variation
	last_surface_steps[last_step_surface]=variation
	var node = steps[next_step]
	next_step = (next_step+1)%steps.size()
	node.stream = step_streams[variation]
	node.pitch_scale = rng.randf_range(0.96,1.04)*(1.04 if sprinting else 1.0)
	node.volume_db = -14 if game.crouching else (-5 if sprinting else -9)
	node.play()

func play_animal():
	for node in animals:
		if node.playing:
			continue
		var angle = rng.randf_range(0,TAU)
		var radius = rng.randf_range(13,26)
		node.global_position = game.player.global_position+Vector3(cos(angle)*radius,rng.randf_range(2,5),sin(angle)*radius)
		node.stream = animal_streams[rng.randi_range(0,animal_streams.size()-1)]
		node.pitch_scale = rng.randf_range(0.88,1.12)
		node.volume_db = rng.randf_range(-14,-9)
		node.play()
		return

func _process(delta):
	update_sound(delta)

func update_sound(delta: float):
	atmosphere.update_sound(delta)
	var active = game.state=="play"
	var paused = game.state in ["paused","journal","dialogue","intro"]
	hurt_voice.stream_paused = paused
	if game.state in ["intro","title","won"]: hurt_voice.stop()
	wind.stream_paused = paused
	leaves.stream_paused = paused
	var indoors = active and not atmosphere.current_interior.is_empty()
	wind.volume_db = -24 if indoors else (-12 if active else -19)
	leaves.volume_db = -29 if indoors else (-17 if active else -24)
	if previous_state!=game.state:
		step_distance = 0
		if not active:
			click.stop()
			door_voice.stop()
			storage_voice.stop()
			weapon_stop_reload()
			for node in weapon_voices:
				node.stop()
			for node in interaction_voices.values():
				node.stop()
			for node in steps:
				node.stop()
			for node in animals:
				node.stop()
		previous_state = game.state
	if not active:
		return
	animal_timer -= delta
	if animal_timer<=0:
		if not indoors:
			play_animal()
		animal_timer = rng.randf_range(10,24)

func _exit_tree():
	if owns_bus:
		var index = AudioServer.get_bus_index(BUS)
		if index>=0:
			AudioServer.remove_bus(index)
