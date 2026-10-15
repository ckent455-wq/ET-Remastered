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
var steps: Array[AudioStreamPlayer] = []
var animals: Array[AudioStreamPlayer3D] = []
var step_streams: Array[AudioStream] = []
var animal_streams: Array[AudioStream] = []
var step_distance = 0.0
var next_step = 0
var last_step = -1
var animal_timer = 8.0
var previous_state = ""
var interaction_voices = {}
var door_voice: AudioStreamPlayer3D
var storage_voice: AudioStreamPlayer3D
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
	wind = voice(stream("wind",true),-8)
	leaves = voice(stream("leaves",true),-17)
	click = voice(stream("flashlight"),-10)
	for cue in ["pickup","power","radio"]:
		interaction_voices[cue] = voice(stream(cue),-12)
	door_voice = spatial_voice(game,stream("door"),-16,20)
	storage_voice = spatial_voice(game,stream("drawer"),-9,10)
	wind.play()
	leaves.play(3.0)
	for i in range(5):
		step_streams.append(stream("step_%d" % i))
	for i in range(3):
		steps.append(voice(step_streams[0],-8))
	for name in ["owl","night_bird","insects"]:
		animal_streams.append(stream(name))
	for i in range(2):
		animals.append(spatial_voice(game,animal_streams[0],-12,45))
	reset()

func reset():
	step_distance = 0
	animal_timer = rng.randf_range(7,13)
	for node in steps:
		node.stop()
	for node in animals:
		node.stop()
	for node in interaction_voices.values():
		node.stop()
	door_voice.stop()
	storage_voice.stop()

func storage_move(p: Vector3, sliding: bool):
	storage_voice.global_position = p+Vector3(0,0.8,0)
	storage_voice.pitch_scale = 1.0 if sliding else 0.76
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
	click.pitch_scale = 1.04 if enabled else 0.92
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
	var variation = rng.randi_range(0,step_streams.size()-2)
	if variation>=last_step:
		variation += 1
	last_step = variation
	var node = steps[next_step]
	next_step = (next_step+1)%steps.size()
	node.stream = step_streams[variation]
	node.pitch_scale = rng.randf_range(0.90,1.09)*(1.09 if sprinting else 1.0)
	node.volume_db = -5 if sprinting else -9
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
	var active = game.state=="play"
	var paused = game.state in ["paused","journal","dialogue","intro"]
	wind.stream_paused = paused
	leaves.stream_paused = paused
	wind.volume_db = -8 if active else -15
	leaves.volume_db = -17 if active else -24
	if previous_state!=game.state:
		step_distance = 0
		if not active:
			click.stop()
			door_voice.stop()
			storage_voice.stop()
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
		play_animal()
		animal_timer = rng.randf_range(10,24)

func _exit_tree():
	if owns_bus:
		var index = AudioServer.get_bus_index(BUS)
		if index>=0:
			AudioServer.remove_bus(index)
