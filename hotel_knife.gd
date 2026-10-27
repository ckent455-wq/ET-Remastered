extends Node3D
## Optional physical pickup, backed by the hotel's existing editable knife prop.
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
var held:Node3D
var elapsed=-1.0
var struck=false
func _ready():
 name="HotelKnifeWeapon"
 for node in game.town.buildings.house.get_children():
  if node.get_meta("retro_asset","")=="knife":source=node;break
 assert(source!=null)
 area=Area3D.new();area.name="HotelKnifePickup";area.collision_layer=2;area.collision_mask=0;area.monitoring=false;area.monitorable=false;area.set_meta("action_id","hotel_knife");add_child(area)
 collision=CollisionShape3D.new();collision.shape=BoxShape3D.new();area.add_child(collision)
 game.town.actions.hotel_knife={"kind":"hotel_knife","label":"Take kitchen knife","area":area,"taken":false}
 held=Node3D.new();held.name="HeldHotelKnife";game.camera.add_child(held)
 var model=preload("res://assets/retro_props/knife.glb").instantiate();held.add_child(model);game.weapons.adapt(model)
 # Native model is 28cm long. Center it and present the broad blade toward the camera.
 var bounds=game.town.apartment_interiors.retro.bounds(model,held)
 model.position=-bounds.get_center()
 model.basis=Basis(Vector3(0,0.66,0.75).normalized(),Vector3.RIGHT,Vector3(0,0.75,-0.66).normalized())
 model.scale=Vector3.ONE*1.12
 sync()
func owned()->bool:return game.town.inventory.get("knife",0)>0
func pickup_focus(start:Vector3,finish:Vector3)->bool:
 if owned() or not source:return false
 var bounds=game.surface_details.bounds_of(source).grow(0.035)
 if bounds.intersects_segment(start,finish)==null:return false
 var query=PhysicsRayQueryParameters3D.create(start,finish,1,[game.player.get_rid()])
 var hit=get_world_3d().direct_space_state.intersect_ray(query)
 return hit.is_empty() or bounds.intersects_segment(start,hit.position)!=null
func reset():
 elapsed=-1;struck=false
 if area:sync()
func sync():
 if not source:return
 var have=owned()
 if not have:
  source.show()
  var box=game.surface_details.bounds_of(source)
  if box.size.length()>0:
   area.global_transform=Transform3D(Basis.IDENTITY,box.get_center())
   collision.shape.size=box.size+Vector3(0.12,0.12,0.12)
 else:source.hide()
 area.visible=not have
 area.collision_layer=0 if have else 2
 game.town.actions.hotel_knife.taken=have
 held.visible=have and game.weapons.selected==SLOT and game.state in ["play","paused","backpack"]
 if game.weapons.selected==SLOT:
  game.arm_visual.hide()
  game.flashlight_model.hide()
 else:game.flashlight_model.show()
func collect()->bool:
 if game.state!="play" or owned():return false
 if not game.crash_site.has_backpack:game.message="Collect your backpack before taking the knife.";return false
 if not game.backpack.room_for("knife"):game.message="Your backpack is full. The knife needs two slots.";return false
 game.town.inventory["knife"]=1
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
