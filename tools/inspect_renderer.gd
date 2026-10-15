extends SceneTree
func _initialize():
	for entry in ProjectSettings.get_property_list():
		if "gl_compatibility/driver" in entry.name:
			print(entry.name," = ",ProjectSettings.get_setting(entry.name))
	quit()
