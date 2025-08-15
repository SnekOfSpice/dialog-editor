@tool
extends Control

signal fd_opened
signal fd_closed

func init():
	print("TODO PageKeyLabelContainer")
	for child in %SelectionContainer.get_children():
		child.queue_free()
	for i in Pages.get_page_count():
		var button = CheckBox.new()
		button.text = str(i)
		%SelectionContainer.add_child(button)
	%Mode.init()
	%Mode.select(0)
	_on_option_button_embed_option_pressed(%Mode.get_selected_id())
	%StartSpinBox.max_value = Pages.get_page_count()
	%EndSpinBox.max_value = Pages.get_page_count()
	%CascadeStartSpinbox.max_value = Pages.get_page_count()

func _on_option_button_embed_option_pressed(index: int) -> void:
	%ModeInput.find_child("Range").visible = index == 1
	%ModeInput.find_child("Cascade").visible = index == 2
	%ModeInput.find_child("SelectionContainer").visible = index == 3


func generate_export() -> String:
	# doesn't do anything atm
	var modifiers := {
		#"include_instructions" = find_child("IncludeInstructionsCheckBox").button_pressed
	}
	var result := ""
	result += Pages.ingestion_actor_declaration
	result += "\nEND ACTORS\n"
	match %Mode.get_selected_id():
		0: # full
			for i in Pages.get_page_count():
				result += Pages.stringify_page(i, modifiers)
		1: # range
			for i in range(%StartSpinBox.value, %EndSpinBox.value):
				result += Pages.stringify_page(i, modifiers)
		2: # cascade
			for i in Pages.get_cascading_trail(%CascadeStartSpinbox.value):
				result += Pages.stringify_page(i, modifiers)
		3: # selection
			for button : CheckBox in %SelectionContainer.get_children():
				if button.button_pressed:
					result += Pages.stringify_page(int(button.text), modifiers)
	return result

func _on_clipboard_button_pressed() -> void:
	DisplayServer.clipboard_set(generate_export())
	Pages.editor.notify("Copied export to clipboard!")


func _on_file_dialog_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(generate_export())
	file.close()


func _on_file_button_pressed() -> void:
	$FileDialog.popup()
	emit_signal("fd_opened")

func _on_file_dialog_close_requested() -> void:
	$FileDialog.hide()
	emit_signal("fd_closed")
