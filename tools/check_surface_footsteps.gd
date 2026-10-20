extends SceneTree
func _initialize():call_deferred("run")
func surface(g,p:Vector3,expected:String):
 g.player.global_position=p
 await physics_frame;await physics_frame
 var found=preload("res://footstep_surfaces.gd").sample(g)
 assert(found==expected,"Expected %s at %s, found %s" % [expected,p,found])
 g.soundscape.step_distance=0;g.soundscape.moved(2.1,false,true)
 assert(g.soundscape.last_step_surface==expected,"Movement chooses the matching bank")
 var node=g.soundscape.steps[(g.soundscape.next_step+2)%3]
 assert(node.stream in g.soundscape.step_banks[expected] and node.playing,"Actual step plays a downloaded surface clip")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.controller.set_process(false);g.town.townspeople.set_physics_process(false)
 g.soundscape.set_process(false);g.reset_game();g.crash_site.wake_phase="";g.state="play"
 var count=0
 for bank in g.soundscape.step_banks.values():
  count+=bank.size()
  for clip in bank:assert(clip is AudioStreamOggVorbis and clip.get_length()>0 and not clip.loop,"Original OGG one-shots imported")
 assert(count==40 and g.soundscape.step_banks.size()==8)
 await surface(g,Vector3(-4,0,5),"grass")
 await surface(g,Vector3(0,0,-35),"concrete")
 await surface(g,Vector3(-5,0,-64),"concrete")
 await surface(g,Vector3(18.3,0,-58),"concrete")
 await surface(g,g.town.buildings.ranger.to_global(Vector3(0,0.1,0)),"wood")
 await surface(g,g.town.streetscape.church.to_global(Vector3(0,0.1,0)),"wood")
 await surface(g,g.hotel_basement.to_global(Vector3(0,0.1,0)),"stone")
 await surface(g,g.grave_dig.GRAVE+Vector3(0,0.01,0),"dirt")
 var hill=g.town.streetscape.chapel_hill
 var middle=hill.samples.size()/2
 var road:Vector3=hill.samples[middle]
 await surface(g,road+Vector3(0,0.05,0),"concrete")
 var shoulder=road+hill.road_sides[middle]*(hill.road_width(middle)+0.22)
 shoulder.y=hill.terrain_height_at(shoulder)+0.05
 await surface(g,shoulder,"gravel")
 # Controlled supporting bodies exercise non-ground surfaces without relying on prop placement.
 for kind in ["metal","stairs"]:
  var body=g.town.box(g,Vector3(45,2,-40),Vector3(2,0.2,2),g.town.mats.metal)
  body.set_meta("footstep_surface",kind)
  await surface(g,Vector3(45,2.12,-40),kind)
  body.free();await physics_frame
 await surface(g,Vector3(-4,0,5),"grass")
 for i in range(15):
  var previous=g.soundscape.last_step
  g.soundscape.moved(2.1,false,true)
  assert(previous!=g.soundscape.last_step,"No adjacent repeated sample on a surface")
 var next=g.soundscape.next_step
 g.soundscape.moved(10,false,false);g.soundscape.moved(0,false,true)
 assert(g.soundscape.next_step==next and g.soundscape.step_distance==0,"Airborne and stationary movement stays silent")
 g.state="paused";g.soundscape.moved(10,false,true);assert(g.soundscape.next_step==next,"Menus cannot trigger footsteps")
 g.reset_game();assert(g.soundscape.last_surface_steps.is_empty(),"New journey clears surface history")
 print("PASS: forty surface clips, actual road/sidewalk/wood/cellar/dirt/hill/gravel support, metal/stairs, real playback, variation, silence and reset")
 g.queue_free();await process_frame;quit()
