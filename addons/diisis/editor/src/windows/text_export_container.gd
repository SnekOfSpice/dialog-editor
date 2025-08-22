@tool
extends Control

signal fd_opened
signal fd_closed

func init():
	for child in %SelectionContainer.get_children():
		child.queue_free()
	for child in %PageKeyLabelContainer.get_children():
		child.queue_free()
	for i in Pages.get_page_count():
		var key : String = Pages.get_page_key(i)
		var label = Label.new()
		label.text = str(i, " - ", key)
		%PageKeyLabelContainer.add_child(label)
	
	for i in Pages.get_page_count():
		var button = CheckBox.new()
		button.text = str(i)
		button.button_pressed = (Pages.preferences_export.get("selection", []) as Array).has(i)
		button.pressed.connect(update_key_labels)
		%SelectionContainer.add_child(button)
	%Mode.init()
	%Mode.select(Pages.preferences_export.get("mode", 0))
	%SyntaxDetailButton.init()
	%SyntaxDetailButton.select(Pages.preferences_export.get("syntax_detail", 0))
	_on_option_button_embed_option_pressed(%Mode.get_selected_id())
	%StartSpinBox.max_value = Pages.get_page_count() - 1
	%EndSpinBox.max_value = Pages.get_page_count() - 1
	%CascadeStartSpinbox.max_value = Pages.get_page_count() - 1
	
	%StartSpinBox.value = Pages.preferences_export.get("range_start", 0)
	%EndSpinBox.value = Pages.preferences_export.get("range_end", 0)
	%CascadeStartSpinbox.value = Pages.preferences_export.get("cascade_start", 0)
	
	var line_types_to_include : Array = Pages.preferences_export.get("line_types_to_include", [0,1,2,3])
	for i in line_types_to_include.size():
		line_types_to_include[i] = int(line_types_to_include[i])
	%IncludeText.button_pressed = DIISISGlobal.LineType.Text in line_types_to_include
	%IncludeChoice.button_pressed = DIISISGlobal.LineType.Choice in line_types_to_include
	%IncludeInstruction.button_pressed = DIISISGlobal.LineType.Instruction in line_types_to_include
	%IncludeFolder.button_pressed = DIISISGlobal.LineType.Folder in line_types_to_include
	
	update_warnings()

func _on_option_button_embed_option_pressed(index: int) -> void:
	%ModeInput.find_child("Range").visible = index == 1
	%ModeInput.find_child("Cascade").visible = index == 2
	%ModeInput.find_child("SelectionContainer").visible = index == 3
	await get_tree().process_frame
	update_key_labels()


func generate_export() -> String:
	var modifiers := {
		"syntax_detail" : %SyntaxDetailButton.get_selected_id(),
		"line_types_to_include" : get_line_types_to_include(),
	}
	var result := ""
	if %SyntaxDetailButton.get_selected_id() != 2:
		result += Pages.ingestion_actor_declaration
		result += "\nEND ACTORS\n"
	
	for i in get_selected_page_range():
		result += Pages.stringify_page(i, modifiers)
	
	return result

func get_selected_page_button_indices() -> Array:
	var selection := []
	for button : CheckBox in %SelectionContainer.get_children():
		if button.button_pressed:
			selection.append(int(button.text))
	return selection

func get_selected_page_range() -> Array:
	match %Mode.get_selected_id():
		0: # full
			return range(0, Pages.get_page_count())
		1: # range
			return range(%StartSpinBox.value, %EndSpinBox.value + 1)
		2: # cascade
			return Pages.get_cascading_trail(%CascadeStartSpinbox.value)
		3: # selection
			return get_selected_page_button_indices()
	return []


func _on_clipboard_button_pressed() -> void:
	DisplayServer.clipboard_set(generate_export())
	Pages.editor.notify("Copied export to clipboard!")


func _on_file_dialog_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(generate_export())
	file.close()
	get_parent().hide()
	Pages.editor.notify("Exported to %s!" % path)


func _on_file_button_pressed() -> void:
	emit_signal("fd_opened")
	$FileDialog.popup()
	$FileDialog.call_deferred("grab_focus")

func _on_file_dialog_close_requested() -> void:
	$FileDialog.hide()
	emit_signal("fd_closed")


func update_key_labels(_unused_value:=0):
	var range := get_selected_page_range()
	for child in %PageKeyLabelContainer.get_children():
		child.visible = child.get_index() in range

func update_warnings_u(_unused_value:=0):
	update_warnings()

func update_warnings() -> void:
	await get_tree().process_frame
	%IDWarningLabel.visible = %SyntaxDetailButton.get_selected_id() != 0
	%IncludeFolder.disabled = %SyntaxDetailButton.get_selected_id() == 2
	var is_range_invalid : bool
	if %Mode.get_selected_id() != 1:
		is_range_invalid = false
	else:
		is_range_invalid = %StartSpinBox.value > %EndSpinBox.value
	%InvalidRangeWarningLabel.visible = is_range_invalid
	%ClipboardButton.disabled = is_range_invalid
	%FileButton.disabled = is_range_invalid
	
	for example : RichTextLabel in %Examples.get_children():
		example.visible = example.name.ends_with(str(%SyntaxDetailButton.get_selected_id()))


func get_line_types_to_include() -> Array:
	var line_types_to_include := []
	if %IncludeText.button_pressed:
		line_types_to_include.append(DIISISGlobal.LineType.Text)
	if %IncludeChoice.button_pressed:
		line_types_to_include.append(DIISISGlobal.LineType.Choice)
	if %IncludeInstruction.button_pressed:
		line_types_to_include.append(DIISISGlobal.LineType.Instruction)
	if %IncludeFolder.button_pressed:
		line_types_to_include.append(DIISISGlobal.LineType.Folder)
	return line_types_to_include

func get_preferences() -> Dictionary:
	return {
		"mode" : %Mode.get_selected_id(),
		"line_types_to_include" : get_line_types_to_include(),
		"syntax_detail" : %SyntaxDetailButton.get_selected_id(),
		"range_start" : %StartSpinBox.value,
		"range_end" : %EndSpinBox.value,
		"cascade_start" : %CascadeStartSpinbox.value,
		"selection" : get_selected_page_button_indices(),
	}
