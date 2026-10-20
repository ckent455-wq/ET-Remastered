extends RefCounted
## A compact, authored low-poly cabin fitted to the downloaded hatchback.
static func build(car,cabin,trim,fabric,dark,metal):
 var game=car.game;var town=game.town
 var charcoal=game.mat(Color("252b29"))
 var rubber=game.mat(Color("111916"))
 var worn=game.mat(Color("66695c"))
 var lens=game.mat(Color("18271f"))
 var markings=game.mat(Color("b2b993"),null,0.08)
 var amber=game.mat(Color("aa833e"),null,0.22)
 var green=game.mat(Color("66845c"),null,0.18)
 # Six-sided dashboard cross-section, rather than a rectangular shelf.
 profile(game,cabin,[-0.73,0.73],[Vector2(0.62,-0.54),Vector2(0.81,-0.54),Vector2(0.91,-0.65),Vector2(0.92,-0.86),Vector2(0.83,-0.94),Vector2(0.62,-0.86)],charcoal)
 town.box(cabin,Vector3(0,0.81,-0.534),Vector3(1.39,0.025,0.012),trim,false)
 # Raised instrument binnacle, recessed dials and a small odometer.
 profile(game,cabin,[-0.65,-0.21],[Vector2(0.88,-0.635),Vector2(1.04,-0.65),Vector2(1.07,-0.76),Vector2(1.02,-0.83),Vector2(0.88,-0.81)],rubber)
 for x in [-0.535,-0.335]:
  dial(game,cabin,Vector3(x,0.977,-0.627),0.068,markings,lens,metal)
 text(cabin,"083741",Vector3(-0.53,0.944,-0.612),0.0010,Color("91a479"))
 for i in range(3):town.box(cabin,Vector3(-0.415+i*0.023,0.932,-0.622),Vector3(0.013,0.009,0.004),amber if i!=1 else green,false)
 # A hooded radio, heater sliders and recessed louvered air vents.
 vent(town,cabin,Vector3(0,0.85,-0.582),Vector2(0.22,0.055),rubber,trim)
 for x in [-0.69,0.62]:vent(town,cabin,Vector3(x,0.83,-0.568),Vector2(0.09,0.045),rubber,trim)
 town.box(cabin,Vector3(0,0.747,-0.522),Vector3(0.25,0.10,0.024),rubber,false)
 town.box(cabin,Vector3(0,0.768,-0.506),Vector3(0.135,0.026,0.006),lens,false)
 text(cabin,"AM  0710",Vector3(0,0.764,-0.501),0.00085,Color("87956d"))
 for x in [-0.097,0.097]:disc(game,cabin,Vector3(x,0.752,-0.501),0.018,0.009,trim)
 for x in [-0.05,-0.025,0,0.025,0.05]:town.box(cabin,Vector3(x,0.72,-0.505),Vector3(0.017,0.012,0.007),metal,false)
 for y in [0.682,0.656]:
  town.box(cabin,Vector3(0,y,-0.525),Vector3(0.16,0.006,0.01),rubber,false)
  town.box(cabin,Vector3(-0.025 if y>0.67 else 0.035,y,-0.515),Vector3(0.022,0.019,0.018),metal,false)
 # Recessed glovebox and latch on the passenger side.
 town.box(cabin,Vector3(0.40,0.725,-0.525),Vector3(0.45,0.135,0.012),rubber,false)
 town.box(cabin,Vector3(0.40,0.725,-0.516),Vector3(0.432,0.12,0.013),trim,false)
 town.box(cabin,Vector3(0.40,0.762,-0.504),Vector3(0.085,0.014,0.009),metal,false)
 # Steering column, three spokes, horn boss and indicator stalks.
 var column=town.box(cabin,Vector3(-0.43,0.80,-0.50),Vector3(0.075,0.075,0.25),rubber,false);column.rotation.x=-0.5
 var torus=TorusMesh.new();torus.inner_radius=0.132;torus.outer_radius=0.161;torus.rings=16;torus.ring_segments=6
 var wheel=game.mesh_at(cabin,torus,Vector3(-0.43,0.93,-0.365),rubber);wheel.rotation.x=1.2
 car.steering_wheel=wheel
 for angle in [0.0,2.15,-2.15]:
  var spoke=town.box(wheel,Vector3(sin(angle)*0.070,0,cos(angle)*0.070),Vector3(0.025,0.027,0.12),charcoal,false);spoke.rotation.y=angle
 var hub=game.cylinder(0.047,0.047,0.042,10);game.mesh_at(wheel,hub,Vector3.ZERO,trim)
 town.box(wheel,Vector3(0,0.025,0),Vector3(0.035,0.008,0.023),metal,false)
 for side in [-1,1]:town.box(cabin,Vector3(-0.43+side*0.105,0.895,-0.46),Vector3(0.12,0.018,0.02),rubber,false)
 # Gear gaiter, lever, handbrake and two low cup recesses.
 town.box(cabin,Vector3(0,0.46,-0.05),Vector3(0.22,0.22,0.85),charcoal,false)
 town.box(cabin,Vector3(0,0.585,-0.27),Vector3(0.14,0.045,0.15),rubber,false)
 var lever=town.box(cabin,Vector3(0,0.67,-0.27),Vector3(0.02,0.14,0.02),metal,false);lever.rotation.x=-0.15
 var knob=SphereMesh.new();knob.radius=0.033;knob.height=0.06;knob.radial_segments=8;knob.rings=4;game.mesh_at(cabin,knob,Vector3(0,0.75,-0.28),rubber)
 for z in [0.05,0.20]:game.mesh_at(cabin,game.cylinder(0.046,0.046,0.008,10),Vector3(0,0.576,z),rubber)
 var brake=town.box(cabin,Vector3(-0.085,0.62,0.15),Vector3(0.025,0.025,0.20),rubber,false);brake.rotation.x=0.22
 # Seat bolsters, fabric channels and small, restrained wear patches.
 for x in [-0.43,0.43]:
  for side in [-1,1]:town.box(cabin,Vector3(x+side*0.245,0.575,-0.10),Vector3(0.105,0.105,0.74),fabric,false)
  for seam in [-0.13,0,0.13]:town.box(cabin,Vector3(x+seam,0.576,-0.12),Vector3(0.006,0.005,0.69),worn,false)
  for i in range(3):town.box(cabin,Vector3(x-0.11+i*0.042,0.578,-0.30+i*0.018),Vector3(0.025,0.004,0.075),dark,false)
 # The windshield slopes back to z=-0.1 at its top; roof-mounted pieces
 # must sit behind that edge, below the curved roof, rather than above glass.
 var mount=town.box(cabin,Vector3(0,1.355,0.09),Vector3(0.018,0.09,0.018),rubber,false)
 mount.name="MirrorRoofMount"
 town.box(cabin,Vector3(0,1.30,0.09),Vector3(0.23,0.075,0.025),rubber,false)
 town.box(cabin,Vector3(0,1.30,0.107),Vector3(0.207,0.055,0.008),game.mat(Color("525f5a")),false)
 for x in [-0.29,0.29]:
  var visor=town.box(cabin,Vector3(x,1.365,0.12),Vector3(0.29,0.022,0.12),trim,false)
  visor.name="SunVisor"
 # Build panels in car coordinates, then preserve their world fit at the hinge.
 for side in [-1,1]:
  var panel=Node3D.new();panel.name="DriverInnerDoor" if side<0 else "PassengerInnerDoor";cabin.add_child(panel)
  # The exterior skin tapers inward to x=+/-0.767 at the belt line.
  # Fit the liner behind that skin, rather than centering it outside the car.
  panel.position=Vector3(side*0.735,0.72,-0.15)
  town.box(panel,Vector3.ZERO,Vector3(0.04,0.49,1.19),trim,false)
  town.box(panel,Vector3(-side*0.028,0.025,0.06),Vector3(0.018,0.26,0.80),fabric,false)
  town.box(panel,Vector3(-side*0.062,0.015,0.06),Vector3(0.075,0.055,0.37),rubber,false)
  town.box(panel,Vector3(-side*0.044,0.14,-0.20),Vector3(0.035,0.035,0.13),metal,false)
  town.box(panel,Vector3(-side*0.036,-0.17,0.20),Vector3(0.035,0.075,0.36),charcoal,false)
  if side<0:panel.reparent(car.door,true)
static func text(parent,words:String,position:Vector3,pixel:float,color:Color):
 var label=Label3D.new();label.text=words;label.font=preload("res://assets/font.ttf");label.font_size=20;label.pixel_size=pixel
 label.position=position;label.modulate=color;label.outline_size=0;label.shaded=true;parent.add_child(label)
static func disc(game,parent,p:Vector3,radius:float,depth:float,material):
 var mesh=game.mesh_at(parent,game.cylinder(radius,radius,depth,16),p,material);mesh.rotation.x=PI/2
static func dial(game,parent,p:Vector3,radius:float,ink,face,rim):
 disc(game,parent,p,radius+0.005,0.012,rim);disc(game,parent,p+Vector3(0,0,0.008),radius,0.008,face)
 for i in range(11):
  var angle=lerpf(-2.3,2.3,i/10.0)
  var tick=game.town.box(parent,p+Vector3(sin(angle)*radius*0.80,cos(angle)*radius*0.80,0.015),Vector3(0.003,0.012,0.003),ink,false);tick.rotation.z=-angle
 var needle=game.town.box(parent,p+Vector3(-0.018,-0.012,0.018),Vector3(0.045,0.003,0.003),ink,false);needle.rotation.z=0.6
static func vent(town,parent,p:Vector3,size:Vector2,dark,trim):
 town.box(parent,p,Vector3(size.x,size.y,0.016),dark,false)
 for i in range(4):town.box(parent,p+Vector3(0,(i-1.5)*size.y/4,0.011),Vector3(size.x*0.90,0.004,0.009),trim,false)
static func profile(game,parent,width:Array,points:Array,material):
 var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 var vertices=[]
 for x in width:
  for point in points:vertices.append(Vector3(x,point.x,point.y))
 var n=points.size()
 for side in range(2):
  for i in range(1,n-1):
   var triangle=[side*n,side*n+i,side*n+i+1]
   if side==0:triangle.reverse()
   for index in triangle:tool.add_vertex(vertices[index])
 for i in range(n):
  var j=(i+1)%n
  for index in [i,j,n+i,n+i,j,n+j]:tool.add_vertex(vertices[index])
 tool.generate_normals();var mesh=MeshInstance3D.new();mesh.name="SculptedDashboard";mesh.mesh=tool.commit();mesh.material_override=material;parent.add_child(mesh)
