extends RefCounted
## Split the shared ground around a real opening, preserving continuous world UVs.
const CENTER=Vector3(12.7,0,-15.45)
const HALF=Vector2(0.75,1.05)
static func build(parent:StaticBody3D,material:Material):
 var left=CENTER.x-HALF.x;var right=CENTER.x+HALF.x
 var back=CENTER.z-HALF.y;var front=CENTER.z+HALF.y
 var rectangles=[Rect2(-70,-115,left+70,180),Rect2(right,-115,70-right,180),Rect2(left,-115,right-left,back+115),Rect2(left,front,right-left,65-front)]
 var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for r in rectangles:
  var points=[Vector3(r.position.x,0,r.position.y),Vector3(r.end.x,0,r.position.y),Vector3(r.position.x,0,r.end.y),Vector3(r.end.x,0,r.end.y)]
  for i in [0,2,1,1,2,3]:
   tool.set_normal(Vector3.UP)
   tool.set_uv(Vector2((points[i].x+70)/140,(points[i].z+115)/180))
   tool.add_vertex(points[i])
  var shape=BoxShape3D.new();shape.size=Vector3(r.size.x,0.6,r.size.y)
  var collision=CollisionShape3D.new();collision.shape=shape
  collision.position=Vector3(r.get_center().x,-0.3,r.get_center().y)
  parent.add_child(collision)
 var mesh=MeshInstance3D.new();mesh.mesh=tool.commit();mesh.material_override=material.duplicate();mesh.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
 parent.add_child(mesh)
