extends Node
## The editor scene stores transforms; gameplay keeps its original furniture and save hierarchy.
var game
var applied_count=0
var added_furniture={}
var reference=preload("res://hotel_reference_layout.gd").new()
const PATH="res://editing/hotel_layout.tscn"
func _ready():
 reference.bind(game)
 call_deferred("apply_when_ready")
func apply_when_ready():
 while not game.surface_details.completed:await get_tree().process_frame
 apply_layout()
func apply_layout(scene:Node=null):
 applied_count=0
 var own=scene==null
 if own:
  if not ResourceLoader.exists(PATH):return
  scene=load(PATH).instantiate()
 var furniture=scene.get_node_or_null("Furniture")
 if furniture:
  var hotel=game.town.buildings.house
  var included={}
  for entry in furniture.get_children():
   if entry.has_meta("runtime_index"):included[int(entry.get_meta("runtime_index"))]=true
  for target in hotel.get_children():
   if not target is Node3D:continue
   var editable=target.is_in_group("ApartmentKitFurniture") or target.is_in_group("RetroInteriorProps") or target.is_in_group("LocalInteriorProps") or target.name in ["house_cabinet","house_drawer"]
   if editable and not included.has(target.get_index()):
    target.hide();disable_removed(target)
  for entry in furniture.get_children():
   if not entry is Node3D:continue
   if entry.has_meta("runtime_spawn_id"):
    var id=str(entry.get_meta("runtime_spawn_id"))
    if not added_furniture.has(id) or not is_instance_valid(added_furniture[id]):
     var added=entry.duplicate(0);added.name="HotelExtra_"+id;game.add_child(added);added_furniture[id]=added
    reference.static_details(entry,added_furniture[id])
    added_furniture[id].global_transform=hotel.global_transform*furniture.transform*entry.transform
    applied_count+=1
    continue
   if not entry.has_meta("runtime_index"):continue
   var index=int(entry.get_meta("runtime_index"))
   if index<0 or index>=hotel.get_child_count():continue
   var target=hotel.get_child(index)
   if not target is Node3D:continue
   var asset=str(target.get_meta("apartment_asset",target.get_meta("retro_asset",target.name)))
   if asset!=str(entry.get_meta("runtime_asset")):push_warning("Hotel layout no longer matches "+entry.name);continue
   if target.find_children("*","Area3D",true,false).is_empty():reference.static_details(entry,target)
   target.transform=furniture.transform*entry.transform
   applied_count+=1
 var obsolete_chair=game.town.buildings.house.get_node_or_null("Abandoned_broken_chair")
 if obsolete_chair:obsolete_chair.hide();disable_removed(obsolete_chair)
 apply_pickups(scene)
 if game.hotel_upper:game.hotel_upper.apply_layout()
 reference.apply(game,scene)
 if game.hotel_staff:game.hotel_staff.restore_joinery()
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
  if not game.town.actions.has(id):continue
  var action=game.town.actions[id]
  if not action.kind in ["item","weapon","ammo","note","cellar_part"]:continue
  var actual=action.area
  copy_letter_geometry(edited,actual)
  actual.transform=shell.transform*edited.transform
func copy_letter_geometry(edited:Node,actual:Node):
 # Keep the real action node, collection state and save hierarchy intact.
 if edited is Node3D and actual is Node3D:actual.transform=edited.transform
 if edited is CollisionShape3D and actual is CollisionShape3D and edited.shape:
  actual.shape=edited.shape.duplicate(true)
 for i in range(mini(edited.get_child_count(),actual.get_child_count())):
  var source=edited.get_child(i);var target=actual.get_child(i)
  if source.get_class()==target.get_class():copy_letter_geometry(source,target)
