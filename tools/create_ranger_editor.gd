extends SceneTree
func _initialize():call_deferred("run")
func own_all(node:Node,owner:Node):
 for child in node.get_children():
  child.owner=owner
  own_all(child,owner)
func strip(node:Node):
 node.set_script(null)
 node.scene_file_path=""
 for child in node.get_children():strip(child)
func furniture(node)->bool:
 if not node is Node3D or not node.is_visible_in_tree():return false
 return node.is_in_group("ApartmentKitFurniture") or node.is_in_group("RetroInteriorProps") or node.is_in_group("LocalInteriorProps") or node.name in ["ranger_cabinet","ranger_drawer"]
func run():
 var path="res://editing/ranger_layout.tscn"
 if FileAccess.file_exists(path) and not "--rebuild-ranger-editor" in OS.get_cmdline_user_args():print("Ranger editor scene already exists; keeping your edits.");quit();return
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 var source=g.town.buildings.ranger
 var scene=Node3D.new();scene.name="RangerLayout";root.add_child(scene)
 var shell=Node3D.new();shell.name="RoomShell_REFERENCE";shell.set_meta("_edit_lock_",true);scene.add_child(shell)
 var movable=Node3D.new();movable.name="Furniture";scene.add_child(movable)
 var count=0
 for node in source.get_children():
  if not node is Node3D or node is CharacterBody3D:continue
  var selected=furniture(node)
  # Skip roof and ceiling in the editor cutaway. Their gameplay geometry stays intact.
  if not selected and node.position.y>=2.98:continue
  var clone=node.duplicate(0);strip(clone)
  if selected:
   movable.add_child(clone)
   var asset=str(node.get_meta("apartment_asset",node.get_meta("retro_asset",node.name)))
   clone.name=(asset.capitalize().replace(" ","_")+"_%02d" % count)
   clone.set_meta("_edit_group_",true)
   clone.set_meta("runtime_index",node.get_index());clone.set_meta("runtime_asset",asset)
   clone.set_meta("editor_description","Move/rotate this furniture root. Save this scene, then restart the game to apply it.")
   count+=1
  else:
   shell.add_child(clone)
   clone.set_meta("_edit_lock_",true)
 var environment=WorldEnvironment.new();environment.name="EditorLighting";environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("30383e")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("d0d4cf");environment.environment.ambient_light_energy=0.8
 scene.add_child(environment)
 var sun=DirectionalLight3D.new();sun.name="EditorLight";sun.rotation_degrees=Vector3(-60,-25,0);sun.light_energy=0.8;scene.add_child(sun)
 own_all(scene,scene)
 var packed=PackedScene.new();assert(packed.pack(scene)==OK)
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://editing"))
 assert(ResourceSaver.save(packed,path)==OK)
 print("PASS: created editable ranger with ",count," furniture roots and a cutaway reference shell")
 scene.free();g.queue_free();await process_frame;quit()
