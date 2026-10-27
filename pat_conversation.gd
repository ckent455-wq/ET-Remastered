extends RefCounted
## Optional local history and advice; it never replaces the physical quest steps.
var game
var progress=preload("res://npc_progress_reactions.gd").new()
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
 var consequence=progress.topic(self,speaker)
 if not consequence.is_empty():TOPICS.append({"id":consequence[0],"question":consequence[1],"title":speaker_name()+" / "+consequence[2]})
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
 if topic.begins_with("consequence_"):return progress.answer(self,speaker,topic.trim_prefix("consequence_"))
 if speaker=="ranger" and topic in ["waiting","cemetery","family","vault","grave","shadow"]:return pat_story.answer(self,topic)
 match topic:
  "origin":
   return "The first thing we could put a date to was the walnut radio. Four weeks before the evacuation. The switch was off. We pulled the plug and antenna, and it kept speaking. The operator wrote it down.\n\nIt sounded like Ada. She was standing beside me. She asked me to turn it off, and the voice in the set finished her sentence.\n\nBellamy put it through the chapel so somebody might recognize the speaker. After that, people started coming to Aubrey. Nobody was sleeping.\n\nI called it interference. Then I called it a fault in the return line. I can show you the wiring. I can't show you where a voice comes from in a set with no power."
  "town":
   return "The mill closed twelve years ago. Most of these buildings were empty long before any of this. We knew which roofs leaked. Which doors had swollen shut.\n\nThen the ground started smelling turned over, even where nobody had been digging. I'd come back from a patrol with grey dust inside my boots. No hole in the soles.\n\nThe last bus left three nights ago. I heard its horn afterward, from the chapel speaker, and opened the road. I knew it was a recording. Then I'd lose hours and find myself waiting for the driver again.\n\nAubrey made me compare the dates in my log. Three days. I thought it was one long night.\n\nThat's why the barrier was open. I'm supposed to know this road. I don't trust my own account of it now."
  "house":
   var line="The mill superintendent's house. The family left three years after the mill closed. Nine years empty. Their clearance notice is still downstairs.\n\nI checked it after the storm. Fresh bare footprints on the cellar stairs. Soil pushed through a hole in the foundation, and burial cloth caught on the brick. The burrow behind it had fallen in.\n\nThe odd thing was the roots. They came through with the soil, pale and soft, but they broke into dust when I touched them. I thought frost damage. It wasn't cold down there.\n\nI shut the cellar door. There's a shovel in that basement if you need one. Watch where you put your hands."
   if game.town.journal_entries.any(func(entry):return entry.id=="victorian_letter"):
    line+="\n\nYou found the notice? Then you know they left years before this signal. Whatever is in there now moved in afterward."
   return line
  "church":
   return "The chapel was built in 1891, above the flood line. The county added the warning amplifier later. Its buried cable comes back to the station. That part is ordinary.\n\nBellamy connected the walnut set to it. He thought somebody would recognize the voices. Then it sounded like his sister, and he wouldn't switch it off.\n\nI tested the rack three weeks before evacuation. MAIN ISOLATOR cut its supply and return line. Both ends went quiet. Bellamy put it back on. Those are the results in my notebook. They don't explain the set speaking unplugged.\n\nI left a spare county tuner and service rifle in the cellar. When I tried to return after Ada left, the creatures drove me down the hill.\n\nTake Pat's cellar key through the mausoleum passage. Cut MAIN ISOLATOR, then use the GREEN bypass at the station. Leave AMBER alone."
  "signal":
   var line="They came in because they couldn't sleep. Normal temperatures. No bites. I checked the water, asked about the mill, looked for something they'd all been exposed to. I never found one answer that fitted.\n\nThen they started losing time. One woman said she could hear roots moving under the pavement. Her husband apologized for her. Two days later he asked me whether I'd heard them too.\n\nThe worst cases lived near the chapel speaker. That's an observation, not a diagnosis. I don't know whether the sound is doing this or whether we're hearing something that's happening anyway.\n\nRead my observations on the shelf and the operator's log. John has a way to isolate the chapel line. We need to try it, then reach a real county dispatcher.\n\nPat thought three days were one night. He's still keeping the road log. I asked him to keep writing, even when it stops making sense."
   if game.story.evidence.has("clinic_note") or game.story.evidence.has("cellar_record"):
    line+="\n\nThose names in the records were our neighbors. I recognized Edith's bracelet and Silas's splinted hand. Whatever you hear in the woods, don't mistake a familiar voice for someone safe."
   return line
  "patients":
   var line="Edith wouldn't leave without Silas. I kept their beds ready after the last bus. By dawn they were empty. Their tracks went toward the chapel.\n\nI found her bracelet on one of those things. The other had the splint I'd fitted to his hand. I recognized the splint first. For a moment I was worried it would chafe.\n\nJonah changed before them. Weeks of little things we kept explaining away. Dry skin. No sleep. Food tasting wrong. By the time I stopped calling it exhaustion, I couldn't get him to tell me where he hurt.\n\nIf you reach the county, ask for no sirens. I've seen the things turn toward sound."
   if game.story.evidence.has("clinic_note"):line+="\n\nYou've read my chart. The dates overlap, but the symptoms don't all follow the same order. I keep looking for something I missed."
   line+="\n\nBut the shrouded things beneath the cemetery are different. Those bodies were already dead before the signal began. I found coffins forced open from inside. They move. That is all I can honestly tell you. I don't know whether they remember anything. The cloth on them is burial wrapping, not bandages I put there."
   return line
  "stayed":
   game.story.request_ada_letter()
   if game.story.ada_letter_delivered:return "I keep her letter in my coat now. You brought back something I was afraid I had lost. Once the radio is safe, I am going after her."
   return "Ada took the last bus. I said I'd secure the equipment and follow her. Her letter is still in our room at Saint George Hotel. Would you bring it back if you get inside?\n\nI remember putting my coat on to leave. Next thing I knew, I was sorting the same screws into the same tray. It was daylight. Ada was gone.\n\nAway from the station I could think again. So I stayed in the workshop, which sounds sensible until you ask why I didn't keep walking.\n\nI want to stop what we put through that speaker. I don't know if that's enough. It's the job I know how to do."
  "help":
   return game.town.townspeople.words(speaker)
 return "Take care out there."

func summary(topic:String)->String:
 if topic.begins_with("consequence_"):return progress.summary(self,speaker,topic.trim_prefix("consequence_"))
 if speaker=="ranger" and topic in ["waiting","cemetery","family","vault","grave","shadow"]:return pat_story.summary(self,topic)
 match topic:
  "origin":return "John first documented an unplugged station radio speaking four weeks before evacuation. It imitated Ada beside him. Bellamy amplified it through the chapel. John's circuit tests identify a way to isolate the line, not the nature or ultimate source of the phenomenon."
  "town":return "Pat distinguishes twelve years of ordinary decline from recent changes in the ground and unexplained grey dust. He lost hours waiting for a recorded bus horn; Aubrey's dated log showed three days had passed. He no longer trusts his recollection of the road."
  "house":return "The old Victorian house belonged to the mill superintendent. Its occupants left nine years ago; their clearance notice is downstairs. Pat found fresh bare footprints leading into the cellar after the storm. He also found a freshly dug breach, soil pushed inward and burial cloth caught on the masonry. Its short burrow was blocked by collapsed earth. He could not identify what came through."
  "church":return "Bellamy amplified the station voices through the chapel. Cases were worst nearby, but the mechanism remains unknown. John tested its independent supply and buried return line: MAIN ISOLATOR silences both ends. Use the spare county tuner and station GREEN bypass to make a clean rescue call."
  "signal":return "Aubrey observed sleeplessness, missing time and physical changes without identifying a common cause. Cases were worst near the chapel speaker, but she cannot establish whether the sound causes the changes. Read her observations and isolate the chapel line before calling county."
  "patients":return "Aubrey recognized Edith's bracelet and Silas's splint on the changed creatures. Their symptoms worsened over weeks. She also found old coffins opened from inside but cannot explain the moving wrapped bodies. Request rescue without sirens."
  "stayed":
   if game.story.ada_letter_delivered:return "You brought Ada's letter to John. He keeps it in his coat and intends to find her after the radio equipment is safe."
   return "John missed the bus after losing time repeating work in his shop. Ada's letter is in their Saint George Hotel room. He thinks more clearly away from the receiver but cannot account for why he stayed. He wants to isolate the system he helped connect."
  "help":return speaker_name()+"'s current advice:\n"+game.town.townspeople.words(speaker)
 return ""
