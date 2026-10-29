extends Node3D
## Saint George's physical second floor and two-stop passenger lift.
const UPPER=3.8
const LIFT_ORIGIN=Vector3(-4.3,0,-3.5)
var game
var town
var cab:AnimatableBody3D
var landing_doors=[]
var landing_jambs=[]
var cab_doors=[]
var room_hinges=[]
var room_colliders=[]
var room_open=[false,false,false]
var floor_index=0
var target_floor=0
var phase="idle"
var door_amount=0.0
var had_occupant=false
var exit_time=0.0
var travel_time=0.0
var travel_start=0.02
var rider=false
var motor:AudioStreamPlayer3D
var chime:AudioStreamPlayer3D
var indicators=[]
var bronze:StandardMaterial3D
var wood:StandardMaterial3D
var cream:StandardMaterial3D
var wallpaper:ShaderMaterial
var floor_mat:StandardMaterial3D
var ready_layout=false
var skirting_nodes=[]
var upper_furniture_count=0
func _ready():
 name="SaintGeorgeUpperFloorAndLift"
 town=game.town;transform=town.buildings.house.transform
 bronze=town.color_material(Color("8f7952"));bronze.roughness=.86
 wood=town.mats.wood.duplicate();wood.albedo_color=Color("8b7258")
 cream=town.color_material(Color("c3b99f"))
 wallpaper=ShaderMaterial.new();wallpaper.shader=preload("res://aged_wallpaper.gdshader")
 floor_mat=town.color_material(Color("665d50"))
 build_upper();build_shaft();build_cab();build_landings();furnish_rooms()
 motor=game.soundscape.spatial_voice(cab,load("res://assets/audio/hotel_lift_motor.wav"),-22,9)
 motor.stream=motor.stream.duplicate();motor.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
 chime=game.soundscape.spatial_voice(cab,load("res://assets/audio/hotel_lift_chime.wav"),-12,12)
 reset();call_deferred("finish_layout")
func finish_layout():
 while not game.surface_details.completed:await get_tree().process_frame
 game.hotel_layout.apply_layout();remove_intruding_plants();ready_layout=true
func box(p:Vector3,size:Vector3,mat:Material,solid=true,parent:Node3D=null):
 return town.box(self if parent==null else parent,p,size,mat,solid)
func text(parent:Node3D,value:String,p:Vector3,size=18):
 var label=town.sign_text(parent,value,p,size,Color("ded3b4"));label.text=value;label.remove_meta("removed_world_caption");label.pixel_size=.0038;label.shaded=true;label.outline_size=0
 return label
func build_upper():
 # Replace the old solid decorative storey without changing approved furniture indices.
 var facade=town.buildings.house.get_node("SaintGeorgeBrickFacade")
 facade.get_child(0).hide()
 facade.get_child(1).hide()
 var rim=town.streetscape.stone
 for z in [-5.08,5.08]:box(Vector3(0,3.73,z),Vector3(12.32,.16,.16),rim,false)
 for x in [-6.08,6.08]:box(Vector3(x,3.73,0),Vector3(.16,.16,10.32),rim,false)
 # Cut the former low ceiling and divider around the new shaft.
 for n in town.buildings.house.get_children():
  if n is Node3D and (n.position.is_equal_approx(Vector3(0,3.10,0)) or n.position.is_equal_approx(Vector3(0,3.49,-3.1))):n.hide()
 box(Vector3(1.6,3.49,-3.1),Vector3(8.6,.16,.16),wood,false)
 var old_ceiling=town.mats.plaster.duplicate();old_ceiling.albedo_color=Color("89897d")
 box(Vector3(1.6,3.10,0),Vector3(8.6,.07,9.7),old_ceiling,false)
 box(Vector3(-4.3,3.10,1.45),Vector3(3.2,.07,6.9),old_ceiling,false)
 # Continuous floor/ceiling slabs leave only the enclosed elevator shaft open.
 box(Vector3(1.6,3.7,0),Vector3(8.6,.2,9.8),floor_mat).set_meta("footstep_surface","wood")
 box(Vector3(-4.3,3.7,1.45),Vector3(3.2,.2,6.9),floor_mat).set_meta("footstep_surface","wood")
 box(Vector3(0,7.12,0),Vector3(11.9,.18,9.9),cream)
 var brick=town.streetscape.brick("house")
 for side in [-1,1]:
  box(Vector3(side*5.96,5.45,0),Vector3(.18,3.7,10),brick)
  box(Vector3(side*5.84,5.45,0),Vector3(.04,3.3,9.8),wallpaper,false)
 for z in [-4.96,4.96]:
  box(Vector3(0,5.45,z),Vector3(12,3.7,.18),brick)
  box(Vector3(0,5.45,z*.975),Vector3(11.7,3.3,.04),wallpaper,false)
 # Three guest rooms open off a central corridor and lift landing.
 # Right-side partition: two door openings, with continuous headers above.
 for zspan in [[-4.86,-3.25],[-1.85,1.85],[3.25,4.86]]:
  box(Vector3(1.25,5.3,(zspan[0]+zspan[1])/2),Vector3(.16,3.0,zspan[1]-zspan[0]),wallpaper)
 for z in [-2.55,2.55]:box(Vector3(1.25,6.75,z),Vector3(.16,.7,1.4),wallpaper)
 box(Vector3(3.55,5.45,0),Vector3(4.6,3.3,.16),wallpaper)
 # Left guest room, with a landing between its door and the lift.
 for span in [[-5.86,-4.05],[-2.65,-1.25]]:box(Vector3((span[0]+span[1])/2,5.45,-.55),Vector3(span[1]-span[0],3.3,.16),wallpaper)
 box(Vector3(-3.35,6.75,-.55),Vector3(1.4,.7,.16),wallpaper)
 box(Vector3(-1.25,5.45,2.15),Vector3(.16,3.3,5.4),wallpaper)
 room_door(Vector3(-3.35,UPPER,-.55),0,"201",0)
 room_door(Vector3(1.25,UPPER,2.55),PI/2,"202",1)
 room_door(Vector3(1.25,UPPER,-2.55),PI/2,"203",2)
 # Restrained burgundy corridor runner, joined skirting and warm sconces.
 var carpet=town.color_material(Color("594644"))
 box(Vector3(0,3.808,0),Vector3(1.85,.014,9.65),carpet,false)
 skirting_run("CorridorLeftSkirting",[[Vector3(-1.14,UPPER+.14,2.15),Vector3(.06,.28,5.4)]])
 var right=[]
 for span in [[-4.86,-3.25],[-1.85,1.85],[3.25,4.86]]:right.append([Vector3(1.14,UPPER+.14,(span[0]+span[1])/2),Vector3(.06,.28,span[1]-span[0])])
 skirting_run("CorridorRightSkirting",right)
 var landing=[]
 for span in [[-5.86,-4.05],[-2.65,-1.25]]:
  for z in [-.66,-.44]:landing.append([Vector3((span[0]+span[1])/2,UPPER+.14,z),Vector3(span[1]-span[0],.28,.06)])
 # Wrap the elevator recess and rear landing, stopping at the metal door casings.
 for span in [[-5.76,-5.36],[-3.24,-2.725]]:
  landing.append([Vector3((span[0]+span[1])/2,UPPER+.14,-1.98),Vector3(span[1]-span[0],.28,.06)])
 landing.append([Vector3(-2.695,UPPER+.14,(-4.816-1.95)/2),Vector3(.06,.28,4.816-1.95)])
 landing.append([Vector3((-2.665+1.11)/2,UPPER+.14,-4.786),Vector3(1.11+2.665,.28,.06)])
 landing.append([Vector3(-5.79,UPPER+.14,(-1.95-.69)/2),Vector3(.06,.28,1.95-.69)])
 # An L-shaped corner bead joins the landing wall to the corridor wall.
 # Its faces stand proud of the baseboards so overlapping joins cannot flicker.
 var corner_height=7.03-UPPER
 landing.append([Vector3(-1.13,UPPER+corner_height/2,-.57),Vector3(.08,corner_height,.12)])
 landing.append([Vector3(-1.17,UPPER+corner_height/2,-.67),Vector3(.16,corner_height,.08)])
 skirting_run("LandingRoomSkirting",landing)
 for z in [-3.9,.0,3.9]:sconce(Vector3(-1.10,5.65,z),PI/2)
 for p in [Vector3(-4.9,5.5,4.75),Vector3(4.7,5.5,4.75),Vector3(4.7,5.5,-4.75)]:sconce(p,0 if p.z>0 else PI)
 for x in [-4.3,-2.15,0,2.15,4.3]:
  box(Vector3(x,4.98,4.835),Vector3(1.12,1.3,.025),town.mats.dark,false)
  for side in [-1,1]:box(Vector3(x+side*.61,5.0,4.79),Vector3(.11,1.5,.1),wood,false)
  for y in [4.25,5.75]:box(Vector3(x,y,4.79),Vector3(1.32,.10,.12),wood,false)
 text(self,"GUEST ROOMS  /  201 - 203",Vector3(0,6.65,-4.78),20)
func skirting_run(label:String,segments:Array):
 # Batch each wall run into one mesh, keeping the existing save hierarchy stable.
 var holder=Node3D.new();holder.name=label;add_child(holder)
 var visual=MeshInstance3D.new();holder.add_child(visual)
 var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for segment in segments:
  var piece=BoxMesh.new();piece.size=segment[1]
  surface.append_from(piece,0,Transform3D(Basis.IDENTITY,segment[0]))
 visual.mesh=surface.commit();visual.material_override=wood
 holder.set_meta("generated_joinery",true);holder.set_meta("skirting_segments",segments);skirting_nodes.append(holder)
func sconce(p:Vector3,yaw:float):
 var holder=Node3D.new();add_child(holder);holder.position=p;holder.rotation.y=yaw
 box(Vector3.ZERO,Vector3(.17,.36,.08),bronze,false,holder)
 box(Vector3(0,.04,.13),Vector3(.27,.22,.18),cream,false,holder)
 town.lamp(holder,Vector3(0,.02,.27),Color("e3bc7f"),.38,4.2)
func room_door(p:Vector3,yaw:float,label:String,index:int):
 var frame=Node3D.new();add_child(frame);frame.position=p;frame.rotation.y=yaw
 for x in [-.74,.74]:box(Vector3(x,1.27,0),Vector3(.12,2.54,.19),wood,false,frame)
 box(Vector3(0,2.6,0),Vector3(1.6,.12,.19),wood,false,frame)
 var hinge=Node3D.new();frame.add_child(hinge);hinge.position.x=-.67
 var leaf=box(Vector3(.67,1.25,0),Vector3(1.34,2.5,.08),wood,true,hinge)
 for y in [-.65,.45]:box(Vector3(0,y,-.055),Vector3(1.05,.75,.035),cream,false,leaf)
 for side in [-1,1]:
  box(Vector3(.48,-.08,side*.09),Vector3(.12,.06,.09),bronze,false,leaf)
  var plaque=text(leaf,label,Vector3(0,.72,side*.061),20)
  if side<0:plaque.rotation.y=PI
 room_hinges.append(hinge);room_colliders.append(leaf.get_child(1))
 town.action_area(frame,Vector3(0,1.2,-.13),Vector3(1.4,2.4,.45),"hotel_room_"+str(index),{"kind":"hotel_room_door","room_index":index,"label":"Open room "+label})
func build_shaft():
 var metal=town.color_material(Color("444843"))
 for x in [-1.50,1.50]:box(LIFT_ORIGIN+Vector3(x,3.55,0),Vector3(.15,7.1,2.85),metal)
 box(LIFT_ORIGIN+Vector3(0,3.55,-1.42),Vector3(3.1,7.1,.15),metal)
 for floor_y in [0.0,UPPER]:
  for side in [-1,1]:box(LIFT_ORIGIN+Vector3(side*1.22,floor_y+1.35,1.4),Vector3(.58,2.7,.18),wallpaper)
  box(LIFT_ORIGIN+Vector3(0,floor_y+3.08,1.4),Vector3(3.0,1.06,.18),wallpaper)
func door_leaf(parent:Node3D,p:Vector3):
 var leaf=box(p,Vector3(.455,2.51,.055),bronze,true,parent)
 for y in [-.72,.15,.85]:
  box(Vector3(0,y,.043),Vector3(.30,.42,.018),wood,false,leaf)
 for x in [-.17,.17]:box(Vector3(x,0,.055),Vector3(.023,2.25,.025),cream,false,leaf)
 return leaf
func build_cab():
 cab=AnimatableBody3D.new();cab.name="PassengerCab";cab.sync_to_physics=false;add_child(cab);cab.position=LIFT_ORIGIN+Vector3(0,.02,0)
 # Shared cab collision follows the actual car throughout the ride.
 cab.set_meta("footstep_surface","stone")
 cab_box(Vector3(0,-.10,0),Vector3(2.75,.20,2.65),preload("res://elevator_tiles.tres"))
 # Raise the finish above the lobby slab where it overlaps the parked car.
 box(Vector3(0,.06,0),Vector3(2.60,.015,2.50),preload("res://elevator_tiles.tres"),false,cab).set_meta("runtime_visual_only",true)
 cab_box(Vector3(0,2.72,0),Vector3(2.75,.18,2.65),wood)
 cab_box(Vector3(0,1.35,-1.28),Vector3(2.75,2.7,.12),wood)
 for side in [-1,1]:cab_box(Vector3(side*1.34,1.35,0),Vector3(.12,2.7,2.65),wood)
 for side in [-1,1]:
  for z in [-.84,0,.84]:
   box(Vector3(side*1.266,1.65,z),Vector3(.02,1.6,.69),town.color_material(Color("756248")),false,cab)
   for edge in [-.365,.365]:box(Vector3(side*1.25,1.65,z+edge),Vector3(.03,1.82,.025),bronze,false,cab)
  box(Vector3(side*1.18,.98,-.13),Vector3(.055,.065,1.95),bronze,false,cab)
 for x in [-.9,0,.9]:
  box(Vector3(x,1.65,-1.205),Vector3(.73,1.6,.025),town.color_material(Color("756248")),false,cab)
  for edge in [-.40,.40]:box(Vector3(x+edge,1.65,-1.18),Vector3(.026,1.82,.035),bronze,false,cab)
 box(Vector3(0,.98,-1.12),Vector3(2.3,.065,.055),bronze,false,cab)
 var glow=town.color_material(Color("e6d2a3"));glow.emission_enabled=true;glow.emission=Color("cfb47b");glow.emission_energy_multiplier=.35
 box(Vector3(0,2.60,0),Vector3(1.7,.05,1.6),bronze,false,cab)
 box(Vector3(0,2.56,0),Vector3(1.45,.04,1.35),glow,false,cab)
 town.lamp(cab,Vector3(0,2.42,0),Color("e3bc7f"),.65,4)
 # Door wings run into pockets rather than rotate through the cabin.
 for side in [-1,1]:
  for panel in 2:cab_doors.append(door_leaf(cab,Vector3(side*(.23+panel*.46),1.28,1.24-panel*.075)))
  cab_box(Vector3(side*1.18,1.28,1.35),Vector3(.45,2.56,.18),wood)
 var panel=Node3D.new();cab.add_child(panel);panel.position=Vector3(1.24,1.25,.38);panel.rotation.y=-PI/2
 box(Vector3.ZERO,Vector3(.33,.82,.055),bronze,false,panel)
 text(panel,"2",Vector3(0,.21,.05),22);text(panel,"L",Vector3(0,-.13,.05),22)
 for y in [-.13,.21]:
  var button=MeshInstance3D.new();var cylinder=CylinderMesh.new();cylinder.top_radius=.045;cylinder.bottom_radius=.045;cylinder.height=.025;cylinder.radial_segments=10;button.mesh=cylinder;button.material_override=cream;button.rotation.x=PI/2;button.position=Vector3(.10,y,.05);panel.add_child(button)
 text(cab,"SAINT GEORGE\nPASSENGER LIFT",Vector3(0,2.15,-1.145),18)
 town.action_area(panel,Vector3(0,0,.10),Vector3(.48,.9,.22),"hotel_lift_controls",{"kind":"hotel_lift_controls","label":"Ride elevator"})
func cab_box(p:Vector3,size:Vector3,mat:Material):
 box(p,size,mat,false,cab)
 var collider=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;collider.shape=shape;collider.position=p;cab.add_child(collider)
func build_landings():
 for i in 2:
  var landing=Node3D.new();add_child(landing);landing.position=LIFT_ORIGIN+Vector3(0,UPPER*i,1.40)
  var leaves=[]
  for side in [-1,1]:
   for panel in 2:leaves.append(door_leaf(landing,Vector3(side*(.23+panel*.46),1.28,-panel*.075)))
   landing_jambs.append(box(Vector3(side*.985,1.2925,.07),Vector3(.15,2.585,.18),bronze,false,landing))
  box(Vector3(0,2.67,.07),Vector3(2.12,.17,.18),bronze,false,landing)
  box(Vector3(0,.015,.05),Vector3(1.98,.03,.28),bronze,false,landing)
  box(Vector3(0,2.94,.13),Vector3(1.98,.19,.035),bronze,false,landing)
  text(landing,"PASSENGER LIFT",Vector3(0,2.94,.16),21)
  var indicator=text(landing,"L",Vector3(0,2.72,.17),16);indicators.append(indicator)
  box(Vector3(1.22,1.22,.08),Vector3(.22,.46,.08),bronze,false,landing)
  text(landing,"CALL",Vector3(1.22,1.37,.14),12)
  box(Vector3(1.22,1.15,.14),Vector3(.08,.08,.04),cream,false,landing)
  town.action_area(landing,Vector3(1.22,1.22,.22),Vector3(.35,.6,.25),"hotel_lift_call_"+str(i),{"kind":"hotel_lift_call","floor":i,"label":"Call elevator"})
  landing_doors.append(leaves)
func fit_prop(asset:String,p:Vector3,size:Vector3,yaw=0.0):
 var holder=StaticBody3D.new();holder.name="UpperFurniture_%02d_%s"%[upper_furniture_count,asset];upper_furniture_count+=1;holder.set_meta("upper_furniture",asset);add_child(holder);holder.position=p;holder.rotation.y=yaw
 var model=load("res://assets/apartment/"+asset+".glb").instantiate();holder.add_child(model)
 var bounds=town.apartment_interiors.retro.bounds(model,holder)
 model.position-=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
 holder.scale=Vector3(size.x/bounds.size.x,size.y/bounds.size.y,size.z/bounds.size.z)
 town.apartment_interiors.adapt(model)
 var collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=bounds.size;collision.shape=shape;collision.position.y=bounds.size.y/2;holder.add_child(collision)
 return holder
func furnish_rooms():
 for z in [-2.45,2.45]:
  fit_prop("bed",Vector3(4.3,UPPER+.02,z),Vector3(1.6,.7,2.25),PI/2)
  fit_prop("side_table",Vector3(4.95,UPPER+.02,z+1.43),Vector3(.6,.62,.55))
  fit_prop("wardrobe",Vector3(2.25,UPPER+.02,z+1.48),Vector3(1.05,2.05,.6))
  fit_prop("chair",Vector3(5.05,UPPER+.02,z-1.45),Vector3(.6,.88,.65),-.3)
func apply_layout():
 repair_doorframes()
 for trim in skirting_nodes:
  trim.transform=Transform3D.IDENTITY;trim.get_child(0).transform=Transform3D.IDENTITY
 # Remove the former bedroom divider and its trim, preserving runtime indices.
 for n in town.buildings.house.get_children():
  if not n is Node3D:continue
  if n.position.is_equal_approx(Vector3(-3.8,1.51,-.9)) or n.position.is_equal_approx(Vector3(-3.8,.12,-.815)):
   n.hide();game.hotel_layout.disable_removed(n)
  if n.name=="Abandoned_crooked_picture":n.position=Vector3(-5.68,2.0,1.1);n.rotation.y=PI/2
  if n.position.is_equal_approx(Vector3(-3.3,2.0,-4.64)):n.position=Vector3(-4.9,5.8,-.43)
 # Lift replaces the downstairs sleeping nook; carry that furnished room upstairs.
 var names=["house_drawer","Apartment_bed7","Apartment_wardrobe8","Apartment_dresser9","books74","Apartment_rug10"]
 for n in town.buildings.house.get_children():
  if n.name in names and n.position.y<2.0:
   n.position+=Vector3(0,UPPER,5.3)
   if n.name in ["Apartment_bed7","Apartment_rug10"]:n.position.z+=.35
 for id in ["medkit_c","shotgun_key"]:
  var pickup=town.actions[id].area
  if pickup.position.y<2.0:pickup.position+=Vector3(0,UPPER,5.3)
 if game.hotel_upper_layout:game.hotel_upper_layout.apply_layout()
func inside_cab()->bool:
 var p=cab.to_local(game.player.global_position)
 return absf(p.x)<1.02 and p.z> -1.05 and p.z<.82 and p.y>-.12 and p.y<1.4
func contains(p:Vector3)->bool:
 var local=to_local(p);return absf(local.x)<6 and absf(local.z)<5 and local.y>=UPPER-.15 and local.y<7.2
func busy()->bool:return phase!="idle"
func prompt(kind:String,data:Dictionary)->String:
 if kind=="hotel_room_door":return "E / "+("Locked" if town.door_locks.locked(town,data) else "Close" if room_open[data.room_index] else "Open")+" room "+str(201+data.room_index)
 if phase=="parking":return "E / Open elevator"
 if busy():return "Elevator moving"
 if kind=="hotel_lift_controls":return "E / Ride to second floor" if floor_index==0 else "E / Ride to lobby"
 return "E / Open elevator" if data.floor==floor_index else "E / Call elevator"
func interact(kind:String,data:Dictionary):
 if game.state!="play":return
 if kind=="hotel_room_door":
  if not town.door_locks.opening_allowed(town,data):return
  var index=data.room_index;room_open[index]=not room_open[index]
  room_colliders[index].set_deferred("disabled",room_open[index]);game.soundscape.door_move(room_hinges[index].global_position,room_open[index]);return
 if phase=="parking" and kind=="hotel_lift_call":phase="opening";game.soundscape.door_move(cab.global_position,true);return
 if busy():return
 if kind=="hotel_lift_controls":
  if not inside_cab():game.message="Step fully inside the elevator to use the controls.";return
  begin_trip(1-floor_index,true)
 else:
  if int(data.floor)==floor_index:
   phase="opening";exit_time=0;game.soundscape.door_move(cab.global_position,true)
  else:begin_trip(int(data.floor),false)
func begin_trip(destination:int,carrying:bool):
 target_floor=destination;rider=carrying;phase="closing";game.jump_queued=false
 game.town.focus_action="";game.soundscape.door_move(cab.global_position,false)
func reset():
 floor_index=0;target_floor=0;phase="idle";door_amount=0;travel_time=0;rider=false;had_occupant=false;exit_time=0
 room_open=[false,false,false];cab.position=LIFT_ORIGIN+Vector3(0,.02,0)
 if motor:motor.stop()
 for i in room_colliders.size():room_colliders[i].set_deferred("disabled",false);room_hinges[i].rotation.y=0
 sync_doors()
func sync_doors():
 for i in 2:
  var amount=door_amount if i==floor_index and phase!="travel" else 0.0
  for j in 4:
   var side=-1 if j<2 else 1
   var panel=j%2
   landing_doors[i][j].position.x=side*lerpf(.23+panel*.46,1.15+panel*.03,amount)
   landing_doors[i][j].get_child(1).set_deferred("disabled",amount>.98)
  indicators[i].text=("L" if floor_index==0 else "2") if phase!="travel" else "-"
 for j in 4:
  var side=-1 if j<2 else 1
  var panel=j%2
  cab_doors[j].position.x=side*lerpf(.23+panel*.46,1.15+panel*.03,door_amount)
  cab_doors[j].get_child(1).set_deferred("disabled",door_amount>.98)
func _physics_process(delta):
 if motor:motor.stream_paused=game.state!="play"
 if game.state!="play":return
 for i in room_hinges.size():room_hinges[i].rotation.y=move_toward(room_hinges[i].rotation.y,-1.50 if room_open[i] else 0.0,delta*2.5)
 if phase=="idle" and door_amount==1:
  if inside_cab():had_occupant=true;exit_time=0
  elif had_occupant:
   if doorway_clear():exit_time+=delta
   else:exit_time=0
   if exit_time>=1.2:phase="parking";had_occupant=false;game.soundscape.door_move(cab.global_position,false)
 if phase=="parking":
  if not doorway_clear() or inside_cab():phase="opening"
  else:
   door_amount=move_toward(door_amount,0.0,delta)
   if door_amount==0:phase="idle";exit_time=0
 elif phase=="closing":
  door_amount=move_toward(door_amount,0.0,delta*1.0)
  if door_amount==0:
   phase="travel";travel_time=0;travel_start=cab.position.y;motor.play()
 elif phase=="travel":
  travel_time+=delta
  var before=cab.position.y;var t=clampf(travel_time/4.0,0,1)
  cab.position.y=lerpf(travel_start,.02 if target_floor==0 else UPPER,t*t*(3.0-2.0*t))
  if rider:game.player.global_position.y+=cab.position.y-before;game.player.velocity=Vector3.ZERO
  if t>=1:
   floor_index=target_floor;phase="opening";motor.stop();chime.play();game.soundscape.door_move(cab.global_position,true)
 elif phase=="opening":
  door_amount=move_toward(door_amount,1.0,delta)
  if door_amount==1:phase="idle";rider=false
 sync_doors()

func remove_intruding_plants():
 var forest=game.get_node_or_null("DetailedForest")
 if not forest:return
 var inverse=global_transform.affine_inverse()
 var rooms=AABB(Vector3(-6.05,0,-5.05),Vector3(12.1,7.2,10.1))
 for plant in forest.get_children():
  var intrudes=false
  for mesh in plant.find_children("*","MeshInstance3D",true,false):
   if not mesh.is_visible_in_tree() or not mesh.mesh:continue
   var source=mesh.mesh.resource_path
   for surface in mesh.mesh.get_surface_count():
    var mat=mesh.get_active_material(surface)
    if mat is StandardMaterial3D and mat.albedo_texture:source+=" "+mat.albedo_texture.resource_path
   if not ("bush" in source or "pine" in source or "twig" in source or "leaf" in source):continue
   if rooms.intersects((inverse*mesh.global_transform)*mesh.get_aabb()):intrudes=true;break
  if intrudes:plant.hide();game.hotel_layout.disable_removed(plant)

func repair_doorframes():
 # Reapply the corrected joins after older saves restore their previous offsets.
 for hinge in room_hinges:
  var frame=hinge.get_parent()
  for i in 2:
   var jamb=frame.get_child(i);jamb.position=Vector3(-.74 if i==0 else .74,1.27,0)
   jamb.get_child(0).transform=Transform3D.IDENTITY;jamb.get_child(0).mesh.size=Vector3(.12,2.54,.19)
 for i in landing_jambs.size():
  var jamb=landing_jambs[i];jamb.position=Vector3(-.985 if i%2==0 else .985,1.2925,.07)
  jamb.get_child(0).transform=Transform3D.IDENTITY;jamb.get_child(0).mesh.size=Vector3(.15,2.585,.18)

func doorway_clear()->bool:
 var p=cab.to_local(game.player.global_position)
 return absf(p.x)>1.65 or p.z>1.75 or p.z<.70 or absf(p.y)>2.0
