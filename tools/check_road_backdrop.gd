extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 var forbidden=PackedVector2Array([Vector2(-5,-101),Vector2(5,-101),Vector2(5,-85),Vector2(-5,-85)])
 for ridge in g.distant_landscape.ridges:
  var faces=ridge.mesh.get_faces()
  for i in range(0,faces.size(),3):
   var tri=PackedVector2Array()
   for j in range(3):tri.append(Vector2(faces[i+j].x,faces[i+j].z))
   for polygon in Geometry2D.intersect_polygons(tri,forbidden):
    var area=0.0
    for k in range(polygon.size()):area+=polygon[k].cross(polygon[(k+1)%polygon.size()])
    assert(absf(area)<0.001,"Backdrop triangle intrudes into road")
 print("ROAD BACKDROP CHECK PASSED: no landscape triangles cross north Main Street")
 g.queue_free();await process_frame;quit()
