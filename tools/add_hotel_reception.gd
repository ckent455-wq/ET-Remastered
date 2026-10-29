extends SceneTree
var town
var walnut:StandardMaterial3D
var panel:StandardMaterial3D
var brass:StandardMaterial3D
var dark:StandardMaterial3D
var paper:StandardMaterial3D
func _initialize():call_deferred("run")
func block(parent:Node3D,p:Vector3,size:Vector3,mat:Material,solid=false):return town.box(parent,p,size,mat,solid)
func part(parent:Node3D,mesh:Mesh,p:Vector3,mat:Material):
 var node=MeshInstance3D.new();node.mesh=mesh;node.position=p;node.material_override=mat;parent.add_child(node);return node
func cylinder(parent:Node3D,p:Vector3,radius:float,height:float,mat:Material,top=-1.0):
 var mesh=CylinderMesh.new();mesh.bottom_radius=radius;mesh.top_radius=radius if top<0 else top;mesh.height=height;mesh.radial_segments=12
 return part(parent,mesh,p,mat)
func sphere(parent:Node3D,p:Vector3,radius:float,height:float,mat:Material):
 var mesh=SphereMesh.new();mesh.radius=radius;mesh.height=height;mesh.radial_segments=12;mesh.rings=6;return part(parent,mesh,p,mat)
func label(parent:Node3D,value:String,p:Vector3,size=18):
 var node=town.sign_text(parent,value,p,size,Color("ddc69d"));node.text=value;node.pixel_size=.0035;node.shaded=true;node.outline_size=0;return node
func wood(color:Color):
 var image=Image.create(128,128,false,Image.FORMAT_RGB8)
 for y in 128:
  for x in 128:
   var grain=.035*sin(float(x)*.71+sin(float(y)*.07)*1.8)+.012*sin(float(x)*3.4+float(y)*.13)+float((x*13+y*7)%11)*.001
   image.set_pixel(x,y,color+Color(grain,grain*.7,grain*.4,0))
 var mat=StandardMaterial3D.new();mat.albedo_texture=ImageTexture.create_from_image(image);mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS;mat.uv1_triplanar=true;mat.uv1_scale=Vector3(1.4,1.4,1.4);mat.roughness=.88;mat.metallic_specular=.15
 return mat
func root_part(parent:Node3D,title:String,id:String,p:Vector3):
 var node=Node3D.new();node.name=title;node.position=p;parent.add_child(node)
 node.set_meta("runtime_spawn_id",id);node.set_meta("_edit_group_",true);node.set_meta("editor_description","Move this complete reception piece; its details and collision move together.")
 return node
func counter(parent:Node3D):
 var node=root_part(parent,"Reception_Counter","hotel_reception_counter",Vector3(3.70,.04,1.25))
 block(node,Vector3(0,.55,0),Vector3(3.20,.92,.65),walnut,true)
 block(node,Vector3(0,.12,.025),Vector3(3.31,.20,.73),walnut)
 block(node,Vector3(0,.245,.385),Vector3(3.28,.055,.08),brass)
 block(node,Vector3(0,.98,.025),Vector3(3.31,.10,.76),walnut)
 block(node,Vector3(0,1.075,.015),Vector3(3.45,.09,.88),walnut)
 block(node,Vector3(0,1.125,.015),Vector3(3.38,.025,.82),panel)
 # Three inset framed panels and fluted pilasters define the public face.
 for x in [-1.08,0,1.08]:
  block(node,Vector3(x,.61,.342),Vector3(.87,.55,.038),panel)
  for side in [-1,1]:block(node,Vector3(x+side*.455,.61,.37),Vector3(.045,.63,.048),walnut)
  for y in [.30,.92]:block(node,Vector3(x,y,.37),Vector3(.955,.045,.048),walnut)
  block(node,Vector3(x,.60,.365),Vector3(.64,.34,.018),walnut)
 for x in [-1.57,-.54,.54,1.57]:
  block(node,Vector3(x,.61,.39),Vector3(.095,.70,.085),walnut)
  for dx in [-.024,0,.024]:block(node,Vector3(x+dx,.61,.436),Vector3(.008,.48,.008),brass)
  for y in [.28,.94]:block(node,Vector3(x,y,.397),Vector3(.15,.07,.10),panel)
 # The short right return creates a clerk station without sealing its entry aisle.
 block(node,Vector3(1.48,.53,-.77),Vector3(.24,.98,.9),walnut,true)
 block(node,Vector3(1.48,1.075,-.77),Vector3(.38,.09,1.0),walnut)
 block(node,Vector3(.1,.78,-.48),Vector3(2.55,.065,.34),panel)
 # Front registration plaque, physically mounted to the central panel.
 block(node,Vector3(0,.61,.391),Vector3(.67,.19,.025),brass)
 label(node,"REGISTRATION",Vector3(0,.61,.409),17)
 bell(node,Vector3(.94,1.14,.11))
 register_book(node,Vector3(-.64,1.1395,.03))
 lamp(node,Vector3(-1.22,1.14,-.10))
 telephone(node,Vector3(.30,1.14,-.10))
 return node
func bell(parent:Node3D,p:Vector3):
 var node=Node3D.new();node.name="Brass_Service_Bell";parent.add_child(node);node.position=p
 cylinder(node,Vector3(0,.018,0),.105,.036,dark)
 sphere(node,Vector3(0,.043,0),.082,.105,brass)
 cylinder(node,Vector3(0,.102,0),.016,.035,brass)
 cylinder(node,Vector3(0,.123,0),.032,.012,brass)
func register_book(parent:Node3D,p:Vector3):
 var book=Node3D.new();book.name="Open_Guest_Register";parent.add_child(book);book.position=p;book.rotation.y=-.12
 block(book,Vector3(0,.01,0),Vector3(.63,.024,.42),dark)
 for side in [-1,1]:
  block(book,Vector3(side*.151,.028,0),Vector3(.292,.018,.385),paper)
  for row in 9:block(book,Vector3(side*.151,.038,-.12+row*.028),Vector3(.242,.0018,.002),town.mats.dark)
  for i in 5:
   var writing=block(book,Vector3(side*.151+.02*sin(i*1.7),.039,-.095+i*.057),Vector3(.09+float(i%3)*.02,.001,.003),dark);writing.rotation.y=.05*float(i%3-1)
 block(book,Vector3(0,.042,0),Vector3(.011,.012,.395),walnut)
 var pen=block(book,Vector3(.38,.025,.08),Vector3(.013,.012,.23),brass);pen.rotation.y=.55
func lamp(parent:Node3D,p:Vector3):
 var node=Node3D.new();node.name="Banker_Lamp";parent.add_child(node);node.position=p
 cylinder(node,Vector3(0,.018,0),.12,.036,brass)
 cylinder(node,Vector3(0,.16,-.03),.019,.27,brass)
 var glass=town.color_material(Color("3b5d49"));glass.roughness=.55
 var shade=cylinder(node,Vector3(0,.31,.025),.11,.32,glass);shade.rotation.z=PI/2
 var bulb=town.color_material(Color("e3ce9a"));bulb.emission_enabled=true;bulb.emission=Color("c8ad75");bulb.emission_energy_multiplier=.4
 block(node,Vector3(0,.25,.025),Vector3(.28,.025,.12),bulb)
 town.lamp(node,Vector3(0,.19,.06),Color("e0bd83"),.25,1.3)
func telephone(parent:Node3D,p:Vector3):
 var node=Node3D.new();node.name="Candlestick_Telephone";parent.add_child(node);node.position=p;node.rotation.y=-.25
 cylinder(node,Vector3(0,.025,0),.11,.05,dark)
 cylinder(node,Vector3(0,.17,-.025),.026,.29,brass)
 cylinder(node,Vector3(0,.31,-.025),.043,.035,brass)
 var mouth=cylinder(node,Vector3(0,.36,.01),.066,.085,dark,.022);mouth.rotation.x=1.05
 block(node,Vector3(-.07,.27,-.025),Vector3(.14,.018,.02),brass)
 cylinder(node,Vector3(-.115,.20,-.02),.025,.15,dark)
 cylinder(node,Vector3(-.115,.12,-.02),.048,.035,dark,.027)
 for i in 10:
  var mesh=TorusMesh.new();mesh.inner_radius=.011;mesh.outer_radius=.018;mesh.rings=8;mesh.ring_segments=6
  part(node,mesh,Vector3(-.12-float(i)*.003,.09-float(i)*.006,-.055),dark)
func rack(parent:Node3D):
 var node=root_part(parent,"Reception_Key_And_Mail_Rack","hotel_reception_key_rack",Vector3(3.7,1.35,-1.37))
 block(node,Vector3(0,.52,-.09),Vector3(2.2,1.16,.08),walnut)
 block(node,Vector3(0,.52,-.035),Vector3(2.03,1.00,.022),dark)
 for col in 5:block(node,Vector3(-1.02+col*.51,.52,.025),Vector3(.035,1.04,.25),walnut)
 for row in 4:block(node,Vector3(0,.025+row*.33,.025),Vector3(2.08,.035,.25),walnut)
 for side in [-1,1]:block(node,Vector3(side*1.1,.52,.02),Vector3(.09,1.23,.30),panel)
 for y in [-.08,1.12]:block(node,Vector3(0,y,.025),Vector3(2.31,.10,.32),walnut)
 for row in 3:
  for col in 4:
   var x=-.765+col*.51;var y=.05+row*.33
   block(node,Vector3(x,y-.015,.164),Vector3(.12,.045,.017),brass)
   label(node,str(201+row*4+col),Vector3(x,y-.015,.176),10)
   if (row*4+col)%3==0:
    block(node,Vector3(x+.10,y+.13,.01),Vector3(.17,.035,.11),paper)
   if row*4+col in [1,4,8]:
    cylinder(node,Vector3(x-.07,y+.23,.0),.012,.025,brass)
    var key=load("res://assets/lockbox/key.glb").instantiate();strip_import(key);node.add_child(key)
    var bounds=town.apartment_interiors.retro.bounds(key,node)
    var scale_factor=.20/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z));key.scale=Vector3.ONE*scale_factor
    key.position=Vector3(x-.07,y+.13,.08)-bounds.get_center()*scale_factor
 block(node,Vector3(0,1.30,-.015),Vector3(2.15,.22,.08),walnut)
 label(node,"SAINT GEORGE HOTEL",Vector3(0,1.30,.03),24)
 return node
func strip_import(n:Node):
 n.scene_file_path="";n.set_script(null)
 for child in n.get_children():strip_import(child)
func own_all(n:Node,owner:Node):
 for child in n.get_children():child.owner=owner;own_all(child,owner)
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.enemies.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 town=g.town;walnut=wood(Color("64442c"));panel=wood(Color("896443"));brass=town.color_material(Color("a68c54"));brass.roughness=.78;dark=town.color_material(Color("29271f"));paper=town.color_material(Color("cbbf9d"))
 var scene=load("res://editing/hotel_layout.tscn").instantiate();root.add_child(scene);var furniture=scene.get_node("Furniture")
 for n in furniture.get_children():
  if str(n.get_meta("runtime_spawn_id","")).begins_with("hotel_reception_"):n.free()
 var desk=counter(furniture);rack(furniture)
 var chair=root_part(furniture,"Reception_Clerks_Chair","hotel_reception_chair",Vector3(3.75,.04,-.30))
 var model=load("res://assets/apartment/chair.glb").instantiate();strip_import(model);chair.add_child(model);town.apartment_interiors.adapt(model)
 var bounds=town.apartment_interiors.retro.bounds(model,chair);model.position-=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
 var shape=BoxShape3D.new();shape.size=bounds.size;var collider=CollisionShape3D.new();collider.shape=shape;collider.position.y=bounds.size.y/2;var chair_body=StaticBody3D.new();chair.add_child(chair_body);chair_body.add_child(collider)
 # Keep the existing letter collectible, resting on the new counter beside the register.
 var note=scene.get_node("RoomShell_REFERENCE").get_node("house_note");note.position=Vector3(3.45,1.1795,1.43);note.show()
 own_all(scene,scene);var packed=PackedScene.new();assert(packed.pack(scene)==OK);assert(ResourceSaver.save(packed,"res://editing/hotel_layout.tscn")==OK)
 print("PASS: reception counter, bell, register, candlestick telephone, banker lamp, key/mail rack and clerk chair added to the editable lobby")
 scene.free();g.queue_free();await process_frame;quit()
