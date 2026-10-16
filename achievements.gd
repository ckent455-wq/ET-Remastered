extends Node
## Local achievements persist across new journeys and game restarts.
const CROW_ID = "crow_killer"
const CROW_TITLE = "Wow, what an asshole"
var storage_path = "user://achievements.cfg"
var unlocked = {}
var toast_title = ""
var toast_seconds = 0.0
var toast_is_new = false

func _ready():
	load_progress()

func load_progress():
	unlocked.clear()
	var config = ConfigFile.new()
	if config.load(storage_path)==OK and config.has_section("unlocked"):
		for id in config.get_section_keys("unlocked"):
			unlocked[id] = str(config.get_value("unlocked",id))

func unlock(id: String, title: String) -> bool:
	# Always acknowledge the gameplay event, including an already-earned achievement.
	toast_title = title
	toast_seconds = 8.0
	toast_is_new = not unlocked.has(id)
	if not toast_is_new:
		return false
	unlocked[id] = title
	var config = ConfigFile.new()
	for key in unlocked:
		config.set_value("unlocked",key,unlocked[key])
	var error = config.save(storage_path)
	if error!=OK:
		push_warning("Could not save local achievement progress: "+str(error))
	return true

func clear_toast():
	toast_title = ""
	toast_is_new = false
	toast_seconds = 0

func update_toast(delta: float):
	toast_seconds = maxf(0,toast_seconds-delta)
