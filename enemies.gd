extends Node3D
## Native animated encounters with real collision and sight rays guarding combat.
var game
var creatures = []
const SPAWNS = [Vector3(19.2,0,-127),Vector3(38.7,0,-139),Vector3(39.5,0,-143.5),Vector3(1.4,0,-57.0),Vector3(-12.55,3.45,-95.2),Vector3(-16.1,-12.99,-96.3),Vector3(30,0,-28),Vector3(25.55,-23.99,-104),Vector3(26.45,-23.99,-96.5),Vector3(22.3,-23.99,-84.08)]
const WOOD_ROUTES = [[Vector3(19.8,0,-129.7),Vector3(21.0,0,-131.5),Vector3(24.0,0,-130.2)],[Vector3(38.3,0,-134.5),Vector3(37.8,0,-130.0),Vector3(34.8,0,-127.5)],[Vector3(39.0,0,-139),Vector3(38.3,0,-134.5),Vector3(37.8,0,-130),Vector3(34.8,0,-127.5)]]
const HEALTH = 85.0
const RESPAWN_SECONDS = 120.0
var sense_clock = 0.0
var streams = {}
var workshop_navigation
var workshop_attack_pending=false
var workshop_armed=false
var workshop_previous_x=18.0
var workshop_spawned=false
var workshop_defeated=false
const HOUSE_INDEX=4
const CELLAR_INDEX=5
const REAPER_INDEX=6
const TUNNEL_INDICES=[7,8,9]
var tunnel_encounter=preload("res://mausoleum_tunnel_monsters.gd").new()
var reaper_encounter=preload("res://cemetery_reaper.gd").new()
var reaper_navigation
var house_encounter=preload("res://house_monster.gd").new()
var cellar_encounter=preload("res://house_cellar_monster.gd").new()
const WORKSHOP_INDEX=3
const WORKSHOP_HEALTH=60.0
var navigation

func _ready():
	name = "BlackwoodCreeps"
	for sound in ["breath","growl","attack"]:
		streams[sound] = load("res://assets/enemies/"+sound+".wav")
	build_woodland_cover()
	for i in range(SPAWNS.size()):
		var actor = CharacterBody3D.new()
		actor.name = "Creep%d" % i
		actor.add_to_group("HostileEnemies")
		actor.set_meta("enemy_index",i)
		actor.floor_snap_length = 0.3
		add_child(actor)
		var collision = CollisionShape3D.new()
		var capsule = CapsuleShape3D.new()
		capsule.radius = 0.40
		capsule.height = 1.8
		collision.shape = capsule
		collision.position.y = 0.91
		actor.add_child(collision)
		var is_wrapper = i in [HOUSE_INDEX,CELLAR_INDEX] or i in TUNNEL_INDICES
		var scene_path = "res://assets/enemies/wrapper/wrapper.glb" if is_wrapper else "res://assets/enemies/creep.glb"
		if i==REAPER_INDEX: scene_path="res://assets/enemies/reaper/reaper.glb"
		var visual = load(scene_path).instantiate()
		actor.add_child(visual)
		game.town.apartment_interiors.adapt(visual)
		if i==CELLAR_INDEX or i in TUNNEL_INDICES: game.town.streetscape.church.basement.prepare_cellar_lighting(visual)
		var animation = visual.find_child("AnimationPlayer",true,false) as AnimationPlayer
		var clips = {}
		for clip in animation.get_animation_list():
			var short = str(clip).split("/")[-1].to_lower()
			clips[short] = clip
			animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if short in ["walk1","walk2","idle1","idle2","sniff"] else Animation.LOOP_NONE
		if is_wrapper:
			var aliases = {"idle1":"idle_watchful","walk1":"walk_nervous","punch":"attack_lunge","roar":"scream_lol","crouch_pose":"idle_watchful","death":"idle_watchful"}
			for alias in aliases: clips[alias] = clips[aliases[alias]]
			for key in ["idle_watchful","walk_nervous","run_frantic"]:
				animation.get_animation(clips[key]).loop_mode = Animation.LOOP_LINEAR
		if i==REAPER_INDEX:
			var aliases={"idle1":"motion_3","walk1":"motion_5","punch":"motion_6","roar":"motion_2","crouch_pose":"motion_3","death":"motion_0"}
			for alias in aliases: clips[alias]=clips[aliases[alias]]
			for key in ["motion_3","motion_5"]: animation.get_animation(clips[key]).loop_mode=Animation.LOOP_LINEAR
			animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		var voice = game.soundscape.spatial_voice(actor,streams.breath,-10,20)
		voice.pitch_scale = 0.92+i*0.06
		voice.unit_size = 5
		var route: Array[Vector3] = []
		for point in (WOOD_ROUTES[i] if i<3 else [SPAWNS[i]]): route.append(ground(point))
		var spawn = SPAWNS[i] if is_wrapper else ground(SPAWNS[i])
		creatures.append({"actor":actor,"visual":visual,"animation":animation,"clips":clips,"clip":"","hp":HEALTH,"state":"lurking","timer":0.0,"cooldown":0.0,"seen":false,"memory":0.0,"target":spawn,"spawn":spawn,"route":route,"waypoint":0,"voice":voice,"voice_timer":5.0+i*4,"blocked":0.0,"previous":spawn,"did_hit":false,"suspicion":0.0,"stalk_time":0.0,"index":i})
	reset()
	call_deferred("build_navigation")

func build_navigation():
	await get_tree().physics_frame
	navigation = preload("res://chapel_enemy_paths.gd").new(self)
	navigation.build()
	workshop_navigation=preload("res://chapel_enemy_paths.gd").new(self)
	workshop_navigation.build(Rect2i(-4,-77,25,39))
	reaper_navigation=preload("res://chapel_enemy_paths.gd").new(self)
	reaper_navigation.build(Rect2i(24,-35,19,34))

func reset():
	workshop_attack_pending=false
	workshop_armed=false
	workshop_previous_x=18.0
	workshop_spawned=false
	workshop_defeated=false
	for data in creatures: reset_creature(data)
	sense_clock = 0

func reset_creature(data):
	data.actor.position = data.spawn
	data.actor.rotation = Vector3(0,PI,0)
	data.actor.velocity = Vector3.ZERO
	data.actor.collision_layer = 1
	data.actor.collision_mask = 1
	data.hp = WORKSHOP_HEALTH if data.index in [WORKSHOP_INDEX,HOUSE_INDEX,CELLAR_INDEX] or data.index in TUNNEL_INDICES else HEALTH
	data["fall_time"] = 0.0
	data.visual.rotation = Vector3.ZERO
	data.visual.position = Vector3.ZERO
	data["max_hp"]=data.hp
	data.actor.show()
	data.state = "lurking"
	data.timer = 2.0
	data.cooldown = 0.0
	data.memory = 0.0
	data.seen = false
	data.waypoint = 0
	data.target = data.spawn
	data.voice.stop()
	data.voice_timer = 5.0
	data.clip = ""
	data.blocked = 0.0
	data.did_hit = false
	data.suspicion = 0.0
	data.stalk_time = 0.0
	data["path"] = PackedVector3Array()
	data["path_timer"] = 0.0
	data["path_target"] = data.spawn
	data.animation.stop()
	play(data,"crouch_pose")
	data["respawn_remaining"] = 0.0
	data.animation.advance(0)
	if data.index==HOUSE_INDEX:
		data.state="house_wait"
		data["house_waypoint"]=0
		play(data,"idle1")
	if data.index==CELLAR_INDEX:
		data.state="cellar_wait"
		data["cellar_waypoint"]=false
		play(data,"idle1")
	if data.index in TUNNEL_INDICES:
		data.state="tunnel_wait"
		data["tunnel_waypoint"]=0
		data["coffin_release"]=0.0
		if data.index==TUNNEL_INDICES[2]:
			data.actor.collision_layer=0
			data.actor.collision_mask=0
		play(data,"idle1")
	if data.index==REAPER_INDEX:
		data.state="reaper_wait"
		data.actor.hide()
		data.actor.collision_layer=0
		data.actor.collision_mask=0
		data["path"]=PackedVector3Array()
		data["path_timer"]=0.0
		play(data,"idle1")
	if data.index==WORKSHOP_INDEX:
		data.state="dormant"
		data.actor.hide()
		data.actor.collision_layer=0
		data.actor.collision_mask=0

func play(data, clip: String):
	if data.clip==clip or not data.clips.has(clip): return
	data.clip = clip
	data.animation.play(data.clips[clip],0.15)

func line_clear(data, target: Vector3) -> bool:
	var from: Vector3 = data.actor.global_position+Vector3(0,1.1,0)
	var ray = PhysicsRayQueryParameters3D.create(from,target,1,[data.actor.get_rid(),game.player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func alert_shot(p: Vector3):
	if game.state!="play": return
	for data in creatures:
		if data.hp<=0 or data.index in [HOUSE_INDEX,CELLAR_INDEX,REAPER_INDEX] or data.index in TUNNEL_INDICES or data.actor.global_position.distance_to(p)>32: continue
		data.target = p
		data.memory = 9.0
		if data.state in ["lurking","returning"]:
			data.state = "stalking"
			data.stalk_time = 0
			data.waypoint = 0
		elif data.state=="patrol":
			data.state = "investigate"
			data.timer = 0

func shoot(index: int, damage: float) -> bool:
	if game.state!="play" or index<0 or index>=creatures.size(): return false
	var data = creatures[index]
	if data.hp<=0 or data.state in ["dormant","reaper_wait","reaper_warning"]: return false
	if data.index==WORKSHOP_INDEX and not workshop_spawned:
		workshop_spawned=true
		workshop_armed=false
	data.hp = maxf(0,data.hp-damage)
	data.target = game.player.global_position
	data.memory = 10.0
	data.timer = 0.38
	data.did_hit = true
	if data.hp<=0:
		data.state = "dead"
		if data.index==TUNNEL_INDICES[1] and game.hotel_basement:
			game.hotel_basement.get_node("CellarCoffinStacks").start_blackout()
		if data.index==WORKSHOP_INDEX:
			workshop_defeated=true
			game.message="The creature collapses. Search the workshop for the signal coil."
		data.respawn_remaining = RESPAWN_SECONDS
		data.actor.velocity = Vector3.ZERO
		data.actor.collision_layer = 0
		data.actor.collision_mask = 0
		data.voice.stop()
		if data.index==REAPER_INDEX: data["death_base"]=data.visual.position
		play(data,"death")
	else:
		data.state = "stagger"
		play(data,"roar")
	return true

func sense(data):
	var p: Vector3 = game.player.global_position
	var distance = data.actor.global_position.distance_to(p)
	var lit = game.flashlight.visible and game.flashlight_charge>0
	data.seen = distance<(24.0 if lit else 15.0) and line_clear(data,p+Vector3(0,1.0,0))
	var heard = distance<8.0 and game.player.velocity.length()>4.0 and line_clear(data,p+Vector3(0,0.8,0))
	if data.seen or heard:
		data.target = p
		data.memory = 7.0
		if data.state in ["patrol","investigate"]:
			data.state = "alert"
			data.timer = 1.1
			play(data,"roar")
			data.voice.stream = streams.growl
			data.voice.play()

func near_chapel() -> bool:
	var p: Vector3 = game.player.global_position
	return p.z< -113 and p.x>10 and p.y>3

func watched(data) -> bool:
	var offset: Vector3 = data.actor.global_position+Vector3(0,0.8,0)-game.camera.global_position
	return offset.length()<25 and -game.camera.global_basis.z.dot(offset.normalized())>0.72 and line_clear(data,game.camera.global_position)

func health_bar_targets() -> Array:
	var targets = []
	if game.state!="play": return targets
	for data in creatures:
		if data.hp<=0 or data.state in ["lurking","house_wait","tunnel_wait"] or not data.actor.is_visible_in_tree(): continue
		if data.actor.global_position.distance_to(game.camera.global_position)>18: continue
		var point: Vector3 = data.actor.global_position+Vector3(0,2.25,0)
		if game.camera.is_position_behind(point) or not line_clear(data,game.camera.global_position): continue
		var screen = game.camera.unproject_position(point)
		if screen.x<26 or screen.x>614 or screen.y>315: continue
		targets.append({"point":Vector2(screen.x,maxf(28,screen.y)),"fraction":clampf(data.hp/data.get("max_hp",HEALTH),0,1)})
	return targets

func _physics_process(delta):
	var active = game.state=="play"
	if active: game.town.townspeople.set_sheltering(town_threat_active())
	sense_clock -= delta
	var sensing = sense_clock<=0
	if sensing: sense_clock = 0.18
	for data in creatures:
		var animation_rate = 1.0
		if data.state in ["attack","alert"] and data.clips.has(data.clip):
			animation_rate = data.animation.get_animation(data.clips[data.clip]).length/(1.45 if data.state=="attack" else 1.1)
		elif data.state=="chase": animation_rate = 1.5
		data.animation.speed_scale = animation_rate if active else 0
		data.voice.stream_paused = not active
		if not active: continue
		if (data.index in [HOUSE_INDEX,CELLAR_INDEX] or data.index in TUNNEL_INDICES) and data.state=="dead":
			data.fall_time = minf(1,data.fall_time+delta/0.7)
			data.animation.speed_scale = 0
			data.visual.rotation.x = -smoothstep(0,1,data.fall_time)*PI/2
			continue
		if data.index==HOUSE_INDEX:
			house_encounter.update(self,data,delta)
			continue
		if data.index==CELLAR_INDEX:
			cellar_encounter.update(self,data,delta)
			continue
		if data.index in TUNNEL_INDICES:
			tunnel_encounter.update(self,data,delta)
			continue
		if data.index==REAPER_INDEX:
			if data.state!="dead": reaper_encounter.update(self,data,delta)
			reaper_encounter.animate(self,data,delta)
			continue
		if data.index==WORKSHOP_INDEX:
			update_workshop_creature(data,delta)
			continue
		if data.state=="dead":
			data.respawn_remaining = maxf(0,data.respawn_remaining-delta)
			if data.respawn_remaining<=0: reset_creature(data)
			continue
		data.timer = maxf(0,data.timer-delta)
		data.cooldown = maxf(0,data.cooldown-delta)
		data.memory = maxf(0,data.memory-delta)
		data.voice_timer -= delta
		if sensing and data.state not in ["lurking","stalking","returning"]: sense(data)
		if data.state=="lurking":
			var close = data.actor.global_position.distance_to(game.player.global_position)<20 and near_chapel()
			data.suspicion = minf(8,data.suspicion+delta) if close else maxf(0,data.suspicion-delta)
			if close and data.voice_timer<=0 and not data.voice.playing:
				data.voice.volume_db = -16
				data.voice.stream = streams.breath
				data.voice.play()
				data.voice_timer = 16
			if data.suspicion>3.5+data.index*1.5 and (not watched(data) or data.suspicion>=8):
				data.state = "stalking"
				data.waypoint = 0
				data.stalk_time = 0
			play(data,"crouch_pose")
			move_creature(data,Vector3.ZERO,delta)
			continue
		if data.state=="stalking":
			data.stalk_time += delta
			var offset: Vector3 = data.route[data.waypoint]-data.actor.global_position
			offset.y = 0
			if offset.length()<0.65:
				data.waypoint = mini(data.waypoint+1,data.route.size()-1)
			play(data,"walk2")
			move_creature(data,path_direction(data,data.route[data.waypoint],delta)*0.95,delta)
			if data.stalk_time>5 and data.actor.global_position.distance_to(game.player.global_position)<12 and line_clear(data,game.player.global_position+Vector3(0,1,0)):
				data.state = "chase"
				data.memory = 8
				data.target = game.player.global_position
				data.voice.stream = streams.growl
				data.voice.volume_db = -10
				data.voice.play()
			elif not near_chapel() and data.stalk_time>12:
				data.state = "returning"
			continue
		if data.state=="returning":
			var offset: Vector3 = data.spawn-data.actor.global_position
			offset.y = 0
			play(data,"walk2")
			move_creature(data,path_direction(data,data.spawn,delta)*0.8 if offset.length()>0.5 else Vector3.ZERO,delta)
			if offset.length()<0.5:
				data.state = "lurking"
				data.suspicion = 0
			continue
		if data.voice_timer<=0 and data.actor.global_position.distance_to(game.player.global_position)<18:
			if not data.voice.playing:
				data.voice.stream = streams.breath
				data.voice.play()
			data.voice_timer = 12
		var desired = Vector3.ZERO
		var target: Vector3 = data.target
		if data.state in ["stagger","alert"]:
			if data.timer<=0: data.state = "chase" if data.seen else "investigate"
		elif data.state=="attack":
			if not data.did_hit and data.timer<0.65:
				data.did_hit = true
				if data.actor.global_position.distance_to(game.player.global_position)<1.9 and line_clear(data,game.player.global_position+Vector3(0,1,0)):
					if game.take_damage(22):
						game.message = "Claws tear into you. Run or fight. H uses a first-aid kit."
			if data.timer<=0:
				data.state = "chase"
				data.cooldown = 0.8
		elif data.state in ["chase","investigate"]:
			var offset: Vector3 = target-data.actor.global_position
			offset.y = 0
			if data.seen and offset.length()<1.55 and data.cooldown<=0:
				data.state = "attack"
				data.timer = 1.45
				data.did_hit = false
				play(data,"punch")
				data.voice.stream = streams.attack
				data.voice.play()
			elif data.memory<=0:
				data.state = "returning"
				data.timer = 2.0
			elif offset.length()>0.7:
				desired = path_direction(data,target,delta)*(2.05 if data.state=="chase" else 1.15)
				play(data,"walk1")
			else:
				play(data,"sniff")
		else:
			var patrol = [data.spawn+Vector3(-1.5,0,0),data.spawn+Vector3(-1.5,0,4),data.spawn+Vector3(0,0,4),data.spawn]
			for point in range(patrol.size()):
				patrol[point].x = clampf(patrol[point].x,-3.1,3.1)
			var offset: Vector3 = patrol[data.waypoint]-data.actor.global_position
			offset.y = 0
			if offset.length()<0.35:
				data.waypoint = (data.waypoint+1)%4
				data.timer = 2.5
			if data.timer<=0:
				desired = offset.normalized()*0.65
				play(data,"walk2")
			else: play(data,"idle1")
		move_creature(data,desired,delta)

func move_creature(data, desired: Vector3, delta: float):
	var actor: CharacterBody3D = data.actor
	if desired.length()>0.1:
		# Probe a capsule before each step. A small fan steers around street
		# furniture while real move_and_slide keeps doors and walls solid.
		var chosen = Vector3.ZERO
		for angle in [0.0,0.65,-0.65,1.15,-1.15,1.65,-1.65]:
			var candidate = desired.rotated(Vector3.UP,angle)
			var step = candidate.normalized()*0.55
			var current_ground = ground(actor.global_position).y
			var next_ground = ground(actor.global_position+step).y
			step.y = maxf(0,next_ground-current_ground)+0.06
			var collision = KinematicCollision3D.new()
			var blocked = actor.test_move(actor.global_transform,step,collision)
			if not blocked or collision.get_normal().y>0.7:
				chosen = candidate
				break
		desired = chosen
		if desired.length()>0.1:
			actor.rotation.y = lerp_angle(actor.rotation.y,atan2(desired.x,desired.z),minf(1,delta*4))
	actor.velocity.x = desired.x
	actor.velocity.z = desired.z
	actor.velocity.y = -0.5 if actor.is_on_floor() else maxf(-12,actor.velocity.y-18*delta)
	actor.move_and_slide()

func path_direction(data, target: Vector3, delta: float) -> Vector3:
	var from: Vector3 = data.actor.global_position
	if navigation!=null and from.z< -117 and from.x>13 and target.z< -117 and target.x>13:
		data.path_timer -= delta
		if data.path_timer<=0 or data.path_target.distance_to(target)>1.5:
			data.path = navigation.path(from,target)
			data.path_target = target
			data.path_timer = 0.8+data.index*0.15
		while data.path.size()>0 and Vector2(from.x,from.z).distance_to(Vector2(data.path[0].x,data.path[0].z))<0.65:
			data.path.remove_at(0)
		if data.path.size()>0: target = data.path[0]
	var direction = target-from
	direction.y = 0
	return direction.normalized() if direction.length()>0.1 else Vector3.ZERO

func ground(p: Vector3) -> Vector3:
	return Vector3(p.x,game.town.streetscape.chapel_hill.terrain_height_at(p)+0.14,p.z)

func build_woodland_cover():
	# Real scenery occludes the resting creatures. The passage around each
	# boulder faces the woods, leaving Chapel Road and the footpath clear.
	for i in range(3):
		var p = ground(SPAWNS[i]+Vector3(0.15,0,2.3))
		var rock = preload("res://assets/forest/rock_1.glb").instantiate()
		add_child(rock)
		rock.position = p
		rock.scale = Vector3(3.0,2.8,2.0)
		game.town.apartment_interiors.adapt(rock)
		var bounds = AABB()
		var first = true
		for mesh in rock.find_children("*","MeshInstance3D",true,false):
			var box: AABB = (global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		var lift: float = p.y-bounds.position.y-0.12
		rock.position.y += lift
		bounds.position.y += lift
		var body = StaticBody3D.new()
		body.name = "ChapelWoodlandCover%d" % i
		add_child(body)
		body.position = bounds.get_center()
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = bounds.size*Vector3(0.88,0.94,0.88)
		collision.shape = shape
		body.add_child(collision)
		for offset in [Vector3(-1.8,0,0.2),Vector3(1.7,0,0.4),Vector3(-0.9,0,-1.5)]:
			var bush = preload("res://assets/forest/bush_f.glb").instantiate()
			add_child(bush)
			bush.position = ground(SPAWNS[i]+offset)
			bush.scale = Vector3(2.4,1.6,2.2)
			game.town.apartment_interiors.adapt(bush)

func arm_workshop_encounter():
	if workshop_spawned or workshop_defeated:return
	game.town.townspeople.set_sheltering(true)
	start_workshop_encounter()

func start_workshop_encounter():
	if workshop_spawned or workshop_defeated:return
	workshop_spawned=true
	workshop_armed=false
	game.message="The power comes on. Something on Main Street starts walking toward you."
	var data=creatures[WORKSHOP_INDEX]
	data.actor.show()
	data.actor.collision_layer=1
	data.actor.collision_mask=1
	data.state="chase"
	data.timer=0.0
	data.path_timer=0.0
	data.voice.stream=streams.growl
	data.voice.play()
	play(data,"walk1")

func workshop_danger() -> bool:
	return workshop_spawned and not workshop_defeated

func update_workshop_creature(data,delta:float):
	var p:Vector3=game.player.global_position
	if data.state in ["dormant","dead"]:return
	if data.state=="ambush_wait":
		move_creature(data,Vector3.ZERO,delta)
		return
	data.timer=maxf(0,data.timer-delta)
	data.cooldown=maxf(0,data.cooldown-delta)
	if data.state in ["alert","stagger"]:
		if data.timer<=0:data.state="chase"
		return
	var target:Vector3=game.player.global_position
	if target.y< -1:
		play(data,"idle1")
		move_creature(data,Vector3.ZERO,delta)
		return
	if data.state=="attack":
		if not data.did_hit and data.timer<0.65:
			data.did_hit=true
			if data.actor.global_position.distance_to(target)<1.9 and line_clear(data,target+Vector3.UP):game.take_damage(14)
		if data.timer<=0:
			data.state="chase"
			data.cooldown=1.0
		move_creature(data,Vector3.ZERO,delta)
		return
	if data.actor.global_position.distance_to(target)<1.55 and data.cooldown<=0 and line_clear(data,target+Vector3.UP):
		data.state="attack"
		data.timer=1.45
		data.did_hit=false
		play(data,"punch")
		data.voice.stream=streams.attack
		data.voice.play()
		return
	var direction=target-data.actor.global_position
	if workshop_navigation:
		data.path_timer-=delta
		if data.path_timer<=0 or data.path_target.distance_to(target)>1.5:
			data.path=workshop_navigation.path(data.actor.global_position,target)
			data.path_target=target
			data.path_timer=0.65
		while data.path.size()>0 and Vector2(data.actor.position.x,data.actor.position.z).distance_to(Vector2(data.path[0].x,data.path[0].z))<0.55:data.path.remove_at(0)
		if data.path.size()>0:direction=data.path[0]-data.actor.global_position
	direction.y=0
	play(data,"walk1")
	move_creature(data,direction.normalized()*1.85 if direction.length()>0.5 else Vector3.ZERO,delta)

func town_threat_active()->bool:
	if game.cemetery_shadow and game.cemetery_shadow.appeared and not game.cemetery_shadow.vanished:return true
	if workshop_armed or workshop_danger():return true
	for data in creatures:
		if data.index==WORKSHOP_INDEX or data.index in TUNNEL_INDICES or data.hp<=0:continue
		if data.state in ["stalking","alert","chase","attack","investigate","stagger"]:return true
	return false
