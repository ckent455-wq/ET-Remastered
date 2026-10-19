extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_physics_process(false);g.enemies.set_physics_process(false);g.weapons.set_physics_process(false);g.cemetery_shadow.set_physics_process(false)
 g.crash_site.wake_phase="";g.crash_site.has_backpack=true;g.state="play"
 var e=g.enemies;var tunnel=g.hotel_basement
 assert(e.TUNNEL_INDICES.size()==3 and e.creatures.size()==10)
 for index in e.TUNNEL_INDICES:
  var d=e.creatures[index]
  assert(d.visual.scene_file_path=="res://assets/enemies/wrapper/wrapper.glb")
  assert(d.state=="tunnel_wait" and d.hp==60 and tunnel.contains(d.actor.global_position))
  for mesh in d.visual.find_children("*","GeometryInstance3D",true,false):assert(mesh.layers==2,"Underground light layer")
 g.player.global_position=tunnel.to_global(Vector3(0,24,-21))
 e._physics_process(0.1)
 for index in e.TUNNEL_INDICES:assert(e.creatures[index].state=="tunnel_wait","Town above cannot trigger tunnel encounter")
 g.town.cemetery.unlocked=true;g.town.cemetery.opened=true
 g.player.global_position=g.town.cemetery.crypt.to_global(Vector3(0,0.01,0))
 g.town.perform("mausoleum_tunnel")
 assert(tunnel.contains(g.player.global_position))
 e._physics_process(0.1)
 for index in e.TUNNEL_INDICES:assert(e.creatures[index].state=="tunnel_wait","Arrival landing is safe")
 g.player.global_position=tunnel.to_global(Vector3(0,0.02,-26.8))
 await physics_frame;await physics_frame
 e._physics_process(0.01)
 var first=e.creatures[e.TUNNEL_INDICES[0]];var second=e.creatures[e.TUNNEL_INDICES[1]]
 assert(first.state=="tunnel_chase" and second.state=="tunnel_wait","Encounters activate separately")
 var start:Vector3=first.actor.global_position
 for frame in range(240):
  e._physics_process(1.0/60);await physics_frame
 assert(first.actor.global_position.distance_to(start)>1.0 and g.health<100,"Physical pursuit reaches real melee damage")
 assert(absf(tunnel.to_local(first.actor.global_position).y)<0.08,"Feet remain on tunnel floor")
 assert(not e.town_threat_active(),"Underground combat does not alarm unrelated surface NPCs")
 g.state="journal";start=first.actor.global_position
 for frame in range(20):e._physics_process(1.0/60)
 assert(first.actor.global_position==start,"Journal pauses movement")
 g.state="play";g.town.perform("hotel_tunnel_return")
 var hp=g.health
 for frame in range(30):e._physics_process(1.0/60);await physics_frame
 assert(g.health==hp and e.tunnel_encounter.inside(tunnel,first.actor.global_position),"Creature does not follow portal or attack from underground")
 g.player.global_position=tunnel.to_global(Vector3(0,0.02,-26.8))
 g.weapons.owned[0]=true;g.weapons.equip(0)
 g.weapons.enemy_hitboxes=preload("res://enemy_shot_hitboxes.gd").new(e)
 first.animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 for shot in range(3):
  first.animation.play(first.clips.idle1,0);first.animation.advance(0)
  g.camera.look_at(g.weapons.enemy_hitboxes.head_center(first))
  await physics_frame
  var before=first.hp
  g.weapons.magazines[0]=8;g.weapons.delay=0;g.weapons.aiming=true
  assert(g.weapons.fire() and first.hp==maxf(0,before-24),"Real aimed headshot damages tunnel Wrapper")
 assert(first.state=="dead" and first.actor.collision_layer==0)
 g.player.global_position=tunnel.to_global(Vector3(0,0.02,-21))
 await physics_frame;await physics_frame
 e._physics_process(0.01);assert(second.state=="tunnel_chase","Second encounter wakes further along passage")
 g.health=100;g.invincible=0
 for frame in range(360):e._physics_process(1.0/60);await physics_frame
 assert(g.health<100 and absf(tunnel.to_local(second.actor.global_position).y)<0.08,"Second monster pursues and attacks on floor")
 e.shoot(second.index,100)
 var third=e.creatures[e.TUNNEL_INDICES[2]]
 g.player.global_position=tunnel.to_global(Vector3(0,0.02,-6))
 await physics_frame;await physics_frame
 assert(third.state=="tunnel_wait" and not e.line_clear(third,g.player.global_position+Vector3.UP),"Cellar monster is concealed behind the storage screen")
 g.player.global_position=tunnel.to_global(Vector3(0,0.02,-3.3))
 await physics_frame;await physics_frame
 e._physics_process(0.01);assert(third.state=="tunnel_chase","Entering open cellar triggers hidden monster")
 g.health=100;g.invincible=0
 for frame in range(720):e._physics_process(1.0/60);await physics_frame
 assert(g.health<100 and third.tunnel_waypoint>=2,"Cellar monster routes around cover and lands a melee hit")
 assert(absf(tunnel.to_local(third.actor.global_position).y)<0.08)
 e.shoot(third.index,100)
 for frame in range(60):e._physics_process(1.0/60)
 for index in e.TUNNEL_INDICES:assert(e.creatures[index].visual.rotation.x< -1.4,"Wrapper falls on death")
 e._physics_process(150)
 for index in e.TUNNEL_INDICES:assert(e.creatures[index].state=="dead","Tunnel monsters stay dead this journey")
 g.reset_game()
 g.crash_site.wake_phase="";g.state="play"
 g.player.global_position=tunnel.to_global(Vector3(0,0.02,-26.8))
 first.actor.global_position=tunnel.to_global(Vector3(0,0.01,-22))
 second.actor.global_position=tunnel.to_global(Vector3(0,0.01,-21.1))
 first.state="tunnel_chase";second.state="tunnel_chase"
 await physics_frame;await physics_frame
 for frame in range(120):
  e._physics_process(1.0/60);await physics_frame
  assert(first.actor.global_position.distance_to(second.actor.global_position)>0.77,"Two active creatures do not interpenetrate")
  assert(e.tunnel_encounter.inside(tunnel,first.actor.global_position) and e.tunnel_encounter.inside(tunnel,second.actor.global_position),"Both remain between tunnel walls")
 g.reset_game()
 for index in e.TUNNEL_INDICES:
  var d=e.creatures[index]
  assert(d.state=="tunnel_wait" and d.hp==60 and d.actor.position==d.spawn and d.visual.rotation==Vector3.ZERO)
 print("PASS: three native Wrappers at entrance, midpoint and hidden far cellar, underground lighting, separate proximity triggers, safe portal arrival, physical pursuit and melee, grounded feet, journal pause, safe escape, three real headshots, falling death, no respawn and new-journey reset")
 g.queue_free();await process_frame;quit()
