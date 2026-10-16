extends Node3D
## Patrolling townspeople with a resettable, skinned death animation made from the user's downloaded humanoid mesh.
var town
var characters = {}
const DEATH_DURATION = 1.7
const PEOPLE = [
	{"id":"ranger","name":"Elias / Ranger","variant":"ranger","building":"","p":Vector3(-5.65,0,-45),"yaw":0.0,"route":[Vector3(-5.65,0,-45),Vector3(-5.65,0,-49),Vector3(-5.65,0,-44.5)]},
	{"id":"nurse","name":"Mara / Nurse","variant":"nurse","building":"clinic","p":Vector3(-0.95,0,0.6),"yaw":0.0,"route":[Vector3(-0.95,0,0.6),Vector3(-0.95,0,2.5),Vector3(0.65,0,2.5),Vector3(0.65,0,0.6)]},
	{"id":"mechanic","name":"Owen / Mechanic","variant":"mechanic","building":"workshop","p":Vector3(1.2,0,1.5),"yaw":0.0,"route":[Vector3(1.2,0,1.5),Vector3(3,0,1.5),Vector3(3,0,3.1),Vector3(1.2,0,3.1)]}]

func _ready():
	name = "Townspeople"
	for data in PEOPLE:
		var actor = CharacterBody3D.new()
		actor.floor_snap_length = 0.15
		actor.name = "NPC_"+data.id
		var parent: Node3D = town if data.building=="" else town.buildings[data.building]
		parent.add_child(actor)
		actor.position = data.p
		actor.rotation.y = data.yaw
		actor.add_to_group("TownNPCs")
		actor.set_meta("npc_id",data.id)
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
		var area = town.action_area(actor,Vector3(0,0.95,0),Vector3(0.75,1.8,0.75),"npc_"+data.id,{"kind":"npc","npc":data.id,"label":data.name})
		var label = town.sign_text(actor,data.name,Vector3(0,2.0,0),26,Color("b7c8ac"))
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size = 0.0038
		label.visibility_range_end = 8
		characters[data.id] = {"actor":actor,"visual":visual,"parent":parent,"spawn":data.p,"yaw":data.yaw,"name":data.name,"route":data.route,"waypoint":1,"wait":1.5,"blocked":0.0,"animation":null,"walk":"","dead":false,"death_time":0.0,"label":label,"area":area,"skeleton":find_skeleton(visual)}
		var animation = visual.find_child("AnimationPlayer",true,false) as AnimationPlayer
		if animation:
			for animation_name in animation.get_animation_list():
				if "walk" in animation_name.to_lower():
					animation.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
					characters[data.id].animation = animation
					characters[data.id].walk = animation_name

func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var skeleton = find_skeleton(child)
		if skeleton:
			return skeleton
	return null

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
		data.dead = false
		data.death_time = 0.0
		data.actor.collision_layer = 1
		data.actor.collision_mask = 1
		data.label.visible = true
		data.area.visible = true
		data.area.collision_layer = 2
		if data.skeleton:
			data.skeleton.reset_bone_poses()
		data.visual.position = Vector3.ZERO
		data.actor.position = data.spawn
		data.actor.velocity = Vector3.ZERO
		data.waypoint = 1
		data.wait = 1.5
		data.blocked = 0.0
		animate_walk(data,false)
		data.actor.rotation = Vector3(0,data.yaw,0)
		data.visual.scale = Vector3.ONE
		data.visual.rotation = Vector3.ZERO

func animate_walk(data: Dictionary, moving: bool):
	var animation = data.animation as AnimationPlayer
	if animation==null:
		return
	if moving:
		if not animation.is_playing():
			animation.play(data.walk,0.15)
	else:
		animation.play(data.walk)
		animation.seek(0,true)
		animation.pause()

func _physics_process(delta):
	for data in characters.values():
		var actor = data.actor as CharacterBody3D
		if data.dead:
			if town.game.state=="play" and data.death_time<DEATH_DURATION:
				data.death_time = minf(DEATH_DURATION,data.death_time+delta)
				animate_death(data)
			continue
		if town.game.state!="play":
			actor.velocity = Vector3.ZERO
			animate_walk(data,false)
			continue
		var offset = town.game.player.global_position-actor.global_position
		var near_player = Vector2(offset.x,offset.z).length()<2.8
		var direction: Vector3 = data.route[data.waypoint]-actor.position
		direction.y = 0
		data.wait = maxf(0,data.wait-delta)
		var walking = not near_player and data.wait<=0 and direction.length()>0.12
		if walking:
			var step_direction = direction.normalized()
			actor.rotation.y = lerp_angle(actor.rotation.y,atan2(step_direction.x,step_direction.z),minf(1,delta*5))
			var world_direction: Vector3 = data.parent.global_basis*step_direction
			actor.velocity = world_direction*0.75
			actor.velocity.y = -0.5
			var previous = actor.global_position
			actor.move_and_slide()
			actor.global_position.y = maxf(0.001,actor.global_position.y)
			var travelled = Vector2(actor.global_position.x-previous.x,actor.global_position.z-previous.z).length()
			data.blocked = data.blocked+delta if travelled<delta*0.1 else 0.0
			if data.blocked>1.0:
				data.waypoint = (data.waypoint+1)%data.route.size()
				data.wait = 1.0
				data.blocked = 0.0
			walking = travelled>delta*0.1
		else:
			actor.velocity = Vector3.ZERO
			if direction.length()<=0.12:
				data.waypoint = (data.waypoint+1)%data.route.size()
				data.wait = 2.0
			if near_player and offset.length()>0.2:
				var local = data.parent.global_basis.inverse()*offset
				actor.rotation.y = lerp_angle(actor.rotation.y,atan2(local.x,local.z),minf(1,delta*4))
		animate_walk(data,walking)

func shoot(id: String) -> bool:
	if town.game.state!="play" or not characters.has(id) or characters[id].dead:
		return false
	var data = characters[id]
	data.dead = true
	data.death_time = 0.0
	data.actor.velocity = Vector3.ZERO
	data.actor.collision_layer = 0
	data.actor.collision_mask = 0
	data.label.visible = false
	if data.animation:
		data.animation.stop()
	if data.skeleton:
		data.skeleton.reset_bone_poses()
	var action = town.actions["npc_"+id]
	action.taken = true
	action.area.visible = false
	action.area.collision_layer = 0
	town.focus_action = ""
	animate_death(data)
	return true

func bone_pose(data: Dictionary, bone_name: String, angles: Vector3):
	var skeleton = data.skeleton as Skeleton3D
	if skeleton:
		var index = skeleton.find_bone(bone_name)
		if index>=0:
			# Imported limbs have different rest axes. Apply offsets relative
			# to those axes so a loose arm does not flip above the head.
			var rest = skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
			skeleton.set_bone_pose_rotation(index,rest*Quaternion.from_euler(angles))

func animate_death(data: Dictionary):
	var t: float = data.death_time
	# The torso folds before the balance gives way. One shoulder leads the
	# forward fall; limbs stay loose rather than rotating as a rigid plank.
	var buckle = smoothstep(0.08,0.55,t)
	var fall = smoothstep(0.35,1.10,t)
	var settle = smoothstep(1.10,DEATH_DURATION,t)
	var impact = sin(clampf(t/0.22,0,1)*PI)
	var landing = sin(settle*PI)*exp(-settle*4.0)
	data.visual.rotation = Vector3(0.08*impact+PI*0.5*fall-0.06*landing,0,-0.38*fall-0.08*landing)
	data.visual.position = Vector3(0.12*fall,-0.16*buckle*(1-fall)+0.19*fall+0.035*landing,0.25*fall)
	bone_pose(data,"body",Vector3(0.18*buckle*(1-fall),0,-0.04*buckle*(1-settle)))
	for side in ["L","R"]:
		var sign = 1.0 if side=="L" else -1.0
		var stagger = 1.0 if side=="L" else 0.72
		bone_pose(data,"leg_"+side,Vector3(lerpf(-0.45,-0.08,settle)*buckle*stagger,0,sign*0.06*buckle))
		bone_pose(data,"shin_"+side,Vector3(lerpf(0.85,0.18,settle)*buckle*stagger,0,0))
		bone_pose(data,"arm_"+side,Vector3(0.04*buckle*(1-settle),0,sign*0.04*buckle*(1-settle)))

func talk(id: String):
	if characters[id].dead:
		return
	town.game.dialogue_name = characters[id].name
	town.game.dialogue_text = words(id)
	town.game.set_state("dialogue")

func words(id: String) -> String:
	if town.radio_ready:
		if town.game.story.direct_channel_selected():
			return "The bypass is green. That is the direct county channel. Tell them our location and ask for no sirens.\n\nHold E at the main receiver to transmit, then switch it off. We need a real person on the road, not another recording."
		return "Repairing the radio restores its power, not its routing. Set the small BYPASS switch on the left of the station desk to GREEN before you call.\n\nAmber still feeds the chapel repeater. The operator's note explains it. Mara's records tell you why the rescue team should come without sirens."
	match id:
		"ranger":
			if town.game.story.evidence.has("ranger_note"):
				var next_step = "The station key is in my desk drawer. Take it." if town.inventory.station_key==0 else "Take the store fuse to the workshop panel. Its powered cabinet holds the coil and cellar key."
				return "That was three nights ago. The horn came from the chapel speaker. I should have locked the barrier again. You should never have been on that road.\n\n"+next_step+"\n\nThe other radio part is beneath the chapel. Keep your light moving in those woods."
			if town.inventory.station_key==0:
				return "We evacuated three nights ago. I reopened Old Mill Road when I heard the last bus coming back. It was only the chapel speaker.\n\nI'm Elias. Only Mara, Owen and I stayed. I changed the sign so travelers would know.\n\nStation key is in my desk drawer. Pistol's on the front crate. Read my log."
			return "You have the station key. The store counter drawer has a fuse; the workshop's outside panel takes it. Its powered cabinet holds a coil and chapel cellar key.\n\nI wrote down what happened that night. It's on my desk. I don't want to say it out here again."
		"nurse":
			if town.game.story.evidence.has("clinic_note"):
				return "Edith and Silas were my patients. I recognized her bracelet and his splinted hand on those things. Jonah, the chapel caretaker, changed first. The signal did this over weeks.\n\nIf the county answers, ask them to come without sirens. The things around the chapel follow sound.\n\nH uses a first-aid kit. Q fits a battery."
			return "I'm Mara. The bus took everyone fit to travel three nights ago. Two patients refused to go; by dawn they had disappeared toward the chapel.\n\nFirst they stopped sleeping. Then came missing hours, strange voices and changes in their hands. The chapel tone was in every case. One voice used my mother's name; they never knew her.\n\nRead the sheet on the back shelf. Medicine is in the rear cabinet. H uses a kit; Q fits a battery."
		"mechanic":
			if not town.powered:
				return "Owen. The radio needs a coil from my powered cabinet. Fuse is in the store counter drawer; the panel is outside this workshop.\n\nI also left a log on the bench. Read it. If I tell you the radio just broke, I'll be lying again."
			if town.inventory.coil==0:
				return "I pulled the station coil to stop the repeater sending voices through town. It stopped those broadcasts; not the speaker on the hill.\n\nTake the coil and cellar key from this cabinet. The spare county tuning unit and service rifle are locked beneath the chapel. I tried to reach them; the creatures drove me back."
			if town.inventory.tuner==0:
				return "Ada left on the last bus. Her letter is at our house. I told her I'd catch up after securing the equipment.\n\nUse the cellar key at the back right inside the church. Take the spare tuner and service rifle. The bench instructions explain the station's bypass switch."
			return "You have both parts. Repair the station receiver, then set its small desk bypass to GREEN / DIRECT COUNTY. Hold E at the main set to call.\n\nNo sirens. Tell them there are people missing in the woods, and that the chapel repeater must be disconnected. Don't let another team mistake its old messages for us."
	return "Stay safe out there."
