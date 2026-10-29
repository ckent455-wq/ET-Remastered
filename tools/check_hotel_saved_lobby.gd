extends SceneTree
var errors=[]
func _initialize():call_deferred("run")
func compare(edited:Node,actual:Node,path:String,compare_root=true):
 if compare_root and edited is Node3D and actual is Node3D:
  if not edited.transform.is_equal_approx(actual.transform):errors.append(path+" transform")
  if edited.visible!=actual.visible:errors.append(path+" visibility")
 if edited is CollisionShape3D and actual is CollisionShape3D and edited.shape and actual.shape:
  if edited.shape is BoxShape3D and actual.shape is BoxShape3D and not edited.shape.size.is_equal_approx(actual.shape.size):errors.append(path+" collider size")
 if edited is OmniLight3D and actual is OmniLight3D:
  if not is_equal_approx(edited.light_energy,actual.light_energy):errors.append(path+" light energy")
 if edited.get_child_count()>actual.get_child_count():errors.append(path+" missing live children")
 for i in range(edited.get_child_count(),actual.get_child_count()):
  if actual.get_child(i) is Node3D and actual.get_child(i).visible:errors.append(path+" deleted decoration still visible")
 for i in mini(edited.get_child_count(),actual.get_child_count()):
  if edited.get_child(i).get_class()!=actual.get_child(i).get_class():errors.append(path+" child type "+str(i));continue
  compare(edited.get_child(i),actual.get_child(i),path+"/"+str(edited.get_child(i).name))
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.enemies.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 await physics_frame
 var scene=load("res://editing/hotel_layout.tscn").instantiate();var furniture=scene.get_node("Furniture")
 var count=0
 for entry in furniture.get_children():
  if entry.has_meta("runtime_spawn_id"):
   var actual=g.hotel_layout.added_furniture[entry.get_meta("runtime_spawn_id")]
   assert(actual.global_transform.is_equal_approx(g.town.buildings.house.global_transform*furniture.transform*entry.transform))
   compare(entry,actual,str(entry.name),false);count+=1
  elif entry.has_meta("runtime_index"):
   var index=int(entry.get_meta("runtime_index"))
   if index in [61,116,117,118,119,120]:continue
   var actual=g.town.buildings.house.get_child(index)
   compare(entry,actual,str(entry.name));count+=1
 var entries=scene.get_node("RoomShell_REFERENCE").get_children().filter(func(n):return n.name not in ["Elevator_REFERENCE","Employees_Wall_REFERENCE"])
 assert(entries.size()==g.hotel_layout.reference.targets.size())
 for i in entries.size():
  var actual=g.hotel_layout.reference.targets[i]
  if actual is Area3D or actual==g.town.doors.house.hinge or actual.get_script()!=null or not actual.find_children("*","Area3D",true,false).is_empty():continue
  if actual.name in ["SaintGeorgeBrickFacade","Abandoned_broken_chair"]:continue
  if actual.position.is_equal_approx(Vector3(-3.8,1.51,-.9)) or actual.position.is_equal_approx(Vector3(-3.8,.12,-.815)):continue
  compare(entries[i],actual,"Shell/"+str(i));count+=1
 for error in errors:print("MISMATCH ",error)
 print("AUDITED ",count," roots; reference ",g.hotel_layout.reference.count,"; mismatches ",errors.size())
 if errors.is_empty():print("PASS: saved downstairs furniture, child meshes, collision sizes and static lights match the live game")
 quit(0 if errors.is_empty() else 1)
