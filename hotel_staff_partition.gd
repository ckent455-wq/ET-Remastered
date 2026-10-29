extends Node3D
## Locked lobby access to the hotel's existing rear service/basement area.
const CENTER=-1.1625
const FRONT=-1.6
var game
var hinge:Node3D
var collision:CollisionShape3D
var unlocked=false
var opened=false
var joinery_rest={}
func _ready():
 name="HotelEmployeesOnlyPartition";transform=game.town.buildings.house.transform
 var town=game.town
 var paint=town.mats.plaster.duplicate();paint.albedo_color=Color("98917f")
 var trim=town.mats.furniture.duplicate();trim.albedo_color=Color("655747")
 # Ends meet the elevator return and existing right-hand partition.
 var left=-2.725;var right=.4;var half_gap=.65
 for span in [[left,CENTER-half_gap],[CENTER+half_gap,right]]:
  town.box(self,Vector3((span[0]+span[1])/2,1.55,FRONT),Vector3(span[1]-span[0],3.1,.14),paint)
 town.box(self,Vector3(CENTER,2.80,FRONT),Vector3(1.3,.6,.14),paint)
 var return_wall=town.box(self,Vector3(-2.8,1.55,-1.865),Vector3(.15,3.1,.67),paint)
 joinery_rest[return_wall]=return_wall.transform
 # Baseboards finish at the casing, rather than continuing through the door.
 for span in [[-2.875,CENTER-.75],[CENTER+.75,right]]:
  var base_end=5.675 if span[1]==right else span[1]
  var base_offset=Vector3((base_end-span[1])/2,0,0)
  moulding(Vector3((span[0]+span[1])/2,.071,FRONT+.105),Vector3(base_end-span[0],.07,.07),Vector3(span[1]-span[0],.07,.045),Vector3(0,.979,-.0125),trim,base_offset)
 moulding(Vector3(-2.69,.071,-1.865),Vector3(.07,.07,.67),Vector3(.045,.07,.67),Vector3(-.0125,.979,0),trim)
 for side in [-1,1]:town.box(self,Vector3(CENTER+side*.69,1.25,FRONT),Vector3(.12,2.50,.23),trim,false)
 town.box(self,Vector3(CENTER,2.56,FRONT),Vector3(1.5,.12,.23),trim,false)
 hinge=Node3D.new();hinge.name="StaffDoorHinge";add_child(hinge);hinge.position=Vector3(CENTER-.62,0,FRONT)
 var door_mat=town.color_material(Color("687263"))
 var leaf=town.box(hinge,Vector3(.62,1.24,0),Vector3(1.24,2.48,.10),door_mat)
 collision=leaf.get_child(1)
 for side in [-1,1]:
  for y in [.58,1.22,2.12]:town.box(leaf,Vector3(0,y-1.24,side*.062),Vector3(.99,.43,.028),trim,false)
  var brass=town.color_material(Color("9f8a58"))
  town.box(leaf,Vector3(.43,-.1,side*.075),Vector3(.09,.18,.025),brass,false)
  var knob=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=.043;sphere.height=.086;sphere.radial_segments=10;sphere.rings=5;knob.mesh=sphere;knob.material_override=brass;knob.position=Vector3(.43,-.07,side*.115);leaf.add_child(knob)
  town.box(leaf,Vector3(0,.47,side*.085),Vector3(.93,.29,.035),brass,false)
  town.box(leaf,Vector3(0,.47,side*.106),Vector3(.86,.22,.016),town.color_material(Color("d0c8ac")),false)
  var sign=town.sign_text(leaf,"EMPLOYEES ONLY",Vector3(0,.47,side*.118),28,Color("282b22"));sign.text="EMPLOYEES ONLY";sign.font=ThemeDB.fallback_font;sign.pixel_size=.0029;sign.outline_size=0;sign.shaded=true
  if side<0:sign.rotation.y=PI
 town.action_area(self,Vector3(CENTER,1.24,FRONT),Vector3(1.29,2.48,.38),"hotel_staff_door",{"kind":"hotel_staff_door","label":"Locked employees-only door"})
 reset()
func staff_side()->bool:return to_local(game.player.global_position).z<FRONT-.15
func prompt()->String:
 if not unlocked:return "E / Unbolt employees-only door" if staff_side() else "E / Locked employees-only door"
 return "E / "+("Close" if opened else "Open")+" employees-only door"
func interact():
 if game.state!="play":return
 if not unlocked:
  if not staff_side():game.message="Locked. Employees only.";return
  unlocked=true
 opened=not opened;collision.set_deferred("disabled",opened)
 game.soundscape.door_move(to_global(Vector3(CENTER,0,FRONT)),opened)
func reset():
 unlocked=false;opened=false;hinge.rotation.y=0;collision.set_deferred("disabled",false)
func _physics_process(delta):
 if game.state=="play":hinge.rotation.y=move_toward(hinge.rotation.y,1.50 if opened else 0.0,delta*2.6)

func moulding(p:Vector3,base_size:Vector3,rail_size:Vector3,rail_offset:Vector3,mat:Material,base_offset=Vector3.ZERO):
 var holder=game.town.box(self,p,base_size,mat,false)
 var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var base=BoxMesh.new();base.size=base_size;surface.append_from(base,0,Transform3D(Basis.IDENTITY,base_offset))
 var rail=BoxMesh.new();rail.size=rail_size;surface.append_from(rail,0,Transform3D(Basis.IDENTITY,rail_offset))
 holder.get_child(0).mesh=surface.commit()
 joinery_rest[holder]=holder.transform

func restore_joinery():
 for node in joinery_rest:node.transform=joinery_rest[node]
