@tool
extends LineEdit
class_name TitleLineEdit

@export var parent_container : Control

signal request_start_editing()
signal editing_cancelled()

func _on_mouse_entered() -> void:
	parent_container.custom_minimum_size.x = parent_container.size.x
	add_theme_stylebox_override("normal", load("uid://wygkuwnsf32l"))
	add_theme_stylebox_override("read_only", load("uid://wygkuwnsf32l"))


func _on_mouse_exited() -> void:
	parent_container.custom_minimum_size.x = 0
	remove_theme_stylebox_override("normal")
	add_theme_stylebox_override("read_only", StyleBoxEmpty.new())


var text_before_editing := ""
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not editable:
				set_editing(true)
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			text = text_before_editing
			set_editing(false)

signal request_text_before_editing()
signal request_save()
signal editing_set(value:bool)
func set_editing(value:bool):
	if value:
		if not editable:
			emit_signal("request_text_before_editing")
	else:
		emit_signal("request_save")
		#save_page_key_from_line_edit()
	emit_signal("editing_set", value)
	#enable_page_key_edit(value)
