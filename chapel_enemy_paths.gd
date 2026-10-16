extends RefCounted
## A small, physics-sampled route graph around the chapel. Built once after
## the forest exists; no navigation through tree trunks, cover or church walls.
var enemies
var graph = AStar3D.new()
var cells = {}
var excludes = []
var capsule = CapsuleShape3D.new()

func _init(owner):
	enemies = owner
	capsule.radius = 0.43
	capsule.height = 1.8
	excludes.append(enemies.game.player.get_rid())
	for data in enemies.creatures: excludes.append(data.actor.get_rid())

func clear_at(p: Vector3) -> bool:
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.exclude = excludes
	query.collision_mask = 1
	# Allow floor slope beneath the capsule while testing trunk/wall clearance.
	query.transform.origin = p+Vector3(0,1.22,0)
	return enemies.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func build():
	for z in range(-151,-117):
		for x in range(14,42):
			var p: Vector3 = enemies.ground(Vector3(x,0,z))
			if not clear_at(p): continue
			var id = graph.get_point_count()
			graph.add_point(id,p)
			cells[Vector2i(x,z)] = id
	for cell in cells:
		var a: Vector3 = graph.get_point_position(cells[cell])
		for step in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(-1,1)]:
			if not cells.has(cell+step): continue
			var b: Vector3 = graph.get_point_position(cells[cell+step])
			if absf(a.y-b.y)>0.60 or not clear_at(a.lerp(b,0.5)): continue
			var ray = PhysicsRayQueryParameters3D.create(a+Vector3(0,1,0),b+Vector3(0,1,0),1,excludes)
			if enemies.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
				graph.connect_points(cells[cell],cells[cell+step])

func path(from: Vector3, target: Vector3) -> PackedVector3Array:
	if graph.get_point_count()==0: return PackedVector3Array()
	var start = graph.get_closest_point(from)
	var end = graph.get_closest_point(target)
	return graph.get_point_path(start,end)
