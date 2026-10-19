extends SceneTree
func _initialize():call_deferred("run")
func bone(d,name):
	var s=d.visual.find_child("Skeleton3D",true,false)
	return d.actor.to_local(s.to_global(s.get_bone_global_pose(s.find_bone(name)).origin))
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	g.set_physics_process(false);g.enemies.set_physics_process(false)
	g.state="play"
	var e=g.enemies;var d=e.creatures[e.REAPER_INDEX]
	assert(d.clips.idle1=="motion_3" and d.clips.walk1=="motion_5" and d.clips.punch=="motion_6" and d.clips.death=="motion_0","Correct source motions")
	for clip in ["idle1","walk1","punch"]:
		e.play(d,clip)
		d.actor.velocity=Vector3(0,0,1.8) if clip=="walk1" else Vector3.ZERO
		for i in range(240):
			e.reaper_encounter.animate(e,d,1.0/60)
			var hip:Vector3=bone(d,"mixamorig_Hips")
			var toe=minf(bone(d,"mixamorig_LeftToeBase").y,bone(d,"mixamorig_RightToeBase").y)
			assert(absf(toe-0.02)<0.002,"Supporting foot stays planted throughout clip and blend")
			assert(Vector2(hip.x,hip.z).length()<0.002,"Animation does not slide outside physical body")
	e.play(d,"idle1");e.reaper_encounter.animate(e,d,0.2)
	var standing:float=bone(d,"mixamorig_Hips").y
	d.state="reaper_chase";d.actor.show();d.actor.collision_layer=1
	g.state="journal"
	var time=d.animation.current_animation_position
	e._physics_process(1)
	assert(d.animation.current_animation_position==time,"Manual animation pauses with gameplay")
	g.state="play";assert(e.shoot(e.REAPER_INDEX,100))
	for i in range(150):e._physics_process(1.0/60)
	assert(bone(d,"mixamorig_Hips").y<standing-0.5,"Native death settles body onto ground")
	var corpse:Vector3=bone(d,"mixamorig_Hips")
	e._physics_process(10)
	assert(bone(d,"mixamorig_Hips").distance_to(corpse)<0.001,"Corpse pose stays settled")
	print("PASS: correct idle/walk/attack/death clips, 720 planted-foot/root-drift samples, speed matching, pause, native grounded death")
	g.queue_free();await process_frame;quit()
