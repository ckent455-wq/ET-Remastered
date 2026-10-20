extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false)
 g.reset_game();g.state="play";g.crash_site.has_backpack=true
 var previous=Vector3.ZERO
 for health in [100,90,75,50,35,25,10,1,0]:
  g.health=health
  var opacity=g.hud.blood_opacities()
  assert(opacity.x>=previous.x and opacity.y>=previous.y and opacity.z>=previous.z,"Every blood layer increases monotonically as health falls")
  assert(is_equal_approx(g.hud.injury_strength(),1.0-health/100.0),"Blood severity uses the same health value as the bar")
  previous=opacity
 for texture in [g.hud.BLOOD_BORDER,g.hud.BLOOD_CRITICAL,g.hud.BLOOD_DROPS]:
  var img=texture.get_image()
  if img.is_compressed():img.decompress()
  assert(img.get_pixel(img.get_width()/2,img.get_height()/2).a<0.01,"Downloaded overlay keeps the aiming centre transparent")
 g.health=25;var wounded=g.hud.blood_opacities()
 g.town.inventory.bandage=1;g.town.use_bandage()
 assert(g.health==35 and g.hud.blood_opacities().x<wounded.x and g.hud.blood_opacities().y<wounded.y,"Bandaging reduces blood as the bar rises")
 g.town.inventory.medkit=2;g.town.use_medkit()
 assert(g.health==85 and g.hud.blood_opacities().x<wounded.x,"Medpack recovery reduces blood")
 g.town.use_medkit();assert(g.health==100 and g.hud.blood_opacities()==Vector3.ZERO,"Full recovery clears every layer")
 g.health=75;g.invincible=0;var before=g.hud.blood_opacities()
 assert(g.take_damage(20) and g.health==55 and g.hud.blood_opacities().x>before.x,"Real damage increases blood immediately")
 g.health=-10;assert(g.hud.injury_strength()==1)
 g.health=110;assert(g.hud.injury_strength()==0)
 g.reset_game();assert(g.health==25 and g.hud.blood_opacities().y>0,"Opening crash starts with the appropriate blood severity")
 print("PASS: health-driven blood layers, monotonic severity, transparent aim area, real damage, bandages, medpacks, full recovery, bounds and restart")
 g.queue_free();await process_frame;quit()
