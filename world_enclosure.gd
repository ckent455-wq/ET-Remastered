extends Node3D
## Close silhouettes and physical edges without obstructing quest routes.
var game
var forest
var rng = RandomNumberGenerator.new()
var shoulder_trees = 0
var shoulder_bushes = 0
var fences = 0
var alley_barriers: Array[Node3D] = []

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
		# The outer boundary is now the rising forest belt, not property walls.
		# Boarded returns close the gaps between storefronts at the building line.
		build_alley_barriers(side)

func build_alley_barriers(side: int):
	var fronts: Array[Dictionary] = []
	for data in game.town.BUILDINGS:
		if signf(data.p.x)==side:
			fronts.append({"z":data.p.z,"width":data.w})
	fronts.append({"z":-85.0,"width":10.0})
	fronts.sort_custom(func(a,b): return a.z>b.z)
	for i in range(fronts.size()-1):
		var near_edge = fronts[i].z-fronts[i].width/2
		var far_edge = fronts[i+1].z+fronts[i+1].width/2
		if side==1 and i==0: continue # Open the contained workshop service alley.
		var center = (near_edge+far_edge)/2
		# Each end embeds 25 cm into its building rather than leaving shoulder gaps.
		var barrier = fence(Vector3(side*6.65,0,center),near_edge-far_edge+0.5,2.8)
		barrier.name = "AlleyBarrier_%s_%d" % ["West" if side<0 else "East",i]
		barrier.set_meta("near_edge",near_edge)
		barrier.set_meta("far_edge",far_edge)
		barrier.set_meta("side",side)
		alley_barriers.append(barrier)

func shoulder_clear(p: Vector3) -> bool:
	if Vector2(p.x+4.2,p.z+31).length()<3.0: return false
	if p.x>0 and p.z> -18 and p.z< -6: return false
	if p.distance_to(Vector3(3.8,0,13))<5.5 or p.distance_to(Vector3(4.4,0,-35))<4.8:
		return false
	if p.length()<7.0:
		return false
	for target in forest.TARGETS:
		var nearest = Geometry2D.get_closest_point_to_segment(Vector2(p.x,p.z),Vector2.ZERO,Vector2(target.x,target.z))
		if Vector2(p.x,p.z).distance_to(nearest)<2.2:
			return false
	return true

func fence(p: Vector3, length: float, height: float) -> Node3D:
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
	for y in [0.65,1.95]:
		game.town.box(root,Vector3(0.14,y,0),Vector3(0.08,0.12,length+0.06),wood,false)
	fences += 1
	return root
