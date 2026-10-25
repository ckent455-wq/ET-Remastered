extends RefCounted
## Optional local history and advice; it never replaces the physical quest steps.
var game
var pat_story=preload("res://pat_cemetery_dialogue.gd").new()
var question_scroll=0
const VISIBLE_QUESTIONS=5
var active=false
var choosing=false
var greeted=false
var selected=0
var current_topic=""
var asked={}
const BOX=Rect2(60,246,520,148)
var speaker="ranger"
var greetings={}
var TOPICS=[]
const QUESTIONS={
 "ranger":[["town","What happened to Blackwood?","Blackwood's decline"],["house","What's with the house at the end of the street?","The old house"]],
 "nurse":[["signal","What is the signal doing to people?","The broadcast and its victims"],["patients","What happened to your patients?","The missing patients"]],
 "mechanic":[["origin","Where did the broadcast begin?","The radio that spoke alone"],["church","Why is there radio equipment beneath the church?","The hilltop church"],["stayed","Why didn't you leave with Ada?","The promise to Ada"]]
}
func speaker_name()->String:
 return {"ranger":"Pat","nurse":"Aubrey","mechanic":"John"}[speaker]
func entry_id(topic:String)->String:
 return speaker_name().to_lower()+"_"+topic

func reset():
 cancel();greeted=false;selected=0;asked.clear();greetings.clear()
func cancel():
 active=false;choosing=false;current_topic=""
func begin(intro:String,force_intro=false,person="ranger"):
 # The bedside introduction also counts in journeys saved before this fix.
 if person=="nurse" and game.story.clinic_rescue_done:greetings["nurse"]=true
 speaker=person;TOPICS=[]
 for item in (pat_story.topics(self) if speaker=="ranger" else QUESTIONS[speaker]):TOPICS.append({"id":item[0],"question":item[1],"title":speaker_name()+" / "+item[2]})
 TOPICS.append({"id":"help","question":"What should I do next?","title":speaker_name()+" / Getting help"})
 active=true;selected=0;question_scroll=0;current_topic=""
 game.dialogue_name=game.town.townspeople.characters[speaker].name
 game.dialogue_text=intro
 game.set_state("dialogue")
 if not greetings.has(speaker) or force_intro:
  greeted=true;greetings[speaker]=true;choosing=false
 else:show_topics()
func show_topics():
 choosing=true;current_topic=""
func row(index:int)->Rect2:
 return Rect2(76,272+(index-question_scroll)*22,488,21)
func move_selection(amount:int):
 if choosing:
  selected=wrapi(selected+amount,0,TOPICS.size()+1)
  if selected<question_scroll:question_scroll=selected
  if selected>=question_scroll+VISIBLE_QUESTIONS:question_scroll=selected-VISIBLE_QUESTIONS+1
func choose(index:int):
 if not active or not choosing:return
 if index==TOPICS.size():game.set_state("play");return
 if index<0 or index>=TOPICS.size():return
 selected=index;current_topic=TOPICS[index].id;choosing=false
 game.dialogue_text=answer(current_topic)
 game.dialogue_pages=preload("res://dialogue_style.gd").pages(game.dialogue_text)
 game.dialogue_page=0
 game.hud.dialogue_last_page=-1
 var note_id=entry_id(current_topic)
 var found=false
 for entry in game.town.journal_entries:
  if entry.id==note_id:entry.text=summary(current_topic);found=true;break
 if not found:game.town.journal_entries.append({"id":note_id,"title":TOPICS[index].title,"text":summary(current_topic)})
 asked[entry_id(current_topic)]=true
func advance():
 if choosing:choose(selected)
 elif game.dialogue_page+1<game.dialogue_pages.size():game.dialogue_page+=1
 else:show_topics()
func handle(event):
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_UP,KEY_W:move_selection(-1)
   KEY_DOWN,KEY_S:move_selection(1)
   KEY_E,KEY_ENTER,KEY_SPACE:advance()
   KEY_ESCAPE,KEY_TAB:
    if choosing:game.set_state("play")
    else:show_topics()
 elif event is InputEventMouseMotion and choosing:
  for i in range(question_scroll,mini(question_scroll+VISIBLE_QUESTIONS,TOPICS.size()+1)):
   if row(i).has_point(event.position):selected=i;break
 elif event is InputEventMouseButton and event.pressed:
  if choosing:
   if event.button_index==MOUSE_BUTTON_WHEEL_UP:move_selection(-1)
   elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:move_selection(1)
   elif event.button_index==MOUSE_BUTTON_LEFT:
    for i in range(question_scroll,mini(question_scroll+VISIBLE_QUESTIONS,TOPICS.size()+1)):
     if row(i).has_point(event.position):choose(i);break
  elif event.button_index==MOUSE_BUTTON_LEFT and preload("res://dialogue_style.gd").BOX.has_point(event.position):advance()

func answer(topic:String)->String:
 if speaker=="ranger" and topic in ["waiting","cemetery","family","vault","grave","shadow"]:return pat_story.answer(self,topic)
 match topic:
  "origin":
   return "It started in that walnut radio at the station, four weeks before the evacuation. No operator. No incoming station. The switch was off. We pulled the plug and antenna, and it kept speaking. The operator wrote it all down beside the set.\n\nIt used dead people's voices. Then Ada's voice, while she was standing beside me. It wasn't just a recording. It wanted us to connect it to the chapel so everyone could hear.\n\nWe thought someone needed help. Bellamy connected the buried line and left the hill amplifier running. Then the sleeplessness began. The missing hours. Jonah changed first.\n\nI can trace the circuit. I cannot tell you what got inside that set. The voices know things they shouldn't. That doesn't make them the people they sound like."
  "town":
   return "Blackwood grew around the mill. Shift whistles, school buses, the church bell on Sunday. You used to hear people before you saw the town.\n\nThe mill closed twelve years ago. Families sold up, shops boarded their windows. That old damage wasn't done in a night.\n\nThe last families left three nights ago, after weeks of trouble with the signal. The bus really did leave. The horn I heard afterward came from the chapel speaker. I opened the road for a recording.\n\nI knew it wasn't a bus. Then the horn played again and I was waiting for the driver. Every time I started back to close the barrier, I'd lose hours and find myself in the office. I kept thinking I would shut it after the bus passed.\n\nTonight Aubrey put three dated pages in front of me. I thought it had been one long night. Three days. That's why the road was still open when you came through. I keep writing it down now so I won't forget again."
  "house":
   var line="The big timber house beyond the shops? That was the mill superintendent's place. The people there held on for three years after the mill closed. Their clearance notice is still downstairs. Nine years, and nobody ever came back for the furniture.\n\nAfter last month's storm I checked it for squatters. Dry cellar, thick walls. I thought it might shelter anyone who missed the evacuation.\n\nThen I found fresh mud on the cellar steps. Bare footprints going down. None coming back up. There was a fresh hole through the foundation. Soil pushed into the room, burial cloth snagged on the brick. Something had dug in from outside. The burrow was choked with fallen earth; I couldn't get through it. I shut the cellar door. That doesn't mean it's empty."
   if game.town.journal_entries.any(func(entry):return entry.id=="victorian_letter"):
    line+="\n\nYou found the notice? Then you know they left years before this signal. Whatever is in there now moved in afterward."
   return line
  "church":
   return "The chapel was built in 1891 as a refuge above the flood line. The county later put a warning amplifier in its cellar: high ground, a buried line to the station, and a speaker that reaches the street.\n\nThe signal began at the station radio. Bellamy connected it to the chapel to identify the voices. When it spoke as his dead sister, he wouldn't shut it off. The neighbors closest to that speaker got the worst exposure. Jonah slept beside the rack. Read Bellamy's maintenance book inside.\n\nI tested the system three weeks before evacuation. The rack's independent supply feeds a return line into the station set. Pulling the transmitter coil stops ordinary broadcasts, but that loop keeps the voices alive.\n\nMAIN ISOLATOR breaks both power and the return line. I heard both ends fall silent. Bellamy switched it back on. I left the spare county tuner and service rifle in the cellar; when I tried to return after Ada left, the creatures drove me down the hill. Cut that isolator, then use GREEN at the station. Never reconnect AMBER."
  "signal":
   var line="First they stopped sleeping. Then they heard familiar voices, became frightened of their families and lost hours they couldn't account for. Finally their bodies changed. No fever. No bites. This wasn't an infection spreading between people.\n\nThe first voices came from the walnut radio at the station. Bellamy sent them through the chapel amplifier. The longest exposure was around that speaker; that's where the worst cases gathered.\n\nRead my observations in the clinic and the operator's log by the radio. John's cellar test explains how to stop it. He removed the station coil, but the chapel kept feeding a return line into the set. Cutting MAIN ISOLATOR stops both.\n\nPat's memory is failing too. Tonight I showed him three dated pages; he thought the last three days were one night. We need a real county dispatcher, not another voice promising to bring someone back."
   if game.story.evidence.has("clinic_note") or game.story.evidence.has("cellar_record"):
    line+="\n\nThose names in the records were our neighbors. I recognized Edith's bracelet and Silas's splinted hand. Whatever you hear in the woods, don't mistake a familiar voice for someone safe."
   return line
  "patients":
   var line="Edith wouldn't leave without Silas. He could barely walk with that splint. I kept two beds ready after the last bus left. By dawn, both beds were empty. Their tracks led uphill.\n\nI went looking. One of those things still wore Edith's bracelet. The other dragged a hand wrapped in the splint I'd fitted. I knew them before I could make myself believe it.\n\nJonah, the chapel caretaker, changed first. It happened over weeks, not all at once. If you reach the county, tell them to come without sirens. The things follow sound."
   if game.story.evidence.has("clinic_note"):line+="\n\nYou've read my chart. Those weren't isolated symptoms. It was the same progression in every patient exposed to that tone."
   line+="\n\nBut the shrouded things beneath the cemetery are different. Those bodies were already dead before the signal began. I found coffins forced open from inside. The tone seems able to move them again. I don't know whether they remember anything. The cloth on them is burial wrapping, not bandages I put there."
   return line
  "stayed":
   game.story.request_ada_letter()
   if game.story.ada_letter_delivered:return "I keep her letter in my coat now. You brought back something I was afraid I had lost. Once the radio is safe, I am going after her."
   return "Ada took the last bus. I promised I'd follow after securing the radio equipment. Her letter is still in our room at Saint George Hotel. I haven't had the courage to go back for it. If you get inside, would you bring it to me?\n\nBefore she left, I was losing hours. She said I repeated things she'd never told me. I blamed the wiring, exhaustion, anything except the set I kept running.\n\nPulling the station coil stopped ordinary broadcasts, but the voices continued through the chapel return loop. Away from the receiver, my head began to clear. The hill speaker kept going on its own power. I stayed because I'd helped keep that thing talking. I need to leave this town quiet before I go."
  "help":
   return game.town.townspeople.words(speaker)
 return "Take care out there."

func summary(topic:String)->String:
 if speaker=="ranger" and topic in ["waiting","cemetery","family","vault","grave","shadow"]:return pat_story.summary(self,topic)
 match topic:
  "origin":return "John says the station radio began speaking while switched off and unplugged. It imitated dead relatives and Ada while she was present, asking to be broadcast. Bellamy connected it to the chapel amplifier. The original speaker remains unidentified."
  "town":return "Pat says the mill closed twelve years ago. Most of the decay predates the signal. The final families evacuated three nights ago. A recorded chapel horn fooled him into reopening Old Mill Road. Repeated exposure disrupted his memory: he kept waiting for the bus, lost hours and failed to close the barrier for three days. Aubrey confronted him with the dated log tonight."
  "house":return "The old Victorian house belonged to the mill superintendent. Its occupants left nine years ago; their clearance notice is downstairs. Pat found fresh bare footprints leading into the cellar after the storm. He also found a freshly dug breach, soil pushed inward and burial cloth caught on the masonry. Its short burrow was blocked by collapsed earth. He could not identify what came through."
  "church":return "The chapel amplified the station signal, exposing the neighborhood. John tested its independent supply and buried return line: MAIN ISOLATOR silences both ends. Use the spare county tuner and station GREEN bypass to make a clean rescue call."
  "signal":return "Aubrey traces sleeplessness, paranoia, missing time and physical transformation to exposure. The station broadcast began first; the chapel amplified it. John found how to break the feedback loop. Familiar voices are not proof the missing people are speaking."
  "patients":return "Aubrey stayed for Edith and Silas after they refused the final bus. Their tracks led toward the chapel; she recognized their bracelet and splint on the changed creatures. Jonah changed first. The creatures follow sound, so rescuers must come without sirens. The shrouded tunnel creatures were already dead before the signal; Aubrey found their coffins broken open from within. She cannot say whether any consciousness remains."
  "stayed":
   if game.story.ada_letter_delivered:return "You brought Ada's letter to John. He keeps it in his coat and intends to find her after the radio equipment is safe."
   return "John promised Ada he would secure the equipment and follow her. Her letter is at Saint George Hotel. He lost time while working near the receiver and improved after disconnecting its coil. He stayed to stop the broadcasts he had helped maintain."
  "help":return speaker_name()+"'s current advice:\n"+game.town.townspeople.words(speaker)
 return ""
