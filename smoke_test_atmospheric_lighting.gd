extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.reset_game()
	game.set_state("play")
	game.set_physics_process(false)
	var cellar = game.town.streetscape.church.basement
	game.player.position = cellar.to_global(Vector3(0,0.01,1.5))
	game.fog_atmosphere.update_fog(3)
	var env = game.camera.environment
	assert(env!=null and env.ambient_light_energy<0.02 and env.fog_light_energy<0.04,"Dark local cellar environment")
	for node in cellar.find_children("*","GeometryInstance3D",true,false):
		assert(node.layers==2,"Sealed cellar on its own lighting layer")
	for node in game.find_children("*","DirectionalLight3D",true,false):
		assert((node.light_cull_mask & 2)==0 and not node.visible,"Moon cannot light cellar")
	for node in game.town.actions.radio_tuner.area.find_children("*","MeshInstance3D",true,false):
		assert(not node.material_override.emission_enabled,"Required part cannot glow in darkness")
	game.state = "paused"
	game.fog_atmosphere.update_fog(3)
	assert(game.camera.environment==env,"Cellar lighting persists in pause")
	game.state = "play"
	game.player.position = game.town.streetscape.church.to_global(Vector3(0,0.01,0))
	game.fog_atmosphere.update_fog(3)
	assert(game.camera.environment==null,"Chapel and exterior lighting restored upstairs")
	assert(game.fog_atmosphere.environment.ambient_light_energy>0.5,"Outdoor ambient restored")
	for light in game.fog_atmosphere.surface_directionals:
		assert(light.visible,"Outdoor directional visibility restored")
	var lights = game.town.streetscape.emergency_lights
	assert(lights.size()==2,"Two bounded police lightbar lights")
	assert(lights[0].light_color.r>lights[0].light_color.b and lights[1].light_color.b>lights[1].light_color.r,"Red and blue")
	for light in lights:
		assert("abandoned_police" in light.get_parent().get_meta("vehicle_model"),"Attached to police car")
		assert(light.light_energy<=0.81 and light.omni_range<=5.5 and not light.shadow_enabled,"Low local glow")
	print("PASS: dark isolated cellar lighting, moon exclusion, non-emissive quest part, pause/upstairs restoration, bounded red and blue police glow")
	quit()
