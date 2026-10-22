extends RefCounted
## The user's original low-poly monster waits in the chapel cellar.
const HEALTH=168.0

func configure(visual:Node3D)->AnimationPlayer:
	visual.name="HollowMonster"
	visual.scale=Vector3.ONE*0.78
	retro(visual)
	var skeleton=visual.find_child("Skeleton3D",true,false) as Skeleton3D
	var player=AnimationPlayer.new()
	player.name="HollowAnimations"
	visual.add_child(player)
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var library=AnimationLibrary.new()
	for clip in ["idle1","walk1","walk2","sniff","crouch_pose","punch","roar","death"]:
		var animation=Animation.new()
		animation.length=1.2 if clip=="death" else 1.45 if clip=="punch" else 2.4 if clip in ["idle1","sniff","crouch_pose"] else 1.1
		animation.loop_mode=Animation.LOOP_LINEAR if clip in ["idle1","walk1","walk2","sniff","crouch_pose"] else Animation.LOOP_NONE
		for name in ["spine","chest","head","upper_arm.L","upper_arm.R","forearm.L","forearm.R","thigh.L","thigh.R","shin.L","shin.R","foot.L","foot.R"]:
			var rest_rotation=skeleton.get_bone_rest(skeleton.find_bone(name)).basis.get_rotation_quaternion()
			var track=animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(track,NodePath(str(visual.get_path_to(skeleton))+":"+name))
			for frame in range(17):
				var t=frame/16.0
				var angle=0.0
				var phase=t*TAU+(PI if name.ends_with(".R") else 0.0)
				if clip in ["walk1","walk2"]:
					if name.begins_with("thigh"):angle=sin(phase)*0.52
					elif name.begins_with("shin"):angle=maxf(0,-sin(phase))*0.75
					elif name.begins_with("foot"):angle=-sin(phase)*0.15
					elif name.begins_with("upper_arm"):angle=-sin(phase)*0.22
					elif name=="chest":angle=0.035+sin(t*TAU*2)*0.018
				elif clip=="punch":
					var wind=sin(clampf(t/0.48,0,1)*PI/2)
					var strike=smoothstep(0.48,0.68,t)
					var settle=smoothstep(0.76,1.0,t)
					if name.begins_with("upper_arm"):angle=(0.65*wind-1.45*strike)*(1-settle)
					elif name.begins_with("forearm"):angle=-0.35*wind*(1-strike)
					elif name=="chest":angle=(0.12*wind-0.28*strike)*(1-settle)
				elif clip=="death":
					if name=="spine":angle=-0.45*sin(t*PI)
					elif name.begins_with("shin"):angle=0.7*sin(t*PI)
					elif name.begins_with("upper_arm"):angle=-0.6*sin(t*PI)
					elif name=="head":angle=-0.22*t
				else:
					if name=="chest":angle=sin(t*TAU)*0.018
					elif name=="head":angle=sin(t*TAU+0.5)*0.022
					elif name.begins_with("upper_arm"):angle=sin(phase)*0.015
					if clip=="roar" and name=="head":angle-=sin(t*PI)*0.20
				animation.rotation_track_insert_key(track,t*animation.length,rest_rotation*Quaternion(Vector3.RIGHT,angle))
		# Every clip resets the root so respawning or changing clips clears a fall.
		var rotation=animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(rotation,NodePath("."))
		var position=animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(position,NodePath("."))
		for t in [0.0,0.3,0.65,1.0]:
			var fall=smoothstep(0.20,1,t) if clip=="death" else 0.0
			animation.rotation_track_insert_key(rotation,t*animation.length,Quaternion(Vector3.RIGHT,fall*PI/2))
			animation.position_track_insert_key(position,t*animation.length,Vector3(0,0.30*fall,0.12*fall))
		library.add_animation(clip,animation)
	player.add_animation_library("",library)
	return player

func retro(node:Node):
	if node is MeshInstance3D:
		node.visibility_range_end=40
		for i in range(node.mesh.get_surface_count()):
			var material=node.mesh.surface_get_material(i).duplicate() as StandardMaterial3D
			material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			material.shading_mode=BaseMaterial3D.SHADING_MODE_PER_VERTEX
			material.roughness=1
			material.metallic=0
			material.metallic_specular=0
			material.emission_enabled=false
			node.set_surface_override_material(i,material)
	for child in node.get_children():retro(child)

func animate(data,delta:float):
	var rate=1.0
	if data.clip in ["walk1","walk2"]:
		# Match the stepping rate to actual travel, including blocked movement.
		rate=Vector2(data.actor.velocity.x,data.actor.velocity.z).length()*1.1/0.95
	data.animation.speed_scale=rate
	data.animation.advance(delta)

func update(e,data,delta:float):
	var cellar=e.game.town.streetscape.church.basement
	var inside=cellar.contains(e.game.player.global_position)
	if data.state=="chapel_wait":
		e.move_creature(data,Vector3.ZERO,delta)
		if inside and cellar.to_local(e.game.player.global_position).z<0.75 and e.line_clear(data,e.game.player.global_position+Vector3.UP):
			data.state="chase";data.pursuing=true;data.target=e.game.player.global_position
			data.voice.stream=e.streams.growl;data.voice.volume_db=-12;data.voice.pitch_scale=0.68;data.voice.play()
		else:
			data.voice_timer-=delta
			if inside and data.voice_timer<=0:
				data.voice.stream=e.streams.breath;data.voice.pitch_scale=0.68;data.voice.play();data.voice_timer=12
