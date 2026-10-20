extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false)
 var car=g.crash_site;car.set_process(false)
 g.reset_game();g.state="play"
 assert(g.health==25 and g.town.inventory.bandage==0,"Crash starts injured, without healing supplies")
 var case_model=preload("res://supply_models.gd").build("medkit")
 g.add_child(case_model)
 var case_bounds=AABB();var first=true
 var case_meshes=case_model.find_children("*","MeshInstance3D",true,false)
 assert(case_model.name=="3DexterFirstAidCase" and case_meshes.size()>=5,"Healing kits use the complete downloaded case, lid, clasps and hinges")
 for mesh in case_meshes:
  var part=(case_model.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
  case_bounds=part if first else case_bounds.merge(part);first=false
 assert(absf(case_bounds.size.x-0.30)<0.001 and absf(case_bounds.position.y)<0.001,"Case is correctly scaled and rests on its base")
 case_model.queue_free()
 assert(g.hud.injury_strength()>0 and car.wreck.find_child("CrashBloodSmear",true,false)!=null,"Crash has blood and visible injury feedback")
 assert(not car.tutorial_areas.has("crash_bandages"),"Bandage is packed inside the backpack, not a separate trunk pickup")
 car.interact_tutorial("crash_backpack")
 assert(g.town.inventory.bandage==0,"Closed trunk prevents collecting the backpack and its contents")
 car.interact_tutorial("crash_rear_hatch")
 await create_timer(0.8).timeout
 car.interact_tutorial("crash_backpack");car.interact_tutorial("crash_flashlight")
 assert(g.town.inventory.bandage==1,"Collecting the backpack includes its starting bandage")
 car.interact_tutorial("crash_backpack")
 assert(g.town.inventory.bandage==1,"Backpack contents cannot be collected twice")
 assert(not g.town.reached_town,"Finding your own bandage does not discover the town")
 assert(g.backpack.counts().bandage==1 and g.backpack.pack(g.backpack.counts()).any(func(item):return item.id=="bandage"),"Bandages occupy real backpack space")
 g.town.inventory.medkit=1
 var heal=InputEventKey.new();heal.keycode=KEY_H;heal.pressed=true;g._unhandled_input(heal)
 assert(g.health==35 and g.town.inventory.bandage==0 and g.town.inventory.medkit==1,"Bandage restores 10 health and H uses it before first-aid kits")
 g.town.use_healing();assert(g.health==85 and g.town.inventory.medkit==0,"First-aid kit restores 50 health")
 g.health=90;g.town.inventory.bandage=2
 g.town.use_bandage();assert(g.health==100 and g.town.inventory.bandage==1 and g.hud.injury_strength()==0,"Healing caps at full health and clears the blood overlay")
 g.town.use_bandage();assert(g.town.inventory.bandage==1,"Full health never wastes a roll")
 g.health=25;g.state="backpack"
 var entries=g.backpack.pack(g.backpack.counts())
 for i in range(entries.size()):
  if entries[i].id=="bandage":g.backpack.selected=i;break
 g.backpack.act("use");assert(g.health==35 and g.town.inventory.bandage==0,"Bandages can also be used directly from inventory")
 g.state="play";g.town.perform("clinic_drawer")
 assert(g.town.inventory.bandage==2,"Searching the clinic drawer supplies two more bandage rolls")
 g.town.perform("clinic_drawer");g.town.perform("clinic_drawer")
 assert(g.town.inventory.bandage==2,"Searching an empty drawer cannot duplicate bandages")
 g.reset_game();assert(g.health==25 and g.town.inventory.bandage==0 and not car.has_backpack,"Restart restores injury with supplies still inside the uncollected backpack")
 g.state="play";car.interact_tutorial("crash_rear_hatch");car.interact_tutorial("crash_backpack")
 assert(g.town.inventory.bandage==1,"A new journey restores the bandage inside the backpack")
 print("PASS: injured start, blood feedback, packed starting bandage, 10/50 healing, inventory, H priority, health caps, clinic supplies and restart")
 g.queue_free();await process_frame;quit()
