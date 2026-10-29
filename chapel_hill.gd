extends Node3D
## A real sloped road, hillside and forecourt connecting Main Street to the chapel.
var town
var church
var samples: Array[Vector3] = []
var road_sides: Array[Vector3] = []
var distances: Array[float] = []
const ROAD_POINTS = [Vector3(0,0,-92),Vector3(0,0.35,-98),Vector3(5,1.5,-105),Vector3(15,3.9,-111),Vector3(25,6.9,-116),Vector3(30,8.6,-120),Vector3(29,9,-126)]
const TERRAIN_RECT = Rect2(-14,-157,70,67)

func _ready():
	name = "ChapelHillRoad"
	build_centerline()
	build_land()
	build_road()
	build_continuous_asphalt()
	var grass = town.mats.floor.duplicate()
	grass.albedo_texture = preload("res://assets/forest/ground_ps2.png")
	grass.albedo_color = Color("65705b")
	grass.uv1_scale = Vector3(4,1,2)
	# The terrain is the walking surface. A second raised collision slab made
	# an invisible step around the court, especially for approaching creatures.
	town.box(self,Vector3(29,9.012,-130),Vector3(16,0.016,8.0),grass,false).hide()
	# Asphalt stops at a small arrival court; only a narrow footpath reaches the door.
	build_footpath()
	# A low foundation is buried in the sculpted hill beneath the chapel.
	town.box(self,Vector3(29,8.6,-141),Vector3(10.5,0.75,14.5),church.masonry)
	roadside_detail()

func nearest_road(p: Vector2) -> Vector3:
	var best = INF
	var result = ROAD_POINTS[0]
	for i in range(samples.size()-1):
		var a: Vector3 = samples[i]
		var b: Vector3 = samples[i+1]
		var start = Vector2(a.x,a.z)
		var line = Vector2(b.x-a.x,b.z-a.z)
		var t = clampf((p-start).dot(line)/line.length_squared(),0,1)
		var distance = p.distance_squared_to(start+line*t)
		if distance<best:
			best = distance
			result = a.lerp(b,t)
	return result

func terrain_height_at(p: Vector3) -> float:
	var lot_factor = smoothstep(-6.0,-3.0,p.x) if p.x> -22 and p.x< -3 and p.z< -89 and p.z> -109 else 1.0
	var point = Vector2(p.x,p.z)
	if not TERRAIN_RECT.has_point(point):
		return 0
	var nearest = nearest_road(point)
	var distance = point.distance_to(Vector2(nearest.x,nearest.z))
	var height = nearest.y*(1-smoothstep(6.0,25.0,distance))
	var court_distance = maxf(maxf(absf(p.x-29)-9,absf(p.z+139)-13),0)
	height = maxf(height,9*(1-smoothstep(0.0,18.0,court_distance)))
	if distance<5:
		height = nearest.y
	var burial = 0.24*minf(smoothstep(4.0,6.0,distance),smoothstep(0.0,3.0,court_distance))
	return maxf(0,height-burial)*lot_factor

func make_surface(label: String, tool: SurfaceTool, material: Material, solid: bool):
	var mesh = tool.commit()
	var visual = MeshInstance3D.new()
	visual.name = label
	var foot_kind="grass"
	if label in ["CurvedChapelFootpath","UphillWalkingSurface","UphillAsphalt","ContinuousRouteAsphalt"]:foot_kind="concrete"
	elif label in ["SoftGravelShoulders","ChapelGravelWalk"]:foot_kind="gravel"
	if label not in ["FadedRoadEdges","WoodedChapelHill"]:preload("res://footstep_surfaces.gd").visual(visual,foot_kind)
	visual.mesh = mesh
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	if solid:
		var body = StaticBody3D.new()
		body.name = label+"Collision"
		var shape = ConcavePolygonShape3D.new()
		shape.set_faces(mesh.get_faces())
		shape.backface_collision = false
		var collision = CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
	return visual

func build_land():
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var church_floor = Rect2(Vector2(church.position.x-5,church.position.z-7),Vector2(10,14))
	for z in range(-157,-90):
		for x in range(-14,56):
			# The chapel owns this floor and its collision. Terrain at the same
			# height rendered through the wood, producing the flickering patches.
			if church_floor.has_point(Vector2(x+0.5,z+0.5)): continue
			var points = [Vector3(x,0,z),Vector3(x+1,0,z),Vector3(x,0,z+1),Vector3(x+1,0,z+1)]
			for j in range(points.size()):
				points[j].y = terrain_height_at(points[j])
			for triangle in [[0,1,2],[1,3,2]]:
				var normal = -(points[triangle[1]]-points[triangle[0]]).cross(points[triangle[2]]-points[triangle[0]]).normalized()
				for index in triangle:
					tool.set_normal(normal)
					tool.set_uv(Vector2(points[index].x,points[index].z)*0.25)
					tool.add_vertex(points[index])
	var material = town.mats.floor.duplicate()
	material.albedo_texture = preload("res://assets/forest/ground_ps2.png")
	material.albedo_color = Color("65705b")
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	make_surface("WoodedChapelHill",tool,material,true)

func append_line(a: Vector3, b: Vector3):
	var count = maxi(1,int(ceil(a.distance_to(b)/0.65)))
	for i in range(1,count+1):
		samples.append(a.lerp(b,float(i)/count))

func build_centerline():
	# Round the old polygon corners, keeping the route and nine metre climb.
	samples.append(ROAD_POINTS[0])
	for i in range(1,ROAD_POINTS.size()-1):
		var corner: Vector3 = ROAD_POINTS[i]
		var before: Vector3 = ROAD_POINTS[i-1]
		var after: Vector3 = ROAD_POINTS[i+1]
		var radius = minf(3.2,minf(before.distance_to(corner),after.distance_to(corner))*0.38)
		var entry = corner.move_toward(before,radius)
		var exit = corner.move_toward(after,radius)
		append_line(samples[-1],entry)
		for j in range(1,13):
			var t = float(j)/12
			samples.append(entry.lerp(corner,t).lerp(corner.lerp(exit,t),t))
	append_line(samples[-1],ROAD_POINTS[-1])
	distances.append(0.0)
	for i in range(samples.size()):
		var direction = samples[mini(i+1,samples.size()-1)]-samples[maxi(i-1,0)]
		direction.y = 0
		direction = direction.normalized()
		road_sides.append(Vector3(-direction.z,0,direction.x))
		if i>0:
			distances.append(distances[-1]+samples[i-1].distance_to(samples[i]))

func road_width(index: int) -> float:
	return 2.25+1.55*(1-smoothstep(0,10,distances[index]))

func road_vertex(index: int, offset: float, lift = 0.0) -> Vector3:
	return samples[index]+road_sides[index]*offset+Vector3(0,lift,0)

func strip_quad(tool: SurfaceTool, points: Array, u0: float, u1: float, v0: float, v1: float):
	for triangle in [[0,1,2],[2,1,3]]:
		var normal = -(points[triangle[1]]-points[triangle[0]]).cross(points[triangle[2]]-points[triangle[0]]).normalized()
		for index in triangle:
			tool.set_normal(normal)
			tool.set_uv(Vector2(u0 if index<2 else u1,v0 if index%2==0 else v1))
			tool.add_vertex(points[index])

func build_road():
	var top = SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shoulders = SurfaceTool.new()
	shoulders.begin(Mesh.PRIMITIVE_TRIANGLES)
	var paint = SurfaceTool.new()
	paint.begin(Mesh.PRIMITIVE_TRIANGLES)
	var walking = SurfaceTool.new()
	walking.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(samples.size()-1):
		var w0 = road_width(i)
		var w1 = road_width(i+1)
		var v0 = distances[i]/4
		var v1 = distances[i+1]/4
		# Adjacent sections share exactly the same cross-section at every bend.
		strip_quad(top,[road_vertex(i,-w0,0.035),road_vertex(i+1,-w1,0.035),road_vertex(i,w0,0.035),road_vertex(i+1,w1,0.035)],0,1.2,v0,v1)
		strip_quad(walking,[road_vertex(i,-w0-0.65),road_vertex(i+1,-w1-0.65),road_vertex(i,w0+0.65),road_vertex(i+1,w1+0.65)],0,1,v0,v1)
		for edge in [-1,1]:
			var outer0 = edge*(w0+0.5)
			var outer1 = edge*(w1+0.5)
			var inner0 = edge*w0
			var inner1 = edge*w1
			strip_quad(shoulders,[road_vertex(i,minf(inner0,outer0),0.012),road_vertex(i+1,minf(inner1,outer1),0.012),road_vertex(i,maxf(inner0,outer0),0.012),road_vertex(i+1,maxf(inner1,outer1),0.012)],0,0.3,v0,v1)
			# Subtle edge paint follows the ribbon rather than separate box segments.
			if i%13!=7 and distances[i]<distances[-1]-1.2:
				var p0 = edge*(w0-0.19)
				var p1 = edge*(w1-0.19)
				strip_quad(paint,[road_vertex(i,p0-0.025,0.041),road_vertex(i+1,p1-0.025,0.041),road_vertex(i,p0+0.025,0.041),road_vertex(i+1,p1+0.025,0.041)],0,1,v0,v1)
	var asphalt = town.streetscape.asphalt.duplicate()
	asphalt.albedo_color = town.streetscape.asphalt.albedo_color
	make_surface("UphillAsphalt",top,asphalt,false)
	var gravel = town.streetscape.pavement.duplicate()
	gravel.albedo_texture = preload("res://assets/forest/ground_ps2.png")
	gravel.albedo_color = Color("77796a")
	make_surface("SoftGravelShoulders",shoulders,gravel,false)
	make_surface("FadedRoadEdges",paint,town.color_material(Color("999b85")),false)
	make_surface("UphillWalkingSurface",walking,town.mats.dark,true).visible = false

func build_footpath():
	# Reference: worn churchyard flags, laid by hand rather than a modern grid.
	var rng = RandomNumberGenerator.new()
	rng.seed = 281047
	var gravel = town.streetscape.pavement.duplicate()
	gravel.albedo_texture = preload("res://assets/forest/rock_surface.png")
	gravel.albedo_color = Color("746e5b")
	gravel.uv1_triplanar = false
	gravel.vertex_color_use_as_albedo = true
	gravel.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var bed = SurfaceTool.new()
	bed.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(22):
		var z = -125.8-float(i)*0.375
		var next_z = z-0.375
		var width_a = lerpf(1.85,1.46,minf(float(i)/5.0,1.0))+sin(float(i)*2.7)*0.07
		var width_b = lerpf(1.85,1.46,minf(float(i+1)/5.0,1.0))+sin(float(i+1)*2.7)*0.07
		var widen_a = smoothstep(16.0,20.0,float(i))
		var widen_b = smoothstep(16.0,20.0,float(i+1))
		width_a = lerpf(width_a,2.25,widen_a)
		width_b = lerpf(width_b,2.25,widen_b)
		for side in [-1,1]:
			for triangle in [[Vector3(29,9.025,z),Vector3(29,9.025,next_z),Vector3(29+side*(width_a-0.24),9.025,z)],[Vector3(29+side*(width_a-0.24),9.025,z),Vector3(29,9.025,next_z),Vector3(29+side*(width_b-0.24),9.025,next_z)]]:
				for p in triangle:
					bed.set_color(Color.WHITE);bed.set_normal(Vector3.UP);bed.set_uv(Vector2(p.x,p.z));bed.add_vertex(p)
			var inside_a = Vector3(29+side*(width_a-0.24),9.025,z)
			var inside_b = Vector3(29+side*(width_b-0.24),9.025,next_z)
			var outside_a = Vector3(29+side*width_a,9.025,z)
			var outside_b = Vector3(29+side*width_b,9.025,next_z)
			for triangle in [[inside_a,inside_b,outside_a],[outside_a,inside_b,outside_b]]:
				for p in triangle:
					bed.set_color(Color(1,1,1,0.0 if p==outside_a or p==outside_b else 1.0));bed.set_normal(Vector3.UP);bed.set_uv(Vector2(p.x,p.z));bed.add_vertex(p)
	make_surface("ChapelGravelWalk",bed,gravel,false)
	# Shared low-resolution stone grain; each flag has its own clipped silhouette.
	var stone = StandardMaterial3D.new()
	stone.albedo_texture = preload("res://assets/forest/rock_surface.png")
	stone.albedo_color = Color("cbd0cd")
	stone.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	stone.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	stone.cull_mode = BaseMaterial3D.CULL_DISABLED
	stone.roughness = 1.0
	stone.metallic_specular = 0.0
	for col in range(3):
		var z = -126.0
		var index = 0
		while z > -132.7:
			var length = minf(rng.randf_range(0.62,1.15),z+132.75)
			if length<0.12:break
			flagstone(Vector3(28.14+col*0.86,9.04,z-length*0.5),Vector2(0.82,length-0.035),stone,rng,"ChapelWalkSlab_%d_%02d"%[col,index])
			z -= length
			index += 1
	for row in range(2):
		for col in range(4):
			flagstone(Vector3(27.43+col*1.045,9.043,-133.05-row*0.63),Vector2(1.005,0.59),stone,rng,"ChapelLanding_%d_%d"%[row,col])
	# Ground-level tufts interrupt the outer edge without obstructing passage.
	var forest = town.game.get_node("DetailedForest")
	for side in [-1,1]:
		for i in range(6):
			var p = Vector3(29+side*(1.5+rng.randf_range(0.03,0.3)),8.99,-126.8-i*0.93)
			var tuft = forest.place(forest.bush_scenes[(i+1)%3],p,Vector3(0.24,0.20,0.29),"ChapelPathWeeds")
			tuft.rotation.y = rng.randf_range(0,TAU)

func flagstone(center: Vector3, size: Vector2, material: StandardMaterial3D, rng: RandomNumberGenerator, label: String):
	var x = size.x*0.5
	var z = size.y*0.5
	var clip = rng.randf_range(0.04,0.105)
	var corners = [Vector3(-x+clip,0,z),Vector3(x-clip,0,z),Vector3(x,0,z-clip),Vector3(x,0,-z+clip),Vector3(x-clip,0,-z),Vector3(-x+clip,0,-z),Vector3(-x,0,-z+clip),Vector3(-x,0,z-clip)]
	var mesh = SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shade = rng.randf_range(0.9,1.12)
	var tint = Color(shade,shade,shade)
	for i in range(corners.size()):
		var a:Vector3 = corners[i]
		var b:Vector3 = corners[(i+1)%corners.size()]
		for point in [Vector3.ZERO,a,b]:
			mesh.set_normal(Vector3.UP)
			mesh.set_color(tint)
			mesh.set_uv(Vector2(point.x+center.x,point.z+center.z)*0.68)
			mesh.add_vertex(point+center)
	var mat = material.duplicate()
	mat.vertex_color_use_as_albedo = true
	var slab = make_surface(label,mesh,mat,false)
	preload("res://footstep_surfaces.gd").visual(slab,"stone")

func roadside_detail():
	var sign = Node3D.new()
	add_child(sign)
	sign.position = Vector3(4.5,0,-94.5)
	town.box(sign,Vector3(0,0.9,0),Vector3(0.12,1.8,0.12),town.mats.wood)
	town.box(sign,Vector3(0,1.55,0),Vector3(2.2,0.65,0.12),town.mats.wood,false)
	var label = town.sign_text(sign,"CHAPEL ROAD\nUP THE HILL",Vector3(0,1.55,0.08),24,Color("b5ad92"))
	label.pixel_size = 0.006
	label.shaded = true
	label.outline_size = 0
	var forest = town.game.get_node("DetailedForest")
	for i in range(9,samples.size()-12,9):
		var p = samples[i]
		var direction = (samples[i+1]-samples[i]).normalized()
		var side = Vector3(-direction.z,0,direction.x).normalized()
		for sign_side in [-1,1]:
			var root_p = p+side*sign_side*5.7
			if root_p.x< -2 and root_p.x> -21 and root_p.z< -89 and root_p.z> -109: continue
			root_p.y = terrain_height_at(root_p)
			var size = 0.9+float(i%3)*0.07
			var tree = forest.place(forest.pine_scenes[i%2],root_p,Vector3.ONE*size,"ChapelRoadTrees")
			var crown = MeshInstance3D.new()
			crown.mesh = forest.crowns[i%2]
			crown.material_override = forest.needle_material
			tree.add_child(crown)
			forest.add_collision(tree,0.25,5.5)


func build_continuous_asphalt():
	# One surface owns the entire route; no flat tiles overlap the incline.
	for child in town.streetscape.get_children():
		if child is MeshInstance3D and (child.mesh==town.streetscape.road_mesh or child.mesh==town.streetscape.approach_road_mesh or child.name=="ContinuousTownEntryAsphalt"):
			child.hide()
	get_node("UphillAsphalt").hide()
	var points:Array[Vector3]=[]
	var widths:Array[float]=[]
	for z in range(97,-93,-1):
		points.append(Vector3(0,0,z))
		widths.append(3.8)
	for i in range(1,samples.size()):
		points.append(samples[i])
		widths.append(road_width(i))
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var travelled=0.0
	for i in range(points.size()-1):
		var before=points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]
		var after=points[mini(i+2,points.size()-1)]-points[i]
		before.y=0;after.y=0
		var side0=Vector3(-before.z,0,before.x).normalized()
		var side1=Vector3(-after.z,0,after.x).normalized()
		var length=points[i].distance_to(points[i+1])
		var lift=Vector3(0,0.05,0)
		strip_quad(tool,[points[i]-side0*widths[i]+lift,points[i+1]-side1*widths[i+1]+lift,points[i]+side0*widths[i]+lift,points[i+1]+side1*widths[i+1]+lift],0,1,travelled/11,(travelled+length)/11)
		travelled+=length
	var material=StandardMaterial3D.new()
	material.albedo_texture=preload("res://assets/roads_experiment/asphalt.jpg")
	material.albedo_color=Color("a6aaa2")
	material.roughness=1
	material.metallic_specular=0
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	make_surface("ContinuousRouteAsphalt",tool,material,false)
