extends Node3D
## A positional, controller-compatible interaction anchored to the editable bell model.
var game
var bell:Node3D
var area:Area3D
var voice:AudioStreamPlayer3D
var button:Node3D
var button_y=0.0
var press_time=0.0
var cooldown=0.0
func _ready():
 name="HotelReceptionBell"
 call_deferred("setup")
func setup():
 while not game.surface_details.completed or not game.hotel_upper.ready_layout:await get_tree().process_frame
 if not game.hotel_layout.added_furniture.has("hotel_reception_counter"):return
 var counter=game.hotel_layout.added_furniture.hotel_reception_counter
 bell=counter.get_node_or_null("Brass_Service_Bell")
 if not bell:return
 area=game.town.action_area(self,Vector3.ZERO,Vector3(.25,.22,.25),"hotel_reception_bell",{"kind":"hotel_reception_bell","label":"Ring desk bell"})
 voice=game.soundscape.spatial_voice(self,load("res://assets/audio/hotel_desk_bell.wav"),-4,16)
 voice.unit_size=3;voice.max_polyphony=4
 for child in bell.get_children():
  if child is MeshInstance3D and (not button or child.position.y>button.position.y):button=child
 if button:button_y=button.position.y
 sync()
func sync():
 if not is_instance_valid(bell) or not area:return
 area.global_transform=bell.global_transform;area.global_position+=bell.global_basis*Vector3(0,.07,0)
 area.visible=bell.is_visible_in_tree()
 area.collision_layer=2 if area.visible else 0
 voice.global_position=bell.global_position
func ring():
 if game.state!="play" or cooldown>0 or not is_instance_valid(bell) or not bell.is_visible_in_tree():return
 sync();voice.play();cooldown=.23;press_time=.12
 if button:button.position.y=button_y-.007
func reset():
 press_time=0;cooldown=0
 if voice:voice.stop()
 if button:button.position.y=button_y
func _physics_process(delta):
 if voice:voice.stream_paused=game.state not in ["play","dialogue"]
 if game.state!="play":return
 sync();cooldown=maxf(0,cooldown-delta);press_time=maxf(0,press_time-delta)
 if button:button.position.y=button_y-.007*press_time/.12
