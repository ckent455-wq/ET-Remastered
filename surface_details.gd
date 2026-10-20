extends Node
## One startup pass: shared paper presentation and support-aware placement of visible props.
var game
var completed=false
var paper_count=0
var adjustments: Array[String] = []
var seen: Dictionary = {}
var support_meshes: Array[MeshInstance3D] = []
func _ready(): call_deferred("apply_details")
func meshes_under(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if node is MeshInstance3D and node.is_visible_in_tree(): meshes.append(node)
	for child in node.get_children(): meshes.append_array(meshes_under(child))
	return meshes
func bounds_of(node: Node3D) -> AABB:
	var box=AABB()
	var first=true
	for mesh in meshes_under(node):
		var part: AABB=mesh.global_transform*mesh.mesh.get_aabb()
		box=part if first else box.merge(part)
		first=false
	return box
func rest_on_surface(node: Node3D, label: String, max_drop=1.2):
	if not node.is_visible_in_tree(): return
	var bounds=bounds_of(node)
	if bounds.size.length_squared()<0.00001: return
	var center=bounds.get_center()
	var start=Vector3(center.x,bounds.position.y+0.10,center.z)
	var highest=-INF
	# Use the visible mesh surface: shelf and tabletop collision often uses a simplified box.
	for mesh in support_meshes:
		if not is_instance_valid(mesh) or not mesh.is_visible_in_tree() or node==mesh or node.is_ancestor_of(mesh): continue
		if mesh.get_world_3d()!=game.get_world_3d():continue
		var box: AABB=mesh.global_transform*mesh.mesh.get_aabb()
		if start.x<box.position.x or start.x>box.end.x or start.z<box.position.z or start.z>box.end.z:continue
		if box.position.y>start.y or box.end.y<start.y-max_drop:continue
		var faces=mesh.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var a: Vector3=mesh.global_transform*faces[i]
			var b: Vector3=mesh.global_transform*faces[i+1]
			var c: Vector3=mesh.global_transform*faces[i+2]
			var normal=(b-a).cross(c-a).normalized()
			if absf(normal.y)<0.7:continue
			var hit=Geometry3D.ray_intersects_triangle(start,Vector3.DOWN,a,b,c)
			if hit!=null and hit.y>=start.y-max_drop:highest=maxf(highest,hit.y)
	if highest== -INF:return
	var shift=highest+0.002-bounds.position.y
	if absf(shift)<0.006 or shift>0.105:return
	# A document belongs on furniture, never dropped a whole metre onto the floor.
	if node.name=="RealisticPaperNote" and shift< -0.35:return
	node.global_position.y+=shift
	adjustments.append(label+" "+str(snappedf(shift,0.001))+"m")
func pickup_visual(area: Area3D) -> Node3D:
	var root=Node3D.new()
	root.name="SupportedPickupVisual"
	area.add_child(root)
	for child in area.get_children():
		if child==root or child is CollisionShape3D or child is Light3D:continue
		if child is Node3D: child.reparent(root,false)
	return root
func apply_details():
	await get_tree().physics_frame
	for id in game.town.actions:
		var data=game.town.actions[id]
		if data.kind!="note":continue
		var area: Area3D=data.area
		for child in area.get_children():
			if child is CollisionShape3D:continue
			if child is Node3D:child.hide()
			child.queue_free()
		var paper=preload("res://paper_note.gd").build(data.title)
		area.add_child(paper)
		paper_count+=1
		if id=="cemetery_note":
			paper.rotation=Vector3(PI/2,-PI/2,0)
			paper.position.x=-0.045
			game.town.box(area,Vector3(0.025,-0.5,0),Vector3(0.07,1.2,0.06),game.town.mats.wood,false)

	await get_tree().process_frame
	support_meshes=meshes_under(game)
	for group in ["LocalInteriorProps","ApartmentKitFurniture"]:
		for object in get_tree().get_nodes_in_group(group):
			if seen.has(object.get_instance_id()): continue
			seen[object.get_instance_id()]=true
			var asset: String=object.get_meta("apartment_asset",object.get_meta("source_asset",""))
			if asset in ["curtain","door","wall_art","wall_cabinet","lamp","sink"]:continue
			rest_on_surface(object,"prop "+asset,0.6)
	for object in get_tree().get_nodes_in_group("RetroInteriorProps"):
		if object.get_meta("retro_asset") in ["cutting_board","knife","plate","burner"]:
			rest_on_surface(object,"retro clutter",0.12)
	for id in game.town.actions:
		var data=game.town.actions[id]
		if data.kind=="note" and id!="cemetery_note":
			var paper: Node3D=data.area.get_node("RealisticPaperNote")
			rest_on_surface(paper,id)
			data.area.position.y+=paper.position.y
			paper.position.y=0
	for id in game.town.actions:
		var data=game.town.actions[id]
		if data.kind in ["item","weapon","ammo","cellar_part"] and data.area.is_visible_in_tree() and not id.begins_with("crash_") and not data.get("authored_placement",false):
			var visual=pickup_visual(data.area)
			if id=="cemetery_cellar_key": visual.position.x+=0.25
			rest_on_surface(visual,id)
	if game.hotel_basement: game.town.streetscape.church.basement.prepare_cellar_lighting(game.hotel_basement)
	game.town.cemetery.fit_cellar_key_target()
	completed=true
	print("PAPER AND SUPPORT PASS: ",paper_count," notes; ",adjustments)
