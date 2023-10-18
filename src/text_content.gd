extends Control



func serialize():
	return find_child("TextBox").text

func deserialize(data: String):
	find_child("TextBox").text = data

func _input(event: InputEvent) -> void:
	pass

func insert(control_sequence: String):
	var tb = find_child("TextBox")
	match control_sequence:
		"autopause":
			tb.text = tb.text + "[ap]"
		"manualpause":
			tb.text = tb.text + "[mp]"
		"lineclear":
			tb.text = tb.text + "[lc]"

func _on_pause_auto_cont_pressed() -> void:
	insert("autopause")


func _on_pause_click_cont_pressed() -> void:
	insert("manualpause")

func _on_line_clear_pressed() -> void:
	insert("lineclear")
