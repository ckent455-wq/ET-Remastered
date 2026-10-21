extends RefCounted
## A real jagged wall aperture, short earthen burrow and visible collapsed end.
static func build(house,cellar:Node3D,stone:Material):
 var town=house.town
 var root=Node3D.new();root.name="BreachedCellarBurrow";cellar.add_child(root)
 root.set_meta("player_accessible",false)
 var soil=town.mats.floor.duplicate();soil.albedo_texture=preload("res://assets/forest/ground_ps2.png");soil.albedo_color=Color("554b39")
 var dark=town.color_material(Color("11130f"))
 var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 var rim=[];var outer=[]
 var center=Vector2(0,0.72)
 var angles=[]
 for i in range(16):angles.append(TAU*i/16)
 # Include exact rectangle corners; radial samples alone cut off triangular wedges.
 for corner in [Vector2(-3.7,0),Vector2(3.7,0),Vector2(-3.7,3),Vector2(3.7,3)]:
  angles.append(fposmod((corner-center).angle(),TAU))
 angles.sort()
 var count=angles.size()
 for i in range(count):
  var angle=angles[i]
  var direction=Vector2(cos(angle),sin(angle))
  var radius=1.0+0.085*sin(i*7.3)
  rim.append(center+direction*Vector2(1.02,0.68)*radius)
  var extent=minf(3.7/maxf(absf(direction.x),0.0001),(3.0-center.y if direction.y>=0 else center.y)/maxf(absf(direction.y),0.0001))
  outer.append(center+direction*extent)
 for i in range(count):
  var j=(i+1)%count
  for z in [-4.1,-4.3]:
   for p in [outer[i],rim[i],outer[j],outer[j],rim[i],rim[j]]:
    tool.set_uv(Vector2(0.5-p.x/3.55,1.0-p.y/3.0));tool.add_vertex(Vector3(p.x,p.y,z))
  for p in [Vector3(rim[i].x,rim[i].y,-4.1),Vector3(rim[j].x,rim[j].y,-4.1),Vector3(rim[i].x,rim[i].y,-4.3),Vector3(rim[j].x,rim[j].y,-4.1),Vector3(rim[j].x,rim[j].y,-4.3),Vector3(rim[i].x,rim[i].y,-4.3)]:
   tool.set_uv(Vector2(0.5-p.x/3.55,1.0-p.y/3.0));tool.add_vertex(p)
 tool.generate_normals()
 var material=stone.duplicate();material.cull_mode=BaseMaterial3D.CULL_DISABLED
 var wall=MeshInstance3D.new();wall.name="JaggedFoundationOpening";wall.mesh=tool.commit();wall.material_override=material;root.add_child(wall)
 var body=StaticBody3D.new();body.name="BrokenFoundationCollision";root.add_child(body)
 var shape=ConcavePolygonShape3D.new();shape.set_faces(wall.mesh.get_faces());shape.backface_collision=true
 var collision=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
 # Irregular earthen tube extends beyond the foundation, never a flat black decal.
 var tube=SurfaceTool.new();tube.begin(Mesh.PRIMITIVE_TRIANGLES)
 for depth in range(3):
  for i in range(count):
   var j=(i+1)%count
   var points=[]
   for pair in [Vector2i(i,depth),Vector2i(j,depth),Vector2i(i,depth+1),Vector2i(j,depth+1)]:
    var p:Vector2=center+(rim[pair.x]-center)*(1.0-0.10*pair.y)
    points.append(Vector3(p.x+0.08*pair.y,p.y,-4.3-0.5*pair.y))
   for index in [0,1,2,1,3,2]:tube.set_uv(Vector2(points[index].x,points[index].z));tube.add_vertex(points[index])
 tube.generate_normals()
 var earth=MeshInstance3D.new();earth.name="DugEarthTunnel";earth.mesh=tube.commit()
 var earth_material=soil.duplicate();earth_material.cull_mode=BaseMaterial3D.CULL_DISABLED;earth.material_override=earth_material;root.add_child(earth)
 town.box(root,Vector3(0.2,0.7,-5.86),Vector3(1.8,1.4,0.08),dark,false)
 # The fallen dirt/stone plug is visible and solid, sealing the short burrow.
 var plug=town.box(root,Vector3(0.12,0.48,-4.85),Vector3(1.8,0.96,0.65),soil)
 plug.name="CollapsedBurrowBlocker";plug.set_meta("footstep_surface","dirt");plug.get_child(0).hide()
 for i in range(9):
  var fallen=load("res://assets/forest/rock_%d.glb" % (i%3)).instantiate();root.add_child(fallen)
  fallen.position=Vector3(-0.58+(i%3)*0.57,0.13+(i/3)*0.26,-4.55-0.12*sin(i*1.8))
  fallen.scale=Vector3(0.24,0.22,0.25);fallen.rotation=Vector3(0.2*sin(i),i*1.7,0.18*cos(i))
 for i in range(16):
  var rock=load("res://assets/forest/rock_%d.glb" % (i%3)).instantiate();root.add_child(rock)
  var near=i<10
  rock.position=Vector3(sin(i*2.4)*(0.95 if near else 0.72),0.06 if near else 0.45+(i%3)*0.19,-3.85+cos(i*1.7)*0.48 if near else -4.52)
  rock.scale=Vector3(0.22+(i%3)*0.06,0.15+(i%2)*0.06,0.20+(i%4)*0.04)
  rock.rotation=Vector3(0.12*i,i*1.9,0.14*sin(i))
 # Earth fans into the room; narrow gouges lead away from the breach.
 for i in range(7):
  var smear=house.game.mesh_at(root,house.game.cylinder(0.21+0.03*(i%3),0.24,0.008,7),Vector3(sin(i*2.6)*0.65,0.009,-3.8+i*0.25),soil)
  smear.scale.z=1.35
  smear.rotation.y=i*0.7
 for i in range(4):
  var scratch=town.box(root,Vector3(-0.48+i*0.15,0.016,-3.48),Vector3(0.025,0.008,0.72-i*0.06),dark,false)
  scratch.rotation.y=-0.14+i*0.06
 # A strip of burial cloth caught on the broken masonry links this breach to the dead.
 var cloth=town.mats.fabric.duplicate();cloth.albedo_color=Color("8a8269")
 var rag=town.box(root,Vector3(-0.83,0.57,-4.02),Vector3(0.17,0.40,0.018),cloth,false)
 rag.rotation.z=-0.35
 return root
