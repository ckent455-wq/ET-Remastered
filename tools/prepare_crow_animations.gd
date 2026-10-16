# Rebuild after copying bird@watch01.FBX, bird@sing.FBX and bird@ruffle.FBX
# from the source_root in assets/crow/source.json to assets/crow/animations/
# as watch.fbx, call.fbx and ruffle.fbx, then running a Godot editor import.
# Staged source copies can be removed after this native animation library is saved.
extends SceneTree
func _initialize():
	var library = AnimationLibrary.new()
	for name in ["watch","call","ruffle"]:
		var scene = load("res://assets/crow/animations/"+name+".fbx").instantiate()
		var clip = scene.get_node("AnimationPlayer").get_animation("Take 001").duplicate(true)
		clip.loop_mode = Animation.LOOP_LINEAR if name=="watch" else Animation.LOOP_NONE
		library.add_animation(name,clip)
		scene.free()
	assert(ResourceSaver.save(library,"res://assets/crow/perch_animations.res")==OK)
	print("PASS: three original crow animation clips saved")
	quit()
