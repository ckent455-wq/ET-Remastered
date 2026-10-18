extends Node3D
## A roadside burial ground with a clear, ungated walking route to the maintenance box.
var town
var crypt: Node3D
var door_hinge: Node3D
var door_collision: CollisionShape3D
var unlocked = false
var opened = false
var door_tween: Tween
const CENTER = Vector3(15,0,-14)

func _ready():
	name = "OldMillCemetery"
	var stone = town.mats.plaster.duplicate()
	stone.albedo_color = Color("73796e")
	var dark_stone = stone.duplicate()
	dark_stone.albedo_color = Color("454e47")
	var iron = town.color_material(Color("353937"))
	# Low masonry with close-spaced wrought iron and an open, legible entrance.
	wall(Vector3(7,0,-19),Vector3(0.42,0.38,10),stone,iron)
	wall(Vector3(7,0,-8),Vector3(0.42,0.38,4),stone,iron)
	wall(Vector3(23,0,-15),Vector3(0.42,0.38,18),stone,iron)
	wall(Vector3(15,0,-24),Vector3(16,0.38,0.42),stone,iron)
	wall(Vector3(15,0,-6),Vector3(16,0.38,0.42),stone,iron)
	for z in [-14,-10]:
		town.box(self,Vector3(7,0.95,z),Vector3(0.65,1.9,0.65),dark_stone)
		town.box(self,Vector3(7,1.94,z),Vector3(0.85,0.16,0.85),stone,false)
		var cap = town.game.mesh_at(self,town.game.cylinder(0.27,0,0.35,4),Vector3(7,2.18,z),stone)
		cap.rotation.y=PI/4
	# Open gate leaves sit along the inside fence, never across the walking route.
	for z in [-15.0,-9.0]:
		for i in range(7):
			town.box(self,Vector3(7.3,0.95,z-0.7+i*0.23),Vector3(0.045,1.2,0.045),iron,false)
		for y in [0.45,1.35]: town.box(self,Vector3(7.3,y,z),Vector3(0.06,0.07,1.65),iron,false)
	var sign = town.sign_text(self,"OLD MILL\nBURIAL GROUND\nEST. 1847",Vector3(6.65,1.1,-9.9),20,Color("b3ae98"))
	sign.rotation.y=-PI/2
	sign.pixel_size=0.003
	# Uneven stepping stones replace the rectangular gravel cross.
	for i in range(23):
		var t=i/22.0
		var x=2.2+t*19.0
		var z=-12.0-sin(t*PI)*0.6
		var slab=town.game.mesh_at(self,town.game.cylinder(0.32,0.36,0.035,7),Vector3(x,0.018,z),dark_stone)
		slab.scale=Vector3(1.0,1,1.3)
		slab.rotation.y=i*1.71
	# Loose family groups, with varied spacing and silhouettes; keep the central walk clear.
	var plots = [Vector3(9.4,0,-8.1),Vector3(10.7,0,-7.7),Vector3(13.0,0,-8.2),Vector3(16.0,0,-7.7),Vector3(17.4,0,-8.1),Vector3(20.1,0,-7.8),Vector3(21.7,0,-8.6),Vector3(9.2,0,-16.7),Vector3(10.6,0,-17.4),Vector3(12.7,0,-16.6),Vector3(16.6,0,-16.2),Vector3(18.2,0,-17.1),Vector3(21.2,0,-16.5),Vector3(9.7,0,-21.6),Vector3(11.2,0,-21.9),Vector3(14.0,0,-21.4),Vector3(16.4,0,-21.9)]
	for i in range(plots.size()): headstone(plots[i],i,stone,dark_stone)
	# Hollow, walkable mausoleum with a keyed iron door.
	crypt = Node3D.new()
	add_child(crypt)
	crypt.position=Vector3(20,0,-21.5)
	town.box(crypt,Vector3(0,0.015,0),Vector3(4.0,0.03,4.0),dark_stone)
	for x in [-1.85,1.85]: town.box(crypt,Vector3(x,1.4,0),Vector3(0.3,2.8,4),stone)
	town.box(crypt,Vector3(0,1.4,-1.85),Vector3(4,2.8,0.3),stone)
	for x in [-1.3,1.3]: town.box(crypt,Vector3(x,1.4,1.85),Vector3(1.2,2.8,0.3),stone)
	town.box(crypt,Vector3(0,2.65,1.85),Vector3(1.4,0.3,0.3),stone)
	for x in [-0.83,0.83]: town.box(crypt,Vector3(x,1.2,2.02),Vector3(0.22,2.4,0.2),dark_stone,false)
	town.box(crypt,Vector3(0,2.87,0),Vector3(4.3,0.2,4.3),dark_stone)
	var roof=town.game.mesh_at(crypt,town.game.cylinder(1,0,0.75,4),Vector3(0,3.33,0),stone)
	roof.scale=Vector3(3.0,1,3.0)
	roof.rotation.y=PI/4
	var inscription=town.sign_text(crypt,"WHITCOMB\n1851",Vector3(0,2.62,2.025),17,Color("464b43"))
	inscription.pixel_size=0.003
	door_hinge=Node3D.new()
	crypt.add_child(door_hinge)
	door_hinge.position=Vector3(-0.7,0,1.88)
	var door=town.box(door_hinge,Vector3(0.7,1.2,0),Vector3(1.4,2.4,0.13),iron)
	door_collision=door.get_child(1)
	for x in [0.12,0.38,0.64,0.90,1.16,1.36]: town.box(door_hinge,Vector3(x,1.4,0.085),Vector3(0.035,1.6,0.03),dark_stone,false)
	town.box(door_hinge,Vector3(1.17,1.1,0.10),Vector3(0.12,0.16,0.05),town.mats.amber,false)
	town.action_area(crypt,Vector3(0,1.15,2.05),Vector3(1.5,2.3,0.25),"cemetery_door",{"kind":"mausoleum_door","label":"Inspect mausoleum lock"})
	# Interior shelf and stone burial ledges; the coupler cannot be reached through walls.
	for x in [-1.25,1.25]: town.box(crypt,Vector3(x,0.36,-0.35),Vector3(0.6,0.72,1.8),dark_stone)
	town.box(crypt,Vector3(0.5,0.48,-1.25),Vector3(1.4,0.96,0.55),town.mats.wood)
	# Reuse the existing forest bushes around the old stones and enclosure edges.
	var forest=town.game.get_node("DetailedForest")
	var plants=[Vector3(8.4,0,-7),Vector3(12,0,-6.8),Vector3(18.7,0,-6.8),Vector3(22.3,0,-9),Vector3(22.3,0,-18),Vector3(18.7,0,-23),Vector3(12,0,-23),Vector3(8,0,-21.6),Vector3(10.4,0,-18),Vector3(17.5,0,-18.1),Vector3(8.2,0,-16)]
	for i in range(plants.size()):
		var bush=forest.place(forest.bush_scenes[i%3],plants[i],Vector3(0.42,0.48,0.42),"CemeteryUndergrowth")
		bush.rotation.y=i*1.8
	var bark=town.mats.wood.duplicate()
	bark.albedo_color=Color("414a3c")
	for p in [Vector3(8.7,0,-22.6),Vector3(21.8,0,-6.9)]: dead_tree(p,bark)
	# The radio spare is stored inside the locked mausoleum, with no outdoor beacon.
	var part=town.action_area(crypt,Vector3(0.5,1.08,-1.25),Vector3(0.7,0.35,0.45),"cemetery_coupler",{"kind":"item","item":"antenna","label":"Take radio antenna coupler"})
	town.box(part,Vector3.ZERO,Vector3(0.55,0.12,0.22),town.mats.metal,false)
	for x in [-0.2,0.2]: town.box(part,Vector3(x,0.015,0),Vector3(0.12,0.18,0.28),town.mats.amber,false)
	var cellar_key=town.action_area(crypt,Vector3(-0.25,1.03,-1.25),Vector3(0.35,0.25,0.35),"cemetery_cellar_key",{"kind":"item","item":"chapel_key","label":"Take chapel cellar key"})
	var key_model=preload("res://assets/lockbox/key.glb").instantiate()
	cellar_key.add_child(key_model)
	key_model.rotation.x=PI/2
	key_model.position.y=-0.04
	var note=town.action_area(self,Vector3(6.6,1.1,-14.0),Vector3(0.3,0.5,0.5),"cemetery_note",{"kind":"note","label":"Read groundskeeper's notice","title":"Groundskeeper's notice","text":"The radio coupling and chapel cellar key have been locked in the Whitcomb mausoleum.\n\nThe Whitcomb family key is held by Elias at the ranger office. Ask him before entering the vault.\n\nThe station needs the aerial coupling, Owen's signal coil, and the county tuning unit before it can transmit."})
	town.box(note,Vector3.ZERO,Vector3(0.015,0.35,0.26),town.mats.paper,false)

func door_prompt() -> String:
	if not unlocked: return "E / Unlock mausoleum" if town.inventory.mausoleum_key>0 else "E / Locked mausoleum - inspect"
	return "E / "+("Close mausoleum" if opened else "Open mausoleum")

func inside() -> bool:
	var p=crypt.to_local(town.game.player.global_position)
	return absf(p.x)<1.65 and absf(p.z)<1.65 and p.y<2.8

func can_take() -> bool:
	return unlocked and opened and inside()

func interact_door():
	if not unlocked and (not town.powered or town.inventory.coil<=0):
		town.game.message="The family vault is locked. Head into town and speak with the ranger and mechanic."
		return
	if not unlocked:
		if town.inventory.mausoleum_key<=0:
			town.game.message="The mausoleum is locked. A groundskeeper's notice is attached to the cemetery gatepost."
			return
		town.inventory.mausoleum_key-=1
		unlocked=true
	if opened and (inside() or crypt.to_local(town.game.player.global_position).distance_to(Vector3(0,0,1.9))<1.2):
		town.game.message="Step clear of the doorway before closing it."
		return
	opened=not opened
	if door_tween and door_tween.is_valid(): door_tween.kill()
	door_collision.set_deferred("disabled",opened)
	door_tween=create_tween()
	door_tween.tween_property(door_hinge,"rotation:y",PI/2 if opened else 0.0,0.65)
	town.game.soundscape.door_move(door_hinge.global_position,opened)
	town.game.message="The iron key turns. The mausoleum door opens." if opened else "Mausoleum door closed."

func reset():
	if door_tween and door_tween.is_valid(): door_tween.kill()
	unlocked=false
	opened=false
	door_hinge.rotation.y=0
	door_collision.set_deferred("disabled",false)

func headstone(p: Vector3, index: int, stone: Material, dark: Material):
	var grave=Node3D.new()
	add_child(grave)
	grave.position=p
	grave.rotation=Vector3(0.015*(index%3-1),0.04*(index%5-2),0.025*(index%5-2))
	var material=stone.duplicate()
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.albedo_color=Color("777e70") if index%3==0 else Color("656d63") if index%3==1 else Color("898b79")
	var width=0.60+0.06*(index%4)
	var height=0.88+0.12*(index%4)
	var profile=PackedVector2Array()
	profile.append(Vector2(-width/2,0))
	profile.append(Vector2(width/2,0))
	if index%4==2:
		profile.append(Vector2(width/2,height-0.25))
		profile.append(Vector2(width*0.24,height-0.20))
		profile.append(Vector2(0,height))
		profile.append(Vector2(-width*0.24,height-0.20))
		profile.append(Vector2(-width/2,height-0.25))
	else:
		# Arched slate tablets, including a few chipped crowns.
		for j in range(9):
			var angle=j*PI/8
			var y=height-width/2+sin(angle)*width/2
			if index%6==0 and j==3: y-=0.10
			profile.append(Vector2(cos(angle)*width/2,y))
	var mesh=extrude(profile,0.13)
	town.game.mesh_at(grave,mesh,Vector3.ZERO,material)
	# A simple collision shape follows the tablet without blocking the aisle.
	var body=StaticBody3D.new()
	grave.add_child(body)
	var collision=CollisionShape3D.new()
	var shape=BoxShape3D.new()
	shape.size=Vector3(width,height,0.16)
	collision.shape=shape
	collision.position.y=height/2
	body.add_child(collision)
	if index%5==1:
		var fallen=town.box(grave,Vector3(0,0.075,0.85),Vector3(0.58,0.09,1.3),dark)
		fallen.rotation.y=0.11
	var names=["HOLLOWAY","MILLER","REED","BELL","WHITCOMB","HOLT","MORROW"]
	var lettering=town.sign_text(grave,"IN MEMORY OF\n"+names[index%names.size()]+"\n"+str(1848+index*3)+" - "+str(1882+index*4),Vector3(0,height*0.56,0.073),15,Color("363c35"))
	lettering.pixel_size=0.0022
	lettering.outline_size=0
	# Faint lichen flecks are attached to the stone, never floating in space.
	var moss=town.color_material(Color("565f43"))
	for j in range(5):
		var x=sin(index*2.1+j*3.4)*width*0.34
		var y=0.10+fmod(j*0.19+index*0.11,height*0.7)
		town.box(grave,Vector3(x,y,0.069),Vector3(0.07+0.015*j,0.04,0.003),moss,false)

func extrude(profile: PackedVector2Array, depth: float) -> ArrayMesh:
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangles=Geometry2D.triangulate_polygon(profile)
	for side in [-1,1]:
		for i in range(0,triangles.size(),3):
			var indices=[triangles[i],triangles[i+1],triangles[i+2]]
			if side<0: indices.reverse()
			for index in indices:
				tool.set_normal(Vector3(0,0,side))
				tool.set_uv(profile[index])
				tool.add_vertex(Vector3(profile[index].x,profile[index].y,side*depth/2))
	for i in range(profile.size()):
		var a=profile[i]
		var b=profile[(i+1)%profile.size()]
		var points=[Vector3(a.x,a.y,-depth/2),Vector3(b.x,b.y,-depth/2),Vector3(a.x,a.y,depth/2),Vector3(b.x,b.y,depth/2)]
		var normal=Vector3(b.y-a.y,a.x-b.x,0).normalized()
		for index in [0,1,2,1,3,2]:
			tool.set_normal(normal)
			tool.set_uv(Vector2(points[index].x,points[index].y))
			tool.add_vertex(points[index])
	return tool.commit()

func dead_tree(p: Vector3, material: Material):
	var trunk=town.game.mesh_at(self,town.game.cylinder(0.23,0.10,4.5,7),p+Vector3(0,2.25,0),material)
	trunk.rotation.z=0.06
	for i in range(7):
		var start=p+Vector3(0,1.7+i*0.34,0)
		var finish=start+Vector3(cos(i*2.3)*1.5,0.9,sin(i*2.3)*1.5)
		var branch=town.game.mesh_at(self,town.game.cylinder(0.07,0.015,start.distance_to(finish),5),(start+finish)/2,material)
		branch.quaternion=Quaternion(Vector3.UP,(finish-start).normalized())

func wall(p: Vector3, dimensions: Vector3, stone: Material, iron: Material):
	town.box(self,p+Vector3(0,dimensions.y/2,0),dimensions,stone)
	var along_x=dimensions.x>dimensions.z
	var length=dimensions.x if along_x else dimensions.z
	for i in range(int(length/0.25)):
		var offset=(i+0.5)*0.25-length/2
		var position=p+Vector3(offset if along_x else 0,1.0,0 if along_x else offset)
		town.box(self,position,Vector3(0.035,1.15,0.035),iron,false)
		town.game.mesh_at(self,town.game.cylinder(0.065,0,0.16,4),position+Vector3(0,0.65,0),iron)
	for y in [0.63,1.39]:
		var rail=Vector3(dimensions.x,0.045,0.045) if along_x else Vector3(0.045,0.045,dimensions.z)
		town.box(self,p+Vector3(0,y,0),rail,iron,false)

func contains(p: Vector3) -> bool:
	return p.x>6.5 and p.x<23.5 and p.z> -24.5 and p.z< -5.5
