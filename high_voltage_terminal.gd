extends Node3D
## Native high-voltage cabinet with a cartridge fuse fitted inside its native holder.
var town
var model:Node3D
var animation:AnimationPlayer
var energized=false
var opened=false
var installed=false
var phase=""
var phase_time=0.0
var open_door=Transform3D.IDENTITY
var fuse_materials:Array[StandardMaterial3D]=[]
var fuse_glow:OmniLight3D

func _ready():
	name="HighVoltageTerminal"
	model=preload("res://assets/high_voltage/fuse_box.glb").instantiate()
	add_child(model)
	model.scale=Vector3.ONE*1.35
	# The source wall prop is authored at 1.24m above its origin.
	model.position=Vector3(0,-1.24*1.35,-0.10)
	adapt(model)
	animation=model.find_child("AnimationPlayer",true,false)
	animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

	reset()

func adapt(node):
	if node is MeshInstance3D:
		for i in range(node.mesh.get_surface_count()):
			var original=node.mesh.surface_get_material(i)
			if original is StandardMaterial3D:
				var material=original.duplicate()
				material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				material.roughness=1
				material.metallic=0
				material.metallic_specular=0
				node.set_surface_override_material(i,material)
	for child in node.get_children(): adapt(child)

func reset():
	energized=false
	opened=false
	installed=false
	phase="closed"
	phase_time=0
	for clip in ["open","pull"]:
		animation.play(clip)
		animation.seek(0,true)
		animation.advance(0)
	animation.stop()
	set_fuse_power(false)
	refresh_prompt()

func configure_fuse(fuse:Node3D):
	for mesh in fuse.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var material=mesh.get_active_material(i).duplicate() as StandardMaterial3D
			mesh.set_surface_override_material(i,material)
			fuse_materials.append(material)
	fuse_glow=OmniLight3D.new()
	fuse_glow.name="FusePowerGlow"
	fuse_glow.position=fuse.position+Vector3(0,0,0.08)
	fuse_glow.light_color=Color(0.12,1.0,0.25)
	fuse_glow.light_energy=0.45
	fuse_glow.omni_range=0.7
	add_child(fuse_glow)
	set_fuse_power(false)

func set_fuse_power(on:bool):
	for material in fuse_materials:
		material.emission_enabled=on
		material.emission=Color(0.05,0.85,0.16)
		material.emission_energy_multiplier=1.8
	if fuse_glow: fuse_glow.visible=on

func refresh_prompt():
	if not town.actions.has("battery_panel"):return
	var label="Open high-voltage cabinet"
	if phase=="opening":label="Opening cabinet..."
	elif phase=="switching":label="Switching on..."
	elif energized:label="Workshop power is on"
	elif installed:label="Flip power switch"
	elif opened:label="Install workshop fuse"
	town.actions.battery_panel.label=label

func interact():
	if town.game.state!="play" or phase in ["opening","switching"]:return
	if energized:
		town.game.message="The workshop power is already on."
	elif not opened:
		phase="opening"
		phase_time=0
		animation.play("open")
		town.game.soundscape.storage_move(global_position,false,true)
	elif not installed:
		if town.inventory.workshop_fuse<=0:
			town.game.message="The cabinet needs the workshop fuse from the general store counter drawer."
			return
		town.inventory.workshop_fuse-=1
		installed=true
		get_parent().get_node("InstalledFuse").show()
		town.game.soundscape.feedback("pickup")
		town.game.enemies.arm_workshop_encounter()
		town.game.message="Fuse installed. Something is coming from Main Street. Flip the power switch."
	else:
		phase="switching"
		phase_time=0
		animation.play("pull")
	refresh_prompt()

func activate_power():
	if energized:return
	energized=true
	set_fuse_power(true)
	town.powered=true
	if town.game.town_changes:town.game.town_changes.power_restored()
	for light in town.powered_lights:light.show()
	town.game.soundscape.feedback("power")
	town.game.message="Workshop power restored. The signal-coil cabinet is released."

func _process(delta):
	if town.game.state!="play":return
	animation.advance(delta)
	if phase=="opening":
		phase_time+=delta
		# Source clips return to their start; hold at the open/on midpoints.
		if phase_time>=animation.get_animation("open").length/2:
			animation.seek(animation.get_animation("open").length/2,true)
			animation.advance(0)
			open_door=model.find_child("fuse_box_door",true,false).transform
			animation.pause()
			opened=true
			phase="open"
			refresh_prompt()
	elif phase=="switching":
		phase_time+=delta
		if phase_time>=animation.get_animation("pull").length/2:
			animation.seek(animation.get_animation("pull").length/2,true)
			animation.advance(0)
			animation.pause()
			phase="on"
			activate_power()
			refresh_prompt()
	if opened:model.find_child("fuse_box_door",true,false).transform=open_door
