extends RefCounted
## Optional local history and advice; it never replaces the physical quest steps.
var game
var active=false
var choosing=false
var greeted=false
var selected=0
var current_topic=""
var asked={}
const BOX=Rect2(60,120,520,264)
const TOPICS=[
 {"id":"town","question":"What happened to Blackwood?","title":"Pat / Blackwood's decline"},
 {"id":"house","question":"What's with the house at the end of the street?","title":"Pat / The old house"},
 {"id":"church","question":"What's the history of the church?","title":"Pat / The hilltop church"},
 {"id":"signal","question":"What are those voices? And the things in the woods?","title":"Pat / Voices in the carrier"},
 {"id":"stayed","question":"Why did you, Aubrey and John stay?","title":"Pat / The three who stayed"},
 {"id":"help","question":"What should I do next?","title":"Pat / Getting help"}
]

func reset():
 cancel();greeted=false;selected=0;asked.clear()
func cancel():
 active=false;choosing=false;current_topic=""
func begin(intro:String,force_intro=false):
 active=true;selected=0;current_topic=""
 game.dialogue_name="Pat / Ranger"
 game.dialogue_text=intro
 game.set_state("dialogue")
 if not greeted or force_intro:
  greeted=true;choosing=false
 else:show_topics()
func show_topics():
 choosing=true;current_topic=""
func row(index:int)->Rect2:
 return Rect2(76,156+index*28,488,26)
func move_selection(amount:int):
 if choosing:selected=wrapi(selected+amount,0,TOPICS.size()+1)
func choose(index:int):
 if not active or not choosing:return
 if index==TOPICS.size():game.set_state("play");return
 if index<0 or index>=TOPICS.size():return
 selected=index;current_topic=TOPICS[index].id;choosing=false
 game.dialogue_text=answer(current_topic)
 game.dialogue_pages=preload("res://dialogue_style.gd").pages(game.dialogue_text)
 game.dialogue_page=0
 game.hud.dialogue_last_page=-1
 var entry_id="pat_"+current_topic
 var found=false
 for entry in game.town.journal_entries:
  if entry.id==entry_id:entry.text=summary(current_topic);found=true;break
 if not found:game.town.journal_entries.append({"id":entry_id,"title":TOPICS[index].title,"text":summary(current_topic)})
 asked[current_topic]=true
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
  for i in range(TOPICS.size()+1):
   if row(i).has_point(event.position):selected=i;break
 elif event is InputEventMouseButton and event.pressed:
  if choosing:
   if event.button_index==MOUSE_BUTTON_WHEEL_UP:move_selection(-1)
   elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:move_selection(1)
   elif event.button_index==MOUSE_BUTTON_LEFT:
    for i in range(TOPICS.size()+1):
     if row(i).has_point(event.position):choose(i);break
  elif event.button_index==MOUSE_BUTTON_LEFT and preload("res://dialogue_style.gd").BOX.has_point(event.position):advance()

func answer(topic:String)->String:
 match topic:
  "town":
   return "Blackwood grew around the mill. Shift whistles, school buses, the church bell on Sunday. You used to hear people before you saw the town.\n\nThe mill closed twelve years ago. Families sold up, shops boarded their windows. That old damage wasn't done in a night.\n\nThe last families left three nights ago, after weeks of trouble with the signal. The bus really did leave. The horn I heard afterward came from the chapel speaker. I opened the road for a recording."
  "house":
   var line="The big timber house beyond the shops? That was the mill superintendent's place. The people there held on for three years after the mill closed. Their clearance notice is still downstairs. Nine years, and nobody ever came back for the furniture.\n\nAfter last month's storm I checked it for squatters. Dry cellar, thick walls. I thought it might shelter anyone who missed the evacuation.\n\nThen I found fresh mud on the cellar steps. Bare footprints going down. None coming back up. I shut the door. That doesn't mean it's empty."
   if game.town.journal_entries.any(func(entry):return entry.id=="victorian_letter"):
    line+="\n\nYou found the notice? Then you know they left years before this signal. Whatever is in there now moved in afterward."
   return line
  "church":
   return "The church went up in 1891. Mill families paid for it a little out of each wage packet. They built above the flood line; when the creek rose, the nave became a shelter. That hill used to mean safety.\n\nDecades later the county put a civil-defense repeater in the cellar. High ground, a buried line to the station, a speaker to warn the whole street. Bellamy kept the old system working after the town ran out of money.\n\nLast month's storm damaged it. Jonah, the caretaker, stayed beside the running rack. The maintenance book inside tells what happened to him. We thought the warning speaker was helping people."
  "signal":
   var line="Ordinary radio didn't do this. There's a low tone underneath the chapel's repeated messages. It started after the storm. First people stopped sleeping. Then they'd answer voices nobody else could hear.\n\nJohn pulled the station coil after the evacuation. That stopped the town broadcasts. The hill equipment has its own power, so its speaker kept going.\n\nAubrey has records in the clinic. She saw what happened to the people who stayed near it. Ask her, and read Bellamy's book. I won't pretend I know where the tone came from."
   if game.story.evidence.has("clinic_note") or game.story.evidence.has("cellar_record"):
    line+="\n\nThose names in the records were our neighbors. If Aubrey recognized them, I believe her. Whatever you hear in the woods, don't mistake a familiar voice for someone safe."
   return line
  "stayed":
   return "Aubrey stayed for the patients who refused the bus. John promised Ada he'd follow once he secured the radio equipment. She left him a letter at Saint George Hotel.\n\nI closed the barrier, then opened it again when I heard that horn. I told dispatch there were three still here. Nobody answered.\n\nI keep counting windows when I walk the street. Looking for a light we missed. I wrote three on the sign so the next person wouldn't waste time searching empty rooms. Didn't do you much good, did it?"
  "help":
   return game.town.townspeople.words("ranger")
 return "Take care out there."

func summary(topic:String)->String:
 match topic:
  "town":return "Pat says the mill closed twelve years ago. Most of the decay predates the signal. The final families evacuated three nights ago. A recorded bus horn from the chapel fooled him into reopening Old Mill Road."
  "house":return "The old Victorian house belonged to the mill superintendent. Its occupants left nine years ago; their clearance notice is downstairs. Pat found fresh bare footprints leading into the cellar after the storm. He could not confirm who was using it."
  "church":return "Mill families funded the hilltop church in 1891. It sheltered people above the flood line. The county later installed the cellar repeater. Bellamy kept the warning system running; its storm damage and Jonah's decline are recorded in the vestry book."
  "signal":return "Pat distinguishes ordinary radio from the unidentified tone beneath the chapel messages. John disconnected the town station, but the hill equipment has separate power. The clinic records and vestry book explain the symptoms. Pat does not know the carrier's origin."
  "stayed":return "Aubrey stayed to search for her patients. John promised Ada he would secure the equipment and follow her. Pat stayed to search and contact dispatch. Ada's letter is at Saint George Hotel. The three on the sign are the surviving townspeople."
  "help":return "Pat's current advice:\n"+game.town.objective()
 return ""
