extends Node3D
## Scavenged ammo cartons built from the user's downloaded cardboard box.
var game
const BOXES = [
	{"id":"pistol_store","room":"store","weapon":0,"support":"dining_table","offset":Vector3(0.35,0,-0.22)},
	{"id":"pistol_house","room":"house","weapon":0,"support":"counter","offset":Vector3(0.32,0,-0.16)},
	{"id":"pistol_clinic","room":"clinic","weapon":0,"support":"","offset":Vector3(1.8,0.016,-3.4)},
	{"id":"shotgun_ranger","room":"ranger","weapon":2,"support":"dresser","offset":Vector3(0.30,0,-0.05)},
	{"id":"shotgun_house","room":"house","weapon":2,"support":"coffee_table","offset":Vector3(0.18,0,-0.40)},
	{"id":"shotgun_workshop","room":"workshop","weapon":2,"support":"desk","offset":Vector3(1.1,0,0.22)},
	{"id":"rifle_workshop","room":"workshop","weapon":1,"support":"desk","offset":Vector3(-1.1,0,0.22)},
	{"id":"rifle_radio","room":"radio","weapon":1,"support":"desk","offset":Vector3(0.85,0,-0.25)},
	{"id":"rifle_cellar","room":"cellar","weapon":1,"support":"","offset":Vector3(-3.4,0.901,-2.95)}]
const AMOUNTS = [6,12,4]
const LABELS = ["PISTOL","RIFLE","SHELLS"]
const COLORS = [Color("8f6151"),Color("647b84"),Color("a68e55")]
var areas: Array[Area3D] = []
var dimensions = {}
func _ready():
	name = "ScavengedAmmunition"
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ammo/manifest.json"))
	for row in manifest.assets: dimensions[row.asset] = row.dimensions
	for recipe in BOXES: make_box(recipe)
func make_box(recipe):
	var town = game.town
	var parent = town.streetscape.church.basement if recipe.room=="cellar" else town.buildings[recipe.room]
	var p: Vector3 = recipe.offset
	if recipe.support!="":
		for instance in town.apartment_interiors.instances:
			if instance.get_meta("room")==recipe.room and instance.get_meta("apartment_asset")==recipe.support:
				p += instance.position
				p.y = instance.position.y+town.apartment_interiors.manifest[recipe.support].dimensions[1]*instance.scale.y+0.001
				break
	var index: int = recipe.weapon
	var area = town.action_area(parent,p+Vector3(0,0.10,0),Vector3(0.42,0.30,0.36),"ammo_"+recipe.id,{"kind":"ammo","weapon_index":index,"amount":AMOUNTS[index],"initial_amount":AMOUNTS[index],"label":"Take "+LABELS[index].to_lower()+" ammunition"})
	areas.append(area)
	var model = load("res://assets/ammo/"+game.weapons.LOADOUT[index].id+".glb").instantiate()
	area.add_child(model)
	model.position.y = -0.10
	game.weapons.adapt(model)
	if index!=2:
		if recipe.room=="cellar": parent.prepare_cellar_lighting(area)
		return
	var height: float = dimensions[game.weapons.LOADOUT[index].id][1]-0.10
	town.box(area,Vector3(0,height+0.003,0),Vector3(0.21,0.004,0.11),town.mats.paper,false)
	town.box(area,Vector3(-0.08,height+0.006,0),Vector3(0.025,0.003,0.10),town.color_material(COLORS[index]),false)
	var label = town.sign_text(area,"12 GA\n"+str(AMOUNTS[index])+" SHELLS",Vector3(0.012,height+0.009,0),16,Color("292d29"))
	label.pixel_size = 0.0014
	label.rotation.x = -PI/2
	label.outline_size = 0
	label.shaded = true
	if recipe.room=="cellar": parent.prepare_cellar_lighting(area)

	var depth: float = dimensions.shotgun[2]
	town.box(area,Vector3(0,(height+0.10)/2-0.10,depth/2+0.004),Vector3(0.20,0.075,0.004),town.mats.paper,false)
	var front = town.sign_text(area,"12 GA / SHELLS",Vector3(0,(height+0.10)/2-0.10,depth/2+0.009),14,Color("292d29"))
	front.pixel_size = 0.0012
	front.outline_size = 0
	front.shaded = true
