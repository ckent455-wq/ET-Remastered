extends Node3D
## Static dressing from the supplied RetroModelPack. Small clutter has no collider.
var town
var scenes={}
var manifest={}
var instances:Array[Node3D]=[]
var replacements=0

func _ready():
	name="RetroModelDressing"
	for row in JSON.parse_string(FileAccess.get_file_as_string("res://assets/retro_props/manifest.json")).assets:
		manifest[row.asset]=row
		scenes[row.asset]=load("res://assets/retro_props/"+row.asset+".glb")

func bounds(node:Node3D,root:Node3D)->AABB:
	var result=AABB()
	var first=true
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		var box:AABB=(root.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		result=box if first else result.merge(box)
		first=false
	return result

func place(asset:String,parent:Node3D,p:Vector3,yaw=0.0,size=Vector3.ZERO,solid=false)->Node3D:
	var root:Node3D=StaticBody3D.new() if solid else Node3D.new()
	root.name="Retro_"+asset+str(instances.size())
	root.set_meta("retro_asset",asset)
	root.add_to_group("RetroInteriorProps")
	parent.add_child(root)
	var model=scenes[asset].instantiate()
	root.add_child(model)
	if asset=="clock": model.rotation.y=-PI/2
	if asset=="knife": model.rotation.z=PI/2
	var box=bounds(model,root)
	model.position-=Vector3(box.get_center().x,box.position.y,box.get_center().z)
	if size!=Vector3.ZERO:
		root.scale=Vector3(size.x/box.size.x,size.y/box.size.y,size.z/box.size.z)
	town.interiors.adapt(model)
	root.position=p
	root.rotation.y=yaw
	root.set_meta("support_height",p.y)
	if solid:
		var col=CollisionShape3D.new()
		var shape=BoxShape3D.new()
		shape.size=box.size
		col.shape=shape
		col.position.y=box.size.y/2
		root.add_child(col)
	instances.append(root)
	return root

func room(asset:String,id:String,p:Vector3,yaw=0.0,size=Vector3.ZERO,solid=false):
	return place(asset,town.buildings[id],p,yaw,size,solid)

func decorate():
	# Kitchen work was interrupted; avoid the key dresser and collectible surfaces.
	room("cutting_board","house",Vector3(3.2,0.98,-4.05),0.18)
	room("knife","house",Vector3(3.2,0.992,-4.05),-0.35)
	room("plate","house",Vector3(5.15,0.98,-4.05))
	room("bucket","house",Vector3(5.35,0.04,-1.9))
	room("table","house",Vector3(-3.9,0.04,0.15),0,Vector3(0.85,0.5,0.62),true)
	room("tv","house",Vector3(-3.9,0.54,0.15),0)
	room("locker","ranger",Vector3(4.55,0.04,-3.65),0,Vector3.ZERO,true)
	room("bucket","ranger",Vector3(4.55,0.04,-2.9))
	room("locker","clinic",Vector3(-4.55,0.04,-3.65),0,Vector3.ZERO,true)
	room("bucket","clinic",Vector3(-4.55,0.04,-2.8))
	room("burner","store",Vector3(-3.8,0.83,3.65))
	room("cutting_board","store",Vector3(-3.2,0.83,3.65),0.18)
	room("bucket","store",Vector3(4.8,0.04,3.7))
	room("locker","workshop",Vector3(5.25,0.04,-2.5),0,Vector3.ZERO,true)
	room("bucket","workshop",Vector3(5.2,0.04,-1.6))
	room("sheet_metal","workshop",Vector3(-4.85,0.045,1.5),0.25)
	room("slate","workshop",Vector3(-4.45,0.045,1.75),-0.3)
	room("scythe","workshop",Vector3(-1.7,0.04,-3.3),PI/2)
	room("knife","workshop",Vector3(-3.35,0.89,-3.15),PI/2)
	room("table","radio",Vector3(3.9,0.04,-0.2),0,Vector3(0.85,0.5,0.62),true)
	room("tv","radio",Vector3(3.9,0.54,-0.2),0)
	room("plate","radio",Vector3(4.55,0.74,3.85))
	room("bucket","radio",Vector3(-4.8,0.04,-3.65))

func decorate_house(house):
	place("entrance_mat",house,Vector3(0,house.FLOOR+0.01,4.35))
	place("bucket",house,Vector3(-4.5,house.FLOOR,-1.4))
	place("plate",house,Vector3(-2.9,house.FLOOR+0.78*0.85,-3.0))
	place("table",house,Vector3(-1.4,house.UPPER,3.9),0,Vector3(0.8,0.5,0.6),true)
	place("tv",house,Vector3(-1.4,house.UPPER+0.5,3.9),PI)
	place("bucket",house.cellar,Vector3(2.9,0.01,1.1))
	place("sheet_metal",house.cellar,Vector3(-2.4,0.01,1.1),0.1)
	place("locker",house.cellar,Vector3(2.6,0.01,0),PI,Vector3.ZERO,true)
