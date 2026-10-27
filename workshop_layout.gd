extends Node
## The editor scene stores transforms; gameplay keeps its original furniture and save hierarchy.
var game
var applied_count=0
var added_furniture={}
const PATH="res://editing/workshop_layout.tscn"
func _ready():call_deferred("apply_when_ready")
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
  var workshop=game.town.buildings.workshop
  for entry in furniture.get_children():
   if not entry is Node3D:continue
   if entry.has_meta("runtime_spawn_id"):
    var id=str(entry.get_meta("runtime_spawn_id"))
    if not added_furniture.has(id) or not is_instance_valid(added_furniture[id]):
     var added=entry.duplicate(0);added.name="WorkshopExtra_"+id;game.add_child(added);added_furniture[id]=added
    added_furniture[id].global_transform=workshop.global_transform*furniture.transform*entry.transform
    applied_count+=1
    continue
   if not entry.has_meta("runtime_index"):continue
   var index=int(entry.get_meta("runtime_index"))
   if index<0 or index>=workshop.get_child_count():continue
   var target=workshop.get_child(index)
   if not target is Node3D:continue
   var asset=str(target.get_meta("apartment_asset",target.get_meta("retro_asset",target.name)))
   if asset!=str(entry.get_meta("runtime_asset")):push_warning("Workshop layout no longer matches "+entry.name);continue
   target.transform=furniture.transform*entry.transform
   applied_count+=1
 if own:scene.free()
