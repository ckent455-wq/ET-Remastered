extends Node
## Required opening rescue, before normal exploration and healing supplies.
var game
var phase = ""
var elapsed = 0.0
var caption_elapsed = 0.0
var start_roll = 0.0
var veil: ColorRect
var faint_caption: Control
const FAINT_LINE = "Oh fuck, im light headed..."
const BLACKOUT_SECONDS = 5.5
var start_eye_height = 1.65
var start_pitch = 0.0
const TOWN_APPROACH_Z = -15.0
const AUBREY_LINE = "Easy. Stay with me. You're in the medical bed at Blackwood's pharmacy clinic. I'm Aubrey. I was checking the road when I saw you go down.\n\nYou were bleeding from the head wound you sustained from the crash. You lost too much blood trying to reach town. I brought you inside and stopped the bleeding. Your backpack and everything in it are still with you.\n\nThe voices are another danger. People here stopped sleeping, lost time, then began to change. Don't follow a familiar voice into the woods. Even if it's mine...\n\nRest a moment, then get up slowly. There's a chart on the back shelf and supplies in the rear cabinet. I put a clean spare bandage in your backpack. Use it from the backpack, or press H, if you need it later. If you need help finding a way out of town, come talk to me."

func _ready():
 name="ClinicRescue"
 var layer=CanvasLayer.new();layer.layer=90;add_child(layer)
 veil=ColorRect.new();veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);veil.color=Color(0,0,0,0);veil.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(veil)
 faint_caption=preload("res://clinic_faint_caption.gd").new();faint_caption.rescue=self;faint_caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(faint_caption)

func reset():
 phase="";elapsed=0;caption_elapsed=0
 if faint_caption:faint_caption.queue_redraw()
 if veil:veil.color.a=0
 if game.camera:game.camera.rotation.z=0;game.camera.h_offset=0;game.camera.v_offset=0

func treat_wound():
 game.story.crash_wound_treated=true


func update_approach(_delta:float):
 if phase!="" or game.state!="play" or game.story.clinic_rescue_done:return
 if game.testing_mode and game.testing_mode.enabled:return
 if game.crash_site.wake_phase!="":return
 if game.player.global_position.z>TOWN_APPROACH_Z or absf(game.player.global_position.x)>4.5:return
 if game.town.townspeople.characters.nurse.dead:return
 phase="dimming";elapsed=0;caption_elapsed=0
 faint_caption.queue_redraw()
 game.message="My head is spinning... I need to find help."

func road_collapse_pending()->bool:
 if game.story.clinic_rescue_done:return false
 if game.testing_mode and game.testing_mode.enabled:return false
 return game.crash_site.wake_phase=="" and not game.town.townspeople.characters.nurse.dead

func begin_collapse():
 phase="faint";elapsed=0;start_roll=game.camera.rotation.z
 start_eye_height=game.camera.position.y;start_pitch=game.pitch
 game.player.velocity=Vector3.ZERO;game.jump_queued=false;game.contact_progress=0
 game.camera.h_offset=0;game.camera.v_offset=0
 game.flashlight.visible=false
 game.message="The bleeding hasn't stopped... I need to sit down."
 game.set_state("clinic_faint")
 game.hud.queue_redraw()

func _process(delta):
 if phase in ["dimming","faint","blackout","wake"] and game.state in ["play","clinic_faint"]:caption_elapsed+=minf(delta,0.1)
 faint_caption.queue_redraw()
 if phase=="" or phase=="bed":return
 if phase=="dimming":
  if game.state!="play":return
  elapsed+=minf(delta,0.1)
  veil.color.a=lerpf(0.0,0.72,smoothstep(0,5.0,elapsed))
  var weakness=smoothstep(0,5.0,elapsed)
  game.camera.rotation.z=sin(elapsed*3.7)*lerpf(0.015,0.11,weakness)
  game.camera.h_offset=sin(elapsed*2.8)*0.035*weakness
  game.camera.v_offset=-absf(sin(elapsed*3.7))*0.035*weakness
  if elapsed>=5.0:begin_collapse()
  game.hud.queue_redraw()
  return
 if game.state!="clinic_faint":reset();return
 elapsed+=minf(delta,0.1)
 if phase=="faint":
  var amount=smoothstep(0,1.8,elapsed)
  game.camera.position.y=lerpf(start_eye_height,0.58,amount)
  game.camera.rotation.x=lerpf(start_pitch,0.58,amount)
  game.camera.rotation.z=lerpf(start_roll,-0.18,amount)
  veil.color.a=lerpf(0.72,1.0,amount)
  if elapsed>=1.8:phase="blackout";elapsed=0
 elif phase=="blackout":
  if elapsed>=BLACKOUT_SECONDS:place_in_bed();phase="wake";elapsed=0;veil.color.a=0
 elif phase=="wake":
  if elapsed>=3.0:begin_explanation()
 game.hud.queue_redraw()

func eye_opening()->float:
 if phase!="wake":return 1.0
 # The same uneven eyelid rhythm used for the original crash awakening.
 var times=[0.0,0.35,0.85,1.05,1.65,1.90,2.60,3.0]
 var openings=[0.0,0.0,0.75,0.0,0.95,0.10,1.0,1.0]
 for i in range(times.size()-1):
  if elapsed<=times[i+1]:return lerpf(openings[i],openings[i+1],smoothstep(times[i],times[i+1],elapsed))
 return 1.0

func place_in_bed():
 var clinic=game.town.buildings.clinic
 game.player.global_position=clinic.to_global(Vector3(-3.3,0.02,-0.65))
 game.player.velocity=Vector3.ZERO
 game.camera.position=Vector3(0,1.0,0);game.camera.rotation.z=0
 var nurse=game.town.townspeople.characters.nurse
 nurse.actor.global_position=clinic.to_global(Vector3(-1.9,0.02,-0.35));nurse.actor.velocity=Vector3.ZERO
 var toward=nurse.actor.global_position+Vector3(0,1.45,0)-game.camera.global_position
 game.player.rotation.y=atan2(-toward.x,-toward.z)
 game.pitch=atan2(toward.y,Vector2(toward.x,toward.z).length())
 game.camera.rotation=Vector3(game.pitch,0,0)
 var facing=nurse.parent.global_basis.inverse()*(game.player.global_position-nurse.actor.global_position)
 nurse.actor.rotation.y=atan2(facing.x,facing.z)
 game.camera.fov=66
 game.health=maxf(game.health,65.0);game.stamina=100
 if game.crash_site.has_backpack and not game.story.clinic_rescue_done:game.town.inventory.bandage+=1
 game.story.crash_wound_treated=true;game.story.clinic_rescue_done=true
 game.invincible=0
 game.camera.make_current()

func begin_explanation():
 game.town.townspeople.conversation.greetings["nurse"]=true
 phase="bed";veil.color.a=0
 faint_caption.queue_redraw()
 game.story.record_aubrey_briefing()
 game.dialogue_name="Aubrey / Nurse";game.dialogue_text=AUBREY_LINE
 var warning="The voices are another danger. People here stopped sleeping, lost time, then began to change. Don't follow a familiar voice into the woods. Even if it's mine..."
 game.dialogue_text=game.dialogue_text.replace(warning,game.story.AUBREY_BRIEFING)
 if missing_gear_prompt()!="":
  game.dialogue_text=game.dialogue_text.replace("Your backpack and everything in it are still with you.","You arrived without "+missing_gear_names()+". You said your supplies were in the trunk of your car. I left them there; you'll need to go back for them when you're steady.")
  game.dialogue_text=game.dialogue_text.replace("I put a clean spare bandage in your backpack. Use it from the backpack, or press H, if you need it later.","I've dressed this wound, but collect your gear before you go exploring.")
 game.set_state("dialogue")
 game.message="Aubrey dressed your crash wound. Finish speaking with her, then get up from the bed."
 if not game.town.journal_entries.any(func(e):return e.id=="clinic_rescue"):
  game.town.journal_entries.append({"id":"clinic_rescue","title":"Aubrey / Found on the road","text":"Your head wound worsened and you collapsed on the approach to Blackwood. Aubrey found you, brought you to the pharmacy clinic and dressed the wound. She says the town's strange voices are a separate danger. Read her clinic observations and ask her what happened to the patients."})
 if missing_gear_prompt()!="":game.town.journal_entries[-1].text+=" "+missing_gear_prompt()
 game.hud.queue_redraw()

func leave_bed():
 if phase!="bed":return
 phase="";elapsed=0;caption_elapsed=0;veil.color.a=0
 game.player.global_position=game.town.buildings.clinic.to_global(Vector3(-2.0,0.02,0.65))
 game.player.velocity=Vector3.ZERO;game.crouching=false
 game.player_collider.shape.height=game.STANDING_HEIGHT;game.player_collider.position.y=game.STANDING_HEIGHT/2
 game.camera.position=Vector3(0,game.STANDING_EYE,0);game.camera.rotation=Vector3.ZERO;game.pitch=0
 game.message=missing_gear_prompt() if missing_gear_prompt()!="" else "Aubrey treated your wound. Search the clinic and talk to her about Blackwood."
 game.invincible=3

func missing_gear_names()->String:
 if not game.crash_site.has_backpack and not game.crash_site.has_flashlight:return "your backpack and flashlight"
 return "your backpack" if not game.crash_site.has_backpack else ("your flashlight" if not game.crash_site.has_flashlight else "")

func missing_gear_prompt()->String:
 var missing=missing_gear_names()
 return "Return to your car and grab "+missing+" from the trunk." if not missing.is_empty() else ""

func movement_scale()->float:
 if phase!="dimming":return 1.0
 var weakness=smoothstep(0,5.0,elapsed)
 var uneven=lerpf(1.0,0.65+0.35*absf(sin(elapsed*3.7)),weakness)
 return lerpf(1.0,0.18,weakness)*uneven

func caption_visible()->bool:
 return caption_elapsed<2.0 and phase in ["dimming","faint","blackout","wake"] and game.state in ["play","clinic_faint"]

func blackout_dots()->int:
 if phase!="blackout" or game.state!="clinic_faint":return 0
 var remaining=BLACKOUT_SECONDS-elapsed
 return clampi(ceili(remaining),1,3) if remaining>0 and remaining<=3.0 else 0
