extends Node3D
## An optional shop doorway: visible full-height junk blocks entry.
var town
var hinge:Node3D
var leaf:StaticBody3D
var opened=false
var clutter_remarked=false
var props=[]
func _ready():
 name="SebusHardwareInterior"
 var brick=town.streetscape.brick("ranger")
 for row in [[Vector3(-4.9,3.1,0),Vector3(.2,6.2,8)],[Vector3(4.9,3.1,0),Vector3(.2,6.2,8)],[Vector3(0,3.1,-3.9),Vector3(10,6.2,.2)],[Vector3(-3,1.35,4),Vector3(4,2.7,.22)],[Vector3(3,1.35,4),Vector3(4,2.7,.22)],[Vector3(0,4.45,4),Vector3(10,3.5,.22)]]:town.box(self,row[0],row[1],brick)
 town.box(self,Vector3(0,-.035,0),Vector3(10,.12,8),town.mats.floor)
 town.box(self,Vector3(0,2.78,0),Vector3(9.8,.12,7.8),town.mats.wood)
 var paint=town.mats.wood.duplicate();paint.albedo_color=Color("626a59")
 hinge=Node3D.new();hinge.name="InwardDoorHinge";hinge.position=Vector3(-.92,0,4.12);add_child(hinge)
 leaf=town.box(hinge,Vector3(.92,1.3,0),Vector3(1.84,2.6,.1),paint)
 leaf.name="HardwareDoor"
 for y in [.55,1.65]:town.box(leaf,Vector3(0,y-1.3,.065),Vector3(1.45,.70,.035),town.mats.wood,false)
 town.box(leaf,Vector3(.65,-.05,.10),Vector3(.08,.28,.07),town.mats.metal,false)
 town.action_area(self,Vector3(0,1.3,4.24),Vector3(1.95,2.6,.34),"sebus_door",{"kind":"sebus_door","label":"Open Sebus Hardware door","door":self})
 # Packed crates, a wedged bookcase and scrap leave no body-width opening.
 for row in [[Vector3(.70,.02,2.62),Vector3(.65,.83,.45),.04],[Vector3(.70,.85,2.62),Vector3(.62,.72,.45),-.12],[Vector3(.70,1.57,2.62),Vector3(.62,.68,.45),.14],[Vector3(.65,2.25,2.62),Vector3(.65,.39,.45),-.10],[Vector3(1.9,.02,2.8),Vector3(1.0,.8,1.0),.18],[Vector3(-2.2,.02,1.8),Vector3(1.3,1.1,1.1),-.14],[Vector3(-2.0,1.12,1.8),Vector3(.9,.7,.9),.13],[Vector3(2.4,.02,-.7),Vector3(1.2,1.05,1.0),.2]]:
  prop("res://assets/interiors/box.glb",row[0],row[1],Vector3(0,row[2],0))
 prop("res://assets/apartment/bookcase.glb",Vector3(1.6,.02,2.35),Vector3(.75,2.45,.5),Vector3(0,-.10,-.12))
 prop("res://assets/apartment/bookcase.glb",Vector3(-3.4,.02,-2.6),Vector3(1.7,2.4,.6),Vector3(0,.15,.10))
 prop("res://assets/retro_props/locker.glb",Vector3(3.7,.02,-2.0),Vector3(.9,2.2,.75),Vector3(0,-.3,.06))
 prop("res://assets/apartment/chair.glb",Vector3(-.15,1.1,2.4),Vector3(.8,.85,.8),Vector3(.1,.4,1.1))
 prop("res://assets/retro_props/bucket.glb",Vector3(-1.5,.02,2.5),Vector3(.45,.5,.45),Vector3(.15,.1,.05))
 prop("res://assets/retro_props/bucket.glb",Vector3(1.7,.02,1.5),Vector3(.48,.55,.48),Vector3(0,.2,0))
 for i in 7:
  var board=town.box(self,Vector3(-.12+float(i)*.09,.45+float(i)*.23,2.75),Vector3(2.5,.12,.16),town.mats.wood,false)
  board.rotation=Vector3(.1,float(i)*.13,-.24+float(i)*.06)
 # Fill the visible gap beside the right jamb, outside the door's swept arc.
 for row in [["res://assets/interiors/box.glb",Vector3(1.22,.02,3.12),Vector3(.50,.65,.50),Vector3(0,.07,0)],["res://assets/interiors/box.glb",Vector3(1.22,.67,3.12),Vector3(.46,.60,.46),Vector3(0,-.12,0)],["res://assets/retro_props/bucket.glb",Vector3(1.20,1.27,3.12),Vector3(.37,.40,.37),Vector3.ZERO],["res://assets/retro_props/sheet_metal.glb",Vector3(1.63,.02,2.90),Vector3(.55,1.9,.08),Vector3(-.08,.12,-.08)]]:
  var extra=prop(row[0],row[1],row[2],row[3])
  extra.set_meta("runtime_visual_only",true)
 for i in 3:
  var scrap=town.box(self,Vector3(1.03+float(i)*.16,1.0,2.95),Vector3(.10,1.95,.11),town.mats.wood,false)
  scrap.rotation.z=-.025+float(i)*.025
  scrap.set_meta("runtime_visual_only",true)
 # The packed shop is scenery: seal its entire footprint, including the doorway.
 var pile=StaticBody3D.new();pile.name="PackedJunkCollision";add_child(pile)
 var collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(9.8,6.2,7.88)
 collision.shape=shape;collision.position=Vector3(0,3.1,0);pile.add_child(collision)
 var spill=OmniLight3D.new();spill.name="StreetLightSpill";spill.position=Vector3(0,2.15,3.3);spill.light_color=Color("c2b891");spill.light_energy=.5;spill.omni_range=4.5;add_child(spill)
 reset()
func prop(path:String,p:Vector3,size:Vector3,angles:Vector3):
 var holder=Node3D.new();add_child(holder)
 var model=load(path).instantiate();holder.add_child(model)
 var bounds=AABB();var first=true
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  var part=(holder.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
  bounds=part if first else bounds.merge(part);first=false
 model.position-=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
 holder.scale=Vector3(size.x/bounds.size.x,size.y/bounds.size.y,size.z/bounds.size.z)
 holder.position=p;holder.rotation=angles;props.append(holder)
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  for surface in mesh.mesh.get_surface_count():
   var mat=mesh.get_active_material(surface)
   if mat is StandardMaterial3D:
    mat=mat.duplicate();mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS;mat.roughness=1;mat.metallic=0;mat.metallic_specular=0
    mesh.set_surface_override_material(surface,mat)
 return holder
func ensure_blocked():
 var pile=get_node("PackedJunkCollision")
 pile.collision_layer=1
 var collision=pile.get_child(0)
 collision.position=Vector3(0,3.1,0)
 collision.shape.size=Vector3(9.8,6.2,7.88)
 collision.set_deferred("disabled",false)
func reset():
 ensure_blocked()
 opened=false;clutter_remarked=false;hinge.rotation.y=0;leaf.get_child(1).set_deferred("disabled",false)
func interact():
 if town.game.state!="play":return
 opened=not opened
 town.game.soundscape.door_move(global_position,opened)
func _process(delta):
 if town.game.state!="play":return
 hinge.rotation.y=move_toward(hinge.rotation.y,0.65 if opened else 0.0,delta*2.7)
 if opened and not clutter_remarked and is_equal_approx(hinge.rotation.y,0.65):
  clutter_remarked=true
  town.game.dialogue_name="You"
  town.game.dialogue_text="I can't get in, it's too cluttered."
  town.game.set_state("dialogue")
