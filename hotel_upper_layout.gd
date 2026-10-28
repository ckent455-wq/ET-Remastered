extends Node
## Saved editor transforms for the hotel's guest-room furniture and pickups.
const PATH="res://editing/hotel_second_floor_layout.tscn"
const ORIGINALS=["house_drawer","Apartment_bed7","Apartment_wardrobe8","Apartment_dresser9","books74","Apartment_rug10"]
var game
var applied_count=0
var shell_targets=[]
var shell_bound=false
var reference=preload("res://ranger_reference_layout.gd").new()
func apply_layout(scene:Node=null):
 if not game.hotel_upper or not ResourceLoader.exists(PATH):return
 var own=scene==null
 if own:scene=load(PATH).instantiate()
 var furniture=scene.get_node_or_null("Furniture")
 if not furniture:
  if own:scene.free()
  return
 var included={};applied_count=0
 for entry in furniture.get_children():
  if not entry is Node3D or not entry.has_meta("runtime_scope"):continue
  var scope=str(entry.get_meta("runtime_scope"));var index=int(entry.get_meta("runtime_index",-1))
  var parent=game.town.buildings.house if scope=="hotel" else game.hotel_upper
  if index<0 or index>=parent.get_child_count():continue
  var target=parent.get_child(index)
  if str(target.name)!=str(entry.get_meta("runtime_name")):continue
  included[str(scope)+str(index)]=true
  if target.find_children("*","Area3D",true,false).is_empty():reference.copy_static(entry,target)
  target.transform=furniture.transform*entry.transform;target.position.y+=game.hotel_upper.UPPER
  applied_count+=1
 for scope in ["hotel","upper"]:
  var parent=game.town.buildings.house if scope=="hotel" else game.hotel_upper
  for target in parent.get_children():
   if not target is Node3D:continue
   var editable=target.name in ORIGINALS if scope=="hotel" else target.has_meta("upper_furniture")
   if editable and not included.has(scope+str(target.get_index())):target.hide();game.hotel_layout.disable_removed(target)
 var pickups=scene.get_node_or_null("Pickups")
 if pickups:
  for entry in pickups.get_children():
   var id=str(entry.get_meta("action_id",""))
   if not game.town.actions.has(id):continue
   var area=game.town.actions[id].area
   game.hotel_layout.copy_letter_geometry(entry,area)
   area.transform=pickups.transform*entry.transform;area.position.y+=game.hotel_upper.UPPER
 apply_shell(scene)
 if own:scene.free()

func bind_shell():
 if shell_bound:return
 var upper=game.hotel_upper
 for n in upper.get_children():
  if not n is Node3D or not n.visible or n.has_meta("upper_furniture") or n is AudioStreamPlayer3D or n==upper.cab or n.position.y>=7:continue
  var bounds=game.surface_details.bounds_of(n)
  if bounds.end.y<upper.UPPER-.15:continue
  shell_targets.append(n)
 shell_bound=true
func apply_shell(scene:Node):
 bind_shell()
 var shell=scene.get_node_or_null("BuildingShell_REFERENCE")
 if not shell:return
 if shell.get_child_count()!=shell_targets.size():
  push_warning("Hotel upper reference structure changed; retaining its existing architecture.");return
 for i in shell_targets.size():
  var actual=shell_targets[i];var edited=shell.get_child(i)
  if actual.get_class()!=edited.get_class():continue
  # Live lift/room-door state owns its moving parts and interaction Areas.
  if actual is Area3D or actual.get_script()!=null or not actual.find_children("*","Area3D",true,false).is_empty():continue
  copy_reference(edited,actual)
  actual.transform=shell.transform*edited.transform;actual.position.y+=game.hotel_upper.UPPER
func copy_reference(edited:Node,actual:Node):
 if edited is Node3D and actual is Node3D:actual.transform=edited.transform;actual.visible=edited.visible
 if edited is MeshInstance3D and actual is MeshInstance3D:
  if not actual.get_parent().get_meta("generated_joinery",false):actual.mesh=edited.mesh
  actual.material_override=edited.material_override
  for surface in edited.mesh.get_surface_count():actual.set_surface_override_material(surface,edited.get_surface_override_material(surface))
 if edited is CollisionShape3D and actual is CollisionShape3D:
  if edited.shape:actual.shape=edited.shape.duplicate(true)
  actual.set_deferred("disabled",edited.disabled)
 if edited is OmniLight3D and actual is OmniLight3D:
  for property in ["light_color","light_energy","omni_range","omni_attenuation","shadow_enabled"]:actual.set(property,edited.get(property))
 if edited.get_child_count()!=actual.get_child_count():return
 for i in edited.get_child_count():
  if edited.get_child(i).get_class()==actual.get_child(i).get_class():copy_reference(edited.get_child(i),actual.get_child(i))
