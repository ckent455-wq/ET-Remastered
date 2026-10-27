extends SceneTree
func _initialize():call_deferred("run")
func owner_all(node,owner):
 node.owner=owner
 for child in node.get_children():owner_all(child,owner)
func run():
 var path="res://editing/workshop_layout.tscn"
 var scene=load(path).instantiate();root.add_child(scene)
 var furniture=scene.get_node("Furniture")
 if furniture.has_node("New_Table_Position_Me"):print("Table already added; keeping its position.");scene.free();quit();return
 var source=furniture.get_node("Table_03")
 var table=StaticBody3D.new();table.name="New_Table_Position_Me"
 furniture.add_child(table)
 table.transform=source.transform
 table.scale.x*=0.60
 table.position=Vector3(1.8,0.04,0.8)
 table.rotation.y=0
 table.set_meta("runtime_spawn_id","extra_table_01")
 table.set_meta("_edit_group_",true)
 table.set_meta("editor_description","New solid table. Move this root, save, and restart the game to use its placement.")
 var visual=source.duplicate(0);visual.name="TableModel";visual.transform=Transform3D.IDENTITY
 for key in visual.get_meta_list():visual.remove_meta(key)
 table.add_child(visual)
 var box=AABB();var first=true
 for mesh in visual.find_children("*","MeshInstance3D",true,false):
  var b=(table.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
  box=b if first else box.merge(b);first=false
 var collision=CollisionShape3D.new();collision.name="TableCollision";collision.shape=BoxShape3D.new();collision.shape.size=box.size;collision.position=box.get_center();table.add_child(collision)
 owner_all(table,scene)
 var packed=PackedScene.new();assert(packed.pack(scene)==OK);assert(ResourceSaver.save(packed,path)==OK)
 print("PASS: new table added with collision and an independent runtime furniture id")
 scene.free();quit()
