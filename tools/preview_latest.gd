extends SceneTree
var game
func _initialize():
	call_deferred("run")
func capture(label: String, p: Vector3, target: Vector3):
	game.player.position = p
	game.camera.look_at(target)
	for frame in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-latest-"+label+".png")
func run():
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.state = "play"
	for id in ["weapon_pistol","weapon_rifle","weapon_shotgun"]:
		game.town.perform(id)
	await capture("sign",Vector3(1,0.001,-30),Vector3(4.4,1.45,-35))
	for i in range(3):
		game.weapons.equip(i)
		await capture("gun%d" % i,Vector3(31.5,0.001,-40),Vector3(31.5,1.3,-44))
	game.weapons.equip(-1)
	game.player.position = Vector3(-23,0.001,-57)
	for frame in range(180):
		await physics_frame
	var actor = game.town.townspeople.characters.ranger.actor
	await capture("walking",Vector3(-23,0.001,-57),actor.global_position+Vector3(0,1,0))
	print("PASS: rendered sign, three weapons and skinned walking previews")
	game.queue_free()
	await process_frame
	quit()
