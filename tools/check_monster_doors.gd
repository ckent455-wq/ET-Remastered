extends SceneTree
func _initialize():call_deferred("run")
func setup_enemy(g,index,id):
 var d=g.enemies.creatures[index]
 d.hp=60;d.state="tunnel_chase" if index in g.enemies.TUNNEL_INDICES else "chase"
 d.actor.global_position=g.town.buildings[id].to_global(Vector3(0,0.01,6.25))
 d.actor.collision_layer=1;d.actor.collision_mask=1
 g.player.global_position=g.town.buildings[id].to_global(Vector3(0,0.01,3.0))
 g.enemies.door_encounter.clear_attempt(d)
 return d
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.town.townspeople.set_physics_process(false)
 g.state="play";g.crash_site.wake_phase=""
 var h=g.enemies.door_encounter;var door=g.town.doors.workshop
 var d=setup_enemy(g,3,"workshop")
 await physics_frame;await physics_frame
 for i in range(35):
  assert(h.update(g.enemies,d,0.1));await physics_frame
 assert(not door.open and d.door_hits>=3,"Loud repeated pounding precedes opening")
 var v=h.voices[d.index]
 assert(v.volume_db==2 and v.max_distance==32 and v.bus==g.soundscape.BUS)
 assert(v.global_position.distance_to(g.town.doorway_position("workshop"))<1.2,"Sound comes from actual door")
 for i in range(8):h.update(g.enemies,d,0.1);await physics_frame
 assert(door.open,"Unlocked town door forced after delay")
 for i in range(100):h.update(g.enemies,d,1.0/60);await physics_frame
 assert(g.town.buildings.workshop.to_local(d.actor.global_position).z<5,"Monster physically crosses breached doorway")
 assert(not g.town.set_building_door("workshop",false,true),"NPC cannot instantly cancel breach")
 assert(g.town.set_building_door("workshop",false,false,true),"Player can still manually close breached door")
 await create_timer(0.65).timeout
 d.actor.global_position=Vector3(0,0,-20)
 d=setup_enemy(g,7,"workshop")
 for i in range(48):h.update(g.enemies,d,0.1);await physics_frame
 assert(not door.open,"Mummy takes longer than town monster")
 for i in range(10):h.update(g.enemies,d,0.1);await physics_frame
 assert(door.open and not door.collision.disabled,"Mummy begins slow physical door push")
 await create_timer(1.8).timeout
 assert(door.collision.disabled and absf(door.hinge.rotation.y-1.55)<0.01)
 # A key in the player's pocket does not itself mean a door has already been unlocked.
 g.town.inventory.station_key=1
 d=setup_enemy(g,3,"radio")
 for i in range(85):h.update(g.enemies,d,0.1);await physics_frame
 assert(not g.town.doors.radio.open and not g.town.doors.radio.unlocked,"Locked station withstands monster")
 g.state="paused";h.update_audio(g)
 assert(not v.playing or v.stream_paused,"Pause stops ongoing pounding")
 g.state="play";g.town.set_building_door("radio",true)
 assert(g.town.doors.radio.unlocked)
 # Killing or losing the target cancels a partially completed attempt.
 d.hp=0;assert(not h.update(g.enemies,d,0.1) and d.door_effort==0)
 g.enemies.reset();assert(h.held_open.is_empty())
 print("PASS: delayed repeated loud spatial pounding, town breach, slow mummy push, locked door protection, NPC/player closure, pause and reset")
 g.queue_free();await process_frame;quit()
