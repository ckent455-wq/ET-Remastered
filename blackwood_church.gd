extends Node3D
## Original abandoned chapel inspired by Holy Trinity, Weston, Missouri.
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
	rotation.y = 0
	masonry = make_stone()
	window = town.color_material(Color("263a36"))
	window.cull_mode = BaseMaterial3D.CULL_DISABLED
	# The entrance starts closed; its floor is flush with the hilltop forecourt.
	town.box(self,Vector3(0,-0.12,0),Vector3(10,0.24,14),town.mats.floor)
	for side in [-1,1]:
		town.box(self,Vector3(side*5,3.6,0),Vector3(0.40,7.2,14),masonry)
		town.box(self,Vector3(side*3.2,1.5,7),Vector3(3.6,3.0,0.4),masonry)
	town.box(self,Vector3(0,5.1,7),Vector3(10,4.2,0.4),masonry)
	town.box(self,Vector3(0,3.6,-7),Vector3(10,7.2,0.4),masonry)
	build_roof()
	pointed_panel(self,Vector3(0,3.6,7.23),3.3,4.25,0,true)
	rose_window(self,Vector3(0,5.5,7.30),0.65)
	pointed_panel(self,Vector3(0,0.06,7.26),2.7,4.0,0,false)
	for side in [-1,1]:
		var hinge = Node3D.new()
		add_child(hinge)
		hinge.position = Vector3(side*1.4,0,7.0)
		door_hinges.append(hinge)
		town.box(hinge,Vector3(-side*0.7,1.35,0),Vector3(1.4,2.7,0.16),town.mats.wood,false)
		for face in [-1,1]:
			town.box(hinge,Vector3(-side*1.17,1.16,face*0.12),Vector3(0.07,0.32,0.07),town.mats.metal,false)
		for z in [-4.8,-1.7,1.5,4.5]:
			pointed_panel(self,Vector3(side*5.22,2.7,z),1.25,2.8,side*PI/2,true)
		for z in [-5.5,-2.5,0.5,3.5]:
			town.box(self,Vector3(side*5.22,2.15,z),Vector3(0.65,4.3,0.5),masonry)
		bell_tower(side,12.2 if side<0 else 11.4)
		for i in range(4):
			pew(Vector3(side*2.85,0,3.0-i*2.0))
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
	# Unkempt forecourt details do not obstruct the sidewalk or center aisle.
	for p in [Vector3(-4.7,0.14,7.35),Vector3(4.7,0.14,7.35)]:
		town.box(self,p,Vector3(0.45,0.28,0.6),masonry)

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

func build_roof():
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1,1]:
		var corners = [Vector3(side*5.35,7.2,-7.3),Vector3(side*5.35,7.2,7.3),Vector3(0,10.2,-7.3),Vector3(0,10.2,7.3)]
		for i in [0,2,1,1,2,3]:
			tool.set_normal(Vector3(side*0.5,1,0).normalized())
			tool.set_uv(Vector2(corners[i].z*0.2,corners[i].x*0.2))
			tool.add_vertex(corners[i])
	var material = town.mats.roof.duplicate()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var roof = MeshInstance3D.new()
	roof.mesh = tool.commit()
	roof.material_override = material
	add_child(roof)
	for z in [-7.0,7.0]:
		var gable = SurfaceTool.new()
		gable.begin(Mesh.PRIMITIVE_TRIANGLES)
		for p in [Vector3(-5,7.1,z),Vector3(0,10.2,z),Vector3(5,7.1,z)]:
			gable.set_normal(Vector3(0,0,1))
			gable.add_vertex(p)
		var face = MeshInstance3D.new()
		face.mesh = gable.commit()
		var stone = masonry.duplicate()
		stone.cull_mode = BaseMaterial3D.CULL_DISABLED
		face.material_override = stone
		add_child(face)

func pointed_panel(parent: Node3D, p: Vector3, width: float, height: float, yaw: float, fill: bool):
	var root = Node3D.new()
	parent.add_child(root)
	root.position = p
	root.rotation.y = yaw
	var outline = [Vector3(-width/2,0,0),Vector3(-width/2,height*0.68,0),Vector3(0,height,0),Vector3(width/2,height*0.68,0),Vector3(width/2,0,0)]
	if fill:
		var tool = SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(5):
			for point in [Vector3(0,height*0.4,0),outline[i],outline[(i+1)%5]]:
				tool.set_normal(Vector3(0,0,1))
				tool.add_vertex(point)
		var pane = MeshInstance3D.new()
		pane.mesh = tool.commit()
		pane.material_override = window
		root.add_child(pane)
		for x in [-width*0.25,0,width*0.25]:
			town.box(root,Vector3(x,height*0.38,0.035),Vector3(0.045,height*0.70,0.05),town.mats.dark,false)
	for i in range(4):
		var a: Vector3 = outline[i]
		var b: Vector3 = outline[i+1]
		var trim = town.box(root,(a+b)/2+Vector3(0,0,0.06),Vector3(0.15,a.distance_to(b)+0.10,0.16),masonry,false)
		trim.rotation.z = -atan2(b.x-a.x,b.y-a.y)

func rose_window(parent: Node3D, p: Vector3, radius: float):
	var rim = town.game.mesh_at(parent,town.game.cylinder(radius+0.12,radius+0.12,0.10,16),p,masonry)
	rim.rotation.x = PI/2
	var glass = town.game.mesh_at(parent,town.game.cylinder(radius,radius,0.12,16),p+Vector3(0,0,0.06),window)
	glass.rotation.x = PI/2
	for i in range(8):
		var spoke = town.box(parent,p+Vector3(0,0,0.14),Vector3(0.035,radius*2,0.06),masonry,false)
		spoke.rotation.z = i*PI/8

func bell_tower(side: int, height: float):
	var x = side*3.65
	town.box(self,Vector3(x,height/2,5.4),Vector3(2.3,height,3.3),masonry)
	for yaw in [0.0,PI/2,-PI/2]:
		var direction = Vector3(sin(yaw),0,cos(yaw))
		pointed_panel(self,Vector3(x,height-3.3,5.4)+direction*(1.70 if yaw==0 else 1.19),1.25,2.3,yaw,true)
	for y in [3.1,height-3.8,height]:
		town.box(self,Vector3(x,y,5.4),Vector3(2.55,0.18,3.55),masonry,false)
	var roof = town.game.mesh_at(self,town.game.cylinder(2.2,0,5.2,4),Vector3(x,height+2.6,5.4),town.mats.roof)
	roof.rotation.y = PI/4
	town.box(self,Vector3(x,height+5.65,5.4),Vector3(0.10,1.1,0.10),town.mats.dark,false)
	town.box(self,Vector3(x,height+5.85,5.4),Vector3(0.65,0.10,0.10),town.mats.dark,false)
	rose_window(self,Vector3(x,5.1,7.12),0.33)

func pew(p: Vector3):
	town.box(self,p+Vector3(0,0.45,0),Vector3(3.0,0.16,0.58),town.mats.wood)
	town.box(self,p+Vector3(0,0.86,0.30),Vector3(3.0,0.75,0.12),town.mats.wood)
	for x in [-1.25,1.25]:
		town.box(self,p+Vector3(x,0.23,0),Vector3(0.14,0.46,0.5),town.mats.wood)

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
	var local_player = to_local(town.game.player.global_position)
	if doors_open and (contains(town.game.player.global_position) or Vector2(local_player.x,local_player.z-7).length()<2.4):
		town.game.message = "Step clear of the entrance before closing the chapel doors."
		return
	if door_tween!=null and door_tween.is_valid():
		door_tween.kill()
	doors_open = not doors_open
	entrance_collision.set_deferred("disabled",doors_open)
	door_tween = create_tween().set_parallel(true)
	for i in range(door_hinges.size()):
		var side = -1 if i==0 else 1
		door_tween.tween_property(door_hinges[i],"rotation:y",side*1.55 if doors_open else 0.0,0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	town.game.soundscape.door_move(to_global(Vector3(0,1,7)),doors_open)

func decorate_entrance():
	var forest = town.game.get_node("DetailedForest")
	for side in [-1,1]:
		# Small paired stone beds frame the porch without crossing the footpath.
		var p = Vector3(side*4.15,0,8.8)
		town.box(self,p+Vector3(0,0.18,0),Vector3(1.4,0.36,2.0),masonry)
		for i in range(2):
			forest.place(forest.bush_scenes[(i+1)%3],to_global(p+Vector3(0,0.35,-0.48+i*0.95)),Vector3(1.0,0.9,1.0),"ChapelEntranceShrubs")
		var lantern = Vector3(side*1.95,2.05,7.45)
		town.box(self,lantern,Vector3(0.24,0.4,0.22),town.mats.dark,false)
		town.box(self,lantern+Vector3(0,0,0.12),Vector3(0.15,0.27,0.025),town.color_material(Color("bf9f68"),0.65),false)
		town.lamp(self,lantern+Vector3(0,0,0.2),Color("c5ab78"),0.38,4.2)
	# One weathered seat beside the left bed adds a quiet, welcoming detail.
	town.box(self,Vector3(-5.7,0.48,9.6),Vector3(1.8,0.13,0.6),town.mats.wood)
	town.box(self,Vector3(-5.7,0.91,9.85),Vector3(1.8,0.7,0.1),town.mats.wood)
	for x in [-6.35,-5.05]:
		town.box(self,Vector3(x,0.23,9.6),Vector3(0.13,0.46,0.5),masonry)
