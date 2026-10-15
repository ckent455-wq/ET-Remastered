extends Node3D
## Friendly, idle townspeople made from the user's downloaded humanoid mesh.
var town
var characters = {}
const PEOPLE = [
	{"id":"ranger","name":"Elias / Ranger","variant":"ranger","building":"","p":Vector3(-26,0,-61),"yaw":0.0},
	{"id":"nurse","name":"Mara / Nurse","variant":"nurse","building":"clinic","p":Vector3(-0.95,0,0.6),"yaw":0.0},
	{"id":"mechanic","name":"Owen / Mechanic","variant":"mechanic","building":"workshop","p":Vector3(1.2,0,1.5),"yaw":0.0}]

func _ready():
	name = "Townspeople"
	for data in PEOPLE:
		var actor = StaticBody3D.new()
		actor.name = "NPC_"+data.id
		var parent: Node3D = town if data.building=="" else town.buildings[data.building]
		parent.add_child(actor)
		actor.position = data.p
		actor.rotation.y = data.yaw
		actor.add_to_group("TownNPCs")
		var collision = CollisionShape3D.new()
		var capsule = CapsuleShape3D.new()
		capsule.radius = 0.25
		capsule.height = 1.75
		collision.shape = capsule
		collision.position.y = 0.88
		actor.add_child(collision)
		var visual = load("res://assets/npcs/%s.glb" % data.variant).instantiate()
		actor.add_child(visual)
		retro_materials(visual)
		town.action_area(actor,Vector3(0,0.95,0),Vector3(0.75,1.8,0.75),"npc_"+data.id,{"kind":"npc","npc":data.id,"label":data.name})
		var label = town.sign_text(actor,data.name,Vector3(0,2.0,0),26,Color("b7c8ac"))
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size = 0.0038
		label.visibility_range_end = 8
		characters[data.id] = {"actor":actor,"visual":visual,"parent":parent,"spawn":data.p,"yaw":data.yaw,"name":data.name}

func retro_materials(node: Node):
	if node is MeshInstance3D:
		node.visibility_range_end = 45
		for i in range(node.mesh.get_surface_count()):
			var material = node.mesh.surface_get_material(i).duplicate() as StandardMaterial3D
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			material.roughness = 1
			material.metallic_specular = 0
			material.normal_enabled = false
			node.set_surface_override_material(i,material)
	for child in node.get_children():
		retro_materials(child)

func reset():
	for data in characters.values():
		data.actor.position = data.spawn
		data.actor.rotation = Vector3(0,data.yaw,0)
		data.visual.scale = Vector3.ONE
		data.visual.rotation = Vector3.ZERO

func _process(delta):
	if town.game.state!="play":
		return
	var index = 0
	for data in characters.values():
		var offset = town.game.player.global_position-data.actor.global_position
		if offset.length()<6 and Vector2(offset.x,offset.z).length()>0.2:
			var local = data.parent.global_basis.inverse()*offset
			data.actor.rotation.y = lerp_angle(data.actor.rotation.y,atan2(local.x,local.z),minf(1,delta*2))
		data.visual.scale.y = 1+sin(town.game.clock*1.5+index)*0.006
		data.visual.rotation.z = sin(town.game.clock*0.7+index)*0.008
		index += 1

func talk(id: String):
	town.game.dialogue_name = characters[id].name
	town.game.dialogue_text = words(id)
	town.game.set_state("dialogue")

func words(id: String) -> String:
	if town.radio_ready:
		return "The radio is working. Someone out there can hear you now.\n\nHead back down the forest road to the landing clearing. Hold E at the beacon to call home. Take care out there."
	match id:
		"ranger":
			if town.inventory.station_key==0:
				return "You're a long way from home, aren't you? I'm Elias.\n\nThe radio station might reach your people. I left its brass key in my cabin's desk drawer. Search it with E. Search the other buildings for supplies."
			return "Good, you found the key. Now try the general store's counter drawer for a fuse. Fit it at the workshop's outside panel, then get the signal coil from the powered cabinet.\n\nBring that coil to the radio-station receiver."
		"nurse":
			return "I'm Mara. Most of Blackwood left in a hurry. Some of us stayed to help anyone still coming through.\n\nSearch the medicine cabinet in the back room for first-aid kits. Press H to use one. Spare flashlight cells are in town's drawers and cabinets; use Q to fit a fresh battery."
		"mechanic":
			if not town.powered:
				return "Name's Owen. The workshop lost power, and the signal coil is stuck in that locked cabinet.\n\nFind the spare fuse in the store's counter drawer. The panel is outside, next to this building's door. Restore power there, then search the coil cabinet."
			if town.inventory.coil==0:
				return "You got the power back! Search the metal signal-coil cabinet here in the workshop.\n\nThat coil will repair the radio receiver. The ranger keeps the station key in his desk drawer."
			return "You've got the coil. Take it to the receiver in the radio station and press E to calibrate the uplink.\n\nThen follow the road back to your landing clearing. We'll keep the lights on."
	return "Stay safe out there."
