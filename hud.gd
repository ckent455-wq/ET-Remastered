extends Control
var game
var font = preload("res://assets/font.ttf")
const INK = Color("d2dfd0")
const DIM = Color("87a39f")
const AMBER = Color("efc58c")
func text(s: String, p: Vector2, size = 14, color = INK):
	draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func centered(s: String, y: float, size: int, color = INK):
	text(s,Vector2(320-font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,y),size,color)
func _draw():
	if game==null:
		return
	if game.state=="intro":
		draw_intro()
		return
	# Thin scanlines and corner shading evoke an early console display.
	for y in range(0,400,3):
		draw_line(Vector2(0,y),Vector2(640,y),Color(0,0,0,0.05))
	for i in range(12):
		draw_rect(Rect2(i,i,640-i*2,400-i*2),Color(0,0,0,0.025),false,1)
	if game.pulse>0:
		draw_rect(Rect2(0,0,640,400),Color(0.4,1,0.8,game.pulse*0.17))
	if game.invincible>1:
		draw_rect(Rect2(0,0,640,400),Color(0.8,0.15,0.1,0.15))
	text("FAR FROM HOME",Vector2(20,27),18)
	text(game.town.location_name()+" / 02:17 AM",Vector2(20,43),10,DIM)
	text("UPLINK / "+("READY" if game.town.radio_ready else "OFFLINE"),Vector2(487,27),13,AMBER)
	centered(game.town.objective(),64,12,AMBER)
	# Directional objective markers remain on a compass, including behind you.
	draw_line(Vector2(220,40),Vector2(420,40),Color("536b70"),1)
	text("SIGNALS",Vector2(301,28),10,DIM)
	if game.town.radio_ready:
		var target = game.HOME
		var diff = target-game.player.position
		var angle = wrapf(atan2(-diff.x,-diff.z)-game.player.rotation.y,-PI,PI)
		var x = 320-angle/PI*96
		draw_circle(Vector2(x,40),3,INK)
	if not game.town.radio_ready:
		var diff = game.town.navigation_target()-game.player.position
		var angle = wrapf(atan2(-diff.x,-diff.z)-game.player.rotation.y,-PI,PI)
		draw_rect(Rect2(317-angle/PI*96,37,6,6),Color("85c2ca"),false,1)
	if game.state=="play":
		draw_circle(Vector2(320,200),1.2,Color(0.8,0.9,0.8,0.8))
	text("VITALITY",Vector2(20,330),10,DIM)
	draw_rect(Rect2(20,337,100,3),Color("2e454b"))
	draw_rect(Rect2(20,337,maxf(0,game.health),3),Color("a1c8a1"))
	text("STAMINA",Vector2(20,357),10,DIM)
	draw_rect(Rect2(20,364,game.stamina,2),DIM)
	text("PULSE / " + ("READY" if game.cooldown<=0 else "%.1fs" % game.cooldown),Vector2(520,357),12,INK)
	text("LIGHT %d%%   H / KITS %d   Q / CELLS %d   TAB / JOURNAL" % [int(game.flashlight_charge),game.town.inventory.medkit,game.town.inventory.battery],Vector2(153,356),10,DIM)
	if game.soundscape.muted:
		text("SOUND OFF / M",Vector2(520,337),10,DIM)
	centered(game.message,381,12)
	if game.state=="play" and game.town.prompt()!="":
		centered(game.town.prompt(),285,15,AMBER)
	if game.town.radio_ready and game.player.position.distance_to(game.HOME)<5.5:
		centered("HOLD E / PHONE HOME",284,19)
		draw_rect(Rect2(240,296,game.contact_progress*40,3),INK)
	if game.state=="journal":
		draw_journal()
		return
	if game.state=="dialogue":
		draw_dialogue()
		return
	if game.state!="play":
		draw_rect(Rect2(0,0,640,400),Color(0.015,0.045,0.065,0.85))
		centered("A SMALL VISITOR. A VERY LONG WAY HOME.",99,12,DIM)
		var title = "FAR FROM HOME"
		if game.state=="won":
			title = "YOU MADE CONTACT"
		elif game.state=="lost":
			title = "SIGNAL LOST"
		elif game.state=="paused":
			title = "PAUSED"
		centered(title,155,40)
		var sub = "Your ship is gone. The forest is listening."
		if game.state=="won":
			sub = "Across the stars, someone heard you. You're going home."
		elif game.state=="lost":
			sub = "Your journey ended. Try again."
		centered(sub,188,14)
		text("01   Explore Blackwood. E searches storage and talks to people.",Vector2(145,225),13)
		text("02   Restore workshop power. Repair the town radio.",Vector2(151,249),13)
		text("03   Calibrate the radio, then call home from the clearing.",Vector2(151,273),13)
		draw_rect(Rect2(213,296,214,34),Color("6b857a"),false,1)
		centered("ENTER / " + ("RESUME" if game.state=="paused" else "BEGIN JOURNEY"),319,16,AMBER)
		centered("MOUSE  look    WASD  move    SHIFT  sprint    F  flashlight",359,11,DIM)
		centered("E  interact    TAB  journal / map    H  heal    Q  battery    ESC  pause",377,11,DIM)

func paragraph(content: String, x: float, y: float, width: float, size: int, color = INK) -> float:
	for line in content.split("\n"):
		var current = ""
		for word in line.split(" "):
			var next = current+word+" "
			if font.get_string_size(next,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width and current!="":
				text(current,Vector2(x,y),size,color)
				y += size+5
				current = word+" "
			else:
				current = next
		text(current,Vector2(x,y),size,color)
		y += size+5
	return y

func draw_journal():
	draw_rect(Rect2(0,0,640,400),Color(0.02,0.04,0.055,0.98))
	draw_rect(Rect2(55,40,530,313),Color("6e8279"),false,1)
	text("BLACKWOOD / FIELD JOURNAL",Vector2(78,70),23)
	text("%d / %d" % [game.journal_page+1,game.town.journal_entries.size()+2],Vector2(520,70),13,DIM)
	if game.journal_page==0:
		text("CURRENT OBJECTIVE",Vector2(78,105),11,DIM)
		paragraph(game.town.objective(),78,127,476,16,AMBER)
		text("PACK / Medkits %d   Batteries %d   Station key %d   Fuse %d   Coil %d" % [game.town.inventory.medkit,game.town.inventory.battery,game.town.inventory.station_key,game.town.inventory.fuse,game.town.inventory.coil],Vector2(78,171),12)
		var searched = game.town.interiors.containers.values().filter(func(storage): return storage.searched).size()
		text("STORAGE / %d of 12 searched - E opens drawers and cabinets" % searched,Vector2(78,188),10,DIM)
		var tasks = [
			[game.town.inventory.station_key>0,"Find the ranger's radio-station key"],
			[game.town.powered,"Find store fuse; restore workshop power"],
			[game.town.inventory.coil>0 or game.town.radio_ready,"Recover workshop signal coil"],
			[game.town.radio_ready,"Calibrate the radio-station receiver"],
			[false,"Return to the clearing and hold E to call home"]]
		for i in range(tasks.size()):
			text(("[+] " if tasks[i][0] else "[ ] ")+tasks[i][1],Vector2(78,205+i*21),13,DIM if tasks[i][0] else INK)
	elif game.journal_page==1:
		text("OLD MILL ROAD / TOWN MAP",Vector2(78,105),14,AMBER)
		draw_line(Vector2(105,221),Vector2(535,221),Color("667a76"),10)
		draw_line(Vector2(320,221),Vector2(320,325),Color("667a76"),5)
		for data in game.town.BUILDINGS:
			var p = Vector2(320+data.p.x*5,125+(data.p.z+80)*4)
			draw_rect(Rect2(p-Vector2(data.w*2.5,20),Vector2(data.w*5,40)),Color("385156"))
			text(data.id.to_upper(),p+Vector2(-22,4),10,INK)
		var player = game.player.position
		if player.z< -35 and player.z> -82:
			draw_circle(Vector2(320+player.x*5,125+(player.z+80)*4),4,AMBER)
		text("SOUTH / FOREST & LANDING CLEARING",Vector2(211,336),11,DIM)
	else:
		var entry = game.town.journal_entries[clampi(game.journal_page-2,0,game.town.journal_entries.size()-1)]
		text(entry.title.to_upper(),Vector2(78,110),18,AMBER)
		paragraph(entry.text,78,150,478,15)
	centered("LEFT / RIGHT  pages     TAB / ESC  close     H  heal and Q  battery during play",379,11,DIM)

func draw_intro():
	draw_rect(Rect2(0,0,640,400),Color("020609"))
	var alpha = minf(clampf(game.intro_elapsed/0.65,0,1),clampf((3.6-game.intro_elapsed)/0.5,0,1))
	var ink = Color(0.76,0.86,0.78,alpha)
	draw_polyline(PackedVector2Array([Vector2(320,93),Vector2(363,165),Vector2(277,165),Vector2(320,93)]),ink,2,true)
	centered("Traingle Studios Presents...",224,32,ink)
	centered("ENTER / SKIP",343,10,Color(0.4,0.53,0.50,alpha*0.8))

func draw_dialogue():
	draw_rect(Rect2(0,0,640,400),Color(0.015,0.035,0.05,0.72))
	draw_rect(Rect2(55,114,530,218),Color("102127"))
	draw_rect(Rect2(55,114,530,218),Color("6e8279"),false,1)
	text(game.dialogue_name.to_upper(),Vector2(78,148),23,AMBER)
	paragraph(game.dialogue_text,78,181,478,15)
	centered("E / ENTER / ESC  finish conversation",359,12,DIM)
