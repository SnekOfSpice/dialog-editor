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
		button.pressed.connect(update_key_labels)
		%SelectionContainer.add_child(button)
	%Mode.init()
	%Mode.select(0)
	_on_option_button_embed_option_pressed(%Mode.get_selected_id())
	%StartSpinBox.max_value = Pages.get_page_count() - 1
	%EndSpinBox.max_value = Pages.get_page_count() - 1
	%CascadeStartSpinbox.max_value = Pages.get_page_count() - 1

func _on_option_button_embed_option_pressed(index: int) -> void:
	%ModeInput.find_child("Range").visible = index == 1
	%ModeInput.find_child("Cascade").visible = index == 2
	%ModeInput.find_child("SelectionContainer").visible = index == 3
	await get_tree().process_frame
	print("fhbghjdf")
	update_key_labels()


func generate_export() -> String:
	# doesn't do anything atm
	var modifiers := {
		#"include_instructions" = find_child("IncludeInstructionsCheckBox").button_pressed,
		"include_ids" = find_child("IncludeIDsCheckBox").button_pressed,
	}
	var result := ""
	result += Pages.ingestion_actor_declaration
	result += "\nEND ACTORS\n"
	
	for i in get_selected_page_range():
		result += Pages.stringify_page(i, modifiers)
	
	return result

func get_selected_page_range() -> Array:
	match %Mode.get_selected_id():
		0: # full
			return range(0, Pages.get_page_count())
		1: # range
			return range(%StartSpinBox.value, %EndSpinBox.value + 1)
		2: # cascade
			return Pages.get_cascading_trail(%CascadeStartSpinbox.value)
		3: # selection
			var selection := []
			for button : CheckBox in %SelectionContainer.get_children():
				if button.button_pressed:
					selection.append(int(button.text))
			return selection
	return []


func _on_clipboard_button_pressed() -> void:
	DisplayServer.clipboard_set(generate_export())
	Pages.editor.notify("Copied export to clipboard!")


func _on_file_dialog_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(generate_export())
	file.close()


func _on_file_button_pressed() -> void:
	emit_signal("fd_opened")
	$FileDialog.popup()
	$FileDialog.call_deferred("grab_focus")

func _on_file_dialog_close_requested() -> void:
	$FileDialog.hide()
	emit_signal("fd_closed")


func update_key_labels(_unused_value:=0):
	var range := get_selected_page_range()
	print(range)
	for child in %PageKeyLabelContainer.get_children():
		child.visible = child.get_index() in range
