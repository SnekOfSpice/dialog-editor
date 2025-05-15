@tool
extends Control
class_name InstructionTextEdit


var text_box : HintedLineEdit
@export var reverse := false

signal request_search(instruction_name : String, reverse : bool)
signal request_search_in_setup(instruction_name : String, reverse : bool)

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
	
	#if compliance == "OK":
		#find_child("ColorRect").self_modulate.a = 0.0
	#else:
		#find_child("ColorRect").self_modulate.a = 0.5
	
	Pages.editor.error_update_countdown = 1.0


func _on_instruction_text_box_focus_entered() -> void:
	await get_tree().process_frame
	text_box.completion_options = Pages.get_all_instruction_names()


func _on_instruction_text_box_caret_changed() -> void:
	var caret_col = text_box.get_caret_column()
	var start = text_box.text.find("(")
	var end = text_box.text.find(")") + 1
	
	if caret_col > start and caret_col < end:
		Pages.editor.request_arg_hint(text_box)
		Pages.editor.build_arg_hint(get_instruction_name(), text_box.text, caret_col)
		
	else:
		Pages.editor.hide_arg_hint()

func _on_instruction_text_box_focus_exited() -> void:
	Pages.editor.hide_arg_hint()


func set_text(text:String):
	text_box.text = text
	_on_instruction_text_box_text_entered(text_box.text)


func _on_instruction_text_box_text_submitted(new_text: String) -> void:
	_on_instruction_text_box_text_entered(new_text)


func _on_go_to_script_button_pressed() -> void:
	DiisisEditorUtil.search_function(get_instruction_name())


func _on_instruction_text_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_command_or_control_pressed() and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			await get_tree().process_frame
			if event.is_shift_pressed():
				emit_signal("request_search_in_setup", get_instruction_name(), reverse)
			else:
				emit_signal("request_search", get_instruction_name(), reverse)
