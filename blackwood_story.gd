extends Node
## An original, optional evidence trail around the existing survival quest.
## Reading never blocks rescue or requires keeping a particular NPC alive.
var game
var evidence = {}
var county_bypass = false
var bypass_lamp: MeshInstance3D
const PROTOCOL = ["clinic_note","workshop_record","cellar_record"]
const RECORDS = {
  "ranger_note": [
    "Road closure log",
    "EVACUATION NIGHT / THREE NIGHTS AGO\nThe mill closed twelve years ago. Most families left over the next few years; the empty shops were boarded long before this emergency.\n01:40. The final bus took the last families still living here. I closed the road behind it.\n02:17. A bus horn sounded from the chapel loudspeaker. I reopened the barrier for the returning driver. No vehicle came.\n02:20. I radioed: \"Three still here. Road open.\" No reply.\nAt dawn only Aubrey, John and I remained. Station key is in my desk drawer. Ada left the shotgun-box key on the Saint George Hotel bedroom dresser.\n- Pat",
    "Pat reopened the barrier after a recorded bus horn. His last message was never acknowledged."
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
    "The coil powers this transmitter. The spare tuning unit provides the direct county channel. Fit both and the spare antenna coupler from Old Mill Cemetery.\nThen use the small BYPASS switch on the left of this desk. AMBER routes through the chapel repeater; GREEN goes directly to county dispatch.\nHold E at the main receiver to transmit. Identify Old Mill Road and request NO SIRENS.\nAubrey, John and the cellar log explain why.",
    "Radio routing is a physical switch: amber repeats through the chapel; green reaches county directly."
  ],
  "crash_record": [
    "The detour sheet",
    "You picked up this photocopied road notice at the fuel stop before turning onto Old Mill Road. You left it on the front seat.\nBRIDGE CLOSED. DIVERT THROUGH BLACKWOOD.\nThe seal is reversed and the sheet has no date. You trusted it.\nA shape crossed the headlights. You swerved into the stump beside the road.\nNo phone service. There are lights in town.",
    "The driver followed an undated detour sheet collected at a fuel stop, then swerved off the road."
  ],
  "workshop_record": [
    "John's disconnection log",
    "AFTER THE EVACUATION\nThe chapel carrier rode every relayed broadcast. Days near a speaker brought confusion; weeks brought changes. Ordinary radio is not the cause. That repeating tone is.\nBefore the bus left, it used Ada's voice while she stood beside me. I removed the station coil after she left. The separately powered hill rack still runs.\nMy cabinet holds the coil. The mausoleum holds the cellar key. The isolated county tuner and rifle are below the chapel. Collect the antenna coupler from the locked cemetery mausoleum as well. Fit all three parts; set the desk bypass GREEN.\n- John",
    "John stopped town broadcasts. The separately powered chapel carrier persists; direct county bypass avoids it."
  ],
  "chapel_record": [
    "Vestry maintenance book",
    "ONE MONTH BEFORE THE EVACUATION\nA month ago, the storm tore at roofs already neglected for years. It damaged the cellar repeater, which began carrying a low tone beneath old messages. Its buried line feeds the station and porch speaker. Nobody transmitted the tone.\nCaretaker Jonah slept beside the running rack. He forgot prayers, then his own name. His hands changed. I saw him crawl into the woods a week before the bus.\nWe kept the warning speaker running. We were spreading it.\nThese entries cover the month since the storm. Tonight I am leaving on the final bus.\n- Father Bellamy",
    "The storm-damaged chapel repeater spread an unidentified carrier. Caretaker Jonah was the first to change."
  ],
  "cellar_record": [
    "Carrier test / direct-channel procedure",
    "JOHN / CELLAR TEST\nThree shapes circle the hill: Jonah in his work coat; Edith with her clinic bracelet; Silas with the splinted hand. The missing did not bring monsters here. They became them.\nA shot stops them, but the carrier starts their bodies moving again about two minutes later. It is not a cure.\nTake the spare tuner and rifle. Fit tuner, coil and cemetery antenna coupler at the station; set BYPASS GREEN / DIRECT COUNTY. Call Old Mill Road, NO SIRENS, then switch off. Amber feeds this rack.",
    "Three transformed residents remain tethered to the active carrier. Gunfire stops them temporarily; green bypass avoids relaying it."
  ]
}

func _ready():
	name = "BlackwoodStory"
	for id in RECORDS:
		if game.town.actions.has(id):
			game.town.actions[id].title = RECORDS[id][0]
			game.town.actions[id].text = RECORDS[id][1]
	var town = game.town
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
	evidence.clear()
	county_bypass = false
	if bypass_lamp: bypass_lamp.material_override = game.town.mats.amber
	game.journal_casefile = false

func read_evidence(id: String):
	if RECORDS.has(id): evidence[id] = true

func direct_channel_selected() -> bool:
	return county_bypass

func rescue_line(progress: float) -> String:
	if direct_channel_selected():
		if progress<1.4: return "[YOU] Blackwood relay compromised. Send help without sirens."
		if progress<2.8: return "[COUNTY] Copy. Approach on foot from Old Mill Road."
		return "[COUNTY] Shut the transmitter down. Don't answer the other voice."
	if progress<1.4: return "[YOU] Car accident outside Blackwood. Is anyone receiving?"
	if progress<2.8: return "[RADIO] Three still here. Road open."
	return "[RADIO] Three still here. Road open. Three still here..."

func ending_title() -> String:
	return "NO SIRENS" if direct_channel_selected() else "SOMETHING ANSWERED"

func ending_text() -> String:
	if direct_channel_selected():
		var living = game.town.townspeople.characters.values().filter(func(data): return not data.dead).size()
		return "County dispatch confirms your location and the silent approach.\nYou report %d surviving residents and switch the set off.\nA rescue team will meet you on Old Mill Road.\nFor now, nothing else answers." % living
	return "The repeater plays Pat's three-night-old message again.\nNo dispatcher identifies themselves or confirms your location.\nYou release the transmit switch. The recording continues.\nThe repaired set was still connected to the chapel."

func question() -> String:
	if direct_channel_selected(): return "Direct county channel selected. Transmit from the main receiver."
	if evidence.has("cellar_record"): return "Repair the radio, then set the desk bypass to green before transmitting."
	if evidence.has("workshop_record"): return "John disabled relayed transmissions. The cellar holds a direct-channel unit."
	if evidence.has("clinic_note"): return "Can the carrier be bypassed before it changes anyone else?"
	if evidence.has("ranger_note"): return "Why did Pat reopen an evacuated road?"
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
