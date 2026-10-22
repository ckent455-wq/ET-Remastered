extends Control
## Opening thought, then a quiet countdown above the black screen.
var rescue
func _draw():
 if rescue==null:return
 var ink=Color("e8e2d5")
 if rescue.caption_visible():
  var style=preload("res://dialogue_style.gd")
  var lines=style.pages(rescue.FAINT_LINE)[0].split("\n")
  var bounds=Rect2(80,42,480,24+lines.size()*22)
  draw_rect(bounds,Color.BLACK)
  draw_rect(bounds,ink,false,2)
  for i in range(lines.size()):draw_string(style.FONT,Vector2(104,71+i*22),lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,style.SIZE,ink)
 var dots=rescue.blackout_dots()
 for i in range(dots):draw_circle(Vector2(320+(i-(dots-1)*0.5)*16,369),3,ink)
