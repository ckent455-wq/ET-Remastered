extends Control
var game
var font = preload("res://assets/font.ttf")
var menu_buttons: Array[Button] = []
var controls_open = false
var last_menu_state = ""
var last_controls_open = false
var last_message = ""
var message_seconds = 0.0
var passage_fade = 0.0
const INK = Color("d2dfd0")
const DIM = Color("87a39f")
const AMBER = Color("efc58c")
func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_button("ENTER BLACKWOOD",Vector2(42,269),Vector2(244,35),begin_game)
	menu_button("CONTROLS",Vector2(42,315),Vector2(116,27),func(): controls_open = true)
	menu_button("QUIT",Vector2(170,315),Vector2(116,27),func(): get_tree().quit())
	menu_button("BACK",Vector2(80,331),Vector2(144,30),func(): controls_open = false)

func menu_button(label: String, p: Vector2, dimensions: Vector2, action: Callable):
	var button = Button.new()
	button.text = label
	button.position = p
	button.size = dimensions
	button.add_theme_font_override("font",font)
	button.add_theme_font_size_override("font_size",15)
	for style_name in ["normal","hover","pressed","focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("182021") if style_name=="normal" else Color("3d2422")
		style.bg_color.a = 0.86
		style.border_color = Color("68665a") if style_name=="normal" else Color("bd725b")
		style.set_border_width_all(1)
		button.add_theme_stylebox_override(style_name,style)
	button.add_theme_color_override("font_color",Color("d8d3bd"))
	button.add_theme_color_override("font_hover_color",Color("fff1d2"))
	button.pressed.connect(action)
	add_child(button)
	menu_buttons.append(button)
	button.visible = false

func begin_game():
	controls_open = false
	game.reset_game()
	game.set_state("play")

func _process(_delta):
	passage_fade = maxf(0,passage_fade-_delta*2.2)
	if game.message!=last_message:
		last_message = game.message
		message_seconds = 6.0
	if game.state=="play":
		game.achievements.update_toast(_delta)
		message_seconds = maxf(0,message_seconds-_delta)
	if game.state!="title":
		controls_open = false
	for i in range(menu_buttons.size()):
		menu_buttons[i].visible = game.state=="title" and (controls_open if i==3 else not controls_open)
	if game.state=="title" and controls_open!=last_controls_open:
		menu_buttons[3 if controls_open else 0].grab_focus()
	last_controls_open = controls_open
	if game.state!=last_menu_state:
		if game.state=="title":
			menu_buttons[0].grab_focus()
		last_menu_state = game.state

func _unhandled_key_input(event):
	if game.state=="title" and controls_open and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		controls_open = false
		get_viewport().set_input_as_handled()

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
	if game.state=="title":
		draw_title()
		return
	# Thin scanlines and corner shading evoke an early console display.
	for y in range(0,400,3):
		draw_line(Vector2(0,y),Vector2(640,y),Color(0,0,0,0.05))
	for i in range(12):
		draw_rect(Rect2(i,i,640-i*2,400-i*2),Color(0,0,0,0.025),false,1)
	if game.invincible>1:
		draw_rect(Rect2(0,0,640,400),Color(0.8,0.15,0.1,0.15))
	if game.state=="play":
		for target in game.enemies.health_bar_targets():
			var p: Vector2 = target.point-Vector2(26,0)
			draw_rect(Rect2(p-Vector2.ONE,Vector2(54,7)),Color(0.02,0.025,0.02,0.9))
			draw_rect(Rect2(p,Vector2(52,5)),Color("40352d"))
			draw_rect(Rect2(p,Vector2(52*target.fraction,5)),Color("a5b187") if target.fraction>0.4 else Color("b96b53"))
		# Only immediate survival information remains in the world view.
		status_bar("HEALTH",Vector2(20,350),game.health,Color("a1c8a1"))
		if game.stamina<99:
			status_bar("STAMINA",Vector2(20,372),game.stamina,DIM)
		var light_color = Color("c48060") if game.flashlight_charge<=15 else Color("d0c59b")
		status_bar("FLASHLIGHT"+(" / OFF" if not game.flashlight.visible else ""),Vector2(500,350),game.flashlight_charge,light_color)
		if game.flashlight_charge<=0:
			text("EMPTY / Q BATTERY",Vector2(500,374),10,light_color)
		text("TAB / JOURNAL",Vector2(20,24),10,DIM)
		if game.weapons.selected>=0:
			text(game.weapons.status(),Vector2(20,329),11,AMBER)
		if game.weapons.hit_feedback>0:
			draw_line(Vector2(315,195),Vector2(325,205),AMBER,1)
			draw_line(Vector2(325,195),Vector2(315,205),AMBER,1)
		draw_circle(Vector2(320,200),1.2,Color(0.8,0.9,0.8,0.8))
		if message_seconds>0:
			centered(game.message,395,11)
		if game.town.prompt()!="":
			centered(game.town.prompt(),285,15,AMBER)
		if game.rescue_available() and game.town.focus_action!="radio_bypass":
			centered("HOLD E / CALL FOR RESCUE",284,19)
			draw_rect(Rect2(240,296,game.contact_progress*40,3),INK)
	if game.state=="play" and game.achievements.toast_seconds>0:
		draw_achievement()
	if game.state=="journal":
		draw_journal()
		return
	if game.state=="dialogue":
		draw_dialogue()
		return
	if game.state!="play":
		draw_rect(Rect2(0,0,640,400),Color(0.015,0.045,0.065,0.85))
		centered("BLACKWOOD / SURVIVAL HORROR",99,12,DIM)
		var title = "FAR FROM HOME"
		if game.state=="won":
			title = game.story.ending_title()
		elif game.state=="lost":
			title = "SIGNAL LOST"
		elif game.state=="paused":
			title = "PAUSED"
		centered(title,155,40)
		var sub = "Search the town. Survive the night."
		if game.state=="won":
			sub = "COUNTY CHANNEL / WARNING SENT" if game.story.direct_channel_selected() else "UNIDENTIFIED CHANNEL / CALL COMPLETE"
		elif game.state=="lost":
			sub = "Your journey ended. Try again."
		centered(sub,188,14)
		if game.state=="won":
			paragraph(game.story.ending_text(),70,221,500,12)
		else:
			text("01   Survive the crash. Follow Old Mill Road into Blackwood.",Vector2(138,225),13)
			text("02   Search for supplies and weapons. Restore the town radio.",Vector2(138,249),13)
			text("03   Hold E at the repaired radio to call for rescue.",Vector2(138,273),13)
		draw_rect(Rect2(213,296,214,34),Color("6b857a"),false,1)
		centered("ENTER / " + ("RESUME" if game.state=="paused" else "BEGIN JOURNEY"),319,16,AMBER)
		centered("MOUSE  look    WASD  move    SHIFT  sprint    F  flashlight",359,11,DIM)
		centered("E  interact    TAB  journal / map    H  heal    Q  battery    ESC  pause",377,11,DIM)

	if game.state=="play" and passage_fade>0:
		draw_rect(Rect2(0,0,640,400),Color(0.005,0.008,0.008,passage_fade))

func draw_title():
	# The real low-poly town remains visible beneath a dark, weathered CRT treatment.
	draw_rect(Rect2(0,0,640,400),Color(0.015,0.020,0.021,0.22))
	for x in range(0,640,4):
		var alpha = lerpf(0.94,0.12,smoothstep(190,620,float(x)))
		draw_rect(Rect2(x,0,4,400),Color(0.018,0.023,0.025,alpha))
	for i in range(32):
		draw_rect(Rect2(0,i*2,640,2),Color(0,0,0,0.30*(1.0-i/32.0)))
		draw_rect(Rect2(0,398-i*2,640,2),Color(0,0,0,0.50*(1.0-i/32.0)))
	for y in range(0,400,3):
		draw_line(Vector2(0,y),Vector2(640,y),Color(0,0,0,0.10))
	for i in range(85):
		var x = fmod(i*173.0+floor(game.clock*8)*13,640)
		var y = fmod(i*67.0+floor(game.clock*6)*7,400)
		draw_rect(Rect2(x,y,1,1),Color(0.7,0.7,0.62,0.08))
	if game.title_weather and game.title_weather.intensity>0:
		var strength: float = game.title_weather.intensity
		# Keep the distant streak in the sky, with a gentle blue lift over the scenery.
		draw_rect(Rect2(300,0,340,400),Color(0.46,0.57,0.68,strength*0.035))
		draw_polyline(game.title_weather.bolt,Color(0.65,0.73,0.81,strength*0.42),1)
		draw_polyline(game.title_weather.branch,Color(0.65,0.73,0.81,strength*0.21),1)
	if controls_open:
		draw_title_controls()
		return
	var paper = Color("dfd8c1")
	var rust = Color("bd725b")
	text("TRAINGLE STUDIOS",Vector2(43,42),11,Color("86877a"))
	draw_line(Vector2(42,72),Vector2(82,72),rust,2)
	text("A SURVIVAL HORROR GAME",Vector2(92,76),10,rust)
	text("FAR FROM",Vector2(39,135),49,Color("4c322d"))
	text("FAR FROM",Vector2(42,133),49,paper)
	text("HOME",Vector2(39,198),74,Color("4c322d"))
	text("HOME",Vector2(42,196),74,paper)
	# Small breaks in the lettering echo a worn, damaged title card.
	draw_rect(Rect2(42,164,212,1),Color(0.025,0.03,0.03,0.65))
	text("THE ROAD WAS CLOSED.",Vector2(43,225),12,rust)
	text("Somebody opened it.",Vector2(43,245),12,Color("a5a598"))
	text("BLACKWOOD",Vector2(454,324),14,paper)
	draw_line(Vector2(454,335),Vector2(596,335),Color("6d6051"),1)
	text("POPULATION 3",Vector2(454,351),10,Color("b6ac92"))
	text("02:17 AM / NO SIGNAL",Vector2(454,367),9,Color("848b80"))
	text("ENTER / BEGIN",Vector2(43,375),10,Color("969b8c"))
	text("M / SOUND "+("OFF" if game.soundscape.muted else "ON"),Vector2(181,375),10,Color("969b8c"))

func draw_title_controls():
	draw_rect(Rect2(62,54,516,310),Color(0.025,0.035,0.037,0.97))
	draw_rect(Rect2(62,54,516,310),Color("6d6051"),false,1)
	text("SURVIVING BLACKWOOD",Vector2(80,91),24,Color("dfd8c1"))
	var rows = ["WASD / ARROWS     Move     SHIFT     Sprint", "MOUSE     Look     F     Flashlight", "E     Search storage / talk / interact", "LMB     Fire     RMB     Aim     R     Reload", "WHEEL / V     Cycle guns     1-3 Select     0 Holster", "H     First aid     Q     Flashlight battery", "TAB     Journal / map     ESC     Pause"]
	for i in range(rows.size()):
		text(rows[i],Vector2(80,127+i*25),13,Color("b6b6a5"))
	text("Find supplies, weapons and a working radio.",Vector2(80,310),12,Color("bd725b"))

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
	if game.journal_casefile:
		text("WHAT HAPPENED HERE?",Vector2(78,110),18,AMBER)
		paragraph(game.story.question(),78,140,478,14)
		text("EVIDENCE / %d of %d records found" % [game.story.evidence.size(),game.story.RECORDS.size()],Vector2(78,187),11,DIM)
		var labels = ["CLINIC OBSERVATIONS","OWEN'S WORKSHOP LOG","CELLAR ISOLATION PROCEDURE"]
		for i in range(3):
			var id = game.story.PROTOCOL[i]
			var found = game.story.evidence.has(id)
			text(("[+] " if found else "[ ] ")+labels[i],Vector2(78,210+i*42),11,AMBER if found else DIM)
			paragraph(game.story.RECORDS[id][2] if found else "Not yet read. Search the room for a document.",78,227+i*42,478,11)
		text("Set the station's desk bypass to GREEN before transmitting.",Vector2(78,348),11,DIM)
		centered("C  inventory / case notes     LEFT / RIGHT  pages     TAB / ESC  close",379,11,DIM)
		return
	if game.journal_page==0:
		text(game.town.location_name()+" / 02:17 AM",Vector2(78,91),11,DIM)
		text("CURRENT OBJECTIVE",Vector2(78,105),11,DIM)
		paragraph(game.town.objective(),78,127,476,16,AMBER)
		text("HEALTH %d   LIGHT %d%%   RADIO %s" % [int(game.health),int(game.flashlight_charge),"READY" if game.town.radio_ready else "OFFLINE"],Vector2(78,151),11,DIM)
		text("PACK / Health kits %d   Batteries %d   [H] Heal   [Q] Fit battery" % [game.town.inventory.medkit,game.town.inventory.battery],Vector2(78,168),12)
		text("KEY %d   FUSE %d   COIL %d   CELLAR KEY %d   TUNER %d" % [game.town.inventory.station_key,game.town.inventory.fuse,game.town.inventory.coil,game.town.inventory.chapel_key,game.town.inventory.tuner],Vector2(78,184),10,DIM)
		var searched = game.town.interiors.containers.values().filter(func(storage): return storage.searched).size()
		text("STORAGE / %d of 12 searched   SHOTGUN BOX KEY %d" % [searched,game.town.inventory.shotgun_key],Vector2(78,199),10,DIM)
		text("AMMO RESERVE / Pistol %d   Rifle %d   Shotgun %d" % game.weapons.reserves,Vector2(78,214),10,DIM)
		var tasks = [
			[game.town.reached_town,"Follow Old Mill Road into Blackwood"],
			[game.town.inventory.station_key>0,"Find the ranger office's radio-station key"],
			[game.town.powered,"Find store fuse; restore workshop power"],
			[game.town.inventory.coil>0 or game.town.radio_ready,"Recover workshop signal coil"],
			[game.town.streetscape.church.basement.unlocked,"Find workshop key; unlock the chapel cellar"],
			[game.town.inventory.tuner>0 or game.town.radio_ready,"Recover the chapel cellar tuning unit"],
			[game.town.radio_ready,"Repair the receiver with both radio parts"],
			[game.contact_progress>=4,"Hold E at the repaired radio to call for rescue"]]
		for i in range(tasks.size()):
			text(("[+] " if tasks[i][0] else "[ ] ")+tasks[i][1],Vector2(78,230+i*14),12,DIM if tasks[i][0] else INK)
		var earned = game.achievements.unlocked
		text("ACHIEVEMENTS / "+(game.achievements.CROW_TITLE if earned.has(game.achievements.CROW_ID) else "0 unlocked"),Vector2(78,346),10,AMBER if not earned.is_empty() else DIM)
	elif game.journal_page==1:
		text("OLD MILL ROAD / TOWN MAP",Vector2(78,105),14,AMBER)
		draw_line(journal_map_point(Vector3(0,0,-93)),journal_map_point(Vector3(0,0,-38)),Color("667a76"),8)
		var hill_points = PackedVector2Array()
		for point in game.town.streetscape.chapel_hill.samples:
			hill_points.append(journal_map_point(point))
		draw_polyline(hill_points,Color("667a76"),4)
		draw_line(Vector2(320,333),Vector2(320,340),Color("667a76"),5)
		for data in game.town.BUILDINGS:
			var p = journal_map_point(data.p)
			draw_rect(Rect2(p-Vector2(data.d*2.5,data.w*0.9),Vector2(data.d*5,data.w*1.8)),Color("385156"))
			text(data.id.to_upper(),p+Vector2(-22,4),10,INK)
		var chapel = journal_map_point(game.town.streetscape.church.position)
		draw_rect(Rect2(chapel-Vector2(25,13),Vector2(50,26)),Color("385156"))
		text("CHAPEL",chapel+Vector2(-20,4),10,INK)
		var player = game.player.position
		if player.z< -35 and player.z> -156:
			draw_circle(journal_map_point(player),4,AMBER)
		text("SOUTH / OLD MILL ROAD & CRASH SITE",Vector2(211,336),11,DIM)
	else:
		var entry = game.town.journal_entries[clampi(game.journal_page-2,0,game.town.journal_entries.size()-1)]
		text(entry.title.to_upper(),Vector2(78,110),18,AMBER)
		paragraph(entry.text,78,150,478,14)
	centered("LEFT / RIGHT  pages     C  case notes     TAB / ESC  close",379,11,DIM)

func draw_intro():
	draw_rect(Rect2(0,0,640,400),Color("020609"))
	var alpha = minf(clampf(game.intro_elapsed/0.65,0,1),clampf((3.6-game.intro_elapsed)/0.5,0,1))
	var ink = Color(0.76,0.86,0.78,alpha)
	draw_polyline(PackedVector2Array([Vector2(320,93),Vector2(363,165),Vector2(277,165),Vector2(320,93)]),ink,2,true)
	centered("Traingle Studios Presents...",224,32,ink)
	centered("ENTER / SKIP",343,10,Color(0.4,0.53,0.50,alpha*0.8))

func draw_dialogue():
	draw_rect(Rect2(0,0,640,400),Color(0.015,0.035,0.05,0.72))
	draw_rect(Rect2(55,84,530,258),Color("102127"))
	draw_rect(Rect2(55,84,530,258),Color("6e8279"),false,1)
	text(game.dialogue_name.to_upper(),Vector2(78,118),23,AMBER)
	paragraph(game.dialogue_text,78,151,478,14)
	centered("E / ENTER / ESC  finish conversation",359,12,DIM)

func journal_map_point(p: Vector3) -> Vector2:
	return Vector2(320+p.x*5,140+(p.z+145)*1.8)

func status_bar(label: String, p: Vector2, amount: float, color: Color):
	text(label,p,10,DIM)
	draw_rect(Rect2(p+Vector2(0,7),Vector2(120,4)),Color("263532"))
	draw_rect(Rect2(p+Vector2(0,7),Vector2(120*clampf(amount/100,0,1),4)),color)

func draw_achievement():
	draw_rect(Rect2(139,25,362,57),Color(0.025,0.032,0.029,0.96))
	draw_rect(Rect2(139,25,362,57),Color("8d805e"),false,1)
	centered("ACHIEVEMENT UNLOCKED" if game.achievements.toast_is_new else "ACHIEVEMENT",45,11,DIM)
	centered(game.achievements.toast_title,68,19,AMBER)
