extends SceneTree
var game
var dark_luminance = 0.0
func _initialize():
	call_deferred("run")
func capture(label: String, p: Vector3, target: Vector3):
	game.player.position = p
	game.camera.look_at(target)
	for i in range(25):
		await process_frame
	await RenderingServer.frame_post_draw
	var picture = root.get_texture().get_image()
	picture.save_png("res://preview-lighting-"+label+".png")
	if label.begins_with("cellar-"):
		var luminance = 0.0
		for y in range(90,300,4):
			for x in range(80,560,4):
				var pixel = picture.get_pixel(x,y)
				luminance += pixel.r*0.2126+pixel.g*0.7152+pixel.b*0.0722
		luminance /= 6360.0
		if label=="cellar-off":
			dark_luminance = luminance
			assert(luminance<0.005,"Cellar is dark without flashlight")
		else:
			assert(luminance>dark_luminance+0.015,"Flashlight reveals cellar and radio workbench")
		print(label," mean view luminance ",luminance)
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.reset_game()
	game.set_state("play")
	game.set_physics_process(false)
	var cellar = game.town.streetscape.church.basement
	var p = cellar.to_global(Vector3(0,0.01,1.5))
	var target = cellar.to_global(Vector3(-2.6,1.09,-3.1))
	game.flashlight.visible = false
	await capture("cellar-off",p,target)
	game.flashlight.visible = true
	await capture("cellar-on",p,target)
	game.flashlight.visible = false
	await capture("police",Vector3(-0.4,0.01,-62.5),Vector3(2.7,1.05,-66))
	await capture("police-side",Vector3(-1,0.01,-67),Vector3(2.7,1.4,-66))
	print("PASS: cellar flashlight comparison and police lightbar glow rendered")
	quit()
