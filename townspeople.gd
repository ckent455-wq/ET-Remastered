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
			if material.resource_name == "Owen_John_Face" and material.albedo_texture:
				# Keep the portrait recognizable without photographic detail at close range.
				var face_image = material.albedo_texture.get_image()
				if face_image.is_compressed():face_image.decompress()
				var ratio = 96.0 / maxf(face_image.get_width(),face_image.get_height())
				face_image.resize(maxi(1,roundi(face_image.get_width()*ratio)),maxi(1,roundi(face_image.get_height()*ratio)),Image.INTERPOLATE_LANCZOS)
				face_image.generate_mipmaps()
				material.albedo_texture = ImageTexture.create_from_image(face_image)
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			material.roughness = 1
			material.metallic_specular = 0
			material.normal_enabled = false
			node.set_surface_override_material(i,material)
	for child in node.get_children():
		retro_materials(child)

func reset():
	if town.game.soundscape:town.game.soundscape.stop_john_death()
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
		if game_clinic_bedside(data):
			actor.velocity=Vector3.ZERO
			animate_walk(data,false)
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
	if id=="mechanic":town.game.soundscape.john_death(data.actor.global_position)
	if id=="mechanic" and town.game.story.ada_letter_requested:town.game.story.update_ada_quest()
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
	var line=conversation.pat_story.key_line()
	if not town.game.crash_site.has_backpack:
		line="Get your backpack from the car first. I'll keep the mausoleum key here until you're ready."
	elif town.game.backpack and not town.game.backpack.room_for("mausoleum_key"):
		line="I have the key to the Whitcomb mausoleum. There's a spare antenna coupler inside, and the chapel cellar key at the far end of the passage beneath it.\n\nYour pack is full. Make one slot, then come back. I'm not sending you out there without the key."
	else:
		town.inventory.mausoleum_key+=1
		grave_key_given=true
		town.game.message="Pat gave you the Whitcomb mausoleum key."
		town.game.soundscape.feedback("pickup")
	conversation.begin(line,true)

func talk(id: String):
	if characters[id].dead:
		return
	if id=="nurse" and not town.game.story.clinic_rescue_done and not conversation.greetings.has("nurse"):
		var intro="I'm Aubrey. This is Blackwood's pharmacy clinic. You came in from Old Mill Road? That dressing on your head was a good idea. Sit down if you feel unsteady.\n\n" if town.game.story.crash_wound_treated else "I'm Aubrey. This is Blackwood's pharmacy clinic. You look hurt. There are supplies in the rear cabinet.\n\n"
		conversation.begin(intro+town.game.story.AUBREY_BRIEFING,false,"nurse")
		town.game.story.record_aubrey_briefing()
		return
	if id=="mechanic" and town.game.story.deliver_ada_letter():
		conversation.begin("That's her handwriting... You went back for it?\n\nShe packed for two nights. I kept telling myself I'd find her when the work was done. I'd forgotten she asked me to leave the set off. She was right there, and I listened to her voice on the radio instead.\n\nThank you. I'm keeping this in my coat. When we get out, I want to hear her say it herself.\n\n"+town.game.story.ada_reward_line(),true,"mechanic")
		return
	if id=="mechanic" and town.game.story.ada_letter_delivered and town.game.story.ada_ammo_pending>0:
		var added=town.game.story.claim_ada_ammo()
		var line="Here are the %d pistol rounds I could fit in your pack." % added if added>0 else "Your pack or pistol-ammo reserve is still full."
		if town.game.story.ada_ammo_pending>0:line+=" I'll hold the remaining %d rounds. Come back when you have room." % town.game.story.ada_ammo_pending
		conversation.begin(line,true,"mechanic")
		return
	if town.powered and town.inventory.coil>0 and id=="ranger" and not grave_key_given and not town.cemetery.unlocked:
		offer_grave_key()
		return
	if id=="ranger":
		if not conversation.greetings.has("ranger"):
			conversation.begin(conversation.pat_story.greeting(conversation),false,id)
			return
		if conversation.pat_story.returned(conversation) and not conversation.greetings.has("pat_return"):
			conversation.greetings["pat_return"]=true
			conversation.begin("You went inside, didn't you?\n\nThere's dust on your collar. The same stuff that was on the vault steps. Sit a moment. Tell me what you found.",true,id)
			return
	if id=="mechanic" and not town.powered and not town.journal_entries.any(func(e):return e.id=="workshop_plan"):
		town.journal_entries.append({"id":"workshop_plan","title":"John / A way to call for help","text":"The county radio needs the signal coil John removed and locked in his workshop cabinet. Its electric latch has no power. Pat's office desk drawer holds the station key. A replacement workshop fuse is in the counter drawer inside the general store. Carry it through the alley between the workshop and Saint George Hotel, open the rear cabinet, install the fuse and flip the switch. Return through the alley to the front entrance to recover the coil. John keeps losing time and no longer trusts himself around live equipment."})
	var reaction=conversation.progress.intro(conversation,id)
	if not reaction.is_empty() and reaction.line!="":
		conversation.greetings[reaction.key]=true
		conversation.begin(reaction.line,true,id)
		return
	conversation.begin(words(id),false,id)

func words(id: String) -> String:
	if id=="nurse" and town.game.story.clinic_rescue_done and not town.powered and town.inventory.coil==0:
		if not town.game.crash_site.tutorial_complete():return "Your wound is dressed. Go back along Old Mill Road to your car and open the rear hatch. Collect your backpack first, then your flashlight. The supplies here will still be waiting when you return.\n\nAfter that, speak to John in the workshop across the street. He knows the county radio."
		if town.needs_workshop_introduction():return "You're steady, and you've got your things. John is in the workshop across the street. Ask him about the county emergency radio.\n\nIf you need a bandage before you go, check the bedside drawer. The medicine cabinet is at the back."
		return "Stay with John's plan. Pat's office desk drawer has the station key. The replacement workshop fuse is in the counter drawer inside the general store. Once you've restored the workshop power, get the coil from John's cabinet."
	if town.radio_ready and not town.game.story.repeater_is_off():return radio_advice(id,"shutdown")
	if town.powered and town.inventory.coil>0 and not town.radio_ready and town.inventory.antenna==0:return radio_advice(id,"coupler")
	if town.radio_ready:return radio_advice(id,"call" if town.game.story.direct_channel_selected() else "route")
	if town.inventory.coil>0 and town.inventory.antenna>0:
		if town.inventory.tuner==0:return radio_advice(id,"tuner")
		return radio_advice(id,"repair" if town.game.story.repeater_is_off() else "shutdown")
	match id:
		"ranger":
			if town.inventory.station_key==0:return "The station key is in my office drawer. The pistol is in the abandoned police car on Main Street. Check the driver's seat.\n\nJohn can tell you what the receiver needs. Read the log on my desk if you want to know why the road was still open."
			if not town.powered:return "The counter drawer inside the general store has a workshop fuse. Take it through the alley beside the hotel to the workshop's rear terminal.\n\nOnce the power is back, John can get you the signal coil. Come back to me before you go looking for the other parts."
			return "Take the signal coil from John's powered workshop cabinet. Then speak to me about the Whitcomb mausoleum. I've got its family key."
		"nurse":
			if town.game.story.evidence.has("clinic_note"):
				return "Edith and Silas were my patients. I recognized her bracelet and his splinted hand on those things. Jonah, the chapel caretaker, changed first. The changes took weeks. I still cannot tell you what caused them.\n\nIf the county answers, ask them to come without sirens. The things around the chapel follow sound.\n\nH uses a bandage first, then a medpack. Q fits a battery."
			return "I'm Aubrey. Most houses were empty long before this. The final bus took the remaining families three nights ago. Two patients refused to go; by dawn they had disappeared toward the chapel.\n\nFirst they stopped sleeping. Then came missing hours, strange voices and changes in their hands. The station voices spread through the chapel speaker. One used my dead mother's name. Read the station operator's log to learn how it began.\n\nRead the sheet on the back shelf. Medicine is in the rear cabinet. H uses a bandage first, then a medpack; Q fits a battery."
		"mechanic":
			if not town.powered:
				var plan="John. Aubrey sent you? The county radio is our best chance of getting help. I pulled its signal coil when the voices started. It's locked in my cabinet now. The electric latch won't release while the workshop's dead.\n\nI don't trust myself around live gear anymore. I keep finding work finished that I don't remember doing."
				if town.inventory.station_key==0:plan+="\n\nGet the station key from Pat's office desk drawer. We'll need it to reach the receiver."
				var terminal=town.actions.battery_panel.area.get_node("HighVoltageTerminal")
				if terminal.installed:plan+="\n\nYou've fitted the fuse. Flip the switch in the rear cabinet, then come back through the front entrance for the coil."
				elif town.inventory.workshop_fuse>0:plan+="\n\nYou've got the fuse. Take the alley between this workshop and Saint George Hotel. Follow it around to the rear cabinet. Open it, fit the fuse, then flip the switch. Come back through the front entrance for the coil."
				else:plan+="\n\nThere's a spare workshop fuse in the counter drawer inside the general store. Take it through the alley between this workshop and Saint George Hotel to the rear cabinet. Open it, fit the fuse, then flip the switch. Come back through the front entrance for the coil."
				if not town.game.knife.owned():plan+="\n\nTake the knife from the worktable if you need it. Pat said there's a pistol on the abandoned police car's driver's seat. Keep something with you out there."
				return plan
			if town.inventory.coil==0:
				return "The station radio started speaking by itself. Bellamy amplified it through the chapel. I pulled the transmitter coil, but the powered chapel return line kept the voices alive. Ask me where the broadcast began; read the operator's station log and my workshop notes.\n\nTake the coil from this cabinet. Ask Pat about the mausoleum; the cellar key is stored there. The spare county tuning unit and service rifle are locked beneath the chapel. I inspected them three weeks before the evacuation, before the creatures reached the chapel grounds. The station still worked then, so I left the spare tuner disconnected and the rifle with the emergency supplies. When I tried to go back after Ada left, the creatures drove me down the hill. I can't reach that equipment now."
			if town.inventory.tuner==0:
				return ("Ada left on the last bus. I keep her letter in my coat now. Thank you for bringing it back." if town.game.story.ada_letter_delivered else "Ada left on the last bus. Her letter is in our room at Saint George Hotel. I told her I'd catch up after securing the equipment.")+"\n\nUse the cellar key at the back right inside the church. Take the spare tuner and service rifle, then cut the rack at MAIN ISOLATOR. The bench instructions explain the station's bypass switch."
			return "You have the coil, tuner and cemetery antenna coupler. Repair the station receiver, then set its small desk bypass to GREEN / DIRECT COUNTY. Hold E at the main set to call.\n\nCut the chapel rack at MAIN ISOLATOR before you transmit. No sirens. Tell them there are people missing in the woods, and the repeater is disconnected. Don't let another team mistake its old messages for us."
	return "Stay safe out there."


func radio_advice(id:String,stage:String)->String:
	if id=="ranger" and stage=="coupler":
		var line="The antenna coupler is on the shelf inside the Whitcomb mausoleum. Old Mill Cemetery is east off the road to your wreck. The chapel cellar key is on the workbench at the far end of the passage below the vault."
		if not grave_key_given and not town.cemetery.unlocked:line+="\n\nSpeak to me for the family key before you go."
		elif conversation.asked.has("pat_vault"):line+="\n\nI've told you what I did. Get the equipment, then leave that place. Don't go looking for him for me."
		else:line+="\n\nKeep your light on. If you hear a voice down there, you don't have to answer it."
		return line
	var lines={
	 "coupler":{
	  "ranger":"I used my family's Whitcomb mausoleum as a temporary lockup during the evacuation. People were wandering into the station and taking equipment, so John asked me to secure the spare antenna coupler. Bellamy gave me the chapel cellar key after locking people away from its running rack. The coupler is on the vault shelf. The cellar key is on the workbench at the far end of the tunnel beneath it. Dry stone, a sound iron door, a lock I controlled. I meant to fetch them afterward.\n\nOld Mill Cemetery is east of the road between town and your wreck. Take the cemetery footpath. You'll need the vault key from me. I haven't been back since I heard those noises below it.",
	  "nurse":"You're still missing the antenna coupler. Pat keeps the family key to the Whitcomb mausoleum in Old Mill Cemetery, east of the road back to your wreck. He put the spare and chapel cellar key there for safekeeping during the evacuation, before we knew what was moving below it. Keep your light on in that passage. I found burial cloth dragged out of the coffins.",
	  "mechanic":"The coil won't fix a broken aerial coupling. Get the brass antenna coupler from the Whitcomb mausoleum in Old Mill Cemetery, east of Old Mill Road. I asked Pat to secure the spare during the evacuation. He used his family's dry, locked vault. Bellamy's chapel cellar key is on the workbench at the far end of the tunnel beneath the vault. Pat has the vault key. Pick up the cellar key while you're in there; the isolated county tuner is your next part."
	 },
	 "tuner":{
	  "ranger":"You've got the coil and cemetery coupler. Now take the cellar key up Chapel Road. The basement door is at the back right inside the church. Recover the tuning unit, then shut down the rack at MAIN ISOLATOR before coming back to the station.",
	  "nurse":"The spare tuner is below the chapel. Use the cellar key at the back-right door inside the church. Take a charged flashlight. Once you have the unit, cut the rack at MAIN ISOLATOR. My patients got worse the longer that tone kept running; don't leave it playing behind you.",
	  "mechanic":"Use the chapel cellar key at the back-right door inside the church. I left the spare county tuner disconnected on the bench before the creatures arrived. Take it, then cut the rack at MAIN ISOLATOR. Turning off the station won't cut that independent supply."
	 },
	 "shutdown":{
	  "ranger":"That speaker is still running on the hill. I'm not letting another rescue crew follow a recording. Cut the repeater at MAIN ISOLATOR in the chapel basement. Then head back to the station, set BYPASS GREEN and call county. Tell them no sirens.",
	  "nurse":"I've seen what that tone does to people. The chapel rack is still running. Shut it down at MAIN ISOLATOR in the chapel basement, then return to the station and set BYPASS GREEN. When you call county, ask them to come without sirens. Those things follow sound.",
	  "mechanic":"The chapel rack feeds a powered return loop into the station radio. Cut MAIN ISOLATOR in the chapel basement to silence both ends; the station switch won't do it. Then return to the station and set BYPASS GREEN for direct county. Call without sirens. I need that carrier silent before we leave."
	 },
	 "repair":{
	  "ranger":"Bring the coil, tuning unit and cemetery antenna coupler to the station receiver. Once it's working, set the desk BYPASS GREEN. Give county Old Mill Road and Blackwood, and ask for a quiet approach. I want someone real answering this time.",
	  "nurse":"The chapel is finally quiet. Take all three parts to the station receiver: coil, tuner and antenna coupler. Use the GREEN bypass when it's repaired. Tell county we have survivors who need medical help, and ask them to approach without sirens.",
	  "mechanic":"The chapel supply is isolated. Fit the signal coil, county tuner and antenna coupler at the station receiver. Then set its desk BYPASS GREEN / DIRECT COUNTY. GREEN isolates the contaminated chapel line and uses the spare county tuner. Leave AMBER disconnected."
	 },
	 "route":{
	  "ranger":"The receiver's working and the hill is quiet. Now set that desk BYPASS GREEN. Amber reconnects the chapel line. Leave it disconnected. Give county our location, not another looped message. Ask them to come without sirens.",
	  "nurse":"The carrier is silent, but you still need a direct line. Set the desk BYPASS GREEN, then call county. My records show how the symptoms progressed; tell them we need medical help. No sirens. I don't want those things following the rescue team.",
	  "mechanic":"The receiver has power, but the desk bypass is still on the dead chapel route. Set BYPASS GREEN / DIRECT COUNTY before transmitting. Green keeps the contaminated chapel line isolated. Hold E at the main receiver to call; ask for no sirens."
	 },
	 "call":{
	  "ranger":"Green. A direct county line, and that speaker can't interrupt us now. Hold E at the main receiver. Give them Blackwood and Old Mill Road, tell them who's still here, and ask for no sirens. Then switch the set off.",
	  "nurse":"The chapel is silent and the GREEN direct line is ready. Hold E at the receiver. Tell county about the survivors and the people missing in the woods. We need medical help, but no sirens; the creatures follow sound. Switch the set off after they answer.",
	  "mechanic":"Carrier isolated. GREEN bypass selected. You're connected directly to county. Hold E at the main receiver to transmit: Blackwood, Old Mill Road, no sirens. Once a real dispatcher confirms the call, switch the set off. We're done keeping that thing talking."
	 }
	}
	return lines.get(stage,{}).get(id,"Check the station instructions before calling county.")


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

func game_clinic_bedside(data:Dictionary)->bool:
	var rescue=town.game.clinic_rescue
	return data.actor.name=="NPC_nurse" and rescue!=null and rescue.phase in ["blackout","wake","bed"]
