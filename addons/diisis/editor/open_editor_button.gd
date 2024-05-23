@tool
extends Button

var is_in_editor := false

signal request_open_diisis()

func _shortcut_input(event):
	if not is_in_editor:
		return
	if event.is_ctrl_pressed() and event.is_alt_pressed() and event.pressed and event.key_label == KEY_D:
		emit_signal("request_open_diisis")
