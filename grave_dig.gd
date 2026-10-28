extends Node3D
## One optional cache; supplies remain physical pickups if the backpack is full.
var game
var shovel:Area3D
var grave:Area3D
var mound:Node3D
var exposed:Node3D
var ground_cover:StaticBody3D
var cover_collision:CollisionShape3D
var dig_sound:AudioStreamPlayer3D
var scrape_sound:AudioStreamPlayer3D
var digging=false
var dug=false
var elapsed=0.0
var strokes=0
var scraped=false
const DURATION=3.1
const GRAVE=Vector3(12.7,0,-15.45)
func _ready():
 name="DisturbedGrave"
 var town=game.town
 shovel=town.action_area(game.victorian_house.cellar,Vector3(-1.5,0.68,-3.75),Vector3(0.55,1.4,0.5),"workshop_shovel",{"kind":"grave_shovel","label":"Take rusted shovel"})
 var model=preload("res://spade_model.gd").build()
 shovel.add_child(model)
 model.position=Vector3(0,-0.66,0)
 model.rotation.x=-0.20
 model.rotation.z=-0.06
 town.streetscape.church.basement.prepare_cellar_lighting(shovel)
 grave=town.action_area(self,GRAVE+Vector3(0,0.22,0),Vector3(1.25,0.5,2.0),"cemetery_disturbed_grave",{"kind":"dig_grave","label":"Inspect disturbed soil"})
 var soil=town.mats.floor.duplicate()
 soil.albedo_texture=preload("res://assets/forest/ground_ps2.png")
 soil.albedo_color=Color("554434")
 mound=Node3D.new();add_child(mound);mound.position=GRAVE
 var dirt=game.mesh_at(mound,game.cylinder(0.65,0.54,0.16,11),Vector3(0,0.08,0),soil)
 dirt.scale.z=1.6
 for i in range(9):
  var clod=game.mesh_at(mound,game.cylinder(0.1,0.08,0.06,5),Vector3(sin(i*2.5)*0.4,0.16,cos(i*3.1)*0.75),soil)
  clod.rotation.y=i*1.3
 # Before digging, a removable cap fills the opening in the shared world ground.
 ground_cover=town.box(self,GRAVE+Vector3(0,-0.055,0),Vector3(1.5,0.11,2.1),soil)
 ground_cover.name="UndugSoilCap"
 ground_cover.set_meta("footstep_surface","dirt")
 cover_collision=ground_cover.get_child(1)
 exposed=Node3D.new();add_child(exposed);exposed.position=GRAVE+Vector3(0,-0.67,0)
 build_pit(soil)

 var coffin=preload("res://assets/coffin/coffin-old.glb").instantiate()
 coffin.name="BuriedCoffin"
 exposed.add_child(coffin)
 coffin.position.y=-0.13
 coffin.scale=Vector3(2.0,1.5,2.15)
 var wood=ShaderMaterial.new();var shader=Shader.new()
 shader.code="shader_type spatial; varying vec3 world_pos; uniform sampler2D wood_texture : source_color, filter_nearest_mipmap, repeat_enable; void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){ALBEDO=mix(vec3(0.34,0.28,0.21),texture(wood_texture,world_pos.xz*2.0).rgb,0.14);ROUGHNESS=1.0;}"
 wood.shader=shader;wood.set_shader_parameter("wood_texture",town.mats.wood.albedo_texture)
 for mesh in coffin.find_children("*","MeshInstance3D",true,false):mesh.material_override=wood
 var support=StaticBody3D.new();support.name="CoffinSupport";exposed.add_child(support)
 var shape=BoxShape3D.new();shape.size=Vector3(1.1,0.3,1.75)
 var collision=CollisionShape3D.new();collision.shape=shape;collision.position.y=0.02
 support.add_child(collision)
 var ammo=town.action_area(exposed,Vector3(-0.22,0.26,0.12),Vector3(0.4,0.2,0.3),"cemetery_buried_ammo",{"kind":"ammo","weapon_index":0,"amount":6,"initial_amount":6,"label":"Take buried pistol rounds"})
 var box=load("res://assets/ammo/pistol.glb").instantiate();ammo.add_child(box)
 box.scale=Vector3.ONE*0.7
 box.position.y=-0.09
 var paper=town.action_area(exposed,Vector3(0.22,0.18,-0.38),Vector3(0.36,0.10,0.46),"cemetery_buried_note",{"kind":"note","label":"Read buried note","title":"Buried in a hurry","text":"John brought the last box of pistol rounds. I hid six beneath this loose coffin lid before the final bus left. If the road is blocked, take them.

The soil was warm when I covered it. I heard nails dragging underneath. This grave has been empty for years.

Do not stay after dark. - P.W."})
 dig_sound=game.soundscape.spatial_voice(self,game.soundscape.stream("grave_dig"),-11,14)
 scrape_sound=game.soundscape.spatial_voice(self,game.soundscape.stream("coffin_scrape"),-7,18)
 dig_sound.position=GRAVE;scrape_sound.position=GRAVE
 reset()
func reset():
 digging=false;dug=false;elapsed=0;strokes=0;scraped=false
 if dig_sound:dig_sound.stop()
 if scrape_sound:scrape_sound.stop()
 mound.scale=Vector3.ONE;mound.show();exposed.hide()
 ground_cover.show();cover_collision.set_deferred("disabled",false)
 for id in ["cemetery_buried_ammo","cemetery_buried_note"]:
  game.town.actions[id].area.collision_layer=0
func prompt()->String:
 if dug:return "The loose coffin lid has been uncovered."
 if game.town.inventory.shovel<=0:return "E / Inspect disturbed soil"
 return "Hold E / Dig disturbed grave"+("  %d%%" % int(elapsed/DURATION*100) if digging else "")
func interact_shovel():
 if not game.backpack.can_collect():return
 if not game.backpack.room_for("shovel"):
  game.message="Make a 1 x 3 space in your backpack for the shovel."
  return
 game.town.inventory.shovel=1
 game.town.actions.workshop_shovel.taken=true
 shovel.hide();shovel.collision_layer=0
 game.soundscape.feedback("pickup")
 game.message="Rusted shovel collected. One cemetery grave has freshly disturbed soil."
func interact_grave():
 if dug:return
 if game.town.inventory.shovel<=0:
  game.message="Fresh soil and spade marks. I need a shovel to uncover this."
  return
 digging=true;elapsed=0;strokes=0;scraped=false
func _process(delta):
 var held=Input.is_physical_key_pressed(KEY_E) or (game.controller and game.controller.interact_held())
 update_dig(delta,held)
func update_dig(delta:float,held:bool):
 if not digging:return
 if game.state!="play":return
 if not held or game.town.focus_action!="cemetery_disturbed_grave" or game.player.global_position.distance_to(GRAVE)>3.4:
  digging=false;elapsed=0;strokes=0;scraped=false
  mound.scale.y=1;dig_sound.stop();scrape_sound.stop()
  return
 elapsed+=delta
 var beat=mini(3,int(elapsed/0.7)+1)
 if beat>strokes:strokes=beat;dig_sound.pitch_scale=1.0+strokes*.04;dig_sound.play()
 mound.scale.y=maxf(0.12,1-elapsed/DURATION)
 if elapsed>=2.25 and not scraped:scraped=true;scrape_sound.play()
 if elapsed<DURATION:return
 digging=false;dug=true;mound.hide();exposed.show()
 ground_cover.hide();cover_collision.set_deferred("disabled",true)
 grave.collision_layer=0
 game.town.actions.cemetery_disturbed_grave.taken=true
 for id in ["cemetery_buried_ammo","cemetery_buried_note"]:game.town.actions[id].area.collision_layer=2
 game.message="Something scraped beneath the lid. There is an ammo box and a folded note."

func contains_pit(p:Vector3)->bool:
 return dug and absf(p.x-GRAVE.x)<1.1 and absf(p.z-GRAVE.z)<1.4 and p.y> -1.2

func build_pit(soil:Material):
 var town=game.town
 # These walls extend below the original ground, not over a painted surface.
 var earth=soil.duplicate();earth.albedo_color=Color("66503b")
 earth.cull_mode=BaseMaterial3D.CULL_DISABLED
 var pit=Node3D.new();exposed.add_child(pit);pit.position.y=0.67
 pit.name="ExcavatedEarth"
 for x in [-0.78,0.78]:town.box(pit,Vector3(x,-0.4,0),Vector3(0.06,0.8,2.16),earth)
 for z in [-1.08,1.08]:town.box(pit,Vector3(0,-0.4,z),Vector3(1.62,0.8,0.06),earth)
 town.box(pit,Vector3(0,-0.84,0),Vector3(1.5,0.08,2.1),earth)
 var dark=earth.duplicate();dark.albedo_color=Color("362c22")
 for y in [-0.19,-0.43,-0.69]:
  for x in [-0.746,0.746]:town.box(pit,Vector3(x,y,0),Vector3(0.008,0.035,2.05),dark,false)
  for z in [-1.046,1.046]:town.box(pit,Vector3(0,y,z),Vector3(1.49,0.035,0.008),dark,false)
 # Clods and uneven spoil along the rim break up the clean cut.
 for i in range(14):
  var side=1 if i%2==0 else -1
  var dirt=game.mesh_at(pit,game.cylinder(0.17+0.035*(i%3),0.13,0.12,7),Vector3(side*(0.9+0.05*sin(i)),0.055,-0.9+(i/2)*0.29),earth)
  dirt.rotation.y=i*1.7;dirt.scale.z=1.35
 for i in range(7):
  var root_piece=town.box(pit,Vector3(-0.727,-0.12-i*0.065,-0.8+i*0.26),Vector3(0.025,0.035,0.23),town.mats.wood,false)
  root_piece.rotation.x=0.2+i*0.17
