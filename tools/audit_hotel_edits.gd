extends SceneTree
func _initialize():call_deferred("run")
func compare(a:Node,b:Node,path:String,offset=false):
 if a is Node3D and b is Node3D:
  var expected=a.transform
  if offset:expected.origin.y+=3.8
  if not expected.is_equal_approx(b.transform):print("DIFF ",path," editor=",expected," live=",b.transform)
 if a.get_child_count()!=b.get_child_count():print("CHILDREN ",path," ",a.get_child_count()," vs ",b.get_child_count());return
 for i in a.get_child_count():compare(a.get_child(i),b.get_child(i),path+"/"+str(a.get_child(i).name))
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.enemies.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 var scene=load(g.hotel_upper_layout.PATH).instantiate();print("APPLIED ",g.hotel_upper_layout.applied_count)
 for entry in scene.get_node("Furniture").get_children():
  var scope=entry.get_meta("runtime_scope","");var index=entry.get_meta("runtime_index",-1);var parent=g.town.buildings.house if scope=="hotel" else g.hotel_upper
  print("ENTRY ",entry.name," ",scope," ",index," ",entry.get_meta("runtime_name","") )
  if index>=0 and index<parent.get_child_count():compare(entry,parent.get_child(index),str(entry.name),true)
 var originals=[]
 for n in g.hotel_upper.get_children():
  if not n is Node3D or not n.visible or n.has_meta("upper_furniture") or n is AudioStreamPlayer3D or n==g.hotel_upper.cab or n.position.y>=7:continue
  var bounds=g.surface_details.bounds_of(n)
  if bounds.end.y<3.65:continue
  originals.append(n)
 var shell=scene.get_node("BuildingShell_REFERENCE");print("SHELL ",shell.get_child_count()," vs ",originals.size())
 for i in mini(shell.get_child_count(),originals.size()):compare(shell.get_child(i),originals[i],"SHELL/"+str(i)+"/"+str(shell.get_child(i).name),true)
 quit()
