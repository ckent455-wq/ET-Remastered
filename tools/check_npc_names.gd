extends SceneTree
func _initialize():call_deferred("check")
func check():
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 assert(g.town.townspeople.characters.ranger.name=="Pat / Ranger")
 assert(g.town.townspeople.characters.nurse.name=="Aubrey / Nurse")
 assert(g.town.townspeople.characters.mechanic.name=="John / Mechanic")
 for data in g.town.actions.values():
  for key in ["label","title","text"]:
   if data.has(key):
    for old in ["Elias","Mara","Owen"]:assert(not old in str(data[key]))
 print("PASS: NPC names and in-game prompts/notes use Pat, Aubrey, John")
 quit()
