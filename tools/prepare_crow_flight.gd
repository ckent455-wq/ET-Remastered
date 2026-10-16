# Copy bird@flyStraight.FBX and bird@landing.FBX from the Living Birds source
# to assets/crow/animations/fly.fbx and landing.fbx; import before running.
extends SceneTree
func _initialize():
	var library = load("res://assets/crow/perch_animations.res").duplicate(true)
	for name in ["fly","landing"]:
		var scene = load("res://assets/crow/animations/"+name+".fbx").instantiate()
		var player = scene.get_node("AnimationPlayer")
		var clip = player.get_animation(player.get_animation_list()[0]).duplicate(true)
		clip.loop_mode = Animation.LOOP_LINEAR if name=="fly" else Animation.LOOP_NONE
		if library.has_animation(name):
			library.remove_animation(name)
		library.add_animation(name,clip)
		print(name," clip length ",clip.length)
		scene.free()
	assert(ResourceSaver.save(library,"res://assets/crow/perch_animations.res")==OK)
	quit()
