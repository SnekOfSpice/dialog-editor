@tool
extends ScrollContainer

var max_scroll_length = 0
@onready var scrollbar = get_v_scroll_bar()

@export var code_edit : CodeEdit



func init() -> void:
	# auto scrolling
	scrollbar.connect("changed", handle_scrollbar_changed)
	max_scroll_length = scrollbar.max_value

func handle_scrollbar_changed():
	var scroll_before : int
	if code_edit:
		scroll_before = scroll_vertical
	
	if max_scroll_length != scrollbar.max_value:
		max_scroll_length = scrollbar.max_value
		scroll_vertical = max_scroll_length
	
	if code_edit:
		var draw_y = int(code_edit.get_caret_draw_pos().y)
		
		if (draw_y > size.y) and (draw_y < scroll_before):
			scroll_vertical = draw_y
		elif draw_y > size.y + scroll_before: # for newlines that extend the size at the end of the text box
			scroll_vertical = draw_y
		else:
			scroll_vertical = scroll_before
