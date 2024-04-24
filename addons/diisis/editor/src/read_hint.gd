@tool
extends Window


func build(hint: String):
	find_child("TextLabel").text = hint

func _on_close_requested() -> void:
	hide()

func get_hint_line_count() -> int:
	return find_child("TextLabel").get_line_count()

func get_text_in_line(line:int) -> String:
	var label_text : String = find_child("TextLabel").text
	var segments = label_text.split("\n")
	if segments.size() <= line:
		push_warning("Text too short.")
		return ""
	return segments[line]
