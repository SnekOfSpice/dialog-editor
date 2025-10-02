@tool
extends Control

var instruction_edit : InstructionTextEdit
var instruction_edit_reverse : InstructionTextEdit

func init() -> void:
	instruction_edit = find_child("InstructionTextEdit")
	instruction_edit_reverse = find_child("InstructionTextEditReverse")
	instruction_edit.init()
	instruction_edit_reverse.init()

func get_instruction_name() -> String:
	return instruction_edit.get_instruction_name()

func serialize():
	var result = {}
	
	var instruction_name = get_instruction_name()
	var instruction_name_reverse = instruction_edit_reverse.get_instruction_name()
	var instruction_text = instruction_edit.get_text()
	var instruction_text_reverse = instruction_edit_reverse.get_text()
	
	result["name"] = instruction_name
	result["reverse_name"] = instruction_name_reverse
	
	result["delay_before"] = %DelayBeforeSpinBox.value
	result["delay_after"] = %DelayAfterSpinBox.value
	
	result["meta.validation_status"] = Pages.get_method_validity(instruction_text)
	result["meta.text"] = instruction_text
	result["meta.reverse_text"] = instruction_text_reverse
	result["meta.has_reverse"] = find_child("HasReverseCheckBox").button_pressed
	
	return result


func deserialize(data: Dictionary):
	instruction_edit.set_text(data.get("meta.text", ""))
	instruction_edit_reverse.set_text(data.get("meta.reverse_text", ""))
	
	%DelayBeforeSpinBox.value = float(data.get("delay_before", data.get("delay.before", data.get("delay", 0.0))))
	%DelayAfterSpinBox.value = float(data.get("delay_after", data.get("delay.after", 0.0)))
	
	find_child("HasReverseCheckBox").button_pressed = data.get("meta.has_reverse", false)
	_on_has_reverse_check_box_toggled(data.get("meta.has_reverse", false))

func set_page_view(view:DiisisEditor.PageView):
	find_child("InputLockContainer").visible = view != DiisisEditor.PageView.Minimal
	find_child("HasReverseCheckBox").visible = view != DiisisEditor.PageView.Minimal
	#find_child("DelayContainer").columns = 2 if view == DiisisEditor.PageView.Full else 4

func _on_has_reverse_check_box_toggled(toggled_on: bool) -> void:
	instruction_edit_reverse.visible = toggled_on


func _on_instruction_request_search(instruction_name: String, reverse: bool) -> void:
	if reverse and instruction_name.is_empty():
		DiisisEditorUtil.search_function(instruction_edit.get_instruction_name())
		return
	DiisisEditorUtil.search_function(instruction_name)


func _on_instruction_text_edit_request_search_in_setup(instruction_name: String, reverse: bool) -> void:
	if reverse and instruction_name.is_empty():
		Pages.editor.open_handler_window(instruction_edit.get_instruction_name())
		return
	Pages.editor.open_handler_window(instruction_name)
