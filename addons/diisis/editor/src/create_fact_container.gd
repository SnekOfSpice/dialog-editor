@tool
extends Control

signal close

func init() -> void:
	find_child("DataTypes").find_child("Bool").button_pressed = true
	_on_bool_pressed()
	_on_default_bool_check_box_toggled(false)
	_on_line_edit_text_changed("")
	find_child("LineEdit").text = ""
	find_child("LineEdit").grab_focus()
	
	find_child("DefaultIntSpinBox").value = 0
	find_child("DefaultBoolCheckBox").button_pressed = false


func _on_bool_pressed() -> void:
	find_child("InitialValue").find_child("Bool").visible = true
	find_child("InitialValue").find_child("Int").visible = false


func _on_int_pressed() -> void:
	find_child("InitialValue").find_child("Bool").visible = false
	find_child("InitialValue").find_child("Int").visible = true

func _on_default_bool_check_box_toggled(toggled_on: bool) -> void:
	var cb : CheckBox = find_child("DefaultBoolCheckBox")
	cb.text = "true" if toggled_on else "false"




func _on_line_edit_text_changed(new_text: String) -> void:
	find_child("NotEmptyLabel").visible = new_text.is_empty()
	find_child("AlreadyExistsLabel").visible = Pages.has_fact(new_text)
	
	find_child("CreateButton").disabled = not Pages.is_fact_new_and_not_empty(new_text)


func _on_cancel_button_pressed() -> void:
	emit_signal("close")


func _on_create_button_pressed() -> void:
	var fact_name = find_child("LineEdit").text
	var fact_value
	if find_child("DataTypes").find_child("Bool").button_pressed:
		fact_value = find_child("DefaultBoolCheckBox").button_pressed
	elif find_child("DataTypes").find_child("Int").button_pressed:
		fact_value = int(find_child("DefaultIntSpinBox").value)
	Pages.register_fact(fact_name, fact_value)
	emit_signal("close")


func _on_visibility_changed() -> void:
	if visible:
		$VBoxContainer/LineEdit.grab_focus()
