extends Node3D
## Bounded first-person weapons: recoil affects the model, never the camera.
var game
const LOADOUT = [
	{"id":"pistol","label":"COVERT PISTOL","clip":8,"max_reserve":64,"pickup_rounds":3,"delay":0.38,"reload":1.35,"pellets":1,"spread":0.006,"damage":24.0},
	{"id":"rifle","label":"SERVICE RIFLE","clip":20,"max_reserve":120,"pickup_rounds":20,"delay":0.15,"reload":1.8,"pellets":1,"spread":0.012,"damage":48.0},
	{"id":"shotgun","label":"DOUBLE BARREL","clip":2,"max_reserve":32,"pickup_rounds":2,"delay":0.65,"reload":2.1,"pellets":8,"spread":0.055,"damage":12.0}]
var ammo_pickups: Node3D
var lockbox: Node3D
var models: Array[Node3D] = []
var magazines: Array[int] = []
var reserves: Array[int] = []
var owned: Array[bool] = [false,false,false]
var selected = -1
const PICKUPS = [
	{"building":"ranger","p":Vector3(-1.9,0.94,2.8)},
	{"building":"cellar","p":Vector3(2.8,0.96,1.2)},
	{"building":"ranger","p":Vector3(-2.7,0.39,-3.0)}]
var delay = 0.0
var reload_remaining = 0.0
var recoil = 0.0
var flash_remaining = 0.0
var aiming = false
var holder: Node3D
var flash: MeshInstance3D
var flash_light: OmniLight3D
var muzzle: Node3D
var marks: Array[Node3D] = []
var hit_feedback = 0.0
var rng = RandomNumberGenerator.new()
var targets: Array[StaticBody3D] = []

func _ready():
	name = "Weapons"
	rng.randomize()
	holder = Node3D.new()
	game.camera.add_child(holder)
	for weapon in LOADOUT:
		var model = load("res://assets/weapons/%s.glb" % weapon.id).instantiate() as Node3D
		holder.add_child(model)
		# The pistol source uses the opposite muzzle axis from the long guns.
		if weapon.id=="pistol":
			model.rotation.y = PI
		adapt(model)
		models.append(model)
	muzzle = Node3D.new()
	holder.add_child(muzzle)
	var material = game.mat(Color("ffc67e"),null,2)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var star = SphereMesh.new()
	star.radius = 0.045
	star.height = 0.14
	star.radial_segments = 5
	star.rings = 3
	flash = game.mesh_at(muzzle,star,Vector3.ZERO,material)
	flash.rotation.x = PI/2
	flash_light = OmniLight3D.new()
	flash_light.light_color = Color("ffd295")
	flash_light.omni_range = 4
	flash_light.light_energy = 1.2
	muzzle.add_child(flash_light)
	make_targets()
	make_pickups()
	lockbox = preload("res://shotgun_lockbox.gd").new()
	lockbox.game = game
	game.town.buildings.ranger.add_child(lockbox)
	ammo_pickups = preload("res://ammo_pickups.gd").new()
	ammo_pickups.game = game
	add_child(ammo_pickups)
	reset()

func make_pickups():
	game.town.box(game.town.buildings.ranger,Vector3(-1.9,0.45,2.8),Vector3(1.1,0.9,0.75),game.town.mats.furniture)
	var basement = game.town.streetscape.church.basement
	var rack = game.town.box(basement,Vector3(2.8,0.42,1.2),Vector3(1.5,0.84,1.2),game.town.mats.wood)
	var label = game.town.sign_text(rack,"COUNTY LOCKUP / SERVICE RIFLE",Vector3(0,0.15,0.61),15,Color("b3b099"))
	label.pixel_size = 0.003
	basement.prepare_cellar_lighting(rack)
	for i in range(LOADOUT.size()):
		var data = PICKUPS[i]
		var id = "weapon_"+LOADOUT[i].id
		var parent = basement if data.building=="cellar" else game.town.buildings[data.building]
		var area = game.town.action_area(parent,data.p,Vector3(0.8,0.3,1.1),id,{"kind":"weapon","weapon_index":i,"label":"Take "+LOADOUT[i].label.to_lower()})
		var model = load("res://assets/weapons/%s.glb" % LOADOUT[i].id).instantiate() as Node3D
		area.add_child(model)
		model.rotation.z = PI/2
		model.rotation.y = 0.15
		if data.building=="cellar": model.rotation.y = PI/2
		model.scale = Vector3.ONE*0.8
		adapt(model)
		if data.building=="cellar": basement.prepare_cellar_lighting(area)

func collect(index: int) -> bool:
	if game.state!="play" or index<0 or index>=LOADOUT.size() or owned[index]:
		return false
	if game.backpack and not game.backpack.room_for("gun%d" % index):
		game.message = "Backpack full. Free space before taking this weapon."
		return false
	owned[index] = true
	magazines[index] = LOADOUT[index].pickup_rounds
	# Keep scavenged rounds collected before finding this weapon.
	if selected<0:
		equip(index)
	return true

func add_ammo(index: int, amount: int) -> int:
	if game.state!="play" or index<0 or index>=LOADOUT.size() or amount<=0: return 0
	var added = mini(amount,LOADOUT[index].max_reserve-reserves[index])
	if game.backpack:
		while added>0 and not game.backpack.room_for("ammo%d" % index,added): added-=1
	reserves[index] += added
	return added

func adapt(node: Node):
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in range(node.mesh.get_surface_count()):
			var original = node.mesh.surface_get_material(surface)
			if original is StandardMaterial3D:
				var material = original.duplicate() as StandardMaterial3D
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
				material.metallic = 0
				material.roughness = 1
				material.normal_enabled = false
				node.set_surface_override_material(surface,material)
	for child in node.get_children():
		adapt(child)

func make_targets():
	# A small range in the mill yard gives the guns something to hit.
	for i in range(4):
		var p = Vector3(30+i*1.5,1.3,-44)
		var post = game.town.box(game.town,p-Vector3(0,0.65,0),Vector3(0.09,1.3,0.09),game.town.mats.wood)
		post.name = "RangePost%d" % i
		var target = game.town.box(game.town,p,Vector3(0.55,0.65,0.10),game.town.mats.metal) as StaticBody3D
		target.set_meta("shooting_target",i)
		target.name = "RangeTarget%d" % i
		targets.append(target)
		game.town.box(target,Vector3(0,0,0.06),Vector3(0.15,0.19,0.02),game.town.mats.paper,false)

func reset():
	magazines.clear()
	reserves.clear()
	owned = [false,false,false]
	for weapon in LOADOUT:
		magazines.append(0)
		reserves.append(0)
	selected = -1
	delay = 0
	reload_remaining = 0
	recoil = 0
	flash_remaining = 0
	hit_feedback = 0
	aiming = false
	for mark in marks:
		mark.queue_free()
	marks.clear()
	for target in targets:
		target.rotation = Vector3.ZERO
		target.set_meta("hits",0)
	if lockbox: lockbox.reset()
	update_model(1)

func cycle(direction = 1):
	if game.state!="play": return
	var start: int = selected if selected>=0 else (-1 if direction>0 else 0)
	for step in range(1,LOADOUT.size()+1):
		var index = wrapi(start+step*direction,0,LOADOUT.size())
		if owned[index]:
			equip(index)
			return

func equip(index: int):
	if game.state!="play" or index==selected:
		return
	if index< -1 or index>=LOADOUT.size():
		return
	if index>=0 and not owned[index]:
		game.message = "You haven't found that weapon. Search Blackwood's buildings."
		return
	selected = index
	reload_remaining = 0
	delay = 0.25
	recoil = 0
	aiming = false
	flash_remaining = 0
	game.soundscape.weapon_stop_reload()
	update_model(1)

func reload():
	if game.state!="play" or selected<0 or reload_remaining>0:
		return
	if magazines[selected]>=LOADOUT[selected].clip or reserves[selected]<=0:
		return
	reload_remaining = LOADOUT[selected].reload
	game.soundscape.weapon_sound("reload")

func fire() -> bool:
	if game.state!="play" or selected<0 or delay>0 or reload_remaining>0:
		return false
	if magazines[selected]<=0:
		delay = 0.3
		game.soundscape.weapon_sound("empty")
		return false
	magazines[selected] -= 1
	delay = LOADOUT[selected].delay
	recoil = 1
	flash_remaining = 0.065
	game.soundscape.weapon_sound(LOADOUT[selected].id)
	if game.enemies: game.enemies.alert_shot(game.camera.global_position)
	for pellet in range(LOADOUT[selected].pellets):
		var spread: float = LOADOUT[selected].spread*(0.25 if aiming else 1.0)
		var direction = -game.camera.global_basis.z
		direction += game.camera.global_basis.x*rng.randf_range(-spread,spread)
		direction += game.camera.global_basis.y*rng.randf_range(-spread,spread)
		var start: Vector3 = game.camera.global_position
		var ray = PhysicsRayQueryParameters3D.create(start,start+direction.normalized()*65,1,[game.player.get_rid()])
		var hit = game.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			impact(hit)
	return true

func impact(hit: Dictionary):
	var body = hit.collider as Node3D
	if body.is_in_group("HostileEnemies"):
		if game.enemies.shoot(int(body.get_meta("enemy_index")),LOADOUT[selected].damage):
			hit_feedback = 0.18
		return
	if body.is_in_group("CrowTargets"):
		if body.get_parent().shoot():
			hit_feedback = 0.18
		return
	if body.is_in_group("TownNPCs"):
		if game.town.townspeople.shoot(str(body.get_meta("npc_id",""))):
			hit_feedback = 0.18
		return
	if body.has_meta("shooting_target"):
		body.set_meta("hits",int(body.get_meta("hits",0))+1)
		body.rotation.x = -0.25
		hit_feedback = 0.18
		game.message = "Metal target hit. R reloads. 1 / 2 / 3 switch weapons."
	# Keep only a few small impact chips, including shotgun pellets.
	if marks.size()>=20:
		marks.pop_front().queue_free()
	var chip = game.mesh_at(game,game.cylinder(0.018,0.018,0.008,5),hit.position+hit.normal*0.009,game.town.mats.dark)
	if absf(hit.normal.dot(Vector3.UP))<0.99:
		chip.quaternion = Quaternion(Vector3.UP,hit.normal)
	marks.append(chip)

func status() -> String:
	if selected<0:
		return "HOLSTERED / 1 2 3 EQUIP" if owned.has(true) else "UNARMED / SEARCH FOR A WEAPON"
	if reload_remaining>0:
		return "%s / RELOADING" % LOADOUT[selected].label
	return "%s  %02d / %02d" % [LOADOUT[selected].label,magazines[selected],reserves[selected]]

func update_model(delta: float):
	game.arm_visual.visible = selected<0
	for i in range(models.size()):
		models[i].visible = i==selected and game.state in ["play","paused"]
	var aim_position = Vector3(0,-0.10,-0.58) if aiming else Vector3(0.25,-0.27,-0.58)
	if reload_remaining>0:
		aim_position += Vector3(0.10,-0.22,0.12)
	holder.position = holder.position.lerp(aim_position,clampf(delta*14,0,1))
	holder.position.z += recoil*0.014
	holder.rotation.x = recoil*0.08
	holder.rotation.z = -0.3 if reload_remaining>0 else 0.0
	muzzle.position = Vector3(0,0.06,-0.29 if selected==0 else -0.5)
	flash.visible = flash_remaining>0 and game.state=="play"
	flash_light.visible = flash.visible

func _physics_process(delta):
	if game.state!="play":
		aiming = false
		flash_remaining = 0
		update_model(delta)
		return
	delay = maxf(0,delay-delta)
	recoil = move_toward(recoil,0,delta*7)
	flash_remaining = maxf(0,flash_remaining-delta)
	hit_feedback = maxf(0,hit_feedback-delta)
	if reload_remaining>0:
		reload_remaining = maxf(0,reload_remaining-delta)
		if reload_remaining==0:
			var amount = mini(LOADOUT[selected].clip-magazines[selected],reserves[selected])
			magazines[selected] += amount
			reserves[selected] -= amount
	aiming = selected>=0 and reload_remaining<=0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	update_model(delta)
