extends RefCounted
## Match the generated reference shell without replacing doors, pickups or saved nodes.
var targets=[]
var mapped=false
var count=0
func movable(node)->bool:
 if not node is Node3D or not node.is_visible_in_tree():return false
 return node.is_in_group("ApartmentKitFurniture") or node.is_in_group("RetroInteriorProps") or node.is_in_group("LocalInteriorProps") or node.name in ["clinic_cabinet","clinic_drawer"]
func bind(g):
 if mapped:return
 for node in g.town.buildings.clinic.get_children():
  if not node is Node3D or node is CharacterBody3D or movable(node):continue
  if node.position.y>=2.98:continue
  targets.append(node)
 mapped=true
func apply(g,scene):
 count=0
 var shell=scene.get_node_or_null("RoomShell_REFERENCE")
 if not shell:return
 if shell.get_child_count()!=targets.size():
  push_warning("Clinic reference structure changed; keeping gameplay architecture rather than guessing mappings.");return
 for i in range(targets.size()):
  var target=targets[i];var edited=shell.get_child(i)
  if target.get_class()!=edited.get_class():continue
  # Interaction and animated-door logic own their state and collision.
  if target is Area3D or target==g.town.doors.clinic.hinge or target.get_script()!=null:continue
  if target.find_children("*","Area3D",true,false).size()>0:continue
  copy_static(edited,target)
  target.transform=shell.transform*edited.transform
  count+=1
func copy_static(edited,actual):
 if edited is Node3D and actual is Node3D:
  actual.transform=edited.transform;actual.visible=edited.visible
 if edited is CollisionShape3D and actual is CollisionShape3D:
  if edited.shape:actual.shape=edited.shape.duplicate(true)
  actual.set_deferred("disabled",edited.disabled)
 if edited.get_child_count()!=actual.get_child_count():return
 for i in range(edited.get_child_count()):
  var source=edited.get_child(i);var target=actual.get_child(i)
  if source.get_class()==target.get_class():copy_static(source,target)
