extends Node
## The editor scene stores transforms; gameplay keeps its original furniture and save hierarchy.
var game
var reference=preload("res://ranger_reference_layout.gd").new()
var applied_count=0
var added_furniture={}
var lockbox_body_rest=Transform3D.IDENTITY
var lockbox_bound=false
const PATH="res://editing/ranger_layout.tscn"
func _ready():call_deferred("apply_when_ready")
func apply_when_ready():
 while not game.surface_details.completed:await get_tree().process_frame
 apply_layout()
func apply_layout(scene:Node=null):
 reference.bind(game)
 applied_count=0
 var own=scene==null
 if own:
  if not ResourceLoader.exists(PATH):return
  scene=load(PATH).instantiate()
 var furniture=scene.get_node_or_null("Furniture")
 if furniture:
  var ranger=game.town.buildings.ranger
  var included={}
  for entry in furniture.get_children():
   if entry.has_meta("runtime_index"):included[int(entry.get_meta("runtime_index"))]=true
  for target in ranger.get_children():
   if not target is Node3D:continue
   var editable=target.is_in_group("ApartmentKitFurniture") or target.is_in_group("RetroInteriorProps") or target.is_in_group("LocalInteriorProps") or target.name in ["ranger_cabinet","ranger_drawer"]
   if editable and not included.has(target.get_index()):
    target.hide();disable_removed(target)
  for entry in furniture.get_children():
   if not entry is Node3D:continue
   if entry.has_meta("runtime_spawn_id"):
    var id=str(entry.get_meta("runtime_spawn_id"))
    if not added_furniture.has(id) or not is_instance_valid(added_furniture[id]):
     var added=entry.duplicate(0);added.name="RangerExtra_"+id;game.add_child(added);added_furniture[id]=added
    added_furniture[id].global_transform=ranger.global_transform*furniture.transform*entry.transform
    applied_count+=1
    continue
   if not entry.has_meta("runtime_index"):continue
   var index=int(entry.get_meta("runtime_index"))
   if index<0 or index>=ranger.get_child_count():continue
   var target=ranger.get_child(index)
   if not target is Node3D:continue
   var asset=str(target.get_meta("apartment_asset",target.get_meta("retro_asset",target.name)))
   if asset!=str(entry.get_meta("runtime_asset")):push_warning("Ranger layout no longer matches "+entry.name);continue
   if target.get_script()==null and target.find_children("*","Area3D",true,false).is_empty():reference.copy_static(entry,target)
   target.transform=furniture.transform*entry.transform
   applied_count+=1
 reference.apply(game,scene)
 apply_pickups(scene)
 apply_lockbox(scene)
 if own:scene.free()
func disable_removed(node:Node):
 if node is CollisionObject3D:node.collision_layer=0
 if node is CollisionShape3D:node.set_deferred("disabled",true)
 for child in node.get_children():disable_removed(child)

func apply_pickups(scene:Node):
 var shell=scene.get_node_or_null("RoomShell_REFERENCE")
 if not shell:return
 for edited in shell.get_children():
  if not edited is Area3D or not edited.has_meta("action_id"):continue
  var id=str(edited.get_meta("action_id"))
  if id=="weapon_shotgun":continue
  if not game.town.actions.has(id):continue
  var action=game.town.actions[id]
  if not action.kind in ["item","weapon","ammo","note","cellar_part"]:continue
  var actual=action.area
  copy_letter_geometry(edited,actual)
  actual.transform=shell.transform*edited.transform
func apply_lockbox(scene:Node):
 var shell=scene.get_node_or_null("RoomShell_REFERENCE")
 if not shell:return
 var edited=shell.get_node_or_null("RangerShotgunLockbox")
 if not edited:return
 var box=game.weapons.lockbox
 var original_mesh=box.get_node("body").find_children("*","MeshInstance3D",true,false)[0]
 var edited_mesh=edited.get_node("body").find_children("*","MeshInstance3D",true,false)[0]
 if not lockbox_bound:
  lockbox_body_rest=box.global_transform.affine_inverse()*original_mesh.global_transform
  lockbox_bound=true
 # The editor permits selecting a crate mesh rather than its scripted root.
 # Lift that offset to the whole working case, retaining the live lid/lock state.
 var relative=edited.transform.affine_inverse()*relative_transform(edited_mesh,shell)
 var offset=relative*lockbox_body_rest.affine_inverse()
 box.transform=shell.transform*edited.transform*offset
 var gun=shell.get_node_or_null("weapon_shotgun")
 if gun:
  copy_letter_geometry(gun,box.pickup)
  box.pickup.transform=box.transform*edited.transform.affine_inverse()*gun.transform
 box.sync_pickup()
func relative_transform(node:Node3D,ancestor:Node3D)->Transform3D:
 var result=node.transform
 var parent=node.get_parent()
 while parent!=ancestor:
  result=parent.transform*result;parent=parent.get_parent()
 return result
func copy_letter_geometry(edited:Node,actual:Node):
 # Keep the real action node, collection state and save hierarchy intact.
 if edited is Node3D and actual is Node3D:actual.transform=edited.transform
 if edited is CollisionShape3D and actual is CollisionShape3D and edited.shape:
  actual.shape=edited.shape.duplicate(true)
 for i in range(mini(edited.get_child_count(),actual.get_child_count())):
  var source=edited.get_child(i);var target=actual.get_child(i)
  if source.get_class()==target.get_class():copy_letter_geometry(source,target)
