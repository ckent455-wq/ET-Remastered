extends Node3D
## A sheltered cellar interior reached through the chapel's locked stair door.
var town
var church
var unlocked = false
var visited = false
var entry_hinge: Node3D
var padlock: Node3D

func _ready():
	name = "ChapelCellar"
	position = Vector3(0,-13,0)
	build_entry()
	build_room()

func contains(p: Vector3) -> bool:
	var local = to_local(p)
	return absf(local.x)<4.9 and absf(local.z)<5.8 and local.y>=-0.4 and local.y<3.8

func build_entry():
	var p = Vector3(3.25,0,-6.72)
	town.box(church,p+Vector3(0,1.35,0.035),Vector3(1.80,2.60,0.015),town.color_material(Color("070b0c")),false)
	entry_hinge = Node3D.new()
	church.add_child(entry_hinge)
	entry_hinge.position = p+Vector3(-0.85,0,0)
	var leaf = church.native_prop("door",entry_hinge,Vector3(0.85,0,0.05))
	leaf.name = "NativeCellarDoorLeaf"
	leaf.scale = Vector3(1.7/1.407018065,2.6/2.7,1.0)
	leaf.set_meta("source_prefab","Flooded_Grounds/Prefabs/Buildings/Churches/Church1_Door_C.prefab")
	var frame = town.color_material(Color("555c50"))
	for side in [-1,1]: town.box(church,p+Vector3(side*0.93,1.38,0.015),Vector3(0.16,2.76,0.16),frame,false)
	town.box(church,p+Vector3(0,2.68,0.015),Vector3(2.02,0.16,0.16),frame,false)
	town.box(entry_hinge,Vector3(1.48,1.15,0.15),Vector3(0.06,0.25,0.08),town.mats.metal,false)
	padlock = town.box(entry_hinge,Vector3(1.44,1.05,0.20),Vector3(0.16,0.20,0.07),town.mats.amber,false)
	var sign = town.sign_text(church,"CELLAR\nKEEP LOCKED",p+Vector3(0,2.98,0.15),22,Color("b5ad92"))
	sign.pixel_size = 0.005
	town.action_area(church,p+Vector3(0,1.3,0.22),Vector3(1.85,2.6,0.28),"cellar_door",{"kind":"cellar_door","label":"Unlock cellar door"})
	# A readable maintenance note beside the altar gives an independent clue.
	town.box(church,Vector3(-3.65,0.5,-5.55),Vector3(0.85,1,0.65),town.mats.wood)
	var note = town.action_area(church,Vector3(-3.65,1.04,-5.5),Vector3(0.62,0.15,0.5),"cellar_note",{"kind":"note","label":"Read chapel maintenance log","title":"Chapel maintenance log","text":"The civil-defense radio's spare tuning unit is on the\ncellar workbench. The station needs it AND a signal coil\nto transmit clearly. Owen took the cellar key to the mill\nworkshop. He keeps it in the powered signal-coil cabinet.\n\nFollow Chapel Road uphill. The locked cellar door is\nat the back right of the chapel. Bring a fresh battery.\nThe cellar stairs return to the chapel."})
	town.box(note,Vector3.ZERO,Vector3(0.45,0.025,0.33),town.mats.paper,false)

func build_room():
	var stone = church.masonry.duplicate()
	stone.albedo_color = Color("797d70")
	stone.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	town.box(self,Vector3(0,-0.15,0),Vector3(9.6,0.3,11.2),stone)
	town.box(self,Vector3(0,3.7,0),Vector3(9.8,0.2,11.4),stone)
	for side in [-1,1]:
		town.box(self,Vector3(side*4.8,1.8,0),Vector3(0.3,3.6,11.4),stone)
		town.box(self,Vector3(0,1.8,side*5.6),Vector3(9.8,3.6,0.3),stone)
	for z in [-4,-1,2]:
		town.box(self,Vector3(0,3.4,z),Vector3(9.3,0.25,0.25),town.mats.wood,false)
	# A short stair flight makes the return route legible. Its ramp collider
	# provides smooth movement instead of capsule-sized steps.
	for i in range(6):
		town.box(self,Vector3(0,(i+1)*0.09,2.6+i*0.4),Vector3(1.8,(i+1)*0.18,0.4),stone,false)
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices = [Vector3(-0.9,0,2.4),Vector3(0.9,0,2.4),Vector3(-0.9,1.08,4.8),Vector3(0.9,1.08,4.8)]
	for i in [0,1,2,1,3,2]:
		tool.add_vertex(vertices[i])
	var body = StaticBody3D.new()
	add_child(body)
	var collision = CollisionShape3D.new()
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(tool.commit().get_faces())
	shape.backface_collision = true
	collision.shape = shape
	body.add_child(collision)
	town.box(self,Vector3(0,0.99,5.0),Vector3(1.8,0.18,0.4),stone)
	town.box(self,Vector3(0,2.22,5.35),Vector3(1.75,2.28,0.1),town.mats.wood,false)
	var sign = town.sign_text(self,"UP TO CHAPEL",Vector3(0,3.12,5.22),22,Color("c4b78f"))
	sign.rotation.y = PI
	sign.pixel_size = 0.005
	town.action_area(self,Vector3(0,2.0,5.15),Vector3(1.8,2.0,0.3),"cellar_exit",{"kind":"cellar_exit","label":"Return upstairs to chapel"})
	# Old civil-defense workbench and a distinct, collectible tuning unit.
	town.box(self,Vector3(-2.6,0.82,-3.3),Vector3(2.5,0.16,1.0),town.mats.wood)
	for x in [-3.6,-1.6]:
		town.box(self,Vector3(x,0.4,-3.3),Vector3(0.16,0.8,0.8),town.mats.wood)
	var unit = town.action_area(self,Vector3(-2.6,1.09,-3.1),Vector3(0.75,0.5,0.6),"radio_tuner",{"kind":"cellar_part","label":"Take emergency radio tuning unit"})
	town.box(unit,Vector3.ZERO,Vector3(0.6,0.3,0.4),town.mats.metal,false)
	var brass = town.mats.amber.duplicate()
	brass.emission_enabled = false
	var display = town.mats.green.duplicate()
	display.emission_enabled = false
	for x in [-0.19,0.19]:
		town.box(unit,Vector3(x,0.05,0.23),Vector3(0.09,0.09,0.08),brass,false)
	town.box(unit,Vector3(0,0.08,0.22),Vector3(0.18,0.12,0.03),display,false)
	var label = town.sign_text(self,"CIVIL DEFENSE\nSPARE RADIO TUNING UNIT",Vector3(-2.6,2.05,-5.4),22,Color("b3b69d"))
	label.pixel_size = 0.005
	# Only a weak stair light remains; the workbench requires the flashlight.
	var stair_light = town.lamp(self,Vector3(0,2.9,4),Color("ba9870"),0.045,2.2)
	stair_light.name = "FaintCellarStairLight"
	stair_light.light_cull_mask = 2
	var cell = town.action_area(self,Vector3(3.3,0.92,-2.4),Vector3(0.5,0.4,0.5),"cellar_battery",{"kind":"item","item":"battery","label":"Take flashlight battery"})
	cell.add_child(preload("res://supply_models.gd").build("battery"))
	town.box(self,Vector3(3.3,0.4,-2.4),Vector3(1.2,0.8,0.7),town.mats.wood)

func dress():
	for p in [Vector3(3.8,0,-4.4),Vector3(3.6,0,-0.4),Vector3(-3.8,0,0.3)]:
		town.interiors.prop("box",self,p,Vector3(0.9,0.9,0.9),p.z*0.12)
	town.interiors.prop("shelf",self,Vector3(-3.5,0,-5.0),Vector3(0.65,0.75,0.7))
	town.interiors.prop("books",self,Vector3(-1.8,0.91,-3.4),Vector3(0.7,0.7,0.7))
	for i in range(5):
		var paper = town.box(self,Vector3(-2+i*0.8,0.014,-0.8+sin(i)),Vector3(0.24,0.012,0.32),town.mats.paper,false)
		paper.rotation.y = i*0.8

	prepare_cellar_lighting(self)

func prepare_cellar_lighting(node: Node):
	if node is GeometryInstance3D:
		node.layers = 2
	if node is Label3D:
		node.shaded = true
	for child in node.get_children():
		prepare_cellar_lighting(child)

func interact():
	if not unlocked:
		if town.inventory.chapel_key==0:
			town.game.message = "Cellar locked. The key is in the workshop's powered signal-coil cabinet."
			return
		unlocked = true
		padlock.hide()
	entry_hinge.rotation.y = -1.4
	visited = true
	move_player(to_global(Vector3(0,0.01,1.5)),0)
	town.game.message = "Chapel cellar. Find the spare tuning unit; the stairs lead back upstairs."

func leave():
	entry_hinge.rotation.y = 0
	move_player(church.to_global(Vector3(3.25,0.01,-4.9)),PI)
	town.game.message = "Back in the chapel. Follow Chapel Road down to town."

func move_player(p: Vector3, yaw: float):
	town.game.jump_queued = false
	town.game.player.global_position = p
	town.game.player.velocity = Vector3.ZERO
	town.game.player.rotation = Vector3(0,yaw,0)
	town.game.pitch = 0
	town.game.camera.rotation = Vector3.ZERO
	town.focus_action = ""
	town.game.hud.passage_fade = 1.0
	town.game.soundscape.door_move(p,true)

func reset():
	unlocked = false
	visited = false
	entry_hinge.rotation.y = 0
	padlock.show()
