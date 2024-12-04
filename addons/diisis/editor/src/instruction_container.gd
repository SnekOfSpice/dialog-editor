@tool
extends Control

var selected_index := 0

var text_box : HintedLineEdit
var reverse_text_box : HintedLineEdit

func init() -> void:
	text_box = find_child("InstructionTextBox")
	reverse_text_box = find_child("ReverseInstructionTextBox")
	_on_hinted_line_edit_text_entered("")

func get_instruction_name(line_edit:=text_box) -> String:
	if line_edit.text.contains("("):
		return line_edit.text.split("(")[0]
	else:
		return line_edit.text

func serialize():
	var result = {}
	
	result["name"] = get_instruction_name()
	result["reverse_name"] = get_instruction_name(reverse_text_box)
	
	result["line_reader.args"] = Pages.get_arg_array_from_instruction_string(text_box.text, get_instruction_name())
	result["line_reader.reverse_args"] = Pages.get_arg_array_from_instruction_string(reverse_text_box.text, get_instruction_name())
	result["delay_before"] = find_child("DelayBeforeSpinBox").value
	result["delay_after"] = find_child("DelayAfterSpinBox").value
	
	result["meta.validation_status"] = Pages.get_entered_instruction_compliance(text_box.text)
	result["meta.text"] = text_box.text
	result["meta.reverse_text"] = reverse_text_box.text
	result["meta.has_reverse"] = find_child("HasReverseCheckBox").button_pressed
	
	return result


func deserialize(data: Dictionary):
	text_box.text = data.get("meta.text", "")
	reverse_text_box.text = data.get("meta.reverse_text", "")
	
	find_child("DelayBeforeSpinBox").value = float(data.get("delay_before", data.get("delay.before", data.get("delay", 0.0))))
	find_child("DelayAfterSpinBox").value = float(data.get("delay_after", data.get("delay.after", 0.0)))
	_on_hinted_line_edit_text_entered(text_box.text)
	_on_reverse_instruction_text_box_text_entered(reverse_text_box.text)
	_on_line_edit_text_entered(reverse_text_box, reverse_text_box.text)
	find_child("HasReverseCheckBox").button_pressed = data.get("meta.has_reverse", false)
	_on_has_reverse_check_box_toggled(data.get("meta.has_reverse", false))

func set_page_view(view:DiisisEditor.PageView):
	find_child("InputLockContainer").visible = view != DiisisEditor.PageView.Minimal
	find_child("DelayContainer").columns = 2 if view == DiisisEditor.PageView.Full else 4

func _on_hinted_line_edit_caret_changed() -> void:
	_on_line_edit_caret_changed(text_box)

func _on_reverse_instruction_text_box_caret_changed() -> void:
	_on_line_edit_caret_changed(reverse_text_box)


func _on_line_edit_caret_changed(line_edit:HintedLineEdit) -> void:
	var caret_col = line_edit.get_caret_column()
	var start = line_edit.text.find("(")
	var end = line_edit.text.find(")") + 1
	
	if caret_col > start and caret_col < end:
		var caret_pos = Vector2i(line_edit.get_caret_draw_pos())
		caret_pos += Vector2i(line_edit.global_position)
		caret_pos.x += 30
		caret_pos.y += 50
		find_child("ArgHint").position = caret_pos
		
		var arg_names = Pages.get_instruction_arg_names(get_instruction_name())
		var arg_types = Pages.get_instruction_arg_types(get_instruction_name())
		var arg_strings := []
		var i := 0
		while i < arg_names.size():
			arg_strings.append(str(arg_names[i], ":", arg_types[i]))
			i += 1
		var args_before_caret :int = line_edit.text.count(",", 0, caret_col)
		
		var args_cleaned := ""
		
		i = 0
		for a in arg_strings:
			if i == args_before_caret:
				args_cleaned += "[b]"
			args_cleaned += a
			if i < arg_strings.size() - 1:
				args_cleaned += ", "
			if i == args_before_caret:
				args_cleaned += "[/b]"
			i += 1
		
		find_child("ArgHint").build(args_cleaned)
		find_child("ArgHint").popup()
		
		line_edit.set_caret_column(caret_col)
		line_edit.call_deferred("grab_focus")
	else:
		find_child("ArgHint").hide()
		

func _on_hinted_line_edit_focus_exited() -> void:
	find_child("ArgHint").hide()


func _on_reverse_instruction_text_box_focus_exited() -> void:
	find_child("ArgHint").hide()


func _on_copy_signature_to_clipboard_button_pressed() -> void:
	var signature : String = Pages.get_instruction_signature(get_instruction_name())
	if not signature.is_empty():
		DisplayServer.clipboard_set(signature)


func _on_hinted_line_edit_focus_entered() -> void:
	await get_tree().process_frame
	find_child("InstructionTextBox").completion_options = Pages.instruction_templates.keys()

func _on_reverse_instruction_text_box_focus_entered() -> void:
	await get_tree().process_frame
	find_child("ReverseInstructionTextBox").completion_options = Pages.instruction_templates.keys()

func _on_reverse_instruction_text_box_text_entered(new_text: String) -> void:
	_on_line_edit_text_entered(reverse_text_box, new_text)


func _on_hinted_line_edit_text_entered(new_text: String) -> void:
	_on_line_edit_text_entered(text_box, new_text)

func _on_line_edit_text_entered(line_edit:HintedLineEdit, new_text: String) -> void:
	if new_text.contains("\n"):
		var lines := new_text.split("\n")
		line_edit.text = "".join(lines)
	var compliance : String = Pages.get_entered_instruction_compliance(new_text)
	var compliance_container = find_child("ComplianceContainer") if line_edit == text_box else find_child("ReverseComplianceContainer")
	var compliance_label = find_child("ComplianceLabel") if line_edit == text_box else find_child("ReverseComplianceLabel")
	
	if line_edit == reverse_text_box and new_text.is_empty():
		compliance = "OK"
	
	compliance_container.visible = compliance != "OK"
	compliance_label.text = compliance
	
	if compliance == "OK":
		find_child("InstructionTextContainer").self_modulate.a = 0.0
	else:
		find_child("InstructionTextContainer").self_modulate.a = 0.5


func _on_copy_signature_to_clipboard_button_2_pressed() -> void:
	var signature : String = Pages.get_instruction_signature(get_instruction_name(reverse_text_box))
	if not signature.is_empty():
		DisplayServer.clipboard_set(signature)


func _on_has_reverse_check_box_toggled(toggled_on: bool) -> void:
	find_child("ReverseContainer").visible = toggled_on
	find_child("ReverseComplianceContainer").visible = toggled_on
