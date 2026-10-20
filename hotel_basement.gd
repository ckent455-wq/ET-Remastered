extends Node3D
## Separate underground space, reached through the mausoleum before the hotel door can be unbolted.
var game
var town
var hotel_unlocked=false
var hotel_entry: Node3D
var tunnel_entry: Node3D
var stone: StandardMaterial3D
var timber: StandardMaterial3D

func _ready():
 name="SaintGeorgeBasementAndTunnel"
 town=game.town
 position=Vector3(26,-24,-80)
 stone=town.mats.brick.duplicate()
 stone.albedo_color=Color("8c897c")
 timber=town.mats.wood.duplicate()
 timber.albedo_color=Color("9c927c")
 build_hotel_entry()
 build_mausoleum_entry()
 build_basement()
 build_tunnel()
 town.streetscape.church.basement.prepare_cellar_lighting(self)
 reset()

func box(p:Vector3,size:Vector3,mat:Material,solid=true):
 return town.box(self,p,size,mat,solid)

func doorway(parent:Node3D,p:Vector3,label:String,id:String,kind:String,face=0.0):
 var frame=Node3D.new()
 parent.add_child(frame)
 frame.position=p
 frame.rotation.y=face
 var paint=town.color_material(Color("687567"))
 town.box(frame,Vector3(0,1.16,0),Vector3(1.1,2.32,0.07),paint,false)
 for x in [-0.61,0.61]:town.box(frame,Vector3(x,1.2,0.025),Vector3(0.12,2.4,0.15),timber,false)
 town.box(frame,Vector3(0,2.4,0.025),Vector3(1.34,0.12,0.15),timber,false)
 for y in [0.57,1.67]:town.box(frame,Vector3(0,y,0.055),Vector3(0.83,0.82,0.035),paint,false)
 town.box(frame,Vector3(0.4,1.05,0.13),Vector3(0.09,0.09,0.09),town.mats.amber,false)
 var sign=town.sign_text(frame,label,Vector3(0,2.66,0.1),18,Color("c5bda5"))
 sign.pixel_size=0.0035
 town.action_area(frame,Vector3(0,1.16,0.17),Vector3(1.15,2.32,0.24),id,{"kind":kind,"label":label})
 return frame

func build_hotel_entry():
 hotel_entry=doorway(town.buildings.house,Vector3(-0.4,0.04,-4.57),"BASEMENT","hotel_basement_door","hotel_basement_door")
 # The bolt is deliberately only on the cellar side; a key cannot open this upstairs door.

func build_mausoleum_entry():
 var crypt=town.cemetery.crypt
 tunnel_entry=Node3D.new()
 crypt.add_child(tunnel_entry)
 tunnel_entry.position=Vector3(-0.78,0.04,-1.66)
 var dark=town.color_material(Color("101412"))
 town.box(tunnel_entry,Vector3(0,1.1,0.02),Vector3(0.88,2.2,0.035),dark,false)
 for x in [-0.49,0.49]:town.box(tunnel_entry,Vector3(x,1.16,0.06),Vector3(0.10,2.32,0.18),stone,false)
 town.box(tunnel_entry,Vector3(0,2.32,0.06),Vector3(1.08,0.14,0.18),stone,false)
 # Open iron gate folded against the vault wall, with worn descending steps beyond.
 var gate=Node3D.new()
 tunnel_entry.add_child(gate)
 gate.position=Vector3(-0.43,0,0.10)
 gate.rotation.y=-1.35
 for x in [0.05,0.23,0.41,0.59,0.77]:town.box(gate,Vector3(x,1.1,0),Vector3(0.035,2.1,0.035),town.mats.metal,false)
 for y in [0.15,1.0,2.1]:town.box(gate,Vector3(0.42,y,0),Vector3(0.84,0.045,0.045),town.mats.metal,false)
 town.action_area(tunnel_entry,Vector3(0,1.05,0.19),Vector3(0.88,2.1,0.22),"mausoleum_tunnel",{"kind":"mausoleum_tunnel","label":"Descend into the hidden tunnel"})

func build_basement():
 box(Vector3(0,-0.12,0),Vector3(9,0.24,10),stone)
 box(Vector3(0,3.15,0),Vector3(9,0.2,10),stone)
 for x in [-4.5,4.5]:box(Vector3(x,1.5,0),Vector3(0.25,3.0,10),stone)
 box(Vector3(0,1.5,5),Vector3(9,3,0.25),stone)
 # Real opening into the tunnel, with no overlapping end wall across it.
 for x in [-2.9,2.9]:box(Vector3(x,1.5,-5),Vector3(3.2,3,0.25),stone)
 box(Vector3(0,2.9,-5),Vector3(2.6,0.2,0.25),stone)
 for z in [-3,0,3]:box(Vector3(0,2.91,z),Vector3(8.75,0.22,0.22),timber,false)
 for x in [-2.7,2.7]:box(Vector3(x,1.45,0),Vector3(0.18,2.9,0.18),timber)
 doorway(self,Vector3(0,0,4.82),"UP TO SAINT GEORGE","hotel_basement_exit","hotel_basement_exit",PI)
 # The bolt is clearly visible beside the return door.
 box(Vector3(-0.42,1.18,4.68),Vector3(0.30,0.06,0.07),town.mats.metal,false)
 var coffins=preload("res://cellar_coffins.gd").new()
 coffins.cellar=self
 add_child(coffins)
 town.interiors.prop("shelf",self,Vector3(3.6,0,-3.8),Vector3(0.72,0.85,0.72))
 # The upright coffin now conceals the far-cellar Wrapper.
 # A grounded workbench and a note explain the route without adding a new required item.
 box(Vector3(-2.6,0.76,-2),Vector3(2.1,0.12,0.8),timber)
 for x in [-3.45,-1.75]:box(Vector3(x,0.35,-2),Vector3(0.12,0.70,0.65),timber)
 var note=town.action_area(self,Vector3(-2.6,0.83,-2),Vector3(0.44,0.12,0.42),"hotel_tunnel_note",{"kind":"note","label":"Read Saint George maintenance ledger","title":"Saint George maintenance ledger","text":"The old passage beneath the Whitcomb vault ends in the Saint George cellar.\nKeep the hotel stair door bolted from this side. The upstairs lock is broken.\nIf anyone comes through the passage, unbolt it before going back up. There is no other way into the cellar from the hotel."})
 town.box(note,Vector3.ZERO,Vector3(0.3,0.01,0.4),town.mats.paper,false)
 for p in [Vector3(0,2.65,3),Vector3(0,2.65,-2)]:
  var light=town.lamp(self,p,Color("ba9d72"),0.13,5)
  light.light_cull_mask=2

func build_tunnel():
 box(Vector3(0,-0.12,-17.5),Vector3(2.6,0.24,25),stone)
 box(Vector3(0,2.9,-17.5),Vector3(2.8,0.2,25),stone)
 for x in [-1.4,1.4]:box(Vector3(x,1.4,-17.5),Vector3(0.2,2.8,25),stone)
 box(Vector3(0,1.4,-30),Vector3(2.8,2.8,0.2),stone)
 for z in [-7,-11,-15,-19,-23,-27]:
  for x in [-1.23,1.23]:box(Vector3(x,1.35,z),Vector3(0.16,2.7,0.16),timber,false)
  box(Vector3(0,2.66,z),Vector3(2.6,0.2,0.22),timber,false)
  # Sparse damp patches and loose stones stay outside the walking strip.
  box(Vector3(1.285,0.65,z+0.6),Vector3(0.012,1.2,0.75),town.color_material(Color("424d3c")),false)
 for z in [-8,-20,-28]:
  var lamp=town.lamp(self,Vector3(0,2.35,z),Color("9aab91"),0.055,4)
  lamp.light_cull_mask=2
 doorway(self,Vector3(0,0,-29.82),"UP TO MAUSOLEUM","hotel_tunnel_return","hotel_tunnel_return")
 var sign=town.sign_text(self,"SAINT GEORGE",Vector3(0,2.3,-6.2),19,Color("b5ad94"))
 sign.rotation.y=PI
 sign.pixel_size=0.004

func contains(p:Vector3)->bool:
 var q=to_local(p)
 return q.y> -0.5 and q.y<3.5 and ((absf(q.x)<4.65 and q.z> -5.2 and q.z<5.2) or (absf(q.x)<1.55 and q.z>=-30.2 and q.z<=-4.8))

func prompt(kind:String)->String:
 if kind=="hotel_basement_door":return "E / Open basement door" if hotel_unlocked else "E / Bolted from the other side"
 if kind=="hotel_basement_exit":return "E / Return upstairs to hotel" if hotel_unlocked else "E / Unbolt door and enter hotel"
 return "E / Return to mausoleum" if kind=="hotel_tunnel_return" else "E / Descend into hidden tunnel"

func interact(kind:String):
 if kind=="mausoleum_tunnel":
  if not town.cemetery.can_take():
   game.message="The passage is inside the locked Whitcomb mausoleum."
   return
  move_player(to_global(Vector3(0,0.02,-28.5)),PI)
  game.message="A tunnel beneath the mausoleum. A faded sign points toward Saint George."
 elif kind=="hotel_basement_door":
  if not hotel_unlocked:
   game.message="Bolted from the other side."
   return
  move_player(to_global(Vector3(0,0.02,3.5)),0)
  game.message="Saint George Hotel basement. The old tunnel leads back to the mausoleum."
 elif kind=="hotel_basement_exit":
  hotel_unlocked=true
  move_player(town.buildings.house.to_global(Vector3(-0.4,0.05,-3.5)),town.buildings.house.global_rotation.y+PI)
  game.message="The bolt slides free. You can now use the hotel basement door from either side."
 elif kind=="hotel_tunnel_return":
  move_player(town.cemetery.crypt.to_global(Vector3(-0.65,0.05,-0.75)),town.cemetery.crypt.global_rotation.y+PI)
  game.message="Back inside the Whitcomb mausoleum."

func move_player(p:Vector3,yaw:float):
 town.streetscape.church.basement.move_player(p,yaw)

func reset():
 hotel_unlocked=false
 if has_node("CellarCoffinStacks"):get_node("CellarCoffinStacks").reset_burst()
