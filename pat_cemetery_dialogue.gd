extends RefCounted
## Pat's optional cemetery arc. Physical discoveries, not conversation order, unlock it.
func read_note(c,id:String)->bool:
 return c.game.town.journal_entries.any(func(e):return e.id==id)
func knows_vault(c)->bool:
 return c.game.town.townspeople.grave_key_given or c.game.town.cemetery.unlocked or c.game.town.inventory.mausoleum_key>0
func returned(c)->bool:
 return c.game.story.pat_vault_seen or c.game.town.actions.cemetery_coupler.taken
func topics(c)->Array:
 var rows=[["town","What happened to Blackwood?","Blackwood's decline"],["house","What's with the house at the end of the street?","The old house"],["waiting","Why are you still here?","Someone Pat is waiting for"],["cemetery","What can you tell me about the cemetery?","Old Mill Cemetery"]]
 if knows_vault(c):rows.append(["family","Who was your grandfather?","Pat's grandfather"])
 if returned(c):rows.append(["vault","What aren't you telling me about the vault?","What Pat left open"])
 if read_note(c,"cemetery_buried_note"):rows.append(["grave","Was that your note in the disturbed grave?","The buried ammunition"])
 if c.game.cemetery_shadow.vanished:rows.append(["shadow","I saw someone beside the mausoleum.","The figure at the fence"])
 return rows
func greeting(c)->String:
 var first="Aubrey patched you up? Good. Stay where I can see you a moment." if c.game.story.clinic_rescue_done else "Easy. You've got blood on your collar. Aubrey's at the clinic if you need help."
 return first+"\n\nI'm Pat. You came in on Old Mill Road? That barrier should've been shut. I thought... never mind. You're here now.\n\nThe station key is in my office drawer. There's a pistol in the abandoned police car on Main Street. We need to get a real dispatcher on that radio. Ask before you go wandering."
func key_line()->String:
 return "Here. This opens the Whitcomb mausoleum, in Old Mill Cemetery. It belongs to my family.\n\nThe spare antenna coupler is on a shelf inside. You'll also need the chapel cellar key. I left it on a workbench at the far end of the passage under the vault.\n\nTake the footpath off Old Mill Road, back toward your car. Keep your light on down there.\n\nI haven't been back since the bus left. If you hear someone calling, don't stop to listen."
func answer(c,topic:String)->String:
 var g=c.game
 match topic:
  "waiting":
   if c.asked.has("pat_vault"):
    if g.story.repeater_is_off():return "It stopped. I keep waiting for the three notes, but they're gone.\n\nI don't feel better yet. I thought there'd be some great relief. Mostly I feel tired.\n\nWhen the county comes, I'm getting on whatever they send. You can hold me to that."
    return "I told myself I was staying to close the road and fetch the equipment. Both needed doing. But I could've left with the others.\n\nI wanted to hear him once more. Even after I knew it wasn't him.\n\nDon't leave that speaker running for my sake. If I ask you to, remind me I said this."
   return "Waiting on someone.\n\nNot the bus. That came.\n\nI know how that sounds. Aubrey keeps asking the same question. I tell her I'm watching the road. She looks at the empty chair in my office.\n\nLet's get you out of here first."
  "cemetery":
   var line="Old Mill Cemetery. East off the road you came down. My family kept the lower gate after the mill stopped paying for it. In daylight it's just weeds and old names."
   if not knows_vault(c):return line+"\n\nThe Whitcomb mausoleum is ours. Keep out of it until you've spoken to me. The ground behind it has been settling.\n\nIf you're only looking for supplies, there's a shovel in the old Victorian house's basement. One grave near the cemetery path has fresh earth. I left an emergency cache there before the bus. Leave the other graves alone."
   return line+"\n\nThe family key opens the Whitcomb mausoleum. The coupler is on the shelf inside. The chapel cellar key is farther in, on a workbench at the tunnel's far end.\n\nIf the entrance closes behind you, it isn't locked again. You can reopen it. Keep your flashlight and a way back."
  "family":
   if c.asked.has("pat_vault"):return "My grandfather worked nights at the mill. He walked me home along that fence when my mother was late. Three notes on his whistle, then he'd wait for me to answer.\n\nHe hated that passage. Floodwater came through it once. He'd never have asked me to open it in the dark.\n\nI remembered that afterward. That's the part I can't forgive myself for."
   return "My mother's father. He was a night watchman at the mill. His name was Whitcomb. The mausoleum is where we buried him.\n\nHe used to whistle three notes when it was time to come home. I could hear him from the cemetery gate.\n\nHe's been dead a long time. I still catch myself turning around."
  "vault":
   if c.asked.has("pat_vault"):return "I left the inner passage open. Not the iron entrance; I locked that behind me. That's why you still needed the family key.\n\nI don't know what I let through. The outer door slamming isn't proof of anything by itself. Those old hinges pull hard. But I heard something moving below me before I ran.\n\nTell Aubrey what you actually saw. She deserves more than another guess from me."
   var line="I told you I hadn't been back. That was a lie.\n\nThe morning after the bus left, I heard his three notes through the chapel speaker. Then his voice: 'Patrick. Wrong door. Open the other one.' He was the only person who called me Patrick.\n\nI went to the vault. The inner passage had an old timber shutter across it. I pulled it loose. Took the cellar key down to the workbench because I thought I'd need both hands. Then I heard someone breathing behind me.\n\nI ran. Locked the iron door. Left the passage open and the key downstairs."
   if g.story.pat_cellar_seen:line+="\n\nThose coffins you found... I never put them there. I don't know whose bodies they were. I just keep thinking about that shutter, and how hard it was to pull free."
   elif g.story.pat_tunnel_seen:line+="\n\nThat passage goes beneath Saint George. It used to be a dry way through when the low road flooded. I shouldn't have sent you down it without telling you what I'd done."
   line+="\n\nI wanted you to think I was frightened of a noise. That was easier than telling you I'd followed it. I'm sorry."
   return line
  "grave":
   return "P.W. Patrick Whitcomb. Yes, that's mine.\n\nJohn brought the rounds before the evacuation. The coffin in that grave had been empty for years; the family moved the remains after a flood. I put the packet under the loose lid in case the road got cut off.\n\nI felt the soil moving while I covered it. Heard that scraping. Told myself it was a branch against the wood.\n\nTake the ammunition. You don't owe me an apology for digging where I told you to. Just don't open the other graves."
  "shadow":
   return "By the fence?\n\nI saw a man there the night before the bus. Thought it was someone from the mill, checking a family plot. He went behind the Whitcomb vault. Never came out the other side.\n\nI don't know what you saw. If it kept its distance, let it. You don't have to follow everything that moves."
 return ""
func summary(c,topic:String)->String:
 match topic:
  "waiting":
   if c.asked.has("pat_vault"):return "Pat admits he stayed partly to hear his grandfather's voice. He asks you to silence the chapel speaker even if he later changes his mind."
   return "Pat says he is waiting for someone, though the last bus already left. He avoids identifying who."
  "cemetery":return "Old Mill Cemetery is east of Old Mill Road. Pat's family owns the Whitcomb mausoleum. The vault shelf holds the antenna coupler; the workbench at the far end of the tunnel holds the chapel cellar key. Pat left emergency ammunition in one disturbed grave. The shovel is in the Victorian basement."
  "family":return "Pat's grandfather was a mill night watchman. Three whistled notes meant it was time to come home. He has been dead for years."
  "vault":return "Pat admits returning the morning after the evacuation. A voice imitating his grandfather called him Patrick and asked him to open the inner passage. Pat removed its old timber shutter, left the chapel key on the far workbench, then fled and locked the outer iron door. He does not know what came through or who placed the coffins."
  "grave":return "Pat wrote the note signed P.W. He hid John's ammunition beneath the lid of an empty coffin before evacuation. The remains had been moved after an earlier flood. He heard scraping while covering the cache. Only this grave is intended to be dug."
  "shadow":return "Pat also saw a figure vanish behind the Whitcomb mausoleum. He cannot identify it and advises against following it."
 return ""
