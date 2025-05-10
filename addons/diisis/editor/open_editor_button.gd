@tool
extends Control

var is_in_editor := false

signal request_open_diisis()
signal request_setup_template(template:int)

func _shortcut_input(event):
	if not is_in_editor:
		return
	if event is InputEventKey:
		if event.is_command_or_control_pressed() and event.alt_pressed and event.key_label == KEY_D:
			emit_signal("request_open_diisis")


func _on_open_editor_button_pressed() -> void:
	if not is_in_editor:
		return
	emit_signal("request_open_diisis")


func _on_v_id_pressed(id: int) -> void:
	match id:
		0:
			emit_signal("request_setup_template", 0)
