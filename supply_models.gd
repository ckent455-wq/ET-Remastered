extends RefCounted
## Shared pickup and inventory geometry, in metres.
static func material(color: String, metallic = 0.0) -> StandardMaterial3D:
	var result=StandardMaterial3D.new()
	result.albedo_color=Color(color)
	result.metallic=metallic
	result.roughness=0.65
	return result

static func part(root: Node3D, mesh: Mesh, position: Vector3, surface: Material) -> MeshInstance3D:
	var node=MeshInstance3D.new()
	node.mesh=mesh
	node.position=position
	node.material_override=surface
	root.add_child(node)
	return node

static func box(root: Node3D, position: Vector3, size: Vector3, surface: Material):
	var mesh=BoxMesh.new()
	mesh.size=size
	return part(root,mesh,position,surface)

static func cylinder(root: Node3D, position: Vector3, radius: float, height: float, surface: Material):
	var mesh=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=16
	return part(root,mesh,position,surface)

static func build(id: String) -> Node3D:
	if id=="medkit":
		var holder=Node3D.new();holder.name="3DexterFirstAidCase"
		var imported=preload("res://assets/healing/healing_items.glb").instantiate()
		holder.add_child(imported)
		prepare_imported(imported)
		var bounds=AABB();var first=true
		for mesh in imported.find_children("*","MeshInstance3D",true,false):
			var part_bounds=mesh.transform*mesh.get_aabb()
			bounds=part_bounds if first else bounds.merge(part_bounds);first=false
			for surface in range(mesh.mesh.get_surface_count()):
				var material=mesh.get_active_material(surface)
				if material is StandardMaterial3D:material.albedo_color*=Color(0.72,0.76,0.67,1)
		var factor=0.30/bounds.size.x
		imported.scale=Vector3.ONE*factor
		imported.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
		return holder
	if id=="workshop_fuse":
		var holder=Node3D.new()
		holder.name="WorkshopFuse"
		var fuse=preload("res://assets/high_voltage/fuse.glb").instantiate()
		holder.add_child(fuse)
		fuse.position.y=-0.0105
		holder.scale=Vector3.ONE*1.35
		prepare_imported(fuse)
		return holder
	if id=="battery":
		var imported=load("res://assets/supplies/"+id+".glb").instantiate() as Node3D
		prepare_imported(imported)
		return imported
	var root=Node3D.new()
	root.name="Supply_"+id
	var steel=material("a7ada9",0.5)
	var dark=material("252c2a")
	var cream=material("e0d4b4")
	match id:
		"bandage":
			var gauze=material("d9d2b9")
			var roll=cylinder(root,Vector3(0,0.044,0),0.044,0.10,gauze)
			roll.rotation.z=PI/2
			for x in [-0.052,0.052]:
				var hollow=cylinder(root,Vector3(x,0.044,0),0.017,0.003,dark)
				hollow.rotation.z=PI/2
			for x in [-0.032,-0.01,0.012,0.034]:
				var seam=cylinder(root,Vector3(x,0.044,0),0.0448,0.002,cream)
				seam.rotation.z=PI/2
			box(root,Vector3(0.005,0.004,0.062),Vector3(0.085,0.006,0.065),gauze)
		"coil":
			var copper=material("b46f3b",0.5)
			var core=cylinder(root,Vector3.ZERO,0.075,0.31,dark)
			core.rotation.x=PI/2
			for z in [-0.16,0.16]:
				var flange=cylinder(root,Vector3(0,0,z),0.13,0.025,steel)
				flange.rotation.x=PI/2
			for i in range(11):
				var winding=TorusMesh.new()
				winding.inner_radius=0.07
				winding.outer_radius=0.115
				winding.rings=16
				winding.ring_segments=8
				var ring=part(root,winding,Vector3(0,0,-0.135+i*0.027),copper)
				ring.rotation.x=PI/2
			for x in [-0.07,0.07]: box(root,Vector3(x,-0.05,0.19),Vector3(0.018,0.018,0.10),copper)
	return root

static func prepare_imported(node: Node):
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var original=node.mesh.surface_get_material(i)
			if original is StandardMaterial3D:
				var surface=original.duplicate() as StandardMaterial3D
				surface.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				surface.shading_mode=BaseMaterial3D.SHADING_MODE_PER_VERTEX
				surface.metallic=0
				surface.roughness=0.85
				node.set_surface_override_material(i,surface)
	for child in node.get_children(): prepare_imported(child)
