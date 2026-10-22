extends RefCounted
## Bullet volumes follow the currently rendered skeleton, independently of locomotion.
var enemies
var rigs={}

func _init(owner): enemies=owner

func rig(data)->Dictionary:
	if rigs.has(data.index): return rigs[data.index]
	var skeleton=data.visual.find_child("Skeleton3D",true,false) as Skeleton3D
	var bones={}
	for i in range(skeleton.get_bone_count()):
		bones[skeleton.get_bone_name(i).to_lower().replace(":","_").replace(".","_")]=i
	var head="head"
	var neck="neck"
	var links=[]
	if data.index==enemies.HOLLOW_INDEX:
		neck="chest"
		links=[["pelvis","chest",0.25],["chest","head",0.24]]
		for side in ["l","r"]:
			for pair in [["upper_arm_","forearm_",0.16],["forearm_","hand_",0.15],["thigh_","shin_",0.15],["shin_","foot_",0.12]]:
				links.append([pair[0]+side,pair[1]+side,pair[2]])
	elif bones.has("mixamorig_head"):
		head="mixamorig_head";neck="mixamorig_neck"
		links=[["mixamorig_hips","mixamorig_spine2",0.26],["mixamorig_spine2",neck,0.20]]
		for side in ["left","right"]:
			links.append(["mixamorig_"+side+"arm","mixamorig_"+side+"forearm",0.14])
			links.append(["mixamorig_"+side+"forearm","mixamorig_"+side+"hand",0.13])
			links.append(["mixamorig_"+side+"upleg","mixamorig_"+side+"leg",0.17])
			links.append(["mixamorig_"+side+"leg","mixamorig_"+side+"foot",0.14])
	elif bones.has("hips"):
		links=[["hips","chest",0.25],["chest",neck,0.20]]
		for side in ["l","r"]:
			for pair in [["upper_arm_","forearm_",0.14],["forearm_","hand_",0.13],["thigh_","shin_",0.17],["shin_","foot_",0.14]]:
				links.append([pair[0]+side,pair[1]+side,pair[2]])
	else:
		links=[["torso","chest",0.29],["chest",neck,0.23]]
		for side in ["l","r"]:
			for pair in [["shoulder_","arm1_",0.17],["arm1_","arm2_",0.15],["arm2_","hand_",0.14],["leg1_","leg2_",0.19],["leg2_","leg3_",0.16],["leg3_","foot_",0.14]]:
				links.append([pair[0]+side,pair[1]+side,pair[2]])
	var result={"skeleton":skeleton,"bones":bones,"head":head,"neck":neck,"links":links}
	rigs[data.index]=result
	return result

func point(r,name:String)->Vector3:
	return r.skeleton.to_global(r.skeleton.get_bone_global_pose(r.bones[name]).origin)

func head_center(data)->Vector3:
	var r=rig(data)
	r.skeleton.force_update_all_bone_transforms()
	if data.index==enemies.HOLLOW_INDEX:
		var transform=r.skeleton.global_transform*r.skeleton.get_bone_global_pose(r.bones.head)
		return transform*Vector3(0,0.38,0)
	var head=point(r,r.head)
	return head+(head-point(r,r.neck)).normalized()*0.09

func sphere(origin:Vector3,direction:Vector3,center:Vector3,radius:float)->float:
	var offset=origin-center
	var b=offset.dot(direction)
	var h=b*b-offset.length_squared()+radius*radius
	if h<0:return INF
	var t=-b-sqrt(h)
	return maxf(0,t) if -b+sqrt(h)>=0 else INF

func capsule(origin:Vector3,direction:Vector3,start:Vector3,end:Vector3,radius:float)->float:
	var nearest=minf(sphere(origin,direction,start,radius),sphere(origin,direction,end,radius))
	var axis=end-start
	var offset=origin-start
	var length=axis.length_squared()
	var along=axis.dot(direction)
	var distance=axis.dot(offset)
	var a=length-along*along
	var b=length*direction.dot(offset)-distance*along
	var c=length*(offset.length_squared()-radius*radius)-distance*distance
	var h=b*b-a*c
	if absf(a)>0.000001 and h>=0:
		var t=(-b-sqrt(h))/a
		var y=distance+t*along
		if t>=0 and y>0 and y<length:nearest=minf(nearest,t)
	return nearest

func trace(origin:Vector3,direction:Vector3,limit:float)->Dictionary:
	var nearest=limit
	var hit={}
	for data in enemies.creatures:
		if data.hp<=0 or not data.actor.is_visible_in_tree() or data.actor.collision_layer==0:continue
		var r=rig(data)
		r.skeleton.force_update_all_bone_transforms()
		var distance=sphere(origin,direction,head_center(data),0.25)
		if data.index==enemies.HOLLOW_INDEX:
			var transform=r.skeleton.global_transform*r.skeleton.get_bone_global_pose(r.bones.head)
			distance=capsule(origin,direction,transform*Vector3(0,0.04,0),transform*Vector3(0,0.69,0),0.24)
		var zone="head"
		for pair in r.links:
			if not r.bones.has(pair[0]) or not r.bones.has(pair[1]):continue
			var body=capsule(origin,direction,point(r,pair[0]),point(r,pair[1]),pair[2])
			if body<distance:
				distance=body;zone="body"
		if distance<nearest:
			nearest=distance
			hit={"collider":data.actor,"position":origin+direction*distance,"normal":-direction,"zone":zone}
	return hit
