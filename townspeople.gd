extends Node3D
## Patrolling townspeople with a resettable, skinned death animation made from the user's downloaded humanoid mesh.
var town
var characters = {}
var managed_doors: Dictionary = {}
var sheltering=false
var motion_clock = 0.0
var grave_key_given = false
var grave_intro_shown = false
var grave_approaching = false
var conversation
const GRAVE_KEY_LINE = "Hey! I've got the key to my grandpappy's grave. The Whitcomb mausoleum, back in the cemetery. They locked the radio spare in there. The chapel cellar key is with it.\n\nHere. Take it. I haven't been back since the evacuation.\n\nIf you hear somebody talking in there... just get the part and leave."

const DEATH_DURATION = 1.7
const PEOPLE = [
	{"id":"ranger","name":"Pat / Ranger","variant":"ranger","building":"","p":Vector3(-5.65,0,-45),"yaw":0.0,"route":[Vector3(-5.65,0,-45),Vector3(-5.65,0,-49),Vector3(-5.65,0,-44.5)]},
	{"id":"nurse","name":"Aubrey / Nurse","variant":"nurse","building":"clinic","p":Vector3(-0.95,0,0.6),"yaw":0.0,"route":[Vector3(-0.95,0,0.6),Vector3(-0.95,0,2.5),Vector3(0.65,0,2.5),Vector3(0.65,0,0.6)]},
	{"id":"mechanic","name":"John / Mechanic","variant":"mechanic_john","building":"workshop","p":Vector3(1.2,0,1.5),"yaw":0.0,"route":[Vector3(1.2,0,1.5),Vector3(3,0,1.5),Vector3(3,0,3.1),Vector3(1.2,0,3.1)]}]

func _ready():
	name = "Townspeople"
	conversation=preload("res://pat_conversation.gd").new()
	conversation.game=town.game
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
		characters[data.id] = {"actor":actor,"visual":visual,"parent":parent,"spawn":data.p,"yaw":data.yaw,"name":data.name,"route":data.route,"waypoint":1,"wait":1.5,"blocked":0.0,"animation":null,"walk":"","dead":false,"death_time":0.0,"label":label,"area":area,"skeleton":find_skeleton(visual),"was_walking":true,"phase":characters.size()*2.1,"door_reach":0.0,"activity":"watch"}
		characters[data.id].route = routine_route(data,parent)
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
	if conversation:conversation.reset()
	sheltering=false
	grave_key_given=false
	grave_intro_shown=false
	grave_approaching=false
	managed_doors.clear()
	motion_clock=0
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
		data.wait = 1.5+data.phase
		data.was_walking = true
		data.door_reach = 0.0
		data.blocked = 0.0
		animate_walk(data,false)
		data.actor.rotation = Vector3(0,data.yaw,0)
		data.visual.scale = Vector3.ONE
		data.visual.rotation = Vector3.ZERO

func routine_route(person: Dictionary, parent: Node3D) -> Array:
	var home="ranger" if person.id=="ranger" else person.building
	var building=town.buildings[home]
	var inspection=Vector3(0.45,0,1.4) if person.id!="mechanic" else Vector3(1.2,0,1.5)
	var local_points=[inspection,Vector3(0,0,3.0),Vector3(0,0,5),Vector3(0,0,7.2),Vector3(-2.3,0,7.2),Vector3(1.8,0,7.2),Vector3(0,0,7.2),Vector3(0,0,5),Vector3(0,0,3.0),inspection]
	var result: Array = []
	for point in local_points: result.append(parent.to_local(building.to_global(point)))
	return result

func animate_walk(data: Dictionary, moving: bool):
	var animation=data.animation as AnimationPlayer
	if data.was_walking==moving: return
	data.was_walking=moving
	if data.skeleton: data.skeleton.reset_bone_poses()
	if animation==null: return
	if moving:
		animation.speed_scale=1.15
		animation.play(data.walk,0.18)
	else:
		animation.play(data.walk)
		animation.seek(0,true)
		animation.pause()

func animate_living(data: Dictionary, walking: bool, near_player: bool, delta: float):
	var t=motion_clock+data.phase
	var body=data.visual as Node3D
	var lean=0.025*sin(t*2) if walking else 0.012*sin(t*1.6)
	body.rotation.z=lerpf(body.rotation.z,lean,minf(1,delta*5))
	body.position.y=0.012*sin(t*2.0) if not walking else 0.0
	if walking: return
	var breath=sin(t*1.7)*0.018
	var gesture=pow(maxf(0,sin(t*0.6)),3)
	bone_pose(data,"body",Vector3(breath,0.025*sin(t*0.45),0.012*sin(t)))
	if near_player:
		bone_pose(data,"arm_R",Vector3(-0.18*gesture,0.08*gesture,-0.16*gesture))
		bone_pose(data,"arm_L",Vector3(0.025*sin(t),0,0.025*sin(t*0.8)))
	elif data.actor.name=="NPC_mechanic":
		bone_pose(data,"body",Vector3(0.07+breath,0,0))
		bone_pose(data,"arm_R",Vector3(-0.20-0.10*gesture,0,-0.12))
		bone_pose(data,"arm_L",Vector3(-0.16-0.05*sin(t*1.9),0,0.10))
	elif data.actor.name=="NPC_nurse":
		bone_pose(data,"body",Vector3(breath,0.035*sin(t*0.5),0.025*sin(t*0.7)))
		bone_pose(data,"arm_L",Vector3(-0.15*gesture,0,0.11*gesture))
		bone_pose(data,"arm_R",Vector3(0.02*sin(t),0,-0.03))
	else:
		bone_pose(data,"body",Vector3(breath,0.10*sin(t*0.35),0))
		bone_pose(data,"arm_R",Vector3(-0.28*gesture,0,-0.10*gesture))
	if data.door_reach>0:
		bone_pose(data,"arm_R",Vector3(-0.46,0.08,-0.18))

func _physics_process(delta):
	var playing=town.game.state=="play"
	if playing or town.game.state=="dialogue": motion_clock+=delta
	var requests: Dictionary = {}
	for data in characters.values():
		var actor=data.actor as CharacterBody3D
		if data.dead:
			if playing and data.death_time<DEATH_DURATION:
				data.death_time=minf(DEATH_DURATION,data.death_time+delta)
				animate_death(data)
			continue
		if sheltering and playing:
			run_to_shelter(data,delta)
			continue
		if not playing:
			actor.velocity=Vector3.ZERO
			animate_walk(data,false)
			if town.game.state=="dialogue" and town.game.dialogue_name==data.name:
				animate_living(data,false,true,delta)
			continue
		var offset=town.game.player.global_position-actor.global_position
		var near_player=Vector2(offset.x,offset.z).length()<1.65 and absf(offset.y)<1.8
		# Only react to nearby players with a clear sightline, not people behind a wall.
		if near_player:
			var ray=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3(0,1.25,0),town.game.player.global_position+Vector3(0,1.25,0),1,[actor.get_rid()])
			var hit=actor.get_world_3d().direct_space_state.intersect_ray(ray)
			near_player=hit.is_empty() or hit.collider==town.game.player
		var target: Vector3=data.parent.to_global(data.route[data.waypoint])
		var rushing=false
		var awaiting_interaction=false
		if town.powered and town.inventory.coil>0 and actor.name=="NPC_ranger" and not grave_key_given and not grave_intro_shown and not town.cemetery.unlocked:
			var player=town.game.player.global_position
			var on_street=absf(player.x)<4.0 and player.z< -37 and player.z> -78
			var outside=not town.player_inside_building("ranger") # Player must be outside too.
			var ranger_local=town.buildings.ranger.to_local(actor.global_position)
			if on_street and outside and ranger_local.z>5.8 and offset.length()<14: grave_approaching=true
			if grave_approaching and on_street and ranger_local.z>5.5:
				var ray=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3(0,1.2,0),player+Vector3(0,1.2,0),1,[actor.get_rid()])
				var hit=actor.get_world_3d().direct_space_state.intersect_ray(ray)
				var clear=hit.is_empty() or hit.collider==town.game.player
				if clear:
					if Vector2(offset.x,offset.z).length()<2.0:
						actor.velocity=Vector3.ZERO
						target=actor.global_position
						awaiting_interaction=true
						near_player=true
						data.wait=0.5
					else:
						target=player-offset.normalized()*1.7
						rushing=true
						data.wait=0.0
						near_player=false
		var direction=target-actor.global_position
		direction.y=0
		data.wait=maxf(0,data.wait-delta)
		data.door_reach=maxf(0,data.door_reach-delta)
		# Request doors while approaching the authored entrance waypoints.
		for id in ["ranger","clinic","workshop","house"]:
			var doorway=town.doorway_position(id)
			var distance=Vector2(actor.global_position.x-doorway.x,actor.global_position.z-doorway.z).length()
			if distance<2.0 or (target.distance_to(doorway)<0.25 and distance<3.0):
				requests[id]=true
				if not town.doors[id].open and town.set_building_door(id,true):
					managed_doors[id]=2.0
					data.door_reach=0.7
					data.wait=maxf(data.wait,0.7)
		var walking=not near_player and data.wait<=0 and direction.length()>0.16
		if walking:
			var step_direction=direction.normalized()
			var local_direction: Vector3=data.parent.global_basis.inverse()*step_direction
			actor.rotation.y=lerp_angle(actor.rotation.y,atan2(local_direction.x,local_direction.z),minf(1,delta*5))
			var velocity=actor.velocity.move_toward(step_direction*(2.2 if rushing else 0.92),delta*(4.5 if rushing else 3.0))
			actor.velocity=Vector3(velocity.x,-0.5,velocity.z)
			var previous=actor.global_position
			actor.move_and_slide()
			actor.global_position.y=maxf(0.001,actor.global_position.y)
			var travelled=Vector2(actor.global_position.x-previous.x,actor.global_position.z-previous.z).length()
			data.blocked=data.blocked+delta if travelled<delta*0.08 else 0.0
			if data.blocked>2.5:
				# Retrace a safe route segment instead of skipping through an interior wall.
				data.waypoint=wrapi(data.waypoint-1,0,data.route.size())
				data.wait=1.2
				data.blocked=0.0
			walking=travelled>delta*0.08
		else:
			actor.velocity=Vector3.ZERO
			if direction.length()<=0.16 and not awaiting_interaction:
				data.waypoint=(data.waypoint+1)%data.route.size()
				var in_doorway=false
				for id in requests:
					if actor.global_position.distance_to(town.doorway_position(id))<2.0: in_doorway=true
				data.wait=0.0 if in_doorway else 3.0+fmod(data.phase+data.waypoint*1.7,4.0)
			if near_player and offset.length()>0.2:
				var local=data.parent.global_basis.inverse()*offset
				actor.rotation.y=lerp_angle(actor.rotation.y,atan2(local.x,local.z),minf(1,delta*3))
		animate_walk(data,walking)
		if data.animation and walking: data.animation.speed_scale=2.5 if rushing else 1.15
		animate_living(data,walking,near_player,delta)
	if playing and sheltering:
		close_shelter_doors()
		return
	# Close only doors opened by an NPC, after all walkers clear the threshold.
	if playing:
		for id in managed_doors.keys():
			if requests.has(id): managed_doors[id]=2.0
			else: managed_doors[id]-=delta
			if managed_doors[id]<=0 and town.set_building_door(id,false): managed_doors.erase(id)

func shoot(id: String) -> bool:
	if town.game.state!="play" or not characters.has(id) or characters[id].dead:
		return false
	var data = characters[id]
	if id=="ranger" and not grave_key_given and not town.cemetery.unlocked:
		var storage=town.interiors.containers.ranger_drawer
		storage.remaining_extras["mausoleum_key"]=1
		storage.pending_loot=true
		grave_approaching=false
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

func offer_grave_key():
	grave_intro_shown=true
	grave_approaching=false
	var line=GRAVE_KEY_LINE
	if town.game.backpack and not town.game.backpack.room_for("mausoleum_key"):
		line="Hey! I've got the key to my grandpappy's grave. The Whitcomb mausoleum. That's where they locked the radio spare.\n\nYour bag's full. Make a little room, then come talk to me. I'll keep the key safe."
	else:
		town.inventory.mausoleum_key+=1
		grave_key_given=true
		town.game.message="Pat gave you the Whitcomb mausoleum key."
		town.game.soundscape.feedback("pickup")
	conversation.begin(line,true)

func talk(id: String):
	if characters[id].dead:
		return
	if town.powered and town.inventory.coil>0 and id=="ranger" and not grave_key_given and not town.cemetery.unlocked:
		offer_grave_key()
		return
	if id=="ranger":
		conversation.begin(words(id))
		return
	conversation.cancel()
	town.game.dialogue_name = characters[id].name
	town.game.dialogue_text = words(id)
	town.game.set_state("dialogue")

func words(id: String) -> String:
	if town.powered and town.inventory.coil>0 and not town.radio_ready and town.inventory.antenna==0:
		return "The radio aerial coupling is broken. There is a brass spare in the locked Whitcomb mausoleum at Old Mill Cemetery, off the road between town and your wreck. Follow the cemetery footpath on the east side. Bring it back with the workshop coil and chapel tuning unit."
	if town.radio_ready:
		if town.game.story.direct_channel_selected():
			return "The bypass is green. That is the direct county channel. Tell them our location and ask for no sirens.\n\nHold E at the main receiver to transmit, then switch it off. We need a real person on the road, not another recording."
		return "Repairing the radio restores its power, not its routing. Set the small BYPASS switch on the left of the station desk to GREEN before you call.\n\nAmber still feeds the chapel repeater. The operator's note explains it. Aubrey's records tell you why the rescue team should come without sirens."
	match id:
		"ranger":
			if town.game.story.evidence.has("ranger_note"):
				var next_step = "The station key is in my desk drawer. Take it." if town.inventory.station_key==0 else "Take the store fuse to the workshop panel. Its powered cabinet holds the coil. Then ask me about my family mausoleum."
				return "That was three nights ago. The horn came from the chapel speaker. I should have locked the barrier again. You should never have been on that road.\n\n"+next_step+"\n\nThe other radio part is beneath the chapel. Keep your light moving in those woods."
			if town.inventory.station_key==0:
				return "Most of Blackwood left after the mill closed twelve years ago. The boarded shops and wrecks have been here for years.\n\nThe last few families evacuated three nights ago. I reopened Old Mill Road when I heard the last bus coming back. It was only the chapel speaker.\n\nI'm Pat. Only Aubrey, John and I stayed. I changed the sign so travelers would know.\n\nStation key is in my desk drawer. Pistol's in the abandoned police car on Main Street. Open the driver's door and check the seat. Read my log."
			return "You have the station key. The store counter drawer has a workshop fuse; the workshop's rear terminal takes it. Its powered cabinet holds the coil. I can help you reach the mausoleum afterward.\n\nI wrote down what happened that night. It's on my desk. I don't want to say it out here again."
		"nurse":
			if town.game.story.evidence.has("clinic_note"):
				return "Edith and Silas were my patients. I recognized her bracelet and his splinted hand on those things. Jonah, the chapel caretaker, changed first. The signal did this over weeks.\n\nIf the county answers, ask them to come without sirens. The things around the chapel follow sound.\n\nH uses a first-aid kit. Q fits a battery."
			return "I'm Aubrey. Most houses were empty long before this. The final bus took the remaining families three nights ago. Two patients refused to go; by dawn they had disappeared toward the chapel.\n\nFirst they stopped sleeping. Then came missing hours, strange voices and changes in their hands. The chapel tone was in every case. One voice used my mother's name; they never knew her.\n\nRead the sheet on the back shelf. Medicine is in the rear cabinet. H uses a kit; Q fits a battery."
		"mechanic":
			if not town.powered:
				return "John. This place was falling apart years before the signal started. Twelve years without the mill, then last month's storm finished off the bad roofs.\n\nThe radio needs a coil from my powered cabinet. Workshop fuse is in the store counter drawer; the panel is behind this workshop, through the alley.\n\nI also left a log on the bench. Read it. If I tell you the radio just broke, I'll be lying again."
			if town.inventory.coil==0:
				return "I pulled the station coil to stop the repeater sending voices through town. It stopped those broadcasts; not the speaker on the hill.\n\nTake the coil from this cabinet. Ask Pat about the mausoleum; the cellar key is stored there. The spare county tuning unit and service rifle are locked beneath the chapel. I tried to reach them; the creatures drove me back."
			if town.inventory.tuner==0:
				return "Ada left on the last bus. Her letter is in our room at Saint George Hotel. I told her I'd catch up after securing the equipment.\n\nUse the cellar key at the back right inside the church. Take the spare tuner and service rifle. The bench instructions explain the station's bypass switch."
			return "You have the coil, tuner and cemetery antenna coupler. Repair the station receiver, then set its small desk bypass to GREEN / DIRECT COUNTY. Hold E at the main set to call.\n\nNo sirens. Tell them there are people missing in the woods, and that the chapel repeater must be disconnected. Don't let another team mistake its old messages for us."
	return "Stay safe out there."


func set_sheltering(next:bool):
	if sheltering==next:return
	sheltering=next
	managed_doors.clear()
	grave_approaching=false
	for person in PEOPLE:
		var data=characters[person.id]
		if data.dead:continue
		data.actor.velocity=Vector3.ZERO
		data.waypoint=0
		data.wait=0.0
		data["shelter_home"]="ranger" if person.id=="ranger" else person.building
		data["shelter_done"]=false
		data["shelter_step"]=0
		data["shelter_wait"]=0.0
		data["shelter_points"]=[]
		if next:
			var building=town.buildings[data.shelter_home]
			var local=building.to_local(data.actor.global_position)
			if absf(local.x)<5 and local.z<3.5 and local.z> -4.8:
				data.shelter_done=true
			else:
				if local.z>5.6:data.shelter_points.append(building.to_global(Vector3(0,0.01,7.2)))
				data.shelter_points.append(building.to_global(Vector3(0,0.01,5)))
				data.shelter_points.append(building.to_global(Vector3(0,0.01,3)))
				var inside=Vector3(1.2,0.01,1.5) if person.id=="mechanic" else Vector3(0.45,0.01,1.4)
				data.shelter_points.append(building.to_global(inside))
	if next:close_shelter_doors()

func run_to_shelter(data:Dictionary,delta:float):
	var actor:CharacterBody3D=data.actor
	if data.get("shelter_done",false):
		actor.velocity=Vector3.ZERO
		animate_walk(data,false)
		animate_living(data,false,false,delta)
		return
	data.shelter_wait=maxf(0,data.shelter_wait-delta)
	var door=town.doors[data.shelter_home]
	var doorway=town.doorway_position(data.shelter_home)
	if actor.global_position.distance_to(doorway)<3.0 and not door.open:
		if town.set_building_door(data.shelter_home,true):data.shelter_wait=0.6
	if data.shelter_wait>0:
		actor.velocity=Vector3.ZERO
		animate_walk(data,false)
		return
	var target:Vector3=data.shelter_points[data.shelter_step]
	var direction=target-actor.global_position
	direction.y=0
	if direction.length()<0.18:
		data.shelter_step+=1
		if data.shelter_step>=data.shelter_points.size():
			data.shelter_done=true
			actor.velocity=Vector3.ZERO
		return
	var desired=direction.normalized()
	var step=desired*minf(0.45,direction.length())
	for angle in [0.0,0.5,-0.5,0.9,-0.9]:
		var probe=step.rotated(Vector3.UP,angle)
		if not actor.test_move(actor.global_transform,probe):
			desired=probe.normalized()
			break
	var local_direction:Vector3=data.parent.global_basis.inverse()*desired
	actor.rotation.y=lerp_angle(actor.rotation.y,atan2(local_direction.x,local_direction.z),minf(1,delta*8))
	actor.velocity=desired*minf(2.8,direction.length()/maxf(delta,0.001))
	actor.velocity.y=-0.5
	actor.move_and_slide()
	animate_walk(data,true)
	if data.animation:data.animation.speed_scale=2.5
	animate_living(data,true,false,delta)

func close_shelter_doors():
	for id in town.doors:
		var approaching=false
		for data in characters.values():
			if not data.dead and data.get("shelter_home","")==id and not data.get("shelter_done",false):approaching=true
		if not approaching:town.set_building_door(id,false,true)

func all_sheltered()->bool:
	if not sheltering:return false
	for data in characters.values():
		if not data.dead and not data.get("shelter_done",false):return false
	for door in town.doors.values():
		if door.open or absf(door.hinge.rotation.y)>0.05:return false
	return true
