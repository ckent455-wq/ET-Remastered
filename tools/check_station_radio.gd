extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.set_physics_process(false);g.controller.set_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 await create_timer(0.2).timeout
 g.crash_site.wake_phase="";g.state="play";g.crash_site.has_flashlight=true;g.crash_site.has_backpack=true
 var receiver=g.town.actions.receiver.area
 var model=receiver.get_node("BlackwoodVintageRadio")
 var bounds=AABB();var first=true;var surfaces=0
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  var b=mesh.global_transform*mesh.mesh.get_aabb()
  bounds=b if first else bounds.merge(b);first=false
  for i in range(mesh.mesh.get_surface_count()):
   var m=mesh.get_active_material(i)
   assert(m.roughness==1 and m.metallic==0 and m.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS)
   surfaces+=1
 print("RADIO BOUNDS ",bounds)
 assert(bounds.size.y>0.5 and bounds.size.y<0.7 and maxf(bounds.size.x,bounds.size.z)>1.0 and maxf(bounds.size.x,bounds.size.z)<1.3)
 assert(absf(bounds.position.y-0.88)<0.04,"Radio feet sit on desktop")
 g.player.global_position=g.town.buildings.radio.to_global(Vector3(-2.3,0.02,-1.75))
 g.camera.global_position=g.player.global_position+Vector3(0,1.35,0)
 g.camera.look_at(receiver.global_position)
 g.camera.make_current();g.hud.queue_redraw()
 g.soundscape.atmosphere.update_sound(1)
 assert(g.soundscape.atmosphere.radio.global_position==receiver.global_position)
 assert(g.soundscape.atmosphere.radio_voices.global_position==receiver.global_position)
 await physics_frame;await physics_frame
 g.town.refresh_focus();assert(g.town.focus_action=="receiver","Crosshair reaches receiver interaction")
 g.town.inventory.coil=1;g.town.inventory.tuner=1;g.town.inventory.antenna=1
 g.town.perform("receiver");assert(g.town.radio_ready and g.town.receiver_light.light_energy==2)
 print("PASS: vintage radio bounds ",bounds,"; retro materials ",surfaces,"; placement, receiver focus, repair and both audio anchors")
 if DisplayServer.get_name()!="headless":
  await create_timer(1).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("C:/Users/jkern/Documents/Codex/2026-10-21/b/outputs/radio-in-game.png")
 g.queue_free();await process_frame;quit()
