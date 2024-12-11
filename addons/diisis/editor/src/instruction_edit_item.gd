@tool
extends Control
class_name InstructionEditItem

var text_before_edit := ""

func set_changes_discardable(value:bool):
	find_child("DiscardButton").visible = value

func get_visible_text():
	if find_child("InstructionLabel").visible:
		return find_child("InstructionLabel").text
	elif find_child("InstructionEdit").visible:
		return find_child("InstructionEdit").text

func get_raw_entered_text() -> String:
	return str(find_child("InstructionLabel").text, find_child("InstructionEdit").text)

func set_template(template:String):
	var args = Pages.instruction_templates.get(template, {}).get("args", [])
	var arg_types = Pages.instruction_templates.get(template, {}).get("arg_types", [])
	
	var display_string := ""
	display_string += template
	if not display_string.is_empty():
		display_string += "("
	var i := 0
	while i < args.size():
		display_string += str(args[i], ":", arg_types[i])
		if i < args.size() - 1:
			display_string += ", "
		i += 1
	if not display_string.is_empty():
		display_string += ")"
	
	find_child("InstructionLabel").text = display_string

func set_editing(value:bool):
	find_child("EditButton").visible = not value
	find_child("InstructionLabel").modulate.a = 0.6 if value else 1.0
	find_child("EditContainer").visible = value
	if value:
		text_before_edit = find_child("InstructionLabel").text
		find_child("SaveButton").disabled = true
		find_child("InstructionEdit").text = text_before_edit
		set_changes_discardable(not text_before_edit.is_empty())
	
		_on_instruction_edit_text_changed(text_before_edit)
	else:
		find_child("ComplianceLabel").visible = false


func _on_save_button_pressed() -> void:
	# if discardable, overwrite, else add
	var new_text : String = find_child("InstructionEdit").text
	if text_before_edit.is_empty():
		Pages.add_template_from_string(new_text)
	else:
		Pages.update_instruction_from_template(text_before_edit.split("(")[0], new_text)
	
	set_template(new_text.split("(")[0])
	set_editing(false)


func _on_edit_button_pressed() -> void:
	set_editing(true)
	set_changes_discardable(text_before_edit != "")


func _on_discard_button_pressed() -> void:
	find_child("InstructionLabel").text = text_before_edit
	set_editing(false)


func _on_instruction_edit_text_changed(new_text: String) -> void:
	var name_before_edit : String = text_before_edit.split("(")[0]
	var entered_name : String = find_child("InstructionEdit").text.split("(")[0]
	var compliance := Pages.get_entered_instruction_compliance(new_text, true, name_before_edit != entered_name)
	
	find_child("SaveButton").disabled = compliance != "OK"
	find_child("ComplianceLabel").visible = compliance != "OK"
	find_child("ComplianceLabel").text = compliance
	if compliance == "OK":
		self_modulate.v = 1.0
	else:
		self_modulate.v = 30.0

func _on_delete_button_pressed() -> void:
	Pages.try_delete_instruction_template(find_child("InstructionLabel").text.split("(")[0])
	queue_free()

func get_instruction_name() -> String:
	var label_text : String = find_child("InstructionLabel").text
	if label_text.contains("("):
		return label_text.split("(")[0]
	else:
		return label_text

func _on_copy_signature_to_clipboard_button_pressed() -> void:
	var signature : String = Pages.get_instruction_signature(get_instruction_name())
	if not signature.is_empty():
		DisplayServer.clipboard_set(signature)

func grab_focus():
	find_child("InstructionEdit").grab_focus()
