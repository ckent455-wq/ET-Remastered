extends Node
## Versioned local snapshots. No objects/scripts are deserialized from disk.
const SCHEMA=1
var game
var directory="user://saves"
var error=""
func safe(value)->bool:
 var type=typeof(value)
 if type in [TYPE_OBJECT,TYPE_CALLABLE,TYPE_SIGNAL,TYPE_RID]:return false
 if value is Array:
  for item in value:
   if not safe(item):return false
 if value is Dictionary:
  for key in value:
   if not safe(key) or not safe(value[key]):return false
 return true
func plain(data:Dictionary)->Dictionary:
 var result={}
 for key in data:
  if safe(data[key]):result[key]=data[key]
 return result.duplicate(true)
func variables(node:Object)->Dictionary:
 var result={}
 for prop in node.get_property_list():
  if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
   var value=node.get(prop.name)
   if value!=null and safe(value):result[prop.name]=value
 return result.duplicate(true)
func set_variables(node:Object,data:Dictionary):
 for key in data:
  if node.get(key) is Array and data[key] is Array:node.get(key).assign(data[key])
  else:node.set(key,data[key])
func tree(node:Node)->Dictionary:
 var result={"vars":variables(node),"children":[],"kind":node.get_class(),"script":node.get_script().resource_path if node.get_script()!=null else ""}
 if node is Node3D:result.merge({"transform":node.transform,"visible":node.visible})
 if node is CollisionObject3D:result.merge({"layer":node.collision_layer,"mask":node.collision_mask})
 if node is CollisionShape3D:result.disabled=node.disabled
 if node is AnimationPlayer:
  result.animation=node.current_animation
  result.time=node.current_animation_position if node.current_animation!="" else 0.0
  result.speed=node.speed_scale
 for child in node.get_children():result.children.append(tree(child))
 return result
func valid_tree(node:Node,data)->bool:
 if not data is Dictionary or data.get("kind","")!=node.get_class() or not data.get("vars") is Dictionary or not data.get("children") is Array:
  return false
 if data.get("script","")!=(node.get_script().resource_path if node.get_script()!=null else ""):
  return false
 if data.children.size()!=node.get_child_count():
  return false
 if node is Node3D and (not data.get("transform") is Transform3D or not data.get("visible") is bool):return false
 for i in range(node.get_child_count()):
  if not valid_tree(node.get_child(i),data.children[i]):return false
 return true
func restore_tree(node:Node,data:Dictionary):
 set_variables(node,data.vars)
 if node is Node3D:node.transform=data.transform;node.visible=data.visible
 if node is CollisionObject3D:node.collision_layer=data.layer;node.collision_mask=data.mask
 if node is CollisionShape3D:node.set_deferred("disabled",data.disabled)
 for i in range(mini(node.get_child_count(),data.children.size())):restore_tree(node.get_child(i),data.children[i])
 if node is AnimationPlayer and data.animation!="" and node.has_animation(data.animation):
  node.play(data.animation);node.seek(data.time,true);node.advance(0);node.speed_scale=data.speed
func roots()->Dictionary:
 return {"crash":game.crash_site,"tree":game.falling_tree,"crow":game.town.sign_crow,"church":game.town.streetscape.church,"cemetery":game.town.cemetery,"hotel":game.hotel_basement,"window":game.hotel_window_figure,"shadow":game.cemetery_shadow,"grave":game.grave_dig,"police":game.weapons.police_car,"lockbox":game.weapons.lockbox,"panel":game.town.actions.battery_panel.area.get_node("HighVoltageTerminal"),"enemies":game.enemies,"people":game.town.townspeople}
func blocked_reason()->String:
 if not game.surface_details.completed:return "The world is still preparing. Wait a moment before saving."
 if game.testing_mode.enabled:return "Turn testing mode off before saving a normal journey."
 if game.health<=0 or game.state not in ["play","paused"]:return "Start or resume a journey before saving."
 if game.crash_site.wake_phase!="" or not game.crash_site.has_backpack:return "Finish the car opening and collect your backpack before saving."
 if game.town.cemetery.slamming:return "Let the mausoleum door finish moving before saving."
 if game.grave_dig.digging:return "Finish digging before saving."
 if game.falling_tree.triggered and not game.falling_tree.reaction_shown:return "Let the falling-tree sequence finish before saving."
 if game.hotel_basement.get_node("CellarCoffinStacks").blackout_active:return "Let the coffin encounter finish before saving."
 return ""
func capture()->Dictionary:
 var town=game.town
 var data={"schema":SCHEMA,"version":str(ProjectSettings.get_setting("application/config/version")),"date":Time.get_datetime_string_from_system(false,true),"location":town.location_name(),"health":game.health,"position":game.player.global_transform,"pitch":game.pitch,"crouching":game.crouching,"stamina":game.stamina,"charge":game.flashlight_charge,"light":game.flashlight.visible,"clock":game.clock,"town":{},"story":variables(game.story),"owned":game.weapons.owned.duplicate(),"magazines":game.weapons.magazines.duplicate(),"reserves":game.weapons.reserves.duplicate(),"selected":game.weapons.selected,"cells":game.backpack.saved_cells.duplicate(true),"rotations":game.backpack.saved_rotations.duplicate(true),"actions":{},"storage":{},"doors":{},"roots":{},"enemies":[],"people":{},"conversation":variables(town.townspeople.conversation)}
 for key in ["inventory","journal_entries","discovered","powered","radio_ready","reached_town"]:data.town[key]=town.get(key).duplicate(true) if town.get(key) is Dictionary or town.get(key) is Array else town.get(key)
 for id in town.actions:
  var action=town.actions[id]
  data.actions[id]={"taken":action.taken,"visible":action.area.visible,"layer":action.area.collision_layer,"disabled":action.area.get_child(0).disabled,"amount":action.get("amount",-1)}
 for id in town.interiors.containers:data.storage[id]=plain(town.interiors.containers[id])
 for id in town.doors:data.doors[id]={"open":town.doors[id].open,"rotation":town.doors[id].hinge.rotation,"disabled":town.doors[id].collision.disabled,"unlocked":town.doors[id].unlocked}
 for key in roots():data.roots[key]=tree(roots()[key])
 for enemy in game.enemies.creatures:data.enemies.append(plain(enemy))
 for id in town.townspeople.characters:data.people[id]=plain(town.townspeople.characters[id])
 return data
func valid(data)->bool:
 if not data is Dictionary or data.get("schema",0)!=SCHEMA:return false
 for key in ["town","story","actions","storage","doors","roots","people","conversation","cells"]:
  if not data.get(key) is Dictionary:return false
 for key in ["owned","magazines","reserves"]:
  if not data.get(key) is Array or data[key].size()!=3:return false
 if not data.get("enemies") is Array or data.enemies.size()!=game.enemies.creatures.size():return false
 if not data.get("position") is Transform3D or not data.position.is_finite():return false
 if not data.get("health") is float and not data.get("health") is int:return false
 if data.health<=0 or data.health>100:return false
 for key in ["inventory","journal_entries","discovered","powered","radio_ready","reached_town"]:
  if not data.town.has(key):return false
 if not data.town.inventory is Dictionary or not data.town.journal_entries is Array:return false
 if data.has("rotations"):
  if not data.rotations is Dictionary:return false
  for key in data.rotations:
   if not key is String or not data.rotations[key] is bool:return false
 for key in game.town.inventory:
  if not data.town.inventory.get(key) is int or data.town.inventory[key]<0:return false
 for id in game.town.actions:
  if not data.actions.get(id) is Dictionary:return false
 for key in roots():
  if not valid_tree(roots()[key],data.roots.get(key)):return false
 return true
func apply(data:Dictionary):
 game.set_state("paused");game.reset_game()
 for key in data.town:
  if game.town.get(key) is Array:game.town.get(key).assign(data.town[key])
  else:game.town.set(key,data.town[key])
 set_variables(game.story,data.story)
 for key in roots():restore_tree(roots()[key],data.roots[key])
 for i in range(data.enemies.size()):
  var enemy=game.enemies.creatures[i]
  enemy.merge(data.enemies[i],true)
  var maximum=game.enemies.health_for(i)
  var previous=float(enemy.get("max_hp",85.0))
  if previous!=maximum:
   enemy.hp=clampf(enemy.hp/maxf(1,previous),0,1)*maximum
  enemy.max_hp=maximum
 for id in data.people:
  game.town.townspeople.characters[id].merge(data.people[id],true)
  var person=game.town.townspeople.characters[id]
  if person.dead:game.town.townspeople.animate_death(person)
 set_variables(game.town.townspeople.conversation,data.conversation);game.town.townspeople.conversation.cancel()
 for id in data.storage:
  var container=game.town.interiors.containers[id];container.merge(data.storage[id],true)
  for part in container.moving:
   if container.mode=="drawer":part.position.z=0.48 if container.open else 0.0
   else:part.rotation.y=float(part.get_meta("side"))*1.65 if container.open else 0.0
 for id in data.doors:
  var door=game.town.doors[id];door.unlocked=data.doors[id].get("unlocked",id!="radio" or game.town.inventory.station_key>0);door.open=data.doors[id].open;door.hinge.rotation=data.doors[id].rotation;door.collision.set_deferred("disabled",data.doors[id].disabled)
 for id in data.actions:
  var action=game.town.actions[id];var old=data.actions[id]
  action.taken=old.taken;action.area.visible=old.visible;action.area.collision_layer=old.layer;action.area.get_child(0).set_deferred("disabled",old.disabled)
  if old.amount>=0:action.amount=old.amount
 game.hotel_basement.place_chapel_key()
 game.town.cemetery.slam_triggered=game.town.cemetery.slam_triggered or game.town.actions.cemetery_coupler.taken
 var panel=roots().panel;panel.set_fuse_power(panel.energized);panel.refresh_prompt()
 game.town.actions.battery_panel.area.get_node("InstalledFuse").visible=panel.installed
 for light in game.town.powered_lights:light.visible=game.town.powered
 game.town.receiver_light.light_energy=1.0 if game.town.radio_ready else 0.4
 game.story.bypass_lamp.material_override=game.town.mats.green if game.story.county_bypass else game.town.mats.amber
 var rack=game.story.repeater
 rack.lamp.material_override=game.town.mats.dark if rack.shutdown_done else game.town.mats.amber
 if rack.shutdown_done:rack.hum.stop()
 game.hotel_window_figure.set_window_light(not game.hotel_window_figure.vanished)
 game.cemetery_shadow.material.albedo_color.a=0 if game.cemetery_shadow.vanished else 1
 game.weapons.owned.assign(data.owned);game.weapons.magazines.assign(data.magazines);game.weapons.reserves.assign(data.reserves)
 game.weapons.selected=data.selected;game.weapons.update_model(1);game.weapons.melee.raised=false;game.weapons.reload_remaining=0
 game.backpack.saved_cells=data.cells.duplicate(true)
 game.backpack.saved_rotations=data.get("rotations",{}).duplicate(true)
 game.crash_site.leave_seat_for_testing();game.crash_site.wake_phase="";game.crash_site.update_door_target();game.crash_site.update_hatch_target();game.crash_site.update_item_targets()
 game.player.global_transform=data.position;game.player.velocity=Vector3.ZERO;game.pitch=data.pitch
 game.crouching=data.crouching
 game.player_collider.shape.height=game.CROUCH_HEIGHT if game.crouching else game.STANDING_HEIGHT;game.player_collider.position.y=game.player_collider.shape.height/2
 game.camera.position=Vector3(0,game.CROUCH_EYE if game.crouching else game.STANDING_EYE,0);game.camera.rotation=Vector3(data.pitch,0,0)
 game.health=data.health;game.stamina=data.stamina;game.flashlight_charge=data.charge;game.flashlight.visible=data.light;game.clock=data.clock
 game.contact_progress=0;game.invincible=0;game.jump_queued=false;game.town.focus_action=""
 game.message="Journey loaded. "+game.town.objective()
 game.set_state("play")
func path(slot:int)->String:return directory+"/slot_%d.sav" % slot
func read_file(file_path:String)->Dictionary:
 if not FileAccess.file_exists(file_path):return {}
 var file=FileAccess.open(file_path,FileAccess.READ)
 if file==null or file.get_length()<72 or file.get_length()>8388608:return {}
 if file.get_buffer(8).get_string_from_ascii()!="FFHSAVE1":file.close();return {}
 var checksum=file.get_buffer(64).get_string_from_ascii()
 var bytes=file.get_buffer(file.get_length()-72);file.close()
 if bytes.hex_encode().sha256_text()!=checksum:return {}
 var data=bytes_to_var(bytes)
 return data if valid(data) else {}

func read_slot(slot:int)->Dictionary:
 if slot<1 or slot>3:return {}
 var data=read_file(path(slot))
 if data.is_empty():
  data=read_file(path(slot)+".bak")
  if not data.is_empty():data.recovered=true
 return data
func save_slot(slot:int)->bool:
 error=blocked_reason()
 if error!="":return false
 if slot<1 or slot>3:error="Invalid save slot.";return false
 var data=capture()
 if not valid(data):error="Could not capture a complete journey. Existing save kept.";return false
 var folder=ProjectSettings.globalize_path(directory)
 if DirAccess.make_dir_recursive_absolute(folder)!=OK:error="Cannot create the save folder.";return false
 var target=ProjectSettings.globalize_path(path(slot));var temp=target+".tmp";var backup=target+".bak"
 var bytes=var_to_bytes(data)
 var file=FileAccess.open(temp,FileAccess.WRITE)
 if file==null:error="Cannot write save. Existing save kept.";return false
 file.store_buffer("FFHSAVE1".to_ascii_buffer());file.store_buffer(bytes.hex_encode().sha256_text().to_ascii_buffer());file.store_buffer(bytes);file.flush();var write_error=file.get_error();file.close()
 if write_error!=OK or read_file(temp).is_empty():error="Save verification failed. Existing save kept.";return false
 if FileAccess.file_exists(target):
  if not read_file(target).is_empty():
   if FileAccess.file_exists(backup):DirAccess.remove_absolute(backup)
   if DirAccess.rename_absolute(target,backup)!=OK:error="Could not back up the existing save.";return false
  elif DirAccess.remove_absolute(target)!=OK:error="Could not replace the damaged save.";return false
 if DirAccess.rename_absolute(temp,target)!=OK:
  if FileAccess.file_exists(backup):DirAccess.copy_absolute(backup,target)
  error="Could not finish writing save. Backup preserved.";return false
 error="";return true
func load_slot(slot:int)->bool:
 var data=read_slot(slot)
 if data.is_empty():error="This slot is empty, damaged or incompatible. Current journey kept.";return false
 apply(data);error="";return true
