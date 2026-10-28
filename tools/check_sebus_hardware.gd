extends SceneTree
var g
func _initialize():call_deferred("run")
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.set_process(false);g.set_process_input(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 while not g.surface_details.completed:await process_frame
 g.reset_game();g.crash_site.wake_phase="";g.crash_site.release_seated_camera();g.crash_site.has_backpack=true;g.crash_site.has_flashlight=true;g.story.clinic_rescue_done=true;g.health=100;g.set_state("play")
 var shop=g.town.streetscape.sebus
 # Audit the entire opening sweep against conservative bounds of every junk mesh.
 var obstacles=StaticBody3D.new();root.add_child(obstacles);obstacles.collision_layer=1<<19;obstacles.collision_mask=0
 for holder in shop.props:
  for mesh in holder.find_children("*","MeshInstance3D",true,false):
   var bounds=mesh.get_aabb();var shape=BoxShape3D.new();shape.size=bounds.size
   var collision=CollisionShape3D.new();collision.shape=shape;obstacles.add_child(collision)
   collision.global_transform=mesh.global_transform*Transform3D(Basis.IDENTITY,bounds.get_center())
 await physics_frame
 for step in 66:
  shop.hinge.rotation.y=float(step)*.01
  for mesh in shop.leaf.find_children("*","MeshInstance3D",true,false):
   var bounds=mesh.get_aabb();var shape=BoxShape3D.new();shape.size=bounds.size
   var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1<<19
   query.transform=mesh.global_transform*Transform3D(Basis.IDENTITY,bounds.get_center())
   assert(root.world_3d.direct_space_state.intersect_shape(query).is_empty(),"Door must clear all junk throughout its swing")
 obstacles.queue_free();shop.hinge.rotation.y=0
 shop.interact();shop._process(2.0)
 assert(shop.opened and is_equal_approx(shop.hinge.rotation.y,.65))
 assert(g.state=="dialogue" and g.dialogue_text=="I can't get in, it's too cluttered.")
 g.set_state("play")
 await physics_frame
 # Walk, strafe and jump the real player against the full doorway, not just straight ray sweeps.
 for height in [g.STANDING_HEIGHT,g.CROUCH_HEIGHT]:
  g.player_collider.shape.height=height;g.player_collider.position.y=height/2
  for start_x in [-1.2,-.6,0.0,.6,1.2]:
   for strafe in [-2.0,0.0,2.0]:
    g.player.global_position=shop.to_global(Vector3(start_x,.04,4.9))
    for tick in 45:
     await physics_frame
     g.player.velocity=shop.global_basis*Vector3(strafe,0,-5)
     g.player.move_and_slide()
     assert(shop.to_local(g.player.global_position).z>=4.15,"Player must stay outside even when sliding around the pile")
  g.player.global_position=shop.to_global(Vector3(.65,1.2,4.9))
  for tick in 30:
   await physics_frame
   g.player.velocity=shop.global_basis*Vector3(0,0,-5);g.player.move_and_slide()
   assert(shop.to_local(g.player.global_position).z>=4.15,"Jumping cannot bypass the shop blocker")
 g.player_collider.shape.height=g.STANDING_HEIGHT;g.player_collider.position.y=g.STANDING_HEIGHT/2
 # Sweep the actual player capsule through every lateral part of the doorway.
 var capsule=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.75
 for x in [-.65,-.3,0.0,.3,.65]:
  var query=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.exclude=[g.player.get_rid()]
  query.transform=Transform3D(Basis.IDENTITY,shop.to_global(Vector3(x,.91,4.8)))
  query.motion=shop.global_basis*Vector3(0,0,-2)
  var hit=root.world_3d.direct_space_state.cast_motion(query)
  assert(hit[0]<.4,"Door and physical pile block passage through the shop entrance")
 var saved=g.saves.backend.capture();assert(g.saves.backend.valid(saved));shop.reset();g.saves.backend.apply(saved)
 assert(shop.opened and is_equal_approx(shop.hinge.rotation.y,.65),"Open door persists")
 shop.interact();shop._process(2.0);assert(not shop.opened and shop.hinge.rotation.y==0)
 var f=FileAccess.open("C:/Users/jkern/Documents/Codex/2026-10-16/go-x20/work/pre-zombie-save.bin",FileAccess.READ)
 var old=f.get_var();f.close();assert(g.saves.backend.valid(old));g.saves.backend.apply(old)
 assert(not shop.opened,"Older journeys start with the optional hardware door closed")
 g.set_state("play");shop.interact();shop._process(2)
 g.player.global_position=shop.to_global(Vector3(.75,.03,6.1));g.player.rotation=Vector3.ZERO;g.camera.position=Vector3(0,g.STANDING_EYE,0)
 g.camera.look_at(shop.to_global(Vector3(0,1.4,3.15)));g.camera.make_current();g.flashlight.show();g.message=""
 for i in 12:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("C:/Users/jkern/Documents/Codex/2026-10-16/go-x20/outputs/sebus-doorway.png")
 print("PASS: Sebus opens inward against clutter, capsule cannot pass, closes again, new save roundtrip and genuine old-save compatibility")
 quit()
