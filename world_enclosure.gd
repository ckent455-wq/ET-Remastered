extends Node3D
## Close silhouettes and physical edges without obstructing quest routes.
var game
var forest
var rng = RandomNumberGenerator.new()
var shoulder_trees = 0
var shoulder_bushes = 0
var fences = 0

func _ready():
	name = "CrampedRoadside"
	rng.seed = 73014
	forest = game.get_node("DetailedForest")
	# Preserve the three side trails and the wreck while enclosing the main road.
	for side in [-1,1]:
		for i in range(23):
			var p = Vector3(side*rng.randf_range(3.4,5.3),0,18-i*2.3)
			if not shoulder_clear(p):
				continue
			var size = rng.randf_range(0.86,1.1)
			var tree = forest.place(forest.pine_scenes[i%2],p,Vector3(size,size,size),"RoadsideTrees")
			var crown = MeshInstance3D.new()
			crown.mesh = forest.crowns[i%2]
			crown.material_override = forest.needle_material
			tree.add_child(crown)
			forest.add_collision(tree,0.25,5.5)
			shoulder_trees += 1
			for offset in [-0.8,0.8]:
				var bush_p = p+Vector3(side*0.2,0,offset)
				if shoulder_clear(bush_p):
					forest.place(forest.bush_scenes[i%3],bush_p,Vector3(1.1,1.1,1.3),"RoadsideBushes")
					shoulder_bushes += 1
		for z in [-25.0,-19.0,-13.0,8.0,14.0]:
			var p = Vector3(side*3.35,0,z)
			if shoulder_clear(p):
				fence(p,4.0,2.1)
		# Rear walls close the broad empty spaces behind the stores.
		for z in [-44.0,-53.0,-62.0,-71.0,-80.0]:
			var material = game.town.mats.brick.duplicate()
			material.albedo_color = Color("666a59")
			game.town.box(self,Vector3(side*18.0,1.65,z),Vector3(0.3,3.3,9.0),material)
			game.town.box(self,Vector3(side*18.0,3.32,z),Vector3(0.52,0.14,9.0),game.town.mats.dark,false)
		# Boarded returns close the gaps between storefronts at the building line.
		for z in [-52.5,-65.5,-79.0]:
			fence(Vector3(side*6.65,0,z),0.9,2.8)

func shoulder_clear(p: Vector3) -> bool:
	if p.distance_to(Vector3(3.8,0,13))<5.5 or p.distance_to(Vector3(4.4,0,-35))<4.8:
		return false
	if p.length()<7.0:
		return false
	for target in forest.TARGETS:
		var nearest = Geometry2D.get_closest_point_to_segment(Vector2(p.x,p.z),Vector2.ZERO,Vector2(target.x,target.z))
		if Vector2(p.x,p.z).distance_to(nearest)<2.2:
			return false
	return true

func fence(p: Vector3, length: float, height: float):
	var root = Node3D.new()
	add_child(root)
	root.position = p
	var wood = game.town.mats.wood.duplicate()
	wood.albedo_color = Color("656b58")
	# One simple collision body per section, with irregular visual planks.
	game.town.box(root,Vector3(0,height/2,0),Vector3(0.16,height,length),game.town.mats.dark)
	var count = maxi(2,int(length/0.27))
	for i in range(count):
		var h = height+rng.randf_range(-0.25,0.12)
		var plank = game.town.box(root,Vector3(0,h/2,-length/2+(i+0.5)*length/count),Vector3(0.23,h,length/count-0.018),wood,false)
		plank.rotation.x = rng.randf_range(-0.035,0.035)
	for z in [-length/2,length/2]:
		game.town.box(root,Vector3(0,height/2,z),Vector3(0.28,height+0.15,0.15),wood,false)
	fences += 1
