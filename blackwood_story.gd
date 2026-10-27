extends Node
## An original, optional evidence trail around the existing survival quest.
## Reading never blocks rescue or requires keeping a particular NPC alive.
var game
const AUBREY_BRIEFING = "Four weeks ago, the station radio started speaking with the switch off. Bellamy put it through the chapel speaker. Since then I've seen people stop sleeping, lose hours, and change in ways I can't account for. The worst cases lived nearest the speaker. I don't know what that means yet.\n\nIt isn't only people. Pat brings in dust from ground he says was wet. The trees along the road have gone brittle. I keep finding grit in dressings I've just opened. We looked for an ordinary cause. We haven't found one.\n\nThe last families left three nights ago. Pat, John and I are still here. John knows the radio equipment; Pat's station key is in his office drawer. My observations are on the shelf if you want to read them.\n\nIf you hear me calling from outside, come and check this room first."
var evidence = {}
var pat_vault_seen=false
var pat_tunnel_seen=false
var pat_cellar_seen=false
var crash_wound_treated=false
var clinic_rescue_done=false
var ada_letter_requested=false
var ada_letter_delivered=false
const ADA_AMMO_REWARD=12
var ada_ammo_pending=0
var county_bypass = false
var repeater
var bypass_lamp: MeshInstance3D
const PROTOCOL = ["radio_note","clinic_note","cellar_record"]
const RECORDS = {
  "ranger_note": [
    "Road closure log",
    "EVACUATION / THREE NIGHTS AGO\nThe mill closed twelve years ago. Most buildings were empty before this.\n01:40. Last bus departed. Barrier closed.\n02:17. Horn from chapel speaker. Opened road for returning bus. No vehicle.\n02:20. Sent: Three still here. Road open. No reply.\nLATER / THREE DATES IN THIS LOG\nI recognized the recording, then heard it again and went back to waiting for the bus. Each time I set out to close the barrier, I lost hours and returned to the office. I kept writing that I would close it after the bus passed.\nTonight Aubrey made me compare the dates. Three days, not one long night. The barrier is still open. Writing this down before I forget again.\nStation key: my drawer. Shotgun-box key: hotel dresser.\n- Pat",
    "The chapel horn kept drawing Pat into a confused waiting loop. He lost three days before Aubrey made him compare the dates. The road was never secured again."
  ],
  "clinic_note": [
    "Clinic / exposure and transformation",
    "THREE WEEKS BEFORE EVACUATION\nFirst: ringing ears and lost sleep. Then familiar voices, paranoia, missing hours and violent confusion. Finally locked jaws, lengthening fingers and altered bodies. No bites. No fever.\nJonah slept beside the chapel amplifier. He changed first. After the final bus, Edith and Silas followed voices uphill. I recognized her bracelet and his splint on the creatures outside the chapel. Those were living townspeople.\nBENEATH THE CEMETERY\nOlder coffins forced open from inside. The wrapped bodies were dead before this began. The broadcast is waking the deceased as well as changing the living.\nTell rescue: NO SIRENS. The creatures follow sound.\n- Aubrey",
    "Exposure changed the living and woke the dead. The chapel creatures were townspeople."
  ],
  "store_note": [
    "Last departure / 01:40",
    "Written before the final evacuation bus:\nFour unused tickets remain. Departure is 01:40. The driver will not return tonight.\nFor weeks customers forgot their shopping, then shouted at voices in the ceiling speaker. We called it exhaustion. The clinic called the evacuation.\nSebus Hardware and the other boarded shops have stood empty for years. We kept this general store open for the few families who stayed after the mill closed twelve years ago.\nOur roof has leaked through several winters. Last month's storm brought part of the ceiling down. Rear stock is spoiled. Do not come back for it.\nI left a workshop fuse in the counter drawer and batteries in the rear cabinet for whoever stays.\n- Ruth",
    "Blackwood declined for twelve years after the mill closed. The storm worsened old damage; the last remaining families evacuated three nights ago."
  ],
  "house_note": [
    "Ada's letter",
    "John,\nI am taking the final 01:40 bus. Our room at Saint George Hotel will be waiting when this is over.\nFirst the ringing. Then you forgot our address. You slept better away from the station, but you kept going back when the walnut set called.\nYou heard my voice inside it while I stood beside you. Yesterday it used your mother's voice. Please remember she has been dead for eleven years.\nIt keeps promising to bring someone home if you leave it broadcasting. That is why Bellamy will not turn the chapel amplifier off. That is why you must.\nCome after you secure the equipment. Aubrey still needs a seat. The shotgun-box key is on our dresser.\nI left dinner. I thought we had more time.\n- Ada",
    "Ada heard the radio imitate her while she stood beside John. Its promises kept him listening; distance eased his symptoms."
  ],
  "radio_note": [
    "Station operator / first broadcast",
    "FOUR WEEKS BEFORE EVACUATION / 02:17\nThe walnut radio began speaking with its switch OFF. No scheduled broadcast. No station identification. I unplugged it and removed the antenna. The voices continued.\nIt used my father's voice. He died in 1986. It said: \"Keep us on. Let them hear us.\"\nBellamy agreed to put its output through the chapel warning system so someone could identify it. After we connected the buried line, the voices reached every street.\nNo incoming frequency on the meter. It begins inside this set. We do not know what is speaking.\nJOHN'S WARNING: Do not reconnect the amber chapel route. Read my workshop log before repairing the transmitter.",
    "An unplugged station radio spoke. Bellamy spread its voices through the chapel."
  ],
  "crash_record": [
    "The detour sheet",
    "You picked up this photocopied road notice at the fuel stop before turning onto Old Mill Road. You stowed it in the trunk.\nBRIDGE CLOSED. DIVERT THROUGH BLACKWOOD.\nThe seal is reversed and the sheet has no date. You trusted it.\nA shape crossed the headlights. You swerved into the stump beside the road.\nNo phone service. There are lights in town.",
    "The driver followed an undated detour sheet collected at a fuel stop, then swerved off the road."
  ],
  "workshop_record": [
    "John / why pulling the coil failed",
    "AFTER THE EVACUATION\nThe walnut radio was the first source. Bellamy's chapel rack amplified it. We kept both connected because the voices sounded like people we had lost.\nI pulled the station's transmitter coil after Ada left. Normal town broadcasts stopped. The voices did not. The chapel's independent supply kept feeding the buried return line back into the set.\nAt my earlier inspection, cutting the rack's MAIN ISOLATOR broke that loop: the unplugged set fell silent. Bellamy turned it back on when it called his sister's name. We should have left it off.\nMy cabinet holds the coil. Pat secured the antenna coupler and cellar key in his mausoleum. Take the spare county tuner from the chapel and cut MAIN ISOLATOR. Then rebuild the station and select BYPASS GREEN.\n- John",
    "John traced a powered feedback loop. The chapel isolator silences it; the spare tuner and GREEN bypass allow a clean county call."
  ],
  "chapel_record": [
    "Vestry / the broadcast we spread",
    "PARISH HISTORY / 1891\nMill families built this chapel above the flood line. The county added the warning repeater decades later.\nFOUR WEEKS BEFORE EVACUATION\nThe station operator brought a recording: voices from the walnut radio, even unplugged. We connected its output to our buried warning line, hoping someone would identify the speaker.\nThe voices asked us to keep broadcasting. I heard my dead sister. Jonah heard his mother. We left the amplifier on for them.\nWithin days Jonah forgot prayers, then his name. His hands changed. The worst cases lived nearest our speaker.\nThe storm damaged roofs, not the beginning of this signal. We mistook an invitation for a call for help.\n- Father Bellamy",
    "Bellamy amplified the station voices to identify them. Familiar voices kept him broadcasting; exposure was worst near the chapel."
  ],
  "cellar_record": [
    "John / isolate the signal, then call",
    "EQUIPMENT TEST / THREE WEEKS BEFORE EVACUATION\nSOURCE: station walnut radio. No incoming station found.\nAMPLIFIER: this chapel rack. Its own supply feeds the warning speaker AND a buried return line to the station. Pulling the station coil alone cannot stop that loop.\nTEST: MAIN ISOLATOR OFF cuts power and the return line. Both the rack and the unplugged station set fall silent. What started the voices remains unknown.\nSAFE CALL:\n1. Leave MAIN ISOLATOR OFF.\n2. Fit the station coil, this spare county tuner and the cemetery antenna coupler.\n3. Set the station desk BYPASS GREEN: direct county, isolated from the contaminated chapel line. AMBER reconnects that line.\n4. Hold E at the receiver. Confirm a real dispatcher and request NO SIRENS. Switch the set off afterward.\n- John",
    "Cut MAIN ISOLATOR. Fit all three parts; select GREEN and call county without sirens."
  ]
}

func _ready():
	name = "BlackwoodStory"
	for id in RECORDS:
		if game.town.actions.has(id):
			game.town.actions[id].title = RECORDS[id][0]
			game.town.actions[id].text = RECORDS[id][1]
	var town = game.town
	town.actions.house_note.label="Take Ada's letter"
	game.crash_site.build_detour_sheet()
	document(town.buildings.workshop,Vector3(-3.15,0.94,-2.4),"workshop_record")
	var chapel = town.streetscape.church
	# A small lectern in the side aisle leaves the nave's center clear.
	town.box(chapel,Vector3(-4.1,0.56,4.4),Vector3(0.7,1.1,0.55),town.mats.furniture)
	document(chapel,Vector3(-4.1,1.12,4.4),"chapel_record")
	var basement = chapel.basement
	for prop in basement.get_children():
		if prop is Node3D and prop.is_in_group("LocalInteriorProps") and prop.get_meta("source_asset","")=="books":
			prop.position = Vector3(-3.38,0.92,-3.42)
	document(basement,Vector3(-1.72,0.94,-3.02),"cellar_record")
	basement.prepare_cellar_lighting(basement)
	build_bypass()
	repeater=preload("res://chapel_repeater.gd").new();repeater.game=game;basement.add_child(repeater)

func build_bypass():
	var town = game.town
	var area = town.action_area(town.buildings.radio,Vector3(-4.05,1.00,-3.05),Vector3(0.32,0.27,0.24),"radio_bypass",{"kind":"radio_bypass","label":"Set radio bypass"})
	town.box(area,Vector3.ZERO,Vector3(0.28,0.18,0.15),town.mats.metal,false)
	var lamp = town.box(area,Vector3(0,0.04,0.085),Vector3(0.10,0.04,0.012),town.mats.amber,false)
	bypass_lamp = lamp.get_child(0)
	var label = town.sign_text(area,"BYPASS",Vector3(0,0.17,0),14,Color("bcb59f"))
	label.pixel_size = 0.003

func toggle_bypass():
	if not game.town.radio_ready:
		game.message = "Fit the coil, tuning unit and cemetery antenna coupler before setting the bypass."
		return
	county_bypass = not county_bypass
	bypass_lamp.material_override = game.town.mats.green if county_bypass else game.town.mats.amber
	game.message = "GREEN / Direct county channel. Hold E at the main receiver." if county_bypass else "AMBER / Chapel repeater connected."
	game.soundscape.flashlight_click(county_bypass)

func document(parent: Node3D, p: Vector3, id: String):
	var row = RECORDS[id]
	var area = game.town.action_area(parent,p,Vector3(0.43,0.14,0.37),id,{"kind":"note","label":"Read "+row[0],"title":row[0],"text":row[1]})
	game.town.box(area,Vector3.ZERO,Vector3(0.36,0.015,0.29),game.town.mats.paper,false)
	for i in range(4):
		game.town.box(area,Vector3(-0.02,0.012,-0.08+i*0.045),Vector3(0.25,0.004,0.008),game.town.mats.dark,false)
	area.add_to_group("StoryEvidence")

func reset():
	pat_vault_seen=false;pat_tunnel_seen=false;pat_cellar_seen=false
	crash_wound_treated=false;clinic_rescue_done=false
	ada_letter_requested=false;ada_letter_delivered=false;ada_ammo_pending=0
	evidence.clear()
	county_bypass = false
	if repeater:repeater.reset()
	if bypass_lamp: bypass_lamp.material_override = game.town.mats.amber
	game.journal_casefile = false

func read_evidence(id: String):
	if RECORDS.has(id): evidence[id] = true

func repeater_is_off()->bool:
	return repeater!=null and repeater.shutdown_done

func direct_channel_selected() -> bool:
	return county_bypass

func rescue_line(progress: float) -> String:
	if direct_channel_selected():
		if progress<1.4: return "[YOU] Blackwood relay compromised. Send help without sirens."
		if progress<2.8: return "[COUNTY] Copy. Carrier is silent. Approach on foot from Old Mill Road."
		return "[COUNTY] Shut the transmitter down. Don't answer the other voice."
	if progress<1.4: return "[YOU] Car accident outside Blackwood. Is anyone receiving?"
	if progress<2.8: return "[RADIO] Three still here. Road open."
	return "[RADIO] Three still here. Road open. Three still here..."

func ending_title() -> String:
	return "NO SIRENS" if direct_channel_selected() else "SOMETHING ANSWERED"

func ending_text() -> String:
	if direct_channel_selected():
		var living = game.town.townspeople.characters.values().filter(func(data): return not data.dead).size()
		return "The chapel repeater is off. The station voices stopped when you broke its return loop. County dispatch confirms your location and the silent approach.\nYou report %d surviving residents and switch the set off.\nA rescue team will meet you on Old Mill Road.\nYou know how the signal spread, but not what first spoke through the set. For now, nothing else answers." % living
	return "The repeater plays Pat's three-night-old message again.\nNo dispatcher identifies themselves or confirms your location.\nYou release the transmit switch. The recording continues.\nThe repaired set was still connected to the chapel."

func question() -> String:
	if game.town.radio_ready and not repeater_is_off():return "Shut down the chapel basement repeater before calling for rescue."
	if direct_channel_selected(): return "Silence the chapel repeater, then transmit on the direct county channel." if not repeater_is_off() else "Carrier silent. Transmit on the direct county channel."
	if evidence.has("cellar_record"): return "The chapel feeds a return loop to the station. Cut MAIN ISOLATOR; repair the radio and use GREEN to call county."
	if evidence.has("workshop_record"): return "Pulling the station coil did not stop the voices. John tested a way to break the chapel feedback loop: MAIN ISOLATOR."
	if evidence.has("clinic_note"): return "The signal changes living people and wakes the dead. Where did it begin, and how can it be silenced?"
	if evidence.has("chapel_record"): return "Bellamy spread the station voices through the chapel amplifier. Find John's isolation test in the cellar."
	if evidence.has("radio_note"): return "The station radio spoke with no power or incoming station. Why did the voices ask to be broadcast?"
	if evidence.has("ranger_note"): return "Pat lost three days to the repeated horn. Can the chapel carrier be silenced?"
	return "Why was Blackwood abandoned? Ask the survivors and look for records at the station, clinic and chapel."

func collect_detour_sheet():
	var id = "crash_record"
	read_evidence(id)
	if not game.town.journal_entries.any(func(entry): return entry.id==id):
		game.town.journal_entries.append({"id":id,"title":RECORDS[id][0],"text":RECORDS[id][1]})
	for i in range(game.town.journal_entries.size()):
		if game.town.journal_entries[i].id==id: game.journal_page=i+2
	game.journal_casefile=false
	game.set_state("journal")

func request_ada_letter():
	ada_letter_requested=true
	update_ada_quest()
func update_ada_quest():
	var text="Find Ada's letter in her room at Saint George Hotel and bring it to John at the workshop."
	if ada_letter_delivered:text="COMPLETED: You brought Ada's letter to John. He read her words and put it safely in his coat."
	elif game.town.townspeople.characters.mechanic.dead:text="John is dead. Ada's letter can no longer be delivered this journey."
	elif game.town.inventory.ada_letter>0:text="Ada's letter is in your backpack. Give it to John at the workshop."
	if ada_letter_delivered:text+=" Reward: 12 pistol rounds."+(" John is holding %d rounds until you have room." % ada_ammo_pending if ada_ammo_pending>0 else " Collected.")
	for entry in game.town.journal_entries:
		if entry.id=="ada_letter_quest":entry.text=text;return
	game.town.journal_entries.append({"id":"ada_letter_quest","title":"Side quest / Ada's letter","text":text})
func deliver_ada_letter()->bool:
	if ada_letter_delivered or game.town.inventory.ada_letter<=0 or game.town.townspeople.characters.mechanic.dead:return false
	game.town.inventory.ada_letter-=1;ada_letter_delivered=true;ada_letter_requested=true
	ada_ammo_pending=ADA_AMMO_REWARD
	claim_ada_ammo()
	update_ada_quest()
	game.message="Side quest completed: Ada's letter delivered. Reward: 12 pistol rounds."
	game.soundscape.feedback("pickup")
	return true

func claim_ada_ammo()->int:
	if not ada_letter_delivered or ada_ammo_pending<=0 or game.town.townspeople.characters.mechanic.dead:return 0
	var added=game.weapons.add_ammo(0,ada_ammo_pending)
	ada_ammo_pending-=added
	update_ada_quest()
	return added
func ada_reward_line()->String:
	if ada_ammo_pending>0:return "I've set aside twelve pistol rounds for you. I'm holding the remaining %d until you've used some ammo or made room in your pack. Come talk to me then." % ada_ammo_pending
	return "Here. Twelve pistol rounds. It's what I can spare. You brought something back that matters to me. Take care of yourself out there."

func refresh_collected_notes():
	# Refresh only entries already earned, including journals loaded from older builds.
	var conversation = game.town.townspeople.conversation
	var previous_speaker = conversation.speaker
	for entry in game.town.journal_entries:
		var id = entry.get("id","")
		if RECORDS.has(id):
			entry.title = RECORDS[id][0]
			entry.text = RECORDS[id][1]
		elif id=="repeater_shutdown":
			entry.text = "You cut the chapel rack's power and buried return line. The station voices stopped. Repair the receiver, select GREEN to isolate the chapel line and call county without sirens."
		else:
			for person in [{"prefix":"john_","speaker":"mechanic"},{"prefix":"aubrey_","speaker":"nurse"},{"prefix":"pat_","speaker":"ranger"}]:
				if id.begins_with(person.prefix):
					conversation.speaker = person.speaker
					var updated = conversation.summary(id.trim_prefix(person.prefix))
					if not updated.is_empty():entry.text = updated
	conversation.speaker = previous_speaker

func needs_aubrey_introduction()->bool:
	return crash_wound_treated and not clinic_rescue_done and not game.town.townspeople.characters.nurse.dead and not game.town.townspeople.conversation.greetings.has("nurse")

func record_aubrey_briefing():
	if not game.town.journal_entries.any(func(e):return e.id=="aubrey_briefing"):
		game.town.journal_entries.append({"id":"aubrey_briefing","title":"Aubrey / What happened to Blackwood","text":"Aubrey says the station radio began speaking on its own. Bellamy amplified it through the chapel, spreading a signal that caused sleeplessness, missing time and transformation. The chapel creatures were townspeople; the wrapped cemetery bodies were already dead. The last families evacuated three nights ago. Read the clinic chart, station operator's log and chapel book. Speak to John at the workshop about the equipment. Pat's office drawer holds the station key. Familiar voices may be imitations, even Aubrey's."})
