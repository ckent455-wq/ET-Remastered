extends RefCounted
## Fitted, chamfered upholstery and restrained period patrol-car fittings.
static func build(owner):
	var game=owner.game;var town=game.town
	var cabin=Node3D.new();cabin.name="PoliceCabin";owner.car.add_child(cabin)
	var trim=game.mat(Color("303a36"));var cloth=game.mat(Color("697166"))
	var vinyl=game.mat(Color("414b44"));var rubber=game.mat(Color("17201c"))
	var metal=game.mat(Color("777f74"));var stitches=game.mat(Color("505b50"))
	var details=preload("res://car_cabin_details.gd")
	town.box(cabin,Vector3(0,0.29,0.02),Vector3(1.39,0.05,1.94),rubber,false)
	for side in [-1,1]:
		var x=side*0.42
		chamfer(cabin,Vector3(x,0.48,-0.17),Vector3(0.48,0.10,0.55),0.035,cloth,"PoliceDriverSeat" if side<0 else "PolicePassengerSeat")
		for edge in [-1,1]:chamfer(cabin,Vector3(x+edge*0.205,0.523,-0.17),Vector3(0.065,0.045,0.48),0.018,vinyl)
		var back=chamfer(cabin,Vector3(x,0.78,0.15),Vector3(0.47,0.12,0.56),0.04,cloth)
		back.rotation.x=PI/2-0.10
		for seam in [-0.13,0,0.13]:
			town.box(back,Vector3(seam,-0.061,0),Vector3(0.004,0.003,0.44),stitches,false)
			# Keep the centre of the driver's cushion clear beneath the pistol.
			if side>0:town.box(cabin,Vector3(x+seam,0.531,-0.17),Vector3(0.004,0.002,0.43),stitches,false)
		for post in [-0.075,0.075]:town.box(cabin,Vector3(x+post,1.075,0.19),Vector3(0.012,0.055,0.012),metal,false)
		var head=chamfer(cabin,Vector3(x,1.145,0.19),Vector3(0.26,0.085,0.13),0.025,vinyl)
		head.rotation.x=PI/2-0.10
		var buckle=town.box(cabin,Vector3(x-side*0.27,0.535,0.025),Vector3(0.045,0.065,0.05),rubber,false)
		town.box(buckle,Vector3(0,0.034,0),Vector3(0.026,0.006,0.028),game.mat(Color("713d35")),false)
		chamfer(cabin,Vector3(x,0.318,-0.65),Vector3(0.37,0.004,0.42),0.025,rubber)
	chamfer(cabin,Vector3(0,0.47,0.70),Vector3(1.24,0.12,0.45),0.05,cloth)
	var rear=chamfer(cabin,Vector3(0,0.76,0.95),Vector3(1.24,0.105,0.46),0.045,vinyl);rear.rotation.x=PI/2
	# A sloping dashboard stays below the original windshield and clear of the seat.
	details.profile(game,cabin,[-0.68,0.68],[Vector2(0.62,-0.43),Vector2(0.74,-0.43),Vector2(0.81,-0.53),Vector2(0.82,-0.64),Vector2(0.73,-0.70),Vector2(0.62,-0.64)],trim)
	details.profile(game,cabin,[-0.62,-0.22],[Vector2(0.79,-0.45),Vector2(0.91,-0.48),Vector2(0.92,-0.54),Vector2(0.82,-0.59),Vector2(0.79,-0.58)],rubber)
	var ink=game.mat(Color("a7b29b"),null,0.025)
	for x in [-0.51,-0.34]:details.dial(game,cabin,Vector3(x,0.854,-0.435),0.048,ink,rubber,metal)
	for x in [-0.10,0.30,0.59]:details.vent(town,cabin,Vector3(x,0.755,-0.421),Vector2(0.12,0.04),rubber,vinyl)
	chamfer(cabin,Vector3(0.39,0.68,-0.423),Vector3(0.40,0.105,0.018),0.012,vinyl)
	town.box(cabin,Vector3(0.39,0.71,-0.409),Vector3(0.055,0.012,0.008),metal,false)
	var column=town.box(cabin,Vector3(-0.42,0.75,-0.44),Vector3(0.065,0.065,0.16),rubber,false);column.rotation.x=-0.4
	var rim=TorusMesh.new();rim.inner_radius=0.12;rim.outer_radius=0.143;rim.rings=16;rim.ring_segments=6
	var wheel=game.mesh_at(cabin,rim,Vector3(-0.42,0.85,-0.34),rubber);wheel.rotation.x=1.2
	for angle in [0.0,2.15,-2.15]:
		var spoke=town.box(wheel,Vector3(sin(angle)*0.06,0,cos(angle)*0.06),Vector3(0.022,0.025,0.10),trim,false);spoke.rotation.y=angle
	game.mesh_at(wheel,game.cylinder(0.036,0.036,0.03,10),Vector3.ZERO,vinyl)
	# One orderly radio console instead of a large block between the seats.
	chamfer(cabin,Vector3(0,0.445,-0.16),Vector3(0.18,0.16,0.62),0.025,trim)
	chamfer(cabin,Vector3(0,0.595,-0.39),Vector3(0.20,0.12,0.18),0.015,rubber)
	town.box(cabin,Vector3(0,0.613,-0.295),Vector3(0.10,0.026,0.006),game.mat(Color("63734b")),false)
	for x in [-0.073,0.073]:details.disc(game,cabin,Vector3(x,0.60,-0.29),0.014,0.01,metal)
	for z in [-0.12,0.02]:game.mesh_at(cabin,game.cylinder(0.034,0.034,0.004,10),Vector3(0,0.527,z),rubber)
	# Trim mounts inward of the source door lining; nothing extends through the skin.
	town.box(owner.door,Vector3(0.01,-0.025,0.35),Vector3(0.008,0.18,0.51),vinyl,false)
	chamfer(owner.door,Vector3(0.035,-0.015,0.36),Vector3(0.08,0.05,0.25),0.015,rubber)
	town.box(owner.door,Vector3(0.04,0.105,0.50),Vector3(0.065,0.035,0.11),vinyl,false)
	town.box(owner.door,Vector3(0.078,0.105,0.50),Vector3(0.014,0.02,0.07),metal,false)
	# The still-powered cruiser provides a modest courtesy light when searched.
	chamfer(cabin,Vector3(0,1.27,0.26),Vector3(0.10,0.015,0.065),0.015,metal)
	var light=OmniLight3D.new();light.name="PoliceCourtesyLight";light.position=Vector3(0,1.15,0.20)
	light.light_color=Color("d6c3a2");light.light_energy=0.32;light.omni_range=1.45;light.shadow_enabled=false
	cabin.add_child(light);light.hide();owner.cabin_light=light

static func chamfer(parent:Node3D,position:Vector3,size:Vector3,bevel:float,material:Material,label="CabinTrim")->MeshInstance3D:
	var x=size.x/2;var z=size.z/2;var b=minf(bevel,minf(x,z)*0.8)
	var outline=[Vector2(-x+b,-z),Vector2(x-b,-z),Vector2(x,-z+b),Vector2(x,z-b),Vector2(x-b,z),Vector2(-x+b,z),Vector2(-x,z-b),Vector2(-x,-z+b)]
	var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(8):
		var a=outline[i];var c=outline[(i+1)%8]
		for p in [Vector3(0,size.y/2,0),Vector3(c.x,size.y/2,c.y),Vector3(a.x,size.y/2,a.y),Vector3(0,-size.y/2,0),Vector3(a.x,-size.y/2,a.y),Vector3(c.x,-size.y/2,c.y),Vector3(a.x,-size.y/2,a.y),Vector3(c.x,size.y/2,c.y),Vector3(c.x,-size.y/2,c.y),Vector3(a.x,-size.y/2,a.y),Vector3(a.x,size.y/2,a.y),Vector3(c.x,size.y/2,c.y)]:tool.add_vertex(p)
	tool.generate_normals()
	var mesh=MeshInstance3D.new();mesh.name=label;mesh.mesh=tool.commit();mesh.material_override=material;mesh.position=position;parent.add_child(mesh)
	return mesh
