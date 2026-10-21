extends Node3D
## An original explorable two-storey house, using the user's local wood and apartment assets.
var game
var town
const ORIGIN = Vector3(-13,0,-98)
const FLOOR = 0.22
const UPPER = 3.45
var siding: StandardMaterial3D
var trim: StandardMaterial3D
var timber: StandardMaterial3D
var roof_mat: StandardMaterial3D
var plaster: Material
var props: Array[Node3D] = []
var cellar: Node3D

func block(p: Vector3, size: Vector3, material: Material, solid = true) -> Node3D:
	return town.box(self,p,size,material,solid)

func _ready():
	name = "DilapidatedVictorianHouse"
	position = ORIGIN
	rotation.y = PI/2
	town = game.town
	town.buildings.victorian = self
	siding = painted_finish(Color("c9c3ab"))
	trim = painted_finish(Color("e1d9c2"))
	timber = painted_finish(Color("8e8875"))
	plaster = ShaderMaterial.new()
	plaster.shader=preload("res://aged_wallpaper.gdshader")
	roof_mat = town.mats.roof.duplicate()
	roof_mat.albedo_color = Color("545a54")
	build_shell()
	build_porch()
	build_stairs()
	build_interior_joins()
	build_cellar()
	build_roofs()
	dress_rooms()
	town.make_door(self,"victorian",5)
	town.doors.victorian.hinge.position.y = FLOOR
	var door_body=town.doors.victorian.body
	var door_paint=painted_finish(Color("9fae9e"))
	var panel_paint=painted_finish(Color("b0bdac"))
	door_body.get_child(0).material_override=door_paint
	# Raised panels on both faces make the painted door read as joinery.
	for face in [-1,1]:
		for x in [-0.39,0.39]:
			for y in [-0.72,0.48]:
				town.box(door_body,Vector3(x,y,face*0.075),Vector3(0.61,0.94,0.035),panel_paint,false)
	town.note("victorian",Vector3(-3.4,1.02,2.6),"victorian_letter","House clearance notice","PROPERTY CLEARANCE / NINE YEARS AGO\nFormer mill superintendent's residence.\nThe mill is gone. We cannot afford another winter of repairs. The upstairs roof leaks above the back bedroom.\nLeave the heavy furniture. We will come back when we can.\nKeep the cellar vents open. It is the last dry room in the house.\nPlease close the front door.")

func painted_finish(tint: Color) -> StandardMaterial3D:
	var material=StandardMaterial3D.new()
	material.albedo_color=tint
	material.roughness=0.92
	material.metallic_specular=0.08
	var noise=FastNoiseLite.new()
	noise.seed=417
	noise.frequency=0.045
	noise.fractal_octaves=3
	var texture=NoiseTexture2D.new()
	texture.width=128
	texture.height=128
	texture.seamless=true
	texture.noise=noise
	var gradient=Gradient.new()
	gradient.colors=PackedColorArray([Color(0.94,0.93,0.90),Color(1,0.99,0.96)])
	texture.color_ramp=gradient
	material.albedo_texture=texture
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.uv1_triplanar=true
	material.uv1_scale=Vector3.ONE*0.7
	return material

func build_shell():
	block(Vector3(0,-0.10,0),Vector3(10.4,0.6,10.4),town.mats.brick)
	block(Vector3(0,FLOOR-0.07,0),Vector3(10,0.14,10),town.mats.floor)
	# Upstairs floor leaves an open stairwell along the east wall.
	block(Vector3(-1.21,UPPER-0.08,0),Vector3(7.58,0.16,10),town.mats.floor)
	block(Vector3(3.73,UPPER-0.08,-4.2),Vector3(2.30,0.16,1.6),town.mats.floor,false)
	ramp(Vector3(3.73,0,-3.65),Vector3(3.73,0,-5),UPPER,UPPER,2.30,false)
	# Stair flight now extends to the wall; no floor strip over its outer edge.
	# Front openings are actual gaps; broken windows show the furnished rooms.
	for base in [FLOOR,UPPER]:
		var wall_height=UPPER-FLOOR-0.16 if base==FLOOR else 3.1
		for side in [-1,1]:
			block(Vector3(side*5,base+wall_height/2,0),Vector3(0.24,wall_height,10.24),siding)
			block(Vector3(side*4.87,base+wall_height/2,0),Vector3(0.04,wall_height,9.9),plaster,false)
		block(Vector3(0,base+wall_height/2,-5),Vector3(10,wall_height,0.24),siding)
		for x in [-4.65,-1.3,1.3,4.65]:
			block(Vector3(x,base+wall_height/2,5),Vector3(0.7 if absf(x)>4 else 0.8,wall_height,0.24),siding)
		for x in [-3,3]:
			block(Vector3(x,base+0.43,5),Vector3(2.6,0.86,0.18),siding)
			block(Vector3(x,base+(2.38+wall_height)/2,5),Vector3(2.6,wall_height-2.38,0.24),siding)
			window_frame(Vector3(x,base+1.64,5.12),x<0 and base==FLOOR)
		if base==UPPER:
			block(Vector3(0,base+wall_height/2,5),Vector3(1.8,wall_height,0.24),siding)
		else:
			block(Vector3(0,base+(2.72+wall_height)/2,5),Vector3(1.8,wall_height-2.72,0.24),siding)
	# Horizontal clapboards and missing strips give the facade a weathered silhouette.
	for row in range(30):
		var y=0.32+row*0.21
		for side in [-1,1]:
			var plank = block(Vector3(side*5.12,y,0),Vector3(0.04,0.025,10),timber,false)
			if row%9==0: plank.rotation.x=0.006*side
		for x in [-4.7,-1.35,1.35,4.7]:
			if (row+int(x*4))%11==0: continue
			block(Vector3(x,y,5.115),Vector3(0.45,0.028,0.035),timber,false)
	for x in [-4.95,4.95]: block(Vector3(x,3.35,5.15),Vector3(0.12,6.3,0.16),trim,false)
	# Ground-floor hall, parlor and rear dining room with clear doorways.
	block(Vector3(-0.7,(FLOOR+UPPER-0.16)/2,-2.1),Vector3(0.18,UPPER-FLOOR-0.16,5.8),plaster)
	block(Vector3(-0.7,(FLOOR+UPPER-0.16)/2,4),Vector3(0.18,UPPER-FLOOR-0.16,2),plaster)
	for span in [[-4.25,1.5],[-1.38,1.35]]:
		var x: float = span[0]
		var width: float = span[1]
		block(Vector3(x,(FLOOR+UPPER-0.16)/2,-1),Vector3(width,UPPER-FLOOR-0.16,0.18),plaster)
	# Two upstairs rooms connected by a door opening near the stair landing.
	for span in [[-3.0,4.0],[1.65,1.5]]:
		var x: float = span[0]
		var width: float = span[1]
		block(Vector3(x,UPPER+1.55,-0.7),Vector3(width,3.1,0.18),plaster)
	# Enclosed upstairs stairwell, with the wide rear landing left open.
	block(Vector3(2.49,UPPER+1.55,2.15),Vector3(0.18,3.1,5.7),plaster)
	block(Vector3(2.36,UPPER+0.1,2.15),Vector3(0.08,0.2,5.7),timber,false)
	block(Vector3(2.36,6.45,2.15),Vector3(0.12,0.12,5.7),trim,false)
	# A finished reveal at the landing joins the new wall to the ceiling.
	block(Vector3(2.49,UPPER+1.53,-0.7),Vector3(0.26,3.06,0.10),trim,false)
	# The landing end is open above a short banister instead of a full wall.
	block(Vector3(2.58,UPPER+0.96,-2.05),Vector3(0.10,0.10,2.7),timber,false)
	block(Vector3(2.58,UPPER+0.07,-2.05),Vector3(0.09,0.09,2.7),timber,false)
	for z in [-3.1,-2.8,-2.5,-2.2,-1.9,-1.6,-1.3,-1.0]:
		block(Vector3(2.58,UPPER+0.47,z),Vector3(0.05,0.88,0.05),trim,false)
		block(Vector3(2.58,UPPER+0.49,z),Vector3(0.08,0.18,0.08),timber,false)
	# Loose plaster and exposed laths remain off the main walking line.
	for i in range(8):
		var chip=block(Vector3(-4.65+(i%3)*0.16,FLOOR+0.025,1.5+i*0.35),Vector3(0.19,0.035,0.13),trim,false)
		chip.rotation.y=i*1.7
	for y in [1.1,1.35,1.6,1.85]: block(Vector3(-4.87,y,-2.6),Vector3(0.02,0.045,1.5),timber,false)

func build_interior_joins():
	# Interior wall lining follows the facade openings exactly.
	for node in get_children():
		if not node is Node3D or absf(absf(node.position.z)-5.0)>0.01: continue
		if node.get_child_count()==0 or not node.get_child(0) is MeshInstance3D: continue
		var visual=node.get_child(0)
		if visual.material_override!=siding or not visual.mesh is BoxMesh: continue
		var size=visual.mesh.size
		size.z=0.02
		block(Vector3(node.position.x,node.position.y,signf(node.position.z)*4.865),size,plaster,false)
	# Continuous ceiling slabs and trim tie the rooms together, with the stairwell left open.
	block(Vector3(0,6.57,0),Vector3(10,0.12,10),plaster)
	for base in [FLOOR,UPPER]:
		var top=UPPER-0.16 if base==FLOOR else 6.51
		for x in [-4.84,4.84]:
			block(Vector3(x,base+0.10,0),Vector3(0.10,0.20,9.9),timber,false)
			block(Vector3(x,top-0.06,0),Vector3(0.15,0.14,9.9),trim,false)
		for z in [-4.84,4.84]:
			block(Vector3(0,top-0.06,z),Vector3(9.53,0.14,0.15),trim,false)
		block(Vector3(0,base+0.1,-4.84),Vector3(9.58,0.2,0.1),timber,false)
		for x in [-2.845,2.845]:
			block(Vector3(x,base+0.1,4.84),Vector3(3.89,0.2,0.1),timber,false)
	# Full headers above the internal openings prevent partitions ending in midair.
	block(Vector3(-0.7,3.0,1.9),Vector3(0.18,0.58,2.2),plaster)
	block(Vector3(-2.7775,3.0,-1),Vector3(1.445,0.58,0.18),plaster)
	for z in [0.8,3.0]:
		block(Vector3(-0.7,1.49,z),Vector3(0.26,2.54,0.13),timber,false)
	block(Vector3(-0.7,2.76,1.9),Vector3(0.26,0.13,2.33),timber,false)
	for x in [-3.5,-2.055]:
		block(Vector3(x,1.49,-1),Vector3(0.13,2.54,0.26),timber,false)
	block(Vector3(-2.7775,2.76,-1),Vector3(1.58,0.13,0.26),timber,false)
	# Original upstairs bedroom doorway and both partition sections.
	block(Vector3(-0.05,6.15,-0.7),Vector3(1.9,0.8,0.18),plaster)
	for x in [-1.0,0.9]:
		block(Vector3(x,UPPER+1.1175,-0.7),Vector3(0.13,2.235,0.26),timber,false)
	block(Vector3(-0.05,UPPER+2.3,-0.7),Vector3(2.03,0.13,0.26),timber,false)
	# Close the exposed floor edge below the landing balustrade.
	block(Vector3(2.58,UPPER-0.10,-0.025),Vector3(0.10,0.18,6.75),timber,false)

func window_frame(p: Vector3, boarded: bool):
	for x in [-1.31,1.31]: block(p+Vector3(x,0,0),Vector3(0.11,1.63,0.14),trim,false)
	for y in [-0.82,0.82]: block(p+Vector3(0,y,0),Vector3(2.78,0.12,0.19),trim,false)
	block(p,Vector3(0.05,1.5,0.06),timber,false)
	block(p,Vector3(2.5,0.05,0.06),timber,false)
	# A few remaining glass panes, rather than opaque black window cards.
	block(p+Vector3(-0.65,0.39,-0.05),Vector3(1.22,0.68,0.025),town.streetscape.glass,false)
	if boarded:
		for y in [-0.5,0.25]:
			var board=block(p+Vector3(0,y,0.09),Vector3(2.9,0.15,0.06),timber,false)
			board.rotation.z=y*0.3
	# Simple pointed lintel for the Victorian profile.
	for side in [-1,1]:
		var lintel=block(p+Vector3(side*0.65,0.99,0),Vector3(1.4,0.08,0.14),trim,false)
		lintel.rotation.z=-side*0.15

func build_porch():
	block(Vector3(0,FLOOR-0.08,5.9),Vector3(10.8,0.16,1.8),timber,false)
	# A continuous deck surface avoids an unseen vertical collider at the entry.
	ramp(Vector3(0,0,5),Vector3(0,0,6.8),FLOOR,FLOOR,10.8)
	# Broad front steps use a smooth collision slope, with no jump required.
	ramp(Vector3(0,0,6.8),Vector3(0,0,8.8),FLOOR,0,2.6)
	for i in range(3):
		block(Vector3(0,FLOOR-float(i+1)*FLOOR/3-0.025,7.13+i*0.66),Vector3(2.6,0.05,0.65),timber,false)
	# Entry ramp comes from the road-side end, clear of the antiques building.
	ramp(Vector3(5.4,0,5.9),Vector3(7.8,0,5.9),FLOOR,0,1.65)
	for x in [-5,-2.8,2.8,5]:
		var post=block(Vector3(x,1.67,6.55),Vector3(0.13,2.9,0.13),trim,false)
		if x== -5: post.rotation.z=0.055
		block(Vector3(x,2.97,6.55),Vector3(0.32,0.14,0.3),trim,false)
		for side in [-1,1]:
			var bracket=block(Vector3(x+side*0.2,2.78,6.55),Vector3(0.48,0.065,0.08),trim,false)
			bracket.rotation.z=side*0.7
	for x in [-4.8,-4.4,-4,-3.6,-3.2,-2.8,-2.4,-2,-1.6,1.8,2.2,2.6,3,3.4,3.8,4.2]:
		if x in [-4.0,-2.0,3.0]:continue
		var rail=block(Vector3(x,0.75,6.72),Vector3(0.055,0.95,0.055),trim,false)
		if x< -3.5:rail.rotation.z=0.13
	for x in [-3.5,3.5]:block(Vector3(x,1.24,6.72),Vector3(3.0,0.07,0.09),trim,false)
	# Porch roof is patched and sagging at the abandoned end.
	for i in range(12):
		if i==1: continue
		var panel=block(Vector3(-5.05+i*0.92,3.17-(0.07 if i<3 else 0),5.9),Vector3(0.89,0.12,2.25),roof_mat,false)
		panel.rotation.x=0.12
		if i==2:panel.rotation.z=0.08

func ramp(a: Vector3,b: Vector3,ya: float,yb: float,width: float, show_surface=true):
	var along=(b-a).normalized()
	var across=Vector3(-along.z,0,along.x)*width/2
	var points=[a+across+Vector3.UP*ya,a-across+Vector3.UP*ya,b+across+Vector3.UP*yb,b-across+Vector3.UP*yb]
	var mesh=SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in [0,2,1,1,2,3]:mesh.add_vertex(points[i])
	mesh.generate_normals()
	var visual=MeshInstance3D.new()
	visual.mesh=mesh.commit()
	visual.material_override=timber
	visual.visible=show_surface
	add_child(visual)
	var body=StaticBody3D.new()
	body.set_meta("footstep_surface","stairs" if not show_surface else "stone")
	add_child(body)
	var shape=ConcavePolygonShape3D.new()
	shape.set_faces(visual.mesh.get_faces())
	shape.backface_collision=true
	var col=CollisionShape3D.new()
	col.shape=shape
	body.add_child(col)

func build_stairs():
	# Collision remains a smooth slope; the visible construction has full treads and risers.
	ramp(Vector3(3.72,0,3.35),Vector3(3.72,0,-3.4),FLOOR,UPPER,2.25,false)
	var count=18
	var run=6.75/count
	var rise=(UPPER-FLOOR)/count
	for i in range(count):
		var z=3.35-(i+0.5)*run
		var height=FLOOR+(i+1)*rise
		block(Vector3(3.72,height-0.035,z),Vector3(2.28,0.07,run if i==count-1 else run+0.045),timber,false)
		block(Vector3(3.72,height-rise/2-0.035,z+run/2),Vector3(2.28,rise,0.045),siding,false)
		# Rounded-looking projecting nosing, simplified to a beveled strip.
		block(Vector3(3.72,height-0.025,z+run/2+0.018),Vector3(2.28,0.045,0.045),trim,false)
	for x in [2.58]:
		var stringer=block(Vector3(x,(FLOOR+UPPER)/2-0.15,-0.025),Vector3(0.10,0.26,7.48),timber,false)
		stringer.rotation.x=atan2(UPPER-FLOOR,6.75)
		var handrail=block(Vector3(x,(FLOOR+UPPER)/2+0.96,-0.025),Vector3(0.10,0.10,7.48),timber,false)
		handrail.rotation.x=atan2(UPPER-FLOOR,6.75)
		for i in range(18):
			var t=float(i)/17
			var p=Vector3(x,lerpf(FLOOR,UPPER,t),lerpf(3.35,-3.4,t))
			block(p+Vector3(0,0.48,0),Vector3(0.05,0.85,0.05),trim,false)
			block(p+Vector3(0,0.50,0),Vector3(0.08,0.18,0.08),timber,false)
		for end in [0.0,1.0]:
			var p=Vector3(x,lerpf(FLOOR,UPPER,end),lerpf(3.35,-3.4,end))
			block(p+Vector3(0,0.52,0),Vector3(0.15,1.04,0.15),timber,false)
			block(p+Vector3(0,1.06,0),Vector3(0.22,0.09,0.22),trim,false)

	# Wall-side skirt touches the plaster without a second balustrade.
	var skirt=block(Vector3(4.82,(FLOOR+UPPER)/2-0.10,-0.025),Vector3(0.08,0.28,7.48),trim,false)
	skirt.rotation.x=atan2(UPPER-FLOOR,6.75)

func roof_triangle(a: Vector3,b: Vector3,c: Vector3,material: Material):
	var mesh=SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [a,b,c]:
		mesh.set_uv(Vector2(point.x,point.z)*0.4)
		mesh.add_vertex(point)
	mesh.generate_normals()
	var visual=MeshInstance3D.new()
	visual.mesh=mesh.commit()
	visual.material_override=material
	add_child(visual)

func build_roofs():
	roof_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	# Steep main gable and an offset front-facing cross-gable.
	for side in [-1,1]:
		var a=Vector3(side*5.4,6.55,5.35)
		var b=Vector3(side*5.4,6.55,-5.35)
		var c=Vector3(0,9.1,5.35)
		var d=Vector3(0,9.1,-5.35)
		for strip in range(5):
			for row in range(4):
				if side== -1 and strip in [1,2] and row==1: continue
				var t0=float(strip)/5
				var t1=float(strip+1)/5
				var v0=float(row)/4
				var v1=float(row+1)/4
				var p0=a.lerp(b,t0).lerp(c.lerp(d,t0),v0)
				var p1=a.lerp(b,t1).lerp(c.lerp(d,t1),v0)
				var p2=a.lerp(b,t0).lerp(c.lerp(d,t0),v1)
				var p3=a.lerp(b,t1).lerp(c.lerp(d,t1),v1)
				roof_triangle(p0,p1,p2,roof_mat)
				roof_triangle(p1,p3,p2,roof_mat)
		# Exposed rafters remain visible through missing slates.
		for z in [-4,-2,0,2,4]:
			var beam=block(Vector3(side*2.5,7.75,z),Vector3(5.7,0.10,0.10),timber,false)
			beam.rotation.z=-side*0.46
	roof_triangle(Vector3(-5.1,6.55,5.1),Vector3(0,9.1,5.1),Vector3(5.1,6.55,5.1),siding)
	roof_triangle(Vector3(-5.1,6.55,-5.1),Vector3(5.1,6.55,-5.1),Vector3(0,9.1,-5.1),siding)
	for side in [-1,1]:
		var rake=block(Vector3(side*2.6,7.87,5.3),Vector3(5.9,0.12,0.18),trim,false)
		rake.rotation.z=-side*0.46
	# Carved bargeboard teeth are irregular and partly missing.
	for i in range(17):
		if i in [3,4,12]:continue
		var x=-4.8+i*0.6
		block(Vector3(x,9.0-absf(x)*0.47-0.15,5.35),Vector3(0.12,0.27,0.10),trim,false)
	block(Vector3(-3.7,7.6,-2.6),Vector3(0.7,2.0,0.65),town.mats.brick,false)
	block(Vector3(-3.7,8.62,-2.6),Vector3(0.9,0.14,0.83),trim,false)

func prop(asset: String,p: Vector3,yaw=0.0,scale_factor=1.0):
	var kit=town.apartment_interiors
	var root=StaticBody3D.new()
	root.name="Victorian_"+asset
	add_child(root)
	root.position=p
	root.rotation.y=yaw
	root.scale=Vector3.ONE*scale_factor
	var model=kit.scenes[asset].instantiate()
	root.add_child(model)
	kit.adapt(model)
	var dims=kit.manifest[asset].dimensions
	var shape=BoxShape3D.new()
	shape.size=Vector3(dims[0]*0.9,dims[1],dims[2]*0.9)
	var col=CollisionShape3D.new()
	col.position.y=dims[1]/2
	col.shape=shape
	root.add_child(col)
	props.append(root)

func dress_rooms():
	prop("sofa",Vector3(-3.6,FLOOR,3.6),PI)
	prop("side_table",Vector3(-3.4,FLOOR,2.6),0,0.9)
	prop("bookcase",Vector3(-4.45,FLOOR,0.1),PI/2,0.85)
	prop("dining_table",Vector3(-2.9,FLOOR,-3),0,0.85)
	prop("chair",Vector3(-3.9,FLOOR,-3),PI/2,0.85)
	prop("chair",Vector3(-2.0,FLOOR,-3),-PI/2,0.85)
	prop("wardrobe",Vector3(0.5,FLOOR,-4.35),PI,0.8)
	prop("bed",Vector3(-3.5,UPPER,2.7),PI,0.9)
	prop("dresser",Vector3(0.9,UPPER,3.8),PI,0.85)
	prop("wardrobe",Vector3(-4.3,UPPER,-3.9),PI/2,0.85)
	prop("bed",Vector3(-2.3,UPPER,-3.7),0,0.85)
	for pos in [Vector3(-4.6,FLOOR,-4.4),Vector3(-4.4,UPPER,0.5),Vector3(-4.5,UPPER,-1.8)]:
		var mess=kit_prop("trash",pos)
		mess.rotation.y=pos.z
	for y in [1.7,UPPER+1.7]: town.lamp(self,Vector3(-1.5,y,0),Color("8e9d89"),0.18,6)

func kit_prop(asset: String,p: Vector3) -> Node3D:
	var node=town.apartment_interiors.scenes[asset].instantiate()
	add_child(node)
	node.position=p
	town.apartment_interiors.adapt(node)
	return node

func contains(p: Vector3) -> bool:
	var local=to_local(p)
	return absf(local.x)<5.3 and absf(local.z)<5.3 and local.y> -0.3 and local.y<7






func cellar_contains(p: Vector3) -> bool:
	if not is_instance_valid(cellar): return false
	var q=cellar.to_local(p)
	return absf(q.x)<3.7 and absf(q.z)<4.3 and q.y> -0.4 and q.y<3.3

func build_cellar():
	# Enclosed triangular stair spandrel; the portal door works like the chapel cellar.
	var corners=PackedVector3Array()
	for x in [2.57,4.86]:
		corners.append(Vector3(x,FLOOR,3.35))
		corners.append(Vector3(x,FLOOR,-3.4))
		corners.append(Vector3(x,UPPER-0.15,-3.4))
	var mesh=SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in [0,1,2,3,5,4,1,4,2,2,4,5,0,2,3,3,2,5]:
		mesh.add_vertex(corners[i])
	mesh.generate_normals()
	var wall=MeshInstance3D.new()
	wall.mesh=mesh.commit()
	# This thin enclosure is visible from the hall and the stair side.
	# It has no bottom face, so it cannot compete with the floor.
	var enclosure_shader=Shader.new()
	enclosure_shader.code=plaster.shader.code.replace("cull_back","cull_disabled")
	var enclosure_material=ShaderMaterial.new()
	enclosure_material.shader=enclosure_shader
	wall.material_override=enclosure_material
	add_child(wall)
	var solid=StaticBody3D.new()
	add_child(solid)
	var shape=ConvexPolygonShape3D.new()
	shape.points=corners
	var collision=CollisionShape3D.new()
	collision.shape=shape
	solid.add_child(collision)
	block(Vector3(2.53,FLOOR+0.09,-0.025),Vector3(0.1,0.18,6.75),timber,false)
	# The tall end is closed all the way to the rear wall, beneath the landing.
	block(Vector3(3.715,(FLOOR+UPPER-0.15)/2,-4.14),Vector3(2.29,UPPER-0.15-FLOOR,1.48),plaster)
	var doorway=Node3D.new()
	add_child(doorway)
	doorway.position=Vector3(2.49,FLOOR,-3.0)
	doorway.rotation.y=-PI/2
	var paint=painted_finish(Color("9fae9e"))
	town.box(doorway,Vector3(0,1.08,0),Vector3(1.0,2.16,0.07),paint,false)
	for x in [-0.56,0.56]: town.box(doorway,Vector3(x,1.12,0.02),Vector3(0.12,2.24,0.12),trim,false)
	town.box(doorway,Vector3(0,2.24,0.02),Vector3(1.24,0.12,0.12),trim,false)
	for y in [0.55,1.55]: town.box(doorway,Vector3(0,y,0.055),Vector3(0.76,0.77,0.045),trim,false)
	town.box(doorway,Vector3(0.36,1.0,0.12),Vector3(0.09,0.09,0.09),town.mats.amber,false)
	town.action_area(doorway,Vector3(0,1.1,0.16),Vector3(1.0,2.2,0.22),"house_cellar_entry",{"kind":"house_cellar_entry","label":"Open basement door"})
	cellar=Node3D.new()
	cellar.name="VictorianCellar"
	add_child(cellar)
	cellar.position=Vector3(0,-13,0)
	var stone=preload("res://victorian_cellar_dressing.gd").surface_material("wallBrick")
	var floor_body=town.box(cellar,Vector3(0,-0.12,0),Vector3(7.4,0.24,8.6),stone)
	floor_body.get_child(0).hide()
	var ceiling_body=town.box(cellar,Vector3(0,3.1,0),Vector3(7.4,0.2,8.6),timber)
	ceiling_body.get_child(0).hide()
	for x in [-3.6,3.6]:
		var cellar_side=town.box(cellar,Vector3(x,1.5,0),Vector3(0.2,3,8.6),stone)
		cellar_side.get_child(0).hide()
	var front_wall=town.box(cellar,Vector3(0,1.5,4.2),Vector3(7.4,3,0.2),stone)
	front_wall.get_child(0).hide()
	preload("res://victorian_breach.gd").build(self,cellar,stone)
	for i in range(5): town.box(cellar,Vector3(0,(i+1)*0.08,2+i*0.4),Vector3(1.6,(i+1)*0.16,0.4),timber,false)
	# Same smooth collision ramp and separate return portal used by the chapel.
	var stairs=StaticBody3D.new()
	stairs.set_meta("footstep_surface","stairs")
	cellar.add_child(stairs)
	var stair_shape=ConvexPolygonShape3D.new()
	stair_shape.points=PackedVector3Array([Vector3(-0.8,0,1.8),Vector3(0.8,0,1.8),Vector3(-0.8,0,3.8),Vector3(0.8,0,3.8),Vector3(-0.8,0.8,3.8),Vector3(0.8,0.8,3.8)])
	var stair_col=CollisionShape3D.new()
	stair_col.shape=stair_shape
	stairs.add_child(stair_col)
	town.box(cellar,Vector3(0,1.85,4.04),Vector3(1.3,2.1,0.08),paint,false)
	var sign=town.sign_text(cellar,"UP TO HOUSE",Vector3(0,2.9,3.98),22,Color("d0c8af"))
	sign.rotation.y=PI
	town.action_area(cellar,Vector3(0,1.8,3.9),Vector3(1.5,2.2,0.3),"house_cellar_exit",{"kind":"house_cellar_exit","label":"Return upstairs to house"})
	preload("res://victorian_cellar_dressing.gd").build(self,cellar)
	var light=town.lamp(cellar,Vector3(0,2.6,2.2),Color("c5ac86"),0.08,2.8)
	light.light_cull_mask=2
	town.streetscape.church.basement.prepare_cellar_lighting(cellar)

func enter_cellar():
	town.streetscape.church.basement.move_player(cellar.to_global(Vector3(0,0.02,0.8)),global_rotation.y)
	game.message="House basement. The stairs lead back upstairs."

func leave_cellar():
	town.streetscape.church.basement.move_player(to_global(Vector3(1.5,FLOOR+0.02,-3.0)),global_rotation.y+PI/2)
	game.message="Back in the house."
