extends RefCounted
## Shared layout keeps page breaks identical to the bitmap text on screen.
const BOX = Rect2(80,266,480,118)
const FONT = preload("res://assets/dialogue_pixels.fnt")
const SIZE = 20
const WIDTH = 432
const MAX_LINES = 4
static func pages(value: String) -> Array[String]:
	var result: Array[String] = []
	var clean = value.to_upper().replace("’","'").replace("‘","'").replace("“","\"").replace("”","\"").replace("—","-").replace("–","-").replace("…","...")
	for paragraph in clean.split("\n\n",false):
		var lines: Array[String] = []
		var line = ""
		for word in paragraph.replace("\n"," ").split(" ",false):
			var candidate = word if line.is_empty() else line+" "+word
			if FONT.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,SIZE).x>WIDTH and not line.is_empty():
				lines.append(line)
				line = word
			else: line = candidate
		if not line.is_empty(): lines.append(line)
		for i in range(0,lines.size(),MAX_LINES):
			result.append("\n".join(lines.slice(i,mini(i+MAX_LINES,lines.size()))))
	if result.is_empty(): result.append("")
	return result

