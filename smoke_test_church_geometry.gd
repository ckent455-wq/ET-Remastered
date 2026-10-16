extends SceneTree
func _initialize(): call_deferred("check")
func points(node: Node, church: Node3D) -> PackedVector3Array:
	var result = PackedVector3Array()
	if node is MeshInstance3D:
		for point in node.mesh.get_faces(): result.append(church.to_local(node.to_global(point)))
	for child in node.get_children(): result.append_array(points(child,church))
	return result
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemies.set_physics_process(false)
	await physics_frame
	var church = game.town.streetscape.church
	var floor_count = 0
	var pew_count = 0
	var tower_count = 0
	for child in church.get_children():
		if child.name=="ContinuousChapelFloor": floor_count += 1
		var asset = child.get_meta("church_asset","")
		assert(asset not in ["front","nave","apse"],"No overlapping complete church modules")
		if asset=="pew":
			pew_count += 1
			var lowest = INF
			for point in points(child,church): lowest = minf(lowest,point.y)
			assert(absf(lowest)<0.002,"Pew feet touch floor")
		if asset=="bell_tower":
			tower_count += 1
			for point in points(child,church):
				if absf(point.z)<6.74:
					var ceiling = 8.32-absf(point.x)*(8.32-5.6)/4.75
					assert(point.y-ceiling>0.15,"Tower cannot hang through interior ceiling")
	assert(floor_count==1 and pew_count==8 and tower_count==1)
	for roof in ["ContinuousExteriorRoof","ContinuousInteriorCeiling"]:
		assert(church.get_node(roof).mesh.get_faces().size()==12,"One continuous roof; four triangles, no prefab seams")
	for index in range(2):
		var leaf = church.door_hinges[index].get_child(0)
		var lo = Vector3(INF,INF,INF)
		var hi = Vector3(-INF,-INF,-INF)
		for point in points(leaf,church): lo = lo.min(point); hi = hi.max(point)
		var side = -1 if index==0 else 1
		assert(absf(lo.y)<0.002 and absf(hi.y-2.7)<0.002,"Door reaches threshold and header")
		assert(absf(lo.x-(-1.4 if side<0 else 0.0))<0.003 and absf(hi.x-(0.0 if side<0 else 1.4))<0.003,"Leaf fits jamb and center seam")
	var cellar_leaf = church.basement.entry_hinge.get_node("NativeCellarDoorLeaf")
	var door_mesh = cellar_leaf.find_children("*","MeshInstance3D",true,false)[0]
	var door_material = door_mesh.get_surface_override_material(0)
	assert(door_material.albedo_texture.resource_path.ends_with("door_BLD_Doors1_A.png") and not door_material.uv1_triplanar,"Correct prefab door atlas, no wall mapping on either side")
	assert("Church1_Door_C.prefab" in cellar_leaf.get_meta("source_prefab"),"Existing local prefab supplies cellar door")
	var lo = Vector3(INF,INF,INF)
	var hi = Vector3(-INF,-INF,-INF)
	for point in points(cellar_leaf,church): lo = lo.min(point); hi = hi.max(point)
	assert(absf(lo.y)<0.002 and absf(hi.y-2.6)<0.002 and absf(hi.x-lo.x-1.7)<0.003,"Cellar prefab leaf fits jamb and header")
	print("PASS: single church shell/floor, continuous roofs, eight grounded native pews, roof-trimmed tower, exact door jamb/header fit")
	game.queue_free()
	await process_frame
	quit()
