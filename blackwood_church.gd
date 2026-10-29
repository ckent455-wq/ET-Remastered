extends Node3D
## Local Flooded Grounds church modules, fitted to the playable hilltop chapel.
## Reference: https://holytrinitycatholic.org/photoalbums/holy-trinity-church
var town
var masonry: StandardMaterial3D
var window: StandardMaterial3D
var basement: Node3D
var doors_open = false
var door_hinges: Array[Node3D] = []
var entrance_collision: CollisionShape3D
var door_tween: Tween

func _ready():
	name = "BlackwoodChurch"
	position = Vector3(29,9,-141)
	masonry = make_stone()
	window = town.color_material(Color("263631"))
	window.cull_mode = BaseMaterial3D.CULL_DISABLED
	build_asset_shell()
	for side in [-1,1]:
		var hinge = Node3D.new()
		add_child(hinge)
		hinge.name = "EntranceLeftHinge" if side<0 else "EntranceRightHinge"
		hinge.position = Vector3(side*1.4,0,7.0)
		door_hinges.append(hinge)
		var door = native_prop("door",hinge,Vector3(-side*0.7,0,0))
		door.scale.x = (1.4/1.407018065) * (-1 if side>0 else 1)
		for face in [-1,1]:
			town.box(hinge,Vector3(-side*1.17,1.16,face*0.10),Vector3(0.07,0.30,0.06),town.mats.metal,false)
		for i in range(4): pew(Vector3(side*2.85,0,3.0-i*2.0))
	var blocker = StaticBody3D.new()
	blocker.name = "ClosedChapelDoors"
	add_child(blocker)
	entrance_collision = CollisionShape3D.new()
	var door_shape = BoxShape3D.new()
	door_shape.size = Vector3(2.8,2.7,0.16)
	entrance_collision.shape = door_shape
	entrance_collision.position = Vector3(0,1.35,7)
	blocker.add_child(entrance_collision)
	town.action_area(self,Vector3(0,1.3,7),Vector3(2.8,2.6,0.7),"chapel_doors",{"kind":"chapel_door","label":"Open chapel doors"})
	altar()
	var plaque = town.sign_text(self,"BLACKWOOD CHAPEL\nALL ARE WELCOME",Vector3(2.8,1.25,7.26),22,Color("b6b09a"))
	plaque.pixel_size = 0.005
	plaque.shaded = true
	plaque.outline_size = 0
	decorate_entrance()
	basement = Node3D.new()
	basement.set_script(preload("res://church_basement.gd"))
	basement.town = town
	basement.church = self
	add_child(basement)

func contains(p: Vector3) -> bool:
	var local = to_local(p)
	return (absf(local.x)<4.9 and absf(local.z)<6.9 and local.y>= -0.3 and local.y<9) or (basement!=null and basement.contains(p))

func make_stone() -> StandardMaterial3D:
	var image = Image.create(128,128,false,Image.FORMAT_RGB8)
	image.fill(Color("454a40"))
	var rng = RandomNumberGenerator.new()
	rng.seed = 191242
	for row in range(8):
		for column in range(5):
			var start = column*32-(16 if row%2 else 0)
			var shade = rng.randf_range(0.48,0.68)
			for y in range(row*16+1,row*16+15):
				for x in range(maxi(0,start+1),mini(128,start+31)):
					var grain = rng.randf_range(-0.055,0.055)
					image.set_pixel(x,y,Color(shade+grain,shade+grain,shade*0.9+grain))
	image.generate_mipmaps()
	var material = StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.uv1_triplanar = true
	material.uv1_scale = Vector3(0.5,0.5,0.5)
	material.roughness = 1
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	return material

func native_prop(asset: String, parent: Node3D, p: Vector3) -> Node3D:
	var model = load("res://assets/church/"+asset+".glb").instantiate()
	parent.add_child(model)
	model.position = p
	model.set_meta("church_asset",asset)
	adapt_native(model)
	if asset=="door": apply_door_material(model)
	return model

func build_asset_shell():
	# A single coherent shell: no complete prefab end sections overlap inside it.
	var siding = entrance_painted_wood(true)
	var plaster = town.mats.plaster.duplicate()
	plaster.albedo_color = Color("aaa99a")
	plaster.uv1_scale = Vector3(0.26,0.26,0.26)
	plaster.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	var trim = town.color_material(Color("555c50"))
	var floor = town.box(self,Vector3(0,-0.12,0),Vector3(10,0.24,14),town.mats.floor)
	floor.name = "ContinuousChapelFloor"
	for side in [-1,1]:
		var wall = town.box(self,Vector3(side*5,2.9,0),Vector3(0.4,5.8,14.4),siding)
		wall.name = "ChapelSideWall%d" % side
		# Interior lining is separated from the exterior wall face by 4 cm.
		town.box(self,Vector3(side*4.77,2.9,0),Vector3(0.04,5.8,13.6),plaster,false)
		town.box(self,Vector3(side*4.73,0.52,0),Vector3(0.04,1.04,13.6),town.mats.wood,false)
		town.box(self,Vector3(side*4.70,1.08,0),Vector3(0.06,0.08,13.6),trim,false)
		# Front sections meet the 2.8 x 2.7m doors exactly.
		town.box(self,Vector3(side*3.2,1.35,7),Vector3(3.6,2.7,0.4),siding)
		town.box(self,Vector3(side*3.2,1.35,6.77),Vector3(3.6,2.7,0.04),plaster,false)
		for z in [-4.2,-0.5,3.2]:
			window_panel(Vector3(side*4.72,1.8,z),-side*PI/2,trim)
			window_panel(Vector3(side*5.23,1.8,z),side*PI/2,trim)
		# Straight jambs and header, with no uncovered arch above the door leaves.
		town.box(self,Vector3(side*1.49,1.43,7.23),Vector3(0.18,2.86,0.14),trim,false)
		town.box(self,Vector3(side*4.99,2.9,7.23),Vector3(0.24,5.8,0.16),trim,false)
	town.box(self,Vector3(0,4.25,7),Vector3(10,3.1,0.4),siding)
	town.box(self,Vector3(0,4.25,6.77),Vector3(9.6,3.1,0.04),plaster,false)
	town.box(self,Vector3(0,2.79,7.23),Vector3(3.16,0.18,0.14),trim,false)
	town.box(self,Vector3(0,-0.02,7),Vector3(2.8,0.04,0.4),town.mats.wood,false)
	town.box(self,Vector3(0,2.9,-7),Vector3(10,5.8,0.4),siding)
	town.box(self,Vector3(0,2.9,-6.77),Vector3(9.6,5.8,0.04),plaster,false)
	town.box(self,Vector3(0,0.52,-6.73),Vector3(9.6,1.04,0.04),town.mats.wood,false)
	for side in [-1,1]:
		gable_face(side*7.21,5.2,5.8,8.6,siding)
		gable_face(side*6.74,4.75,5.8,8.32,plaster)
	continuous_roof(5.4,5.8,8.6,7.4,town.mats.roof,"ContinuousExteriorRoof")
	continuous_roof(4.75,5.60,8.32,6.74,plaster,"ContinuousInteriorCeiling")
	rose_panel(Vector3(0,4.8,7.25),0,trim)
	rose_panel(Vector3(0,4.8,6.73),PI,trim)
	# Only the isolated bell tower is retained from the native facade.
	# Its cut base is embedded in the roof, never suspended inside the nave.
	native_prop("bell_tower",self,Vector3(0,0,5.3))
	for side in [-1,1]:
		town.box(self,Vector3(side*5.22,5.78,0),Vector3(0.16,0.16,14.5),trim,false)

func gable_face(z: float, width: float, bottom: float, top: float, material: Material):
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [Vector3(-width,bottom,z),Vector3(0,top,z),Vector3(width,bottom,z)]:
		tool.set_normal(Vector3(0,0,1 if z>0 else -1))
		tool.set_uv(Vector2(point.x*0.3,point.y*0.3))
		tool.add_vertex(point)
	var visual = MeshInstance3D.new()
	visual.mesh = tool.commit()
	visual.material_override = material.duplicate()
	visual.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	add_child(visual)

func continuous_roof(width: float, eaves: float, ridge: float, depth: float, material: Material, label: String):
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1,1]:
		var corners = [Vector3(side*width,eaves,-depth),Vector3(side*width,eaves,depth),Vector3(0,ridge,-depth),Vector3(0,ridge,depth)]
		for i in [0,2,1,1,2,3]:
			tool.set_normal(Vector3(side*(ridge-eaves)/width,1,0).normalized())
			tool.set_uv(Vector2(corners[i].z*0.25,corners[i].x*0.25))
			tool.add_vertex(corners[i])
	var roof = MeshInstance3D.new()
	roof.name = label
	roof.mesh = tool.commit()
	roof.material_override = material.duplicate()
	roof.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	add_child(roof)

func window_panel(p: Vector3, yaw: float, frame: Material):
	var root = Node3D.new()
	root.name = "MountedGothicWindow"
	add_child(root)
	root.position = p
	root.rotation.y = yaw
	var outline = [Vector3(-0.55,0,0),Vector3(-0.55,1.65,0),Vector3(0,2.25,0),Vector3(0.55,1.65,0),Vector3(0.55,0,0)]
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(5):
		for point in [Vector3(0,0.9,0),outline[i],outline[(i+1)%5]]:
			tool.set_normal(Vector3(0,0,1))
			tool.add_vertex(point)
	var pane = MeshInstance3D.new()
	pane.mesh = tool.commit()
	pane.material_override = window
	root.add_child(pane)
	for i in range(5):
		var a = outline[i]
		var b = outline[(i+1)%5]
		var bar = town.box(root,(a+b)/2+Vector3(0,0,0.045),Vector3(0.09,a.distance_to(b)+0.07,0.07),frame,false)
		bar.rotation.z = -atan2(b.x-a.x,b.y-a.y)
	for x in [-0.20,0.20]: town.box(root,Vector3(x,0.83,0.04),Vector3(0.035,1.60,0.04),frame,false)
	town.box(root,Vector3(0,0.8,0.04),Vector3(1.04,0.035,0.04),frame,false)

func rose_panel(p: Vector3, yaw: float, frame: Material):
	var root = Node3D.new()
	add_child(root)
	root.position = p
	root.rotation.y = yaw
	var rim = town.game.mesh_at(root,town.game.cylinder(0.73,0.73,0.10,16),Vector3.ZERO,frame)
	rim.rotation.x = PI/2
	var glass = town.game.mesh_at(root,town.game.cylinder(0.61,0.61,0.11,16),Vector3(0,0,0.04),window)
	glass.rotation.x = PI/2
	for i in range(6):
		var spoke = town.box(root,Vector3(0,0,0.11),Vector3(0.035,1.20,0.04),frame,false)
		spoke.rotation.z = i*PI/6

func pew(p: Vector3):
	var bench = native_prop("pew",self,p)
	bench.rotation.y = PI
	bench.scale = Vector3(1,0.82,0.75)
	var collider = town.box(self,p+Vector3(0,0.5,0),Vector3(2.85,1.0,0.82),town.mats.wood)
	collider.get_child(0).hide()

func altar():
	town.box(self,Vector3(0,0.85,-5.5),Vector3(3.1,0.18,1.05),masonry)
	for x in [-1.2,1.2]:
		town.box(self,Vector3(x,0.4,-5.5),Vector3(0.3,0.8,0.75),masonry)
	town.box(self,Vector3(0,3.7,-6.72),Vector3(0.16,3.1,0.15),town.mats.wood,false)
	town.box(self,Vector3(0,4.25,-6.72),Vector3(1.55,0.16,0.15),town.mats.wood,false)
	for x in [-1.1,1.1]:
		town.box(self,Vector3(x,1.15,-5.5),Vector3(0.08,0.5,0.08),town.mats.paper,false)
		town.lamp(self,Vector3(x,1.5,-5.5),Color("cba777"),0.35,3)

func reset_doors():
	if door_tween!=null and door_tween.is_valid():
		door_tween.kill()
	doors_open = false
	for hinge in door_hinges:
		hinge.rotation.y = 0
	entrance_collision.set_deferred("disabled",false)

func toggle_doors():
	if door_tween!=null and door_tween.is_valid():
		door_tween.kill()
	doors_open = not doors_open
	entrance_collision.set_deferred("disabled",doors_open)
	door_tween = create_tween().set_parallel(true)
	for i in range(door_hinges.size()):
		var side = -1 if i==0 else 1
		door_tween.tween_property(door_hinges[i],"rotation:y",-side*1.55 if doors_open else 0.0,0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	town.game.soundscape.door_move(to_global(Vector3(0,1,7)),doors_open)

func decorate_entrance():
	var forest = town.game.get_node("DetailedForest")
	# Low, overlapping shrubs grow from broad soil pockets against the facade.
	var soil = town.mats.floor.duplicate()
	soil.albedo_texture = preload("res://assets/forest/ground_ps2.png")
	soil.albedo_color = Color("65634e")
	soil.vertex_color_use_as_albedo = true
	soil.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	soil.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side in [-1,1]:
		var tool = SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var center = Vector3(side*3.6,0.026,8.35)
		for i in range(14):
			var a = float(i)*TAU/14
			var b = float(i+1)*TAU/14
			var edge_a = Vector3(cos(a)*1.45,0,sin(a)*(1.05+0.1*sin(a*3)))
			var edge_b = Vector3(cos(b)*1.45,0,sin(b)*(1.05+0.1*sin(b*3)))
			for p in [center,center+edge_a*0.72,center+edge_b*0.72]:
				tool.set_color(Color.WHITE);tool.set_normal(Vector3.UP);tool.set_uv(Vector2(p.x,p.z));tool.add_vertex(p)
			for tri in [[edge_a*0.72,edge_a,edge_b*0.72],[edge_b*0.72,edge_a,edge_b]]:
				for edge in tri:
					var p = center+edge
					tool.set_color(Color(1,1,1,0.0 if edge==edge_a or edge==edge_b else 1.0))
					tool.set_normal(Vector3.UP);tool.set_uv(Vector2(p.x,p.z));tool.add_vertex(p)
		var patch = MeshInstance3D.new()
		patch.name = "ChapelFoundationSoil"
		patch.mesh = tool.commit();patch.material_override = soil;add_child(patch)
	var planting = [Vector3(-2.9,0,7.95),Vector3(-4.25,0,7.7),Vector3(-3.6,0,8.75),Vector3(2.95,0,7.85),Vector3(4.3,0,7.8),Vector3(4.0,0,8.9)]
	for i in range(planting.size()):
		var size = 1.05+float((i*3)%5)*0.07
		for layer in range(2):
			var offset = Vector3(0.28*layer,-0.06,-0.27*layer)
			var shrub = forest.place(forest.bush_scenes[(i+layer)%3],to_global(planting[i]+offset),Vector3(size,size*0.69,size*0.9),"ChapelEntranceShrubs")
			shrub.rotation.y = float(i)*1.73+layer*1.1
	garden_rock_borders(forest)
	entrance_porch()
	for side in [-1,1]:
		town.box(self,Vector3(side*1.95,2.05,7.29),Vector3(0.09,0.12,0.20),town.mats.metal,false)
		var lantern = Vector3(side*1.95,2.05,7.45)
		town.box(self,lantern,Vector3(0.24,0.4,0.22),town.mats.dark,false)
		town.box(self,lantern+Vector3(0,0,0.12),Vector3(0.15,0.27,0.025),town.color_material(Color("bf9f68"),0.65),false)
		town.lamp(self,lantern+Vector3(0,0,0.2),Color("c5ab78"),0.38,4.2)
	# Retain the legacy node slots for saved scene compatibility; the imported
	# bench owns the visible geometry and collision now.
	var old_bench = []
	old_bench.append(town.box(self,Vector3(-5.7,0.48,9.6),Vector3(1.8,0.13,0.6),town.mats.wood))
	old_bench.append(town.box(self,Vector3(-5.7,0.91,9.85),Vector3(1.8,0.7,0.1),town.mats.wood))
	for x in [-6.35,-5.05]:old_bench.append(town.box(self,Vector3(x,0.23,9.6),Vector3(0.13,0.46,0.5),masonry))
	for old in old_bench:
		old.hide();old.collision_layer=0;old.collision_mask=0
	imported_garden_bench()

func imported_garden_bench():
	var bench = StaticBody3D.new()
	bench.name = "ChapelGardenBench"
	add_child(bench)
	bench.position = Vector3(-5.9,0,10.45)
	# The original model faces -Z. Turn it outward toward the arrival road.
	bench.rotation.y = PI
	var visual = preload("res://assets/chapel_bench/park_bench.glb").instantiate()
	bench.add_child(visual)
	var bounds = AABB()
	var has_bounds = false
	var wood = StandardMaterial3D.new()
	wood.resource_name = "ChapelBenchWeatheredWood"
	wood.albedo_texture = preload("res://assets/lockbox/lid_T_WoodRough_basecolor.png")
	wood.albedo_color = Color("afa18b")
	wood.uv1_triplanar = true
	wood.uv1_scale = Vector3(1.0,1.0,1.0)
	wood.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	wood.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	wood.roughness = 1.0
	wood.metallic_specular = 0.0
	for mesh in visual.find_children("*","MeshInstance3D",true,false):
		var relative:Transform3D = bench.global_transform.affine_inverse()*mesh.global_transform
		var part:AABB = relative*mesh.get_aabb()
		bounds = bounds.merge(part) if has_bounds else part
		has_bounds = true
		mesh.material_override = wood
	if has_bounds:
		var fit = 1.95/bounds.size.x
		visual.scale *= fit
		visual.position -= Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*fit
	for spec in [[Vector3(0,0.265,0),Vector3(1.95,0.53,0.66)],[Vector3(0,0.73,0.28),Vector3(1.95,0.40,0.10)]]:
		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = spec[1];shape.shape = box;shape.position = spec[0];bench.add_child(shape)

func garden_rock_borders(forest):
	# Reuse the project's three local forest rock models as low fieldstone edging.
	var rng = RandomNumberGenerator.new()
	rng.seed = 281028
	var border = Node3D.new()
	border.name = "ChapelGardenRockBorders"
	add_child(border)
	for side in [-1,1]:
		for i in range(28):
			var angle = float(i)*TAU/28.0
			var stone = Node3D.new()
			stone.name = "GardenStone_%d_%02d"%[side,i]
			border.add_child(stone)
			stone.position = Vector3(side*3.65+cos(angle)*1.4,0.0,8.35+sin(angle)*1.05)
			stone.position.x += rng.randf_range(-0.025,0.025)
			stone.position.z += rng.randf_range(-0.025,0.025)
			stone.rotation.y = rng.randf_range(0,TAU)
			var visual = forest.rock_scenes[(i+(1 if side>0 else 0))%3].instantiate()
			stone.add_child(visual)
			forest.prepare_meshes(visual)
			var bounds = AABB()
			var has_bounds = false
			for mesh in visual.find_children("*","MeshInstance3D",true,false):
				var relative:Transform3D = stone.global_transform.affine_inverse()*mesh.global_transform
				var part:AABB = relative*mesh.get_aabb()
				bounds = bounds.merge(part) if has_bounds else part
				has_bounds = true
			if not has_bounds:continue
			var target = Vector3(rng.randf_range(0.27,0.36),rng.randf_range(0.16,0.23),rng.randf_range(0.24,0.31))
			var fitted = target/bounds.size
			visual.scale *= fitted
			visual.position -= Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*fitted
			visual.position.y -= 0.045

func entrance_painted_wood(clapboard: bool) -> StandardMaterial3D:
	# Quiet paint wear and fine grain, instead of reusing the striped siding atlas.
	var image = Image.create(128,128,false,Image.FORMAT_RGB8)
	var rng = RandomNumberGenerator.new()
	rng.seed = 281020 if clapboard else 281021
	for y in range(128):
		for x in range(128):
			var grain = sin(float(x)*1.9+sin(float(y)*0.07))*0.009+rng.randf_range(-0.012,0.012)
			var wear = sin(float(x)*0.067+sin(float(y)*0.11))*sin(float(y)*0.039)*0.014
			grain += wear
			var shade = 0.0
			if clapboard:
				shade = -0.12 if y%16==0 else (-0.035 if y%16==1 else 0.0)
			else:
				shade = -0.035 if x%43==0 else 0.0
			image.set_pixel(x,y,Color(0.64+grain+shade,0.65+grain+shade,0.59+grain+shade))
	image.generate_mipmaps()
	var mat = StandardMaterial3D.new()
	mat.resource_name = "ChapelWeatheredClapboard" if clapboard else "ChapelPaintedTimber"
	mat.albedo_texture = ImageTexture.create_from_image(image)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(0.5,0.5,0.5)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat.roughness = 1.0
	mat.metallic_specular = 0.0
	return mat

func entrance_porch():
	# A shallow timber portico, inspired by rural Missouri chapel entrances.
	var trim = entrance_painted_wood(false)
	var timber = StandardMaterial3D.new()
	timber.resource_name = "ChapelExposedWeatheredTimber"
	timber.albedo_texture = preload("res://assets/lockbox/lid_T_WoodRough_basecolor.png")
	timber.albedo_color = Color("9b9283")
	timber.uv1_triplanar = true
	timber.uv1_scale = Vector3(0.7,0.7,0.7)
	timber.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	timber.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	timber.roughness = 1.0
	timber.metallic_specular = 0.0
	var post_wood = timber.duplicate()
	post_wood.resource_name = "ChapelVerticalGrainPosts"
	var source = timber.albedo_texture.get_image()
	if source.is_compressed():source.decompress()
	source.resize(128,128,Image.INTERPOLATE_LANCZOS)
	var vertical = Image.create(128,128,false,Image.FORMAT_RGB8)
	for y in range(128):
		for x in range(128):vertical.set_pixel(x,y,source.get_pixel(y,127-x))
	vertical.generate_mipmaps()
	post_wood.albedo_texture = ImageTexture.create_from_image(vertical)
	post_wood.uv1_scale = Vector3(2.0,0.45,2.0)
	var roof = town.mats.roof.duplicate()
	roof.albedo_color = Color("73776c")
	var canopy = Node3D.new()
	canopy.name = "ChapelEntrancePorch"
	add_child(canopy)
	for side in [-1,1]:
		var post = town.box(canopy,Vector3(side*2.04,1.47,8.72),Vector3(0.17,2.86,0.17),post_wood)
		post.name = "PorchPost%d"%side
		town.box(canopy,Vector3(side*2.04,0.14,8.72),Vector3(0.26,0.2,0.26),masonry,false)
		town.box(canopy,Vector3(side*2.04,2.81,8.72),Vector3(0.27,0.15,0.27),timber,false)
		town.box(canopy,Vector3(side*2.04,2.92,8.0),Vector3(0.16,0.18,1.9),timber,false)
		var brace = town.box(canopy,Vector3(side*1.82,2.68,8.72),Vector3(0.1,0.62,0.12),timber,false)
		brace.rotation.z = -side*0.65
		var pitch = atan2(0.62,2.28)
		var panel = town.box(canopy,Vector3(side*1.14,3.26,8.05),Vector3(sqrt(2.28*2.28+0.62*0.62),0.10,2.3),roof,false)
		panel.rotation.z = -side*pitch
		var fascia = town.box(canopy,Vector3(side*1.14,3.22,9.255),Vector3(sqrt(2.28*2.28+0.62*0.62),0.13,0.1),trim,false)
		fascia.rotation.z = -side*pitch
	town.box(canopy,Vector3(0,2.9,8.72),Vector3(4.25,0.16,0.16),timber,false)
	town.box(canopy,Vector3(0,3.59,8.05),Vector3(0.11,0.10,2.34),trim,false)

func adapt_native(node: Node):
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var original = node.mesh.surface_get_material(surface)
			if original is StandardMaterial3D:
				var mat = original.duplicate()
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
				mat.roughness = 1
				mat.metallic = 0
				mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				node.set_surface_override_material(surface,mat)
	for child in node.get_children(): adapt_native(child)

func apply_door_material(node: Node):
	# Use the prefab's BLD_Doors1 atlas on both faces, with its authored UVs.
	# Do not inherit the building atlas or a triplanar wall material.
	if node is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.resource_name = "ChurchDoorPrefab_BLD_Doors1"
		mat.albedo_texture = preload("res://assets/church/door_BLD_Doors1_A.png")
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat.roughness = 1
		mat.metallic = 0
		mat.uv1_triplanar = false
		mat.cull_mode = BaseMaterial3D.CULL_BACK
		for surface in range(node.mesh.get_surface_count()): node.set_surface_override_material(surface,mat)
	for child in node.get_children(): apply_door_material(child)
