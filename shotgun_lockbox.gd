extends Node3D
## Local Haunted Farmhouse crate and Rust Key, with a real hinged lid.
var game
var hinge: Node3D
var latch: Node3D
var unlocked = false
var opened = false
var pickup: Area3D
var action: Area3D
func _ready():
	name = "RangerShotgunLockbox"
	position = Vector3(-2.7,0.04,-3.0)
	var body = preload("res://assets/lockbox/body.glb").instantiate()
	add_child(body)
	game.weapons.adapt(body)
	game.town.box(self,Vector3(0,0.28,0),Vector3(1.48,0.56,0.94),game.town.mats.wood).get_child(0).hide()
	hinge = Node3D.new()
	add_child(hinge)
	hinge.position = Vector3(0,0.59,-0.48)
	var lid = preload("res://assets/lockbox/lid.glb").instantiate()
	hinge.add_child(lid)
	lid.position.z = 0.48
	game.weapons.adapt(lid)
	game.town.box(self,Vector3(0,0.39,0),Vector3(1.25,0.28,0.45),game.town.mats.wood,false)
	latch = game.town.box(self,Vector3(0,0.46,0.50),Vector3(0.13,0.20,0.04),game.town.mats.metal,false)
	action = game.town.action_area(self,Vector3(0,0.65,0.54),Vector3(1.3,0.6,0.12),"shotgun_lockbox",{"kind":"shotgun_lockbox","label":"Inspect shotgun lockbox"})
	var key = game.town.action_area(game.town.buildings.house,Vector3(-2.8,1.00,-1.38),Vector3(0.35,0.25,0.35),"shotgun_key",{"kind":"item","item":"shotgun_key","label":"Take ranger shotgun-box key"})
	var key_model = preload("res://assets/lockbox/key.glb").instantiate()
	key.add_child(key_model)
	key_model.rotation.x = PI/2
	key_model.position.y = -0.044 # Bottom of the rotated key rests on the 0.94m dresser top.
	game.weapons.adapt(key)
	pickup = game.town.actions.weapon_shotgun.area
	pickup.position.y = 0.79
	pickup.get_child(1).position.y = -0.14
	pickup.get_child(1).rotation.y = PI/2
	reset()
func reset():
	unlocked = false
	opened = false
	hinge.rotation.x = 0
	latch.show()
	sync_pickup()
func can_take() -> bool:
	return unlocked and opened and hinge.rotation.x< -1.0
func prompt() -> String:
	if not unlocked: return "E / Unlock shotgun box" if game.town.inventory.shotgun_key>0 else "E / Locked shotgun box - inspect"
	return "E / "+("Close shotgun box" if opened else "Open shotgun box")
func interact():
	if game.state!="play": return
	if not unlocked:
		if game.town.inventory.shotgun_key<=0:
			game.message = "Locked shotgun box. A scratched label reads: spare key on the Saint George Hotel bedroom dresser."
			return
		game.town.inventory.shotgun_key -= 1
		unlocked = true
		latch.hide()
	opened = not opened
	game.message = "The lock clicks free. Lift the lid and take the shotgun." if opened else "Shotgun box closed."
	game.soundscape.feedback("pickup")
func sync_pickup():
	if not is_instance_valid(pickup): return
	action.position.x = -0.64 if opened else 0.0
	(action.get_child(0).shape as BoxShape3D).size.x = 0.25 if opened else 1.3
	var available = not game.town.actions.weapon_shotgun.taken
	pickup.visible = opened and available
	pickup.collision_layer = 2 if available and can_take() else 0
func _process(delta):
	if game.state!="play": return
	hinge.rotation.x = move_toward(hinge.rotation.x,-1.75 if opened else 0.0,delta*2.8)
	sync_pickup()
