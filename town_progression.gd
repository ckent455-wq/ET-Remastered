extends Node3D
## Derived world state lives outside saved scene roots, preserving older save trees.
var game
var startup=-1.0
var motor_running=false
var interference_running=false
var bulbs=[]
var lights=[]
var motor:AudioStreamPlayer3D
var interference:AudioStreamPlayer3D
var on_material:StandardMaterial3D
var off_material:StandardMaterial3D
func _ready():
 name="TownProgression"
 transform=game.town.buildings.workshop.global_transform
 on_material=game.town.color_material(Color("d7ba7d"),0.7)
 off_material=game.town.color_material(Color("48483f"))
 for x in [-3.7,3.7]:
  game.town.box(self,Vector3(x,2.91,3.7),Vector3(0.28,0.08,0.22),game.town.mats.metal,false)
  var bulb=MeshInstance3D.new();var mesh=SphereMesh.new();mesh.radius=0.055;mesh.height=0.11;mesh.radial_segments=8;mesh.rings=4
  bulb.mesh=mesh;bulb.position=Vector3(x,2.80,3.7);bulb.material_override=off_material;add_child(bulb);bulbs.append(bulb)
  var light=game.town.lamp(self,Vector3(x,2.68,3.7),Color("d5bd88"),0.42,4.0);lights.append(light)
 var wave=AudioStreamWAV.new();wave.format=AudioStreamWAV.FORMAT_16_BITS;wave.mix_rate=24000
 var pcm=PackedByteArray();pcm.resize(48000)
 for i in range(24000):
  var t=float(i)/24000.0
  var sample=(sin(TAU*60*t)*0.6+sin(TAU*120*t)*0.22+sin(TAU*180*t)*0.08)*(0.92+0.08*sin(TAU*7*t))
  pcm.encode_s16(i*2,int(sample*16000))
 wave.data=pcm;wave.loop_mode=AudioStreamWAV.LOOP_FORWARD;wave.loop_begin=0;wave.loop_end=24000
 motor=game.soundscape.spatial_voice(self,wave,-29,12);motor.position=Vector3(0,1,-2.5);motor.unit_size=1.5
 interference=game.soundscape.spatial_voice(self,game.soundscape.stream("horror/radio_static",true),-40,7);interference.position=Vector3(0,1,-2.5);interference.unit_size=1.0
 sync()
func reset():
 startup=-1.0
 motor_running=false;interference_running=false
 if motor:motor.stop()
 if interference:interference.stop()
 sync()
func power_restored():
 startup=0.0
 sync()
func sync():
 if not motor:return
 var powered=game.town.powered
 var active=game.state in ["play","dialogue","clinic_faint"]
 visible=game.state not in ["intro","title"]
 var interrupted=false
 if startup>=0:
  for interval in [[0.45,0.65],[1.0,1.2],[1.55,1.75]]:
   if startup>=interval[0] and startup<interval[1]:interrupted=true
 var illuminated=powered and not interrupted
 for bulb in bulbs:bulb.material_override=on_material if illuminated else off_material
 for light in lights:light.visible=illuminated
 for light in game.town.powered_lights:light.visible=illuminated
 if powered and active:
  if not motor_running:
   motor.stream_paused=false;motor.play();motor_running=true
 else:
  motor.stop();motor_running=false
 var signal_on=powered and not game.story.repeater_is_off()
 if signal_on and active:
  if not interference_running:
   interference.stream_paused=false;interference.play();interference_running=true
 else:
  interference.stop();interference_running=false
 motor.volume_db=-35 if interrupted else -29
func _process(delta):
 if startup>=0 and game.state in ["play","dialogue"]:
  startup+=minf(delta,0.1)
  if startup>=2.0:startup=-1.0
 sync()
