extends Node
## Per-creature low-pass buses let walls muffle voices, pounding and footsteps together.
var game
var sources={}
var sample_time=0.0
func register(data):
 var name="MonsterSpatial_"+str(get_instance_id())+"_"+str(data.index)
 AudioServer.add_bus();var index=AudioServer.bus_count-1
 AudioServer.set_bus_name(index,name);AudioServer.set_bus_send(index,game.soundscape.BUS)
 var filter=AudioEffectLowPassFilter.new();filter.cutoff_hz=20000;filter.resonance=.5
 AudioServer.add_bus_effect(index,filter)
 data.voice.bus=name
 var step=game.soundscape.spatial_voice(data.actor,game.soundscape.step_banks.concrete[0],-12,20)
 step.name="MonsterFootsteps";step.position.y=.15;step.unit_size=3
 step.bus=name;step.set_meta("runtime_visual_only",true)
 sources[data.index]={"bus":name,"filter":filter,"step":step,"previous":data.actor.global_position,"distance":0.0,"blocked":0.0,"mix":0.0,"last_step":-1}
func obstruction(data)->float:
 var listener:Vector3=game.camera.global_position
 var source:Vector3=data.actor.global_position+Vector3.UP*1.1
 if listener.distance_to(source)>45:return 0.0
 var blocked=0.0
 for height in [-.22,0.0,.22]:
  var query=PhysicsRayQueryParameters3D.create(listener,source+Vector3.UP*height,1,[game.player.get_rid(),data.actor.get_rid()])
  if not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty():blocked+=1.0
 return blocked/3.0
func surface(data)->String:
 var p:Vector3=data.actor.global_position
 var query=PhysicsRayQueryParameters3D.create(p+Vector3.UP*.35,p-Vector3.UP*.55,1,[data.actor.get_rid(),game.player.get_rid()])
 var hit=game.get_world_3d().direct_space_state.intersect_ray(query)
 return str(hit.collider.get_meta("footstep_surface","concrete")) if not hit.is_empty() else "grass"
func update_steps(data,source:Dictionary):
 var p:Vector3=data.actor.global_position
 var distance:float=Vector2(p.x,p.z).distance_to(Vector2(source.previous.x,source.previous.z))
 source.previous=p
 if data.hp<=0 or not data.actor.visible or distance>2.0:
  source.distance=0.0;source.step.stop();return
 source.distance+=distance
 if distance<.001 or source.distance<.95:return
 source.distance=fmod(source.distance,.95)
 var bank:Array=game.soundscape.step_banks.get(surface(data),game.soundscape.step_banks.concrete)
 var choice=randi()%bank.size()
 if choice==source.last_step and bank.size()>1:choice=(choice+1)%bank.size()
 source.last_step=choice;source.step.stream=bank[choice]
 source.step.pitch_scale=randf_range(.83,.94) if game.enemies.is_mummy(data.index) else randf_range(.92,1.04)
 source.step.play()
func _physics_process(delta):
 if not game.surface_details.completed or not game.hotel_upper.ready_layout:return
 sample_time-=delta
 var sample=sample_time<=0.0
 if sample:sample_time=.12
 for data in game.enemies.creatures:
  if not sources.has(data.index):register(data)
  var source:Dictionary=sources[data.index]
  if game.enemies.door_encounter.voices.has(data.index):game.enemies.door_encounter.voices[data.index].bus=source.bus
  if game.state!="play":
   source.previous=data.actor.global_position;source.distance=0.0;source.step.stop();continue
  if sample:source.blocked=obstruction(data)
  source.mix=move_toward(source.mix,source.blocked,delta*4.0)
  source.filter.cutoff_hz=lerpf(20000.0,900.0,source.mix)
  var index=AudioServer.get_bus_index(source.bus)
  if index>=0:AudioServer.set_bus_volume_db(index,-9.0*source.mix)
  update_steps(data,source)
func _exit_tree():
 for source in sources.values():
  var index=AudioServer.get_bus_index(source.bus)
  if index>=0:AudioServer.remove_bus(index)
