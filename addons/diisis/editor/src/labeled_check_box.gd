@tool
extends CheckBox

signal labeled_pressed(label: String, pressed:bool)


func _on_pressed() -> void:
	emit_signal("labeled_pressed", text, button_pressed)
