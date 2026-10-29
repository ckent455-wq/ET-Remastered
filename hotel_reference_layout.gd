extends RefCounted
## Preserve the original hotel nodes while applying the editor's static room details.
var targets=[]
var bound=false
var count=0
var copy=preload("res://ranger_reference_layout.gd").new()
func furniture(n)->bool:
 return n.is_in_group("ApartmentKitFurniture") or n.is_in_group("RetroInteriorProps") or n.is_in_group("LocalInteriorProps") or n.name in ["house_cabinet","house_drawer"]
func bind(g):
 if bound:return
 for n in g.town.buildings.house.get_children():
  if not n is Node3D or n is CharacterBody3D:continue
  if n.is_visible_in_tree() and furniture(n):continue
  if n.position.y>=2.98:continue
  targets.append(n)
 bound=true
func apply(g,scene):
 var shell=scene.get_node_or_null("RoomShell_REFERENCE");count=0
 if not shell:return
 var entries=shell.get_children().filter(func(n):return n.name not in ["Elevator_REFERENCE","Employees_Wall_REFERENCE"])
 if entries.size()!=targets.size():push_warning("Hotel reference map differs: "+str(entries.size())+" editor nodes / "+str(targets.size())+" live nodes");return
 for i in targets.size():
  var actual=targets[i];var edited=entries[i]
  if actual.get_class()!=edited.get_class():continue
  if actual is Area3D or actual==g.town.doors.house.hinge or actual.get_script()!=null or not actual.find_children("*","Area3D",true,false).is_empty():continue
  # The editor cutaway and retired bedroom are deliberately different from gameplay.
  if actual.name in ["SaintGeorgeBrickFacade","Abandoned_broken_chair"]:continue
  if actual.position.is_equal_approx(Vector3(-3.8,1.51,-.9)) or actual.position.is_equal_approx(Vector3(-3.8,.12,-.815)):continue
  static_details(edited,actual)
  actual.transform=shell.transform*edited.transform;count+=1
func static_details(edited:Node,actual:Node):
 if edited is Node3D and actual is Node3D:actual.transform=edited.transform;actual.visible=edited.visible
 if edited is MeshInstance3D and actual is MeshInstance3D:
  actual.mesh=edited.mesh;actual.material_override=edited.material_override
  if edited.mesh:
   for surface in edited.mesh.get_surface_count():actual.set_surface_override_material(surface,edited.get_surface_override_material(surface))
 if edited is CollisionShape3D and actual is CollisionShape3D:
  if edited.shape:actual.shape=edited.shape.duplicate(true)
  actual.set_deferred("disabled",edited.disabled)
 if edited is OmniLight3D and actual is OmniLight3D:
  for property in ["light_color","light_energy","omni_range","omni_attenuation","shadow_enabled"]:actual.set(property,edited.get(property))
 # Deleted static decorations must not survive solely in the running game.
 for i in mini(edited.get_child_count(),actual.get_child_count()):
  if edited.get_child(i).get_class()==actual.get_child(i).get_class():static_details(edited.get_child(i),actual.get_child(i))

 # Retain node indices for saved games, but hide static children deleted in the editor.
 for i in range(edited.get_child_count(),actual.get_child_count()):
  var extra=actual.get_child(i)
  if extra is Node3D:extra.hide()
  disable_deleted(extra)
func disable_deleted(n:Node):
 if n is CollisionObject3D:n.collision_layer=0
 if n is CollisionShape3D:n.set_deferred("disabled",true)
 for child in n.get_children():disable_deleted(child)
