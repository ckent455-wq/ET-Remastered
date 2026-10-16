extends SceneTree
func _initialize():
	var image = Image.load_from_file("res://assets/crow/Materials-Textures/crowDiffuse.png")
	print("Texture ",image.get_size())
	image.resize(256,256,Image.INTERPOLATE_LANCZOS)
	image.save_png("res://assets/crow/Materials-Textures/crowDiffuse.png")
	quit()
