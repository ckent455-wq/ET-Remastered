extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.enemies.set_physics_process(false)
 while not g.surface_details.completed or not g.hotel_upper.ready_layout:await process_frame
 var editor=load(g.hotel_upper_layout.PATH).instantiate();var furniture=editor.get_node("Furniture")
 g.hotel_upper_layout.apply_layout(editor);assert(g.hotel_upper_layout.applied_count==14)
 var entry=furniture.get_children().filter(func(n):return n.get_meta("runtime_scope")=="upper")[0]
 var actual=g.hotel_upper.get_child(entry.get_meta("runtime_index"));var original=actual.position
 entry.position.x+=.3;g.hotel_upper_layout.apply_layout(editor)
 assert(is_equal_approx(actual.position.x,original.x+.3));assert(is_equal_approx(actual.position.y,original.y))
 var shape=actual.find_children("*","CollisionShape3D",true,false)[0];assert(shape!=null)
 var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved))
 editor.free();print("PASS: 14 editable upper-floor furnishings map to gameplay, movement and colliders follow, save hierarchy retained");quit()
