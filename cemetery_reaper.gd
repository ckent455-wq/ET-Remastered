extends RefCounted
## Optional forest-edge encounter beyond the east (rear) cemetery fence.
func at_edge(p:Vector3)->bool:
	return p.y<2 and p.y> -1 and p.x>=35 and p.x<43 and p.z>= -28 and p.z<= -6

func spawn(enemies,data)->bool:
	var nav=enemies.reaper_navigation
	if not nav: return false
	var game=enemies.game
	var player:Vector3=game.player.global_position
	var choices=[]
	for id in nav.graph.get_point_ids():
		var p:Vector3=nav.graph.get_point_position(id)
		var distance=p.distance_to(player)
		if distance<7 or distance>14 or not nav.clear_at(p): continue
		var direction=(p-game.camera.global_position).normalized()
		var out_of_view=direction.dot(-game.camera.global_basis.z)<0.1
		var ray=PhysicsRayQueryParameters3D.create(game.camera.global_position,p+Vector3.UP,1,[game.player.get_rid(),data.actor.get_rid()])
		if not out_of_view and enemies.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		var path=nav.path(p,player)
		if path.is_empty() or path[-1].distance_to(player)>1.5: continue
		choices.append(p)
	if choices.is_empty(): return false
	data.actor.global_position=choices[choices.size()/2]
	data.actor.velocity=Vector3.ZERO
	data.actor.collision_layer=1
	data.actor.collision_mask=1
	data.actor.show()
	data.state="reaper_chase"
	data.timer=0
	data.path_timer=0
	return true

func update(enemies,data,delta:float):
	var game=enemies.game
	if data.state=="reaper_wait":
		if at_edge(game.player.global_position):
			data.state="reaper_warning"
			data.timer=0.8
			data.voice.stream=enemies.streams.growl
			data.voice.pitch_scale=0.65
			data.voice.volume_db=-8
			data.voice.play()
		return
	data.timer=maxf(0,data.timer-delta)
	data.cooldown=maxf(0,data.cooldown-delta)
	if data.state=="reaper_warning":
		if not at_edge(game.player.global_position):
			data.state="reaper_wait"
			data.voice.stop()
		elif data.timer<=0: spawn(enemies,data)
		return
	if data.state=="stagger":
		enemies.move_creature(data,Vector3.ZERO,delta)
		if data.timer<=0: data.state="reaper_chase"
		return
	var target:Vector3=game.player.global_position
	var near=target.x>23 and target.x<43 and target.z> -35 and target.z< -1 and absf(target.y-data.actor.global_position.y)<2
	if data.state=="attack":
		enemies.move_creature(data,Vector3.ZERO,delta)
		if not data.did_hit and data.timer<0.55:
			data.did_hit=true
			if data.actor.global_position.distance_to(target)<2.0 and enemies.line_clear(data,target+Vector3.UP): game.take_damage(26)
		if data.timer<=0:
			data.state="reaper_chase"
			data.cooldown=1.0
		return
	if not near:
		enemies.play(data,"idle1")
		enemies.move_creature(data,Vector3.ZERO,delta)
		return
	if target.distance_to(data.actor.global_position)<1.7 and data.cooldown<=0 and enemies.line_clear(data,target+Vector3.UP):
		data.state="attack"
		data.timer=1.15
		data.did_hit=false
		enemies.play(data,"punch")
		enemies.move_creature(data,Vector3.ZERO,delta)
		return
	if target.distance_to(data.actor.global_position)<1.5:
		enemies.play(data,"idle1")
		enemies.move_creature(data,Vector3.ZERO,delta)
		return
	data.path_timer-=delta
	if data.path_timer<=0:
		data.path=enemies.reaper_navigation.path(data.actor.global_position,target)
		data.path_timer=0.6
	while not data.path.is_empty() and data.actor.global_position.distance_to(data.path[0])<0.45: data.path.remove_at(0)
	var destination:Vector3=data.path[0] if not data.path.is_empty() else target
	var direction=destination-data.actor.global_position
	direction.y=0
	var wanted=direction.normalized()*1.8 if direction.length()>0.3 else Vector3.ZERO
	var velocity:Vector3=data.actor.velocity
	velocity.y=0
	var smooth=velocity.lerp(wanted,1-exp(-8*delta))
	enemies.move_creature(data,smooth,delta)
	var speed=Vector2(data.actor.velocity.x,data.actor.velocity.z).length()
	enemies.play(data,"walk1" if speed>0.15 else "idle1")

func animate(_enemies,data,delta:float):
	if data.state=="dead":
		data.animation.speed_scale=data.animation.get_animation(data.clips.death).length/1.35
		data.animation.advance(delta)
		data.visual.position=data.get("death_base",Vector3.ZERO)
		return
	var speed=Vector2(data.actor.velocity.x,data.actor.velocity.z).length()
	if data.clip=="walk1": data.animation.speed_scale=clampf(speed/1.6,0.2,1.4)
	elif data.clip=="punch": data.animation.speed_scale=data.animation.get_animation(data.clips.punch).length/0.9
	else: data.animation.speed_scale=1.0
	data.animation.advance(delta)
	# Imported clips contain their own hip travel. The CharacterBody owns world
	# movement, so remove that drift and place the supporting toe at ground level.
	var skeleton=data.visual.find_child("Skeleton3D",true,false) as Skeleton3D
	skeleton.force_update_all_bone_transforms()
	data.visual.position=Vector3.ZERO
	var hip:Vector3=data.actor.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_Hips")).origin))
	var feet=[]
	for name in ["mixamorig_LeftToeBase","mixamorig_RightToeBase"]:
		feet.append(data.actor.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(name)).origin)).y)
	data.visual.position=Vector3(-hip.x,0.02-minf(feet[0],feet[1]),-hip.z)
