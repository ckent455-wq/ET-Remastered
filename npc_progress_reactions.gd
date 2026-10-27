extends RefCounted
## Witnessed consequences and player reports, rather than omniscient NPC exposition.
func stage(c,id:String)->String:
 var g=c.game
 if g.story.repeater_is_off():return "silence"
 if g.story.pat_cellar_seen and id=="nurse":return "coffins"
 if g.enemies.workshop_defeated and id=="mechanic":return "attack"
 if g.town.powered:return "power"
 return ""
func intro(c,id:String)->Dictionary:
 var event=stage(c,id)
 var key="reaction_"+id+"_"+event
 if event=="" or c.greetings.has(key) or not c.greetings.has(id):return {}
 var lines={
  "silence":{
   "ranger":"Hold on. Listen.\n\nI've been waiting for the next note all night. Now I can hear the pipes in the office. I'd forgotten they made a sound.",
   "nurse":"It's quiet. Not outside. In here.\n\nI can finish a thought without someone finishing it for me. Whatever you switched off, leave it off.",
   "mechanic":"The sound stopped in the wall before the meter moved.\n\nI don't have a test for that. I'm done pretending I do. We use the county line now. Nothing through the chapel."
  },
  "coffins":{"nurse":"Wait. You've got that black grit on your cuffs.\n\nI washed the same stuff out of Silas's dressings. It kept settling at the bottom of the basin. Tell me where you've been."},
  "attack":{"mechanic":"I heard it hit the door. Then the shots.\n\nI was standing here with my hand on the latch. Kept thinking you were about to knock. I'm sorry."},
  "power":{
   "ranger":"John's windows came on. For a second I thought the street was opening up for the morning.\n\nThen I looked at my watch. I've been doing that a lot.",
   "nurse":"The workshop's running again. I heard the motor through the floor.\n\nI'd just washed the basin. There was grey grit in it again when I turned around. I hadn't used it.\n\nYou're still steady? Good. Tell me if that changes.",
   "mechanic":"That should be a steady load. The lamps shouldn't have done that.\n\nKeep the workshop on long enough to get the coil. Don't connect anything else because it sounds like it needs you."
  }
 }
 return {"key":key,"line":lines.get(event,{}).get(id,"")}
func topic(c,id:String)->Array:
 match stage(c,id):
  "silence":return ["consequence_"+stage(c,id),"The repeater is off. Is it over?","After the silence"]
  "coffins":return ["consequence_"+stage(c,id),"I found coffins beneath the hotel. Something came out.","The bodies beneath Saint George"]
  "attack":return ["consequence_"+stage(c,id),"What was that thing outside the workshop?","The workshop attack"]
  "power":return ["consequence_"+stage(c,id),"Did you notice what happened when the workshop came on?","The workshop circuit"]
 return []
func answer(c,id:String,event:String="")->String:
 if event=="":event=stage(c,id)
 if event=="silence":
  return {
   "ranger":"I want to tell you yes. But the road's still empty, and I can't account for half the entries in my own log.\n\nLet's get a dispatcher. A name, a location, something we can check. I'll stay here with Aubrey until the county comes.",
   "nurse":"The noise has stopped. I can hear the refrigerator again.\n\nThe grit is still in the basin. So I can't tell you we're safe, or that anyone will get better.\n\nI've put our names and today's date on the chart. If I disagree with it, show it to me. Call the county on the direct line. Ask for no sirens.",
   "mechanic":"The circuit is isolated. GREEN keeps your call off the chapel line. That's what I tested.\n\nI went to pick up my coat when it went quiet. Then I came back to check the meter. I'd already checked it twice.\n\nWe need to leave. Call the county, switch the set off, and come get us."
  }[id]
 if event=="coffins":return "Wrapped bodies? Under Saint George?\n\nWas the cloth wet? I've found that grey grit in old dressings and new ones. I keep checking the cupboard for damp.\n\nWith Silas, his skin came away dry, as if it had been burned. His temperature was normal. He said it didn't hurt. He asked me to open the window so he could hear better.\n\nI don't know how any of that fits a body buried for years. Tell me what you saw before I put words to it."
 if event=="attack":return "I saw it through the boards. It stopped under the window and pressed its hand against the brick. Stayed like that until you came out.\n\nI thought it was listening. I don't know what else to call it.\n\nThe coil's in the powered cabinet. Take it. I can keep this door shut while you get the other parts."
 if event=="power":
  return {
   "ranger":"The light in John's shop went out and came back. Three times. I counted without meaning to.\n\nMy grandfather used to whistle three notes. I'm aware that isn't an explanation. I'm trying to stop treating it like one.\n\nJohn needs that power for the coil cabinet. After that, stay with the plan.",
   "nurse":"The pipes carried the motor noise into this room. I could feel it through the sink. That happens in old buildings.\n\nThe water left a grey ring when it drained. It didn't do that yesterday. I ran it again to be sure, then realized I'd been standing there for nearly an hour.\n\nI've stopped using that tap. I don't know if that helps. I needed to do something.",
   "mechanic":"This branch runs the workshop. The chapel has its own supply. Bringing this one up shouldn't change anything on that hill.\n\nThe lamps dropped three times. Same gap between each. A loose connection can do that.\n\nThat's what I told Bellamy when the set first spoke. A loose connection. Take the coil before I find another excuse to test it."
  }[id]
 return "Tell me what you found."
func summary(c,id:String,event:String="")->String:
 if event=="":event=stage(c,id)
 return {"silence":"The chapel signal is quiet, but nobody can promise its effects are reversed. Use the isolated GREEN county route and request no sirens.","coffins":"You told Aubrey about the coffins under Saint George. She remembers patients holding their breath to listen and warns that stillness does not prove a creature harmless.","attack":"John heard the workshop attack and admits he stayed behind the door. He recognized a rhythm from his old speaker tests. The coil remains in the powered cabinet.","power":"The workshop lights and electrical hum returned. The survivors noticed an unsettling three-part interruption, although the chapel uses a separate supply."}.get(event,"The survivors are comparing what they witnessed.")
