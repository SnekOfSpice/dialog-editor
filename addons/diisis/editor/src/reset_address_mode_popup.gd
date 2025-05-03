@tool
extends Window

signal change_to_mode(mode : AddressModeButton.Mode)

func _ready() -> void:
	close_requested.connect(set.bind("visible", false))
	about_to_popup.connect(on_about_to_popup)


func on_about_to_popup():
	var s : String = "OBJ" if Pages.default_address_mode_pages == AddressModeButton.Mode.Objectt else "ADR"
	find_child("DefaultButton").text = str("Set to default (", s, ")")


func _on_object_button_pressed() -> void:
	emit_signal("change_to_mode", AddressModeButton.Mode.Objectt)
	visible = false


func _on_address_button_pressed() -> void:
	emit_signal("change_to_mode", AddressModeButton.Mode.Address)
	visible = false


func _on_default_button_pressed() -> void:
	emit_signal("change_to_mode", Pages.default_address_mode_pages)
	visible = false


func _on_cancel_button_pressed() -> void:
	visible = false
