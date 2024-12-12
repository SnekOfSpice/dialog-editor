@tool
extends Control
class_name InstructionTextEdit


var text_box : HintedLineEdit
@export var reverse := false

func init():
	text_box = find_child("InstructionTextBox")
	_on_instruction_text_box_text_entered("")
	if reverse:
		visible = false

func get_text() -> String:
	return text_box.text

func get_instruction_name() -> String:
	if text_box.text.contains("("):
		return text_box.text.split("(")[0]
	else:
		return text_box.text

func _on_copy_signature_to_clipboard_button_pressed() -> void:
	var signature : String = Pages.get_instruction_signature(get_instruction_name())
	if not signature.is_empty():
		DisplayServer.clipboard_set(signature)

func _on_instruction_text_box_text_entered(new_text: String) -> void:
	if new_text.contains("\n"):
		var lines := new_text.split("\n")
		text_box.text = "".join(lines)
	var compliance : String = Pages.get_entered_instruction_compliance(new_text)
	var compliance_container = find_child("ComplianceContainer")
	var compliance_label = find_child("ComplianceLabel")
	
	if reverse and new_text.is_empty():
		compliance = "OK"
	
	compliance_container.visible = compliance != "OK"
	compliance_label.text = compliance
	
	if compliance == "OK":
		find_child("ColorRect").self_modulate.a = 0.0
	else:
		find_child("ColorRect").self_modulate.a = 0.5


func _on_instruction_text_box_focus_entered() -> void:
	await get_tree().process_frame
	text_box.completion_options = Pages.instruction_templates.keys()


func _on_instruction_text_box_caret_changed() -> void:
	var caret_col = text_box.get_caret_column()
	var start = text_box.text.find("(")
	var end = text_box.text.find(")") + 1
	
	if caret_col > start and caret_col < end:
		var caret_pos = Vector2i(text_box.get_caret_draw_pos())
		caret_pos += Vector2i(text_box.global_position)
		caret_pos *= Pages.editor.content_scale
		caret_pos += Vector2(0, 10) * Pages.editor.content_scale
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

func _on_instruction_text_box_focus_exited() -> void:
	find_child("ArgHint").hide()


func set_text(text:String):
	text_box.text = text
	_on_instruction_text_box_text_entered(text_box.text)


func _on_instruction_text_box_text_submitted(new_text: String) -> void:
	_on_instruction_text_box_text_entered(new_text)
