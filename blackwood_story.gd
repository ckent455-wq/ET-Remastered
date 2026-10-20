extends Node
## An original, optional evidence trail around the existing survival quest.
## Reading never blocks rescue or requires keeping a particular NPC alive.
var game
var evidence = {}
var ada_letter_requested=false
var ada_letter_delivered=false
const ADA_AMMO_REWARD=12
var ada_ammo_pending=0
var county_bypass = false
var repeater
var bypass_lamp: MeshInstance3D
const PROTOCOL = ["clinic_note","workshop_record","cellar_record"]
const RECORDS = {
  "ranger_note": [
    "Road closure log",
    "EVACUATION / THREE NIGHTS AGO\nThe mill closed twelve years ago. Most buildings were empty before this.\n01:40. Last bus departed. Barrier closed.\n02:17. Horn from chapel speaker. Opened road for returning bus. No vehicle.\n02:20. Sent: Three still here. Road open. No reply.\nLATER / THREE DATES IN THIS LOG\nI recognized the recording, then heard it again and went back to waiting for the bus. Each time I set out to close the barrier, I lost hours and returned to the office. I kept writing that I would close it after the bus passed.\nTonight Aubrey made me compare the dates. Three days, not one long night. The barrier is still open. Writing this down before I forget again.\nStation key: my drawer. Shotgun-box key: hotel dresser.\n- Pat",
    "The chapel horn kept drawing Pat into a confused waiting loop. He lost three days before Aubrey made him compare the dates. The road was never secured again."
  ],
  "clinic_note": [
    "Clinic observations",
    "THREE WEEKS OF EXPOSURE\nFirst: sleeplessness and ringing ears. Then missing hours, violent confusion and voices from unplugged sets. Late cases developed locked jaws and lengthening fingers. No fever or bites.\nThe two who refused the 01:40 bus, Edith and Silas, walked uphill at 02:10. I found Edith's bracelet on a changing wrist. They were my patients.\nPat and I stayed to search. Stop the chapel carrier. Tell rescue: NO SIRENS.\n- Aubrey",
    "Aubrey documented gradual mental and physical changes after prolonged exposure. Two creatures were her patients."
  ],
  "store_note": [
    "Last departure / 01:40",
    "Written before the final evacuation bus:\nFour unused tickets remain. Departure is 01:40. The driver will not return tonight.\nFor weeks customers forgot their shopping, then shouted at voices in the ceiling speaker. We called it exhaustion. The clinic called the evacuation.\nSebus Hardware and the other boarded shops have stood empty for years. We kept this general store open for the few families who stayed after the mill closed twelve years ago.\nOur roof has leaked through several winters. Last month's storm brought part of the ceiling down. Rear stock is spoiled. Do not come back for it.\nI left a workshop fuse in the counter drawer and batteries in the rear cabinet for whoever stays.\n- Ruth",
    "Blackwood declined for twelve years after the mill closed. The storm worsened old damage; the last remaining families evacuated three nights ago."
  ],
  "house_note": [
    "Ada's letter",
    "John,\nI am taking the final 01:40 bus. I packed for two nights in case they let us return.\nMost of the rooms at Saint George Hotel have been shut for years. We kept ours warm and dry. Please do not spend another winter here alone.\nFirst it was the ringing. Then you forgot our address. You slept when we unplugged the set and stayed away from the hill. Please keep it off.\nYou heard my voice on the radio while I stood beside you. I believe you. You do not owe that repeater another night.\nCome after you secure the equipment. Aubrey still needs a seat. The shotgun-box key is on our dresser.\nI left dinner. I thought we had more time.\n- Ada",
    "Ada describes John's early symptoms easing away from the signal. She left on the last bus."
  ],
  "radio_note": [
    "County radio / bypass switch",
    "The coil powers this transmitter. The spare tuning unit provides the direct county channel. Fit both and the spare antenna coupler from Old Mill Cemetery.\nFirst shut down the chapel basement rack at MAIN ISOLATOR. Then set this desk's BYPASS to GREEN for direct county. AMBER goes through the now-silent repeater and cannot reach county.\nHold E at the main receiver to transmit. Identify Old Mill Road and request NO SIRENS.\nAubrey, John and the cellar log explain why.",
    "Radio routing is a physical switch: amber repeats through the chapel; green reaches county directly."
  ],
  "crash_record": [
    "The detour sheet",
    "You picked up this photocopied road notice at the fuel stop before turning onto Old Mill Road. You stowed it in the trunk.\nBRIDGE CLOSED. DIVERT THROUGH BLACKWOOD.\nThe seal is reversed and the sheet has no date. You trusted it.\nA shape crossed the headlights. You swerved into the stump beside the road.\nNo phone service. There are lights in town.",
    "The driver followed an undated detour sheet collected at a fuel stop, then swerved off the road."
  ],
  "workshop_record": [
    "John's disconnection log",
    "AFTER THE EVACUATION\nI inspected the chapel cellar three weeks before the bus, before the creatures reached the grounds. The station still worked. I left the spare county tuner disconnected on the bench and the service rifle in the emergency supplies.\nI removed the station coil after Ada left. Town broadcasts stopped; the separately powered hill rack did not. When I tried to return for the spare equipment, creatures drove me back down the hill.\nJonah's coat. Edith's bracelet. Silas's splint. Those three were living residents changed by exposure. A shot stops them, but they move again about two minutes later while the carrier runs. Aubrey found older dead moving beneath the cemetery too.\nMy cabinet holds the coil. Pat cached the cellar key and spare antenna coupler in his locked family vault during the evacuation. Get the tuner and rifle from the chapel. Cut its rack at MAIN ISOLATOR. Fit all three radio parts at the station; set BYPASS GREEN and call.\n- John",
    "John inspected the cellar before the creatures arrived. His later return failed. The chapel remains powered; cut its independent supply before calling on the green bypass."
  ],
  "chapel_record": [
    "Vestry maintenance book",
    "PARISH HISTORY / 1891\nMill families built above the flood line. The nave sheltered neighbors. The county added the cellar repeater decades later.\nONE MONTH BEFORE EVACUATION\nThe storm damaged the old repeater. A low tone began beneath recordings. Its buried line feeds the station and porch speaker. Nobody transmitted it.\nCaretaker Jonah slept by the rack. He forgot prayers, then his name. His hands changed. He crawled into the woods a week before the bus.\nWe kept the warning speaker running. We were spreading it.\nThese entries cover the last month. Tonight I leave on the final bus.\n- Father Bellamy",
    "The storm-damaged chapel repeater spread an unidentified carrier. Caretaker Jonah was the first to change."
  ],
  "cellar_record": [
    "Carrier test / direct-channel procedure",
    "JOHN / EQUIPMENT CHECK\nTHREE WEEKS BEFORE EVACUATION\nThe station still works. Leave the spare county tuning unit disconnected on this bench. Keep the service rifle with the emergency supplies. Bellamy can lock the cellar after the inspection.\nThe hill rack has its own supply. Removing the station coil will not shut this equipment down.\nIf the town receiver needs rebuilding: fit its coil, this spare tuner and the cemetery antenna coupler. Set the station desk BYPASS GREEN for DIRECT COUNTY. Amber routes through this rack.\nBefore transmitting, cut this rack's independent supply at MAIN ISOLATOR. Then return to the station, select GREEN and call. Switching off the station alone cannot silence the chapel.\n- John",
    "John's earlier inspection left the spare tuner and rifle in the cellar. Cut the chapel rack at MAIN ISOLATOR before transmitting from the station on GREEN."
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
		return "The chapel repeater is off. County dispatch confirms your location and the silent approach.\nYou report %d surviving residents and switch the set off.\nA rescue team will meet you on Old Mill Road.\nFor now, nothing else answers." % living
	return "The repeater plays Pat's three-night-old message again.\nNo dispatcher identifies themselves or confirms your location.\nYou release the transmit switch. The recording continues.\nThe repaired set was still connected to the chapel."

func question() -> String:
	if game.town.radio_ready and not repeater_is_off():return "Shut down the chapel basement repeater before calling for rescue."
	if direct_channel_selected(): return "Silence the chapel repeater, then transmit on the direct county channel." if not repeater_is_off() else "Carrier silent. Transmit on the direct county channel."
	if evidence.has("cellar_record"): return "Repair the radio, then set the desk bypass to green before transmitting."
	if evidence.has("workshop_record"): return "John disabled town broadcasts. The chapel still has its own power: take the spare tuner and cut its MAIN ISOLATOR."
	if evidence.has("clinic_note"): return "Can the carrier be bypassed before it changes anyone else?"
	if evidence.has("ranger_note"): return "Pat lost three days to the repeated horn. Can the chapel carrier be silenced?"
	return "The detour sheet was undated. Why was the road into Blackwood still open?"

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
