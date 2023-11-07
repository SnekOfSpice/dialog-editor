extends Control



func serialize():
	return find_child("TextBox").text

func deserialize(data: String):
	find_child("TextBox").text = data

func _input(event: InputEvent) -> void:
	pass

func insert(control_sequence: String):
	var tb : TextEdit = find_child("TextBox")
	match control_sequence:
		"autopause":
			tb.insert_text_at_caret("<ap>")
		"manualpause":
			tb.insert_text_at_caret("<mp>")
		"lineclear":
			tb.insert_text_at_caret("<lc>")

func _on_pause_auto_cont_pressed() -> void:
	insert("autopause")


func _on_pause_click_cont_pressed() -> void:
	insert("manualpause")

func _on_line_clear_pressed() -> void:
	insert("lineclear")
