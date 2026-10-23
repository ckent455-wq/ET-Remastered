extends RefCounted
var enemies
const NOTES=[
 ["Mara's folded shopping list","Bread. Batteries. Something for Elsie's birthday.\n\nBelow the list, the same sentence has been written six times: The station radio is speaking with Dad's voice. Dad has been buried for eleven years. I must not take Elsie there."],
 ["A mill worker's pocket diary","The sound from the chapel reaches the workshop now. I went home at six. The clock said nine when I reached the door.\n\nJohn says to write down the hours. I found mud under my nails this morning. I don't remember going outside."],
 ["An unsent note to Ruth","Ruth, take the bus. Don't wait for me. Aubrey says the voices are getting into our sleep.\n\nI heard you calling from behind the chapel, but you were still sitting at our kitchen table. Please don't come looking if you hear me."],
 ["A rain-soaked photograph","A family stands outside Blackwood's pharmacy. Someone has written on the back:\n\nIf I forget their faces, show me this. If I call from the woods, keep the children inside. That thing knows how I sound."]
]
func _init(owner):enemies=owner
func prepare(data):
 if data.has("body_searched"):return
 data["body_searched"]=false
 data["body_ammo_type"]=randi_range(0,2)
 data["body_ammo"]=randi_range(1,2 if data.body_ammo_type==2 else 3) if randf()<0.45 else 0
 data["body_note"]=data.index if data.index<3 else 1 if data.index==enemies.WORKSHOP_INDEX else -1
 if data.index==1:data.body_note=2
 if data.index==2:data.body_note=3
func focus(start:Vector3,finish:Vector3,limit:float)->String:
 var nearest=limit
 var result=""
 for data in enemies.creatures:
  if data.hp>0 or not data.actor.is_visible_in_tree() or data.get("body_searched",false):continue
  var center=data.visual.to_global(Vector3(0,0.8,0))
  var point=Geometry3D.get_closest_point_to_segment(center,start,finish)
  var distance=start.distance_to(point)
  if center.distance_to(point)<0.85 and distance<nearest and start.distance_to(center)<3.2:
   nearest=distance;result="body_search_"+str(data.index)
 return result
func search(index:int):
 var g=enemies.game
 if g.state!="play" or index<0 or index>=enemies.creatures.size():return
 var data=enemies.creatures[index]
 if data.hp>0 or data.get("body_searched",false):return
 var center=data.visual.to_global(Vector3(0,0.8,0))
 if g.camera.global_position.distance_to(center)>3.4:return
 prepare(data)
 var amount=int(data.body_ammo)
 var kind=int(data.body_ammo_type)
 var testing=g.testing_mode and g.testing_mode.enabled
 if amount>0 and not testing:
  if not g.crash_site.has_backpack:
   g.message="There's ammunition in the pocket. I need my backpack to carry it.";return
  if g.weapons.reserves[kind]+amount>g.weapons.LOADOUT[kind].max_reserve or not g.backpack.room_for("ammo%d" % kind,amount):
   g.message="There's ammunition here. Make room in your backpack before searching.";return
 data.body_searched=true
 var found="Nothing useful in the pockets."
 if amount>0:
  g.weapons.add_ammo(kind,amount)
  found="Found %d %s." % [amount,["pistol rounds","rifle rounds","shotgun shells"][kind]]
  if testing:found+=" Dev mode keeps your ammunition full."
 var note=int(data.body_note)
 if note>=0:
  var id="personal_body_"+str(index)
  if not g.town.journal_entries.any(func(entry):return entry.id==id):
   g.town.journal_entries.append({"id":id,"title":NOTES[note][0],"text":NOTES[note][1]})
  g.journal_page=g.town.journal_entries.size()+1;g.journal_casefile=false
  g.set_state("journal")
  found+=" A personal note has been added to your journal."
 g.message=found
 g.soundscape.feedback("pickup")
