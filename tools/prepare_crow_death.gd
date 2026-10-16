# Stage bird@die.FBX from assets/crow/source.json as assets/crow/animations/die.fbx
# and run a Godot editor import before rebuilding this compact native clip library.
extends SceneTree
func _initialize():
	var library = load("res://assets/crow/perch_animations.res").duplicate(true)
	var scene = load("res://assets/crow/animations/die.fbx").instantiate()
	var player = scene.get_node("AnimationPlayer")
	var clip = player.get_animation(player.get_animation_list()[0]).duplicate(true)
	clip.loop_mode = Animation.LOOP_NONE
	if library.has_animation("die"):
		library.remove_animation("die")
	library.add_animation("die",clip)
	assert(ResourceSaver.save(library,"res://assets/crow/perch_animations.res")==OK)
	print("Death clip length ",clip.length)
	scene.free()
	quit()
