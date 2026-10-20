extends Node3D
## The pistol belongs to the patrol car; reach it only through its open door.
var game
var car:StaticBody3D
var door:Node3D
var door_area:Area3D
var pickup:Area3D
var door_open=false
var tween:Tween
var leaf:StaticBody3D
var collision:CollisionShape3D
var cabin_light:OmniLight3D
const OPEN_ANGLE=-1.12

func _ready():
	name="PoliceCarSearch"
	for child in game.town.streetscape.get_children():
		if child is StaticBody3D and "abandoned_police" in str(child.get_meta("vehicle_model","")):car=child;break
	door=car.find_child("DriverDoor",true,false)
	build_cabin()
	door_area=game.town.action_area(door,Vector3(-0.12,0.10,0.57),Vector3(0.23,0.42,0.32),"police_driver_door",{"kind":"police_door","label":"Open police car driver's door"})
	leaf=StaticBody3D.new();door.add_child(leaf)
	collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(0.06,0.43,0.65);collision.shape=shape;collision.position=Vector3(-0.02,0,0.34);collision.disabled=true;leaf.add_child(collision)
	pickup=game.town.actions.weapon_pistol.area
	pickup.reparent(car,false)
	game.town.actions.weapon_pistol.authored_placement=true
	pickup.position=Vector3(-0.42,0.57,-0.19)
	var model=pickup.get_child(1)
	model.rotation=Vector3(0,0.35,PI/2);model.scale=Vector3.ONE*0.65
	var bounds=AABB();var first=true
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		var part=(pickup.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		bounds=part if first else bounds.merge(part);first=false
	model.position-=bounds.get_center()
	pickup.position.y=0.536+bounds.size.y/2
	pickup.get_child(0).shape.size=bounds.size+Vector3(0.10,0.10,0.10)
	reset()

func build_cabin():
	preload("res://police_cabin_details.gd").build(self)

func reset():
	if tween:tween.kill()
	door_open=false;door.rotation.y=0
	cabin_light.hide()
	collision.set_deferred("disabled",true)
	pickup.collision_layer=0
	game.town.actions.police_driver_door.label="Open police car driver's door"

func interact():
	door_open=not door_open
	cabin_light.visible=door_open
	if tween:tween.kill()
	collision.set_deferred("disabled",true)
	tween=create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(door,"rotation:y",OPEN_ANGLE if door_open else 0.0,0.65)
	game.town.actions.police_driver_door.label=("Close" if door_open else "Open")+" police car driver's door"
	game.soundscape.storage_move(car.global_position,false,door_open)
	game.message="A pistol is lying on the driver's seat." if door_open and not game.weapons.owned[0] else "Police car door opened." if door_open else "Police car door closed."

func can_take()->bool:
	return door_open and absf(door.rotation.y-OPEN_ANGLE)<0.04

func _process(_delta):
	if tween and tween.is_valid():
		if game.state!="play":tween.pause()
		elif not tween.is_running() and not is_equal_approx(door.rotation.y,OPEN_ANGLE if door_open else 0.0):tween.play()
	pickup.collision_layer=2 if can_take() and not game.town.actions.weapon_pistol.taken else 0
	if game.state!="play" or not can_take():return
	# Never enable a stationary open door inside the player's capsule.
	var query=PhysicsShapeQueryParameters3D.new();query.shape=collision.shape;query.transform=collision.global_transform;query.collision_mask=1;query.exclude=[car.get_rid(),leaf.get_rid()]
	var overlaps=get_world_3d().direct_space_state.intersect_shape(query)
	var player_overlap=overlaps.any(func(hit):return hit.collider==game.player)
	if collision.disabled!=player_overlap:collision.set_deferred("disabled",player_overlap)

func pickup_focus(start:Vector3,finish:Vector3)->String:
	if not can_take() or game.town.actions.weapon_pistol.taken:return ""
	var a=car.to_local(start);var b=car.to_local(finish)
	if a.x>=-0.90 or b.x<=a.x:return ""
	var t=(-0.74-a.x)/(b.x-a.x)
	if t<0 or t>1:return ""
	var crossing=a.lerp(b,t)
	if crossing.y<0.40 or crossing.y>1.24 or crossing.z< -0.54 or crossing.z>0.205:return ""
	var query=PhysicsRayQueryParameters3D.create(start,finish,2,[door_area.get_rid()]);query.collide_with_areas=true;query.collide_with_bodies=false
	var hit=get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.collider!=pickup:return ""
	var obstacle=PhysicsRayQueryParameters3D.create(start,hit.position,1,[car.get_rid(),leaf.get_rid(),game.player.get_rid()])
	return "weapon_pistol" if get_world_3d().direct_space_state.intersect_ray(obstacle).is_empty() else ""
