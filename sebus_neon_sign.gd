extends Node3D
## Original geometry referenced from Sebus Brothers' projecting Hotpoint sign.
var town
var tubes:StandardMaterial3D
var letter_paint:StandardMaterial3D
var lights:Array[OmniLight3D]=[]
var halos:Array[Sprite3D]=[]
var rng=RandomNumberGenerator.new()
var wait=0.0
var burst_left=0
var dipped=false
func _ready():
 name="SebusNeonSign";position=Vector3(-1.5,4.85,5.55);rotation.y=PI/2
 rng.randomize();wait=rng.randf_range(5.0,12.0)
 var blue=town.color_material(Color("182d64"));blue.roughness=0.65;blue.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 var cream=town.color_material(Color("c6c8b3"));cream.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;cream.cull_mode=BaseMaterial3D.CULL_DISABLED
 letter_paint=cream.duplicate()
 var lower=town.mats.metal.duplicate();lower.albedo_color=Color("546368")
 tubes=town.color_material(Color("fff0c9"),2.0);tubes.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;tubes.metallic_specular=0;tubes.cull_mode=BaseMaterial3D.CULL_DISABLED
 town.box(self,Vector3.ZERO,Vector3(2.65,1.30,.16),blue,false)
 town.box(self,Vector3(0,-.87,0),Vector3(2.65,.40,.14),lower,false)
 for face in [-1,1]:
  var front=Node3D.new();front.name="StreetFace" if face>0 else "ReturnFace";add_child(front);front.position.z=face*.09;front.rotation.y=0 if face>0 else PI
  var rim=[Vector2(-1.23,-.64),Vector2(1.23,-.64),Vector2(1.31,-.58),Vector2(1.31,.58),Vector2(1.23,.64),Vector2(-1.23,.64),Vector2(-1.31,.58),Vector2(-1.31,-.58),Vector2(-1.23,-.64)]
  stroke(front,[rim],.025,.01,cream,"PorcelainRim")
  var paths=hotpoint_paths()
  var shadow=town.color_material(Color("101e42"))
  stroke(front,paths,.028,.025,shadow,"PaintedLetterShadows")
  stroke(front,paths,.022,.04,letter_paint,"PaintedHotpointLetters")
  stroke(front,paths,.008,.069,tubes,"HotpointNeonTubing")
  neon_haze(front,paths)
  lettering(front,"APPLIANCES",Vector3(0,-.39,.028),2.17,Color("d8dacb"))
  lettering(front,"SEBUS BROTHERS",Vector3(0,-.87,.025),2.43,Color("c4c1aa"))
  # A broad low-opacity halo works with the game's compatibility renderer.
  var image=Image.create(64,32,false,Image.FORMAT_RGBA8)
  for y in range(32):
   for x in range(64):
    var d=Vector2((x-31.5)/31.5,(y-15.5)/15.5).length()
    image.set_pixel(x,y,Color(1,.83,.55,pow(maxf(0,1-d),2)*.12))
  var halo=Sprite3D.new();halo.name="NeonHalo";halo.texture=ImageTexture.create_from_image(image);halo.pixel_size=.052;halo.position=Vector3(0,.15,.11);halo.no_depth_test=false;front.add_child(halo);halos.append(halo)
 # Wall mounts project from the building; no collision over the sidewalk.
 for y in [-.45,.43]:
  town.box(self,Vector3(1.4,y,0),Vector3(.3,.09,.28),town.mats.metal,false)
 # The blade is perpendicular to the facade, so its right edge meets the wall.
 var light=OmniLight3D.new();light.name="NeonStreetSpill";light.position=Vector3(0,.1,0);light.light_color=Color("ffe4b5");light.light_energy=.65;light.omni_range=4.4;light.omni_attenuation=1.8;add_child(light);lights.append(light)
 set_lit(true)
func neon_haze(parent:Node3D,paths:Array):
 var image=Image.create(256,128,false,Image.FORMAT_RGBA8)
 image.fill(Color(0,0,0,0))
 for path in paths:
  for i in range(path.size()-1):
   var a:Vector2=path[i];var b:Vector2=path[i+1]
   var steps=maxi(1,int(a.distance_to(b)*100))
   for step in range(steps+1):
    var p=a.lerp(b,float(step)/steps)
    var px=int((p.x+1.5)*256/3.0);var py=int((.75-p.y)*128/1.5)
    for y in range(maxi(0,py-5),mini(128,py+6)):
     for x in range(maxi(0,px-5),mini(256,px+6)):
      var d=Vector2(x-px,y-py).length()/5.0
      var alpha=pow(maxf(0,1-d),2)*.32
      if alpha>image.get_pixel(x,y).a:image.set_pixel(x,y,Color(1,.78,.42,alpha))
 var haze=Sprite3D.new();haze.name="IndividualTubeGlow";haze.texture=ImageTexture.create_from_image(image);haze.pixel_size=3.0/256;haze.position.z=.085;haze.no_depth_test=false;parent.add_child(haze);halos.append(haze)

func lettering(parent:Node3D,text:String,p:Vector3,width:float,color:Color):
 var label=Label3D.new();label.name=text.replace(" ","_");label.text=text;label.font=ThemeDB.fallback_font;label.font_size=96;label.pixel_size=width/label.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,96).x;label.position=p;label.modulate=color;label.outline_size=0;label.shaded=false;parent.add_child(label)
func hotpoint_paths()->Array:
 var paths=[]
 var x=-1.12
 paths.append([Vector2(x,.0),Vector2(x,.55)]);paths.append([Vector2(x+.29,0),Vector2(x+.29,.55)]);paths.append([Vector2(x-.08,.32),Vector2(x+.34,.32)]);x+=.39
 for letter in "otpoint":
  if letter=="o":paths.append(oval(x+.125,.20,.125,.175));x+=.30
  elif letter=="t":
   paths.append([Vector2(x+.08,.54),Vector2(x+.08,.10),Vector2(x+.10,.04),Vector2(x+.16,.025),Vector2(x+.21,.05)]);paths.append([Vector2(x-.015,.36),Vector2(x+.22,.36)]);x+=.245
  elif letter=="p":
   paths.append([Vector2(x, -.18),Vector2(x,.38)]);paths.append(oval(x+.12,.205,.12,.17));x+=.29
  elif letter=="i":
   paths.append([Vector2(x+.035,.025),Vector2(x+.035,.37)]);paths.append(oval(x+.035,.52,.018,.018));x+=.12
  elif letter=="n":
   paths.append([Vector2(x,.025),Vector2(x,.37)]);paths.append([Vector2(x,.25),Vector2(x+.04,.34),Vector2(x+.10,.38),Vector2(x+.17,.36),Vector2(x+.23,.29),Vector2(x+.23,.025)]);x+=.28
 # Lift title as a unit above the APPLIANCES line.
 for path in paths:
  for i in range(path.size()):path[i]=path[i]*Vector2(1.02,1.0)+Vector2(0,.06)
 return paths
func oval(cx:float,cy:float,rx:float,ry:float)->Array:
 var points=[]
 for i in range(25):points.append(Vector2(cx+cos(float(i)*TAU/24)*rx,cy+sin(float(i)*TAU/24)*ry))
 return points
func stroke(parent:Node3D,paths:Array,radius:float,z:float,material:Material,label:String):
 var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for path in paths:
  for i in range(path.size()-1):
   var a=Vector3(path[i].x,path[i].y,z);var b=Vector3(path[i+1].x,path[i+1].y,z);var direction:Vector3=(b-a).normalized();var across=Vector3(-direction.y,direction.x,0)
   for side in range(6):
    var angle=float(side)*TAU/6;var next=float(side+1)*TAU/6
    var na=across*cos(angle)+Vector3.FORWARD*sin(angle);var nb=across*cos(next)+Vector3.FORWARD*sin(next)
    for item in [[a+na*radius,na],[b+na*radius,na],[a+nb*radius,nb],[a+nb*radius,nb],[b+na*radius,na],[b+nb*radius,nb]]:
     tool.set_normal(item[1]);tool.add_vertex(item[0])
 var mesh=MeshInstance3D.new();mesh.name=label;mesh.mesh=tool.commit();mesh.material_override=material;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(mesh)
func set_lit(on:bool):
 letter_paint.albedo_color=Color("c6c8b3") if on else Color("657068")
 tubes.emission_energy_multiplier=2.0 if on else .035
 tubes.albedo_color=Color("fff0c9") if on else Color("5d625c")
 for light in lights:light.light_energy=.65 if on else .02
 for halo in halos:halo.visible=on
func _process(delta):
 wait-=delta
 if wait>0:return
 if burst_left==0:
  burst_left=rng.randi_range(2,6);dipped=true;set_lit(false);wait=rng.randf_range(.045,.13)
 else:
  dipped=not dipped;set_lit(not dipped);burst_left-=1
  if burst_left==0:dipped=false;set_lit(true);wait=rng.randf_range(6.0,17.0)
  else:wait=rng.randf_range(.04,.17)
