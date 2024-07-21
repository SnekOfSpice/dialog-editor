@tool
extends Control

var selected_index := 0

var text_box : HintedLineEdit

func init() -> void:
	text_box = find_child("HintedLineEdit")
	_on_hinted_line_edit_text_entered("")

func get_instruction_name() -> String:
	if text_box.text.contains("("):
		return text_box.text.split("(")[0]
	else:
		return text_box.text

func serialize():
	var result = {}
	
	result["name"] = get_instruction_name()
	
	result["line_reader.args"] = Pages.get_arg_array_from_instruction_string(text_box.text, get_instruction_name())
	result["delay_before"] = find_child("DelayBeforeSpinBox").value
	result["delay_after"] = find_child("DelayAfterSpinBox").value
	
	result["meta.validation_status"] = Pages.get_entered_instruction_compliance(text_box.text)
	result["meta.text"] = text_box.text
	
	return result


func deserialize(data: Dictionary):
	text_box.text = data.get("meta.text", "")
	
	find_child("DelayBeforeSpinBox").value = float(data.get("delay_before", data.get("delay.before", data.get("delay", 0.0))))
	find_child("DelayAfterSpinBox").value = float(data.get("delay_after", data.get("delay.after", 0.0)))
	_on_hinted_line_edit_text_entered(text_box.text)

func set_page_view(view:DiisisEditor.PageView):
	find_child("InputLockContainer").visible = view != DiisisEditor.PageView.Minimal


func _on_hinted_line_edit_caret_changed() -> void:
	var caret_col = text_box.get_caret_column()
	var start = text_box.text.find("(")
	var end = text_box.text.find(")") + 1
	
	if caret_col > start and caret_col < end:
		var caret_pos = Vector2i(text_box.get_caret_draw_pos())
		caret_pos += Vector2i(text_box.global_position)
		find_child("ArgHint").position = caret_pos
		
		var arg_names = Pages.get_instruction_arg_names(get_instruction_name())
		var arg_types = Pages.get_instruction_arg_types(get_instruction_name())
		var arg_strings := []
		var i := 0
		while i < arg_names.size():
			arg_strings.append(str(arg_names[i], ":", arg_types[i]))
			i += 1
		var args_before_caret :int = text_box.text.count(",", 0, caret_col)
		
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
		
		text_box.set_caret_column(caret_col)
		text_box.call_deferred("grab_focus")
	else:
		find_child("ArgHint").hide()
		

func _on_hinted_line_edit_focus_exited() -> void:
	find_child("ArgHint").hide()



func _on_copy_signature_to_clipboard_button_pressed() -> void:
	var signature : String = Pages.get_instruction_signature(get_instruction_name())
	if not signature.is_empty():
		DisplayServer.clipboard_set(signature)


func _on_hinted_line_edit_focus_entered() -> void:
	find_child("HintedLineEdit").completion_options = Pages.instruction_templates.keys()


func _on_hinted_line_edit_text_entered(new_text: String) -> void:
	if new_text.contains("\n"):
		var lines := new_text.split("\n")
		text_box.text = "".join(lines)
	var compliance : String = Pages.get_entered_instruction_compliance(new_text)
	find_child("ComplianceContainer").visible = compliance != "OK"
	find_child("ComplianceLabel").text = compliance
	
	if compliance == "OK":
		find_child("InstructionTextContainer").self_modulate.a = 0.0
	else:
		find_child("InstructionTextContainer").self_modulate.a = 0.5
