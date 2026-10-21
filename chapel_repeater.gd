extends Node3D
## Independent chapel carrier supply: a permanent, physical shutdown per journey.
var game
var lamp:MeshInstance3D
var lever:Node3D
var hum:AudioStreamPlayer3D
var shutdown_done=false
func _ready():
 name="ChapelRepeaterRack"
 var town=game.town
 position=Vector3(4.12,0,1.10)
 var dark=town.mats.metal.duplicate();dark.albedo_color=Color("353d38")
 var panel=town.mats.metal.duplicate();panel.albedo_color=Color("797a68")
 town.box(self,Vector3(0,1.10,0),Vector3(0.62,2.20,0.92),dark)
 for y in [0.42,0.90,1.40,1.88]:
  town.box(self,Vector3(-0.326,y,0),Vector3(0.025,0.35,0.79),panel,false)
  for i in range(5):town.box(self,Vector3(-0.343,y-0.09+i*0.04,0.17),Vector3(0.012,0.012,0.26),town.mats.dark,false)
 var lamp_body=town.box(self,Vector3(-0.352,1.95,-0.23),Vector3(0.025,0.09,0.12),town.mats.amber,false)
 lamp=lamp_body.get_child(0)
 lever=Node3D.new();lever.position=Vector3(-0.38,1.24,-0.23);add_child(lever)
 town.box(lever,Vector3(-0.04,0.09,0),Vector3(0.055,0.20,0.055),town.mats.dark,false)
 var plate=Label3D.new();plate.text="CHAPEL REPEATER\nMAIN ISOLATOR\nON  /  OFF";plate.position=Vector3(-0.36,1.66,-0.02);plate.rotation.y=-PI/2;plate.pixel_size=0.0018;plate.font=preload("res://assets/font.ttf");plate.font_size=24;plate.modulate=Color("d2c9a8");add_child(plate)
 town.action_area(self,Vector3(-0.40,1.24,-0.20),Vector3(0.24,0.42,0.42),"chapel_repeater",{"kind":"chapel_repeater","label":"Shut down chapel repeater"})
 hum=game.soundscape.spatial_voice(self,game.soundscape.stream("horror/radio_static",true),-23,9);hum.position=Vector3(0,1.4,0);hum.unit_size=1.8
 town.streetscape.church.basement.prepare_cellar_lighting(self)
 reset()
func reset():
 shutdown_done=false;lever.rotation.z=0;lamp.material_override=game.town.mats.amber
 if hum:hum.play();hum.stream_paused=game.state not in ["play","dialogue"]
func shutdown()->bool:
 var cellar=game.town.streetscape.church.basement
 if shutdown_done or game.state!="play":return false
 if not cellar.unlocked or not cellar.contains(game.player.global_position) or game.player.global_position.distance_to(global_position)>2.8:
  game.message="The repeater's main isolator is inside the locked chapel basement.";return false
 shutdown_done=true;lever.rotation.z=-PI/2;lamp.material_override=game.town.mats.dark;hum.stop()
 game.contact_progress=0
 game.soundscape.feedback("power")
 game.message="Chapel repeater shut down. The carrier is silent. Use the station's GREEN / direct county channel to call for rescue."
 var id="repeater_shutdown"
 if not game.town.journal_entries.any(func(e):return e.id==id):game.town.journal_entries.append({"id":id,"title":"Chapel repeater / shut down","text":"You cut the chapel rack's independent power. Its carrier is silent. Repair the town receiver, select GREEN / direct county, and call for rescue without sirens."})
 return true
func _process(_delta):
 hum.stream_paused=game.state not in ["play","dialogue"]
