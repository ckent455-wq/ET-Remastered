extends Node3D
## Shared knife weapon with independent physical pickups in the hotel and workshop.
const SLOT=-2
const COST=14.0
const REACH=1.8
const HIT_RADIUS=0.18
const DAMAGE=28.0
const RECOVERY=0.48
const HIT_TIME=0.15
var game
var source:Node3D
var area:Area3D
var collision:CollisionShape3D
var pickups={}
var held:Node3D
var elapsed=-1.0
var struck=false
func _ready():
 name="HotelKnifeWeapon"
 for location in [["hotel_knife","house"],["workshop_knife","workshop"]]:
  var prop:Node3D
  for node in game.town.buildings[location[1]].get_children():
   if node.get_meta("retro_asset","")=="knife":prop=node;break
  assert(prop!=null)
  var target=Area3D.new();target.name=location[0];target.collision_layer=2;target.collision_mask=0;target.monitoring=false;target.monitorable=false;target.set_meta("action_id",location[0]);add_child(target)
  var shape=CollisionShape3D.new();shape.shape=BoxShape3D.new();target.add_child(shape)
  pickups[location[0]]={"source":prop,"area":target,"collision":shape}
  game.town.actions[location[0]]={"kind":"hotel_knife","label":"Take kitchen knife","area":target,"taken":false}
 source=pickups.hotel_knife.source;area=pickups.hotel_knife.area;collision=pickups.hotel_knife.collision
 held=Node3D.new();held.name="HeldHotelKnife";game.camera.add_child(held)
 var model=preload("res://assets/retro_props/knife.glb").instantiate();held.add_child(model);game.weapons.adapt(model)
 # Native model is 28cm long. Center it and present the broad blade toward the camera.
 var bounds=game.town.apartment_interiors.retro.bounds(model,held)
 model.position=-bounds.get_center()
 model.basis=Basis(Vector3(0,0.66,0.75).normalized(),Vector3.RIGHT,Vector3(0,0.75,-0.66).normalized())
 model.scale=Vector3.ONE*1.12
 sync()
func owned()->bool:return game.town.inventory.get("knife",0)>0
func pickup_focus(start:Vector3,finish:Vector3)->String:
 var result=""
 var nearest=INF
 for id in pickups:
  if game.town.actions[id].taken:continue
  var bounds=game.surface_details.bounds_of(pickups[id].source).grow(0.035)
  var point=bounds.intersects_segment(start,finish)
  if point==null:continue
  var query=PhysicsRayQueryParameters3D.create(start,finish,1,[game.player.get_rid()])
  var hit=get_world_3d().direct_space_state.intersect_ray(query)
  if not hit.is_empty() and bounds.intersects_segment(start,hit.position)==null:continue
  var distance=start.distance_to(point)
  if distance<nearest:nearest=distance;result=id
 return result
func reset():
 elapsed=-1;struck=false
 if area:sync()
func sync():
 var have=owned()
 for id in pickups:
  var data=pickups[id]
  var taken=game.town.actions[id].taken
  data.source.visible=not taken
  if not taken:
   var box=game.surface_details.bounds_of(data.source)
   if box.size.length()>0:
    data.area.global_transform=Transform3D(Basis.IDENTITY,box.get_center())
    data.collision.shape.size=box.size+Vector3(0.12,0.12,0.12)
  data.area.visible=not taken
  data.area.collision_layer=0 if taken else 2
 held.visible=have and game.weapons.selected==SLOT and game.state in ["play","paused","backpack"]
 if game.weapons.selected==SLOT:
  game.arm_visual.hide()
  game.flashlight_model.hide()
func collect(id:String="hotel_knife")->bool:
 if game.state!="play" or not pickups.has(id) or game.town.actions[id].taken:return false
 if not game.crash_site.has_backpack:game.message="Collect your backpack before taking the knife.";return false
 if not game.backpack.room_for("knife"):game.message="Your backpack is full. The knife needs two slots.";return false
 game.town.inventory["knife"]+=1
 game.town.actions[id].taken=true
 game.soundscape.feedback("pickup")
 game.message="Kitchen knife collected. 4 equips it; attack uses stamina."
 game.weapons.equip(SLOT);sync();game.hud.queue_redraw()
 return true
func attack()->bool:
 if game.state!="play" or not owned() or game.weapons.selected!=SLOT:return false
 if elapsed>=0 or game.weapons.delay>0 or game.grave_dig.digging:return false
 if game.stamina<COST:game.message="Too exhausted to stab.";return false
 game.stamina-=COST;elapsed=0;struck=false;game.weapons.delay=RECOVERY
 return true
func strike():
 var origin=game.camera.global_position
 var hit={}
 var nearest=INF
 # Cover the blade's path from eye level down to the held stabbing height.
 # Each trace still stops at solid cover; one stab resolves only one impact.
 for height in [0.0,0.2,0.4]:
  var start=origin-game.camera.global_basis.y*height
  var contact=game.weapons.trace_shot(start,-game.camera.global_basis.z,REACH,HIT_RADIUS)
  if not contact.is_empty() and contact.collider.is_in_group("HostileEnemies") and not clear_contact(start,contact.collider):continue
  if not contact.is_empty() and start.distance_to(contact.position)<nearest:
   nearest=start.distance_to(contact.position);hit=contact
 if hit.is_empty():return
 var body=hit.collider
 if body.is_in_group("HostileEnemies"):
  if game.enemies.shoot(int(body.get_meta("enemy_index")),DAMAGE,18.0):game.weapons.hit_feedback=0.18
 elif body.is_in_group("TownNPCs"):
  if game.town.townspeople.shoot(str(body.get_meta("npc_id",""))):game.weapons.hit_feedback=0.18
 elif body.has_meta("shooting_target"):
  body.set_meta("hits",int(body.get_meta("hits",0))+1);game.weapons.hit_feedback=0.18
func clear_contact(start:Vector3,body:Node3D)->bool:
 # The forgiving contact radius must never reach through a closed door or wall.
 var target=body.global_position+Vector3.UP*clampf(start.y-body.global_position.y,0.3,1.7)
 var excludes:Array[RID]=[game.player.get_rid()]
 for data in game.enemies.creatures:excludes.append(data.actor.get_rid())
 var query=PhysicsRayQueryParameters3D.create(start,target,1,excludes)
 return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
func _process(delta):
 if game.state=="play" and elapsed>=0:
  elapsed+=delta
  if elapsed>=HIT_TIME and not struck:struck=true;strike()
  if elapsed>=RECOVERY:elapsed=-1
 if game.weapons.selected!=SLOT:elapsed=-1
 apply_pose(elapsed)
 sync()
func apply_pose(time:float):
 # A tiny pullback, fast straight extension, then a slower recovery.
 var thrust=0.0
 var pullback=0.0
 if time>=0 and time<0.05:pullback=sin(time/0.05*PI)*0.025
 elif time>=0.05 and time<HIT_TIME:thrust=smoothstep(0.05,HIT_TIME,time)
 elif time>=HIT_TIME and time<0.18:thrust=1.0
 elif time>=0.18:thrust=1.0-smoothstep(0.18,RECOVERY,time)
 held.position=Vector3(0.26-0.11*thrust,-0.22+0.06*thrust,-0.43-0.34*thrust+pullback)
 # Pitch the blade toward the target instead of sweeping it sideways.
 held.rotation=Vector3(-0.85*thrust,0,0)
