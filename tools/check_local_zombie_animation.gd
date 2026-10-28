extends SceneTree
func _initialize():call_deferred("run")
func run():
 for variant in [1,2,3]:
  var m=load("res://assets/enemies/local_zombie/zombie_%d.glb" % variant).instantiate();root.add_child(m)
  var a=m.find_child("AnimationPlayer",true,false);var sk=m.find_child("Skeleton3D",true,false)
  a.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
  var head=sk.find_bone("Base HumanHead");assert(head>=0)
  assert(a.get_animation_list().size()==5)
  for clip in a.get_animation_list():
   a.play(clip);a.seek(0,true);a.advance(0);sk.force_update_all_bone_transforms();var first=sk.get_bone_global_pose(head)
   a.seek(.5,true);a.advance(0);sk.force_update_all_bone_transforms()
   assert(not first.is_equal_approx(sk.get_bone_global_pose(head)),"Imported animation actually moves the skeleton: "+str(variant)+" / "+clip)
  for mesh in m.find_children("*","MeshInstance3D",true,false):assert(mesh.mesh.surface_get_material(0).albedo_texture!=null)
  m.free()
 print("PASS: all three local zombie variants have textured meshes and five working animated clips")
 quit()
