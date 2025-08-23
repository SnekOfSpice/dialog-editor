@tool
extends Control

signal fd_opened
signal fd_closed

func init():
	var is_data_empty : bool = Pages.editor.get_save_path().is_empty()#Pages.get_page_data(0, true).get("lines", []).is_empty()
	%ImportMode.init()
	%BlankOverrideNotice.visible = is_data_empty
	if is_data_empty:
		%ImportMode.select(1)
	else:
		%ImportMode.select(Pages.preferences_import.get("mode", 0))
	_on_import_mode_option_pressed(%ImportMode.get_selected_id())
	set_import_text("")
	%ImportAgainWarning.visible = false
	%FileButton.grab_focus()
	%ImportMode.set_item_disabled(0, is_data_empty)
	$FileDialog.clear_filters()
	$FileDialog.add_filter("*.txt", "Raw text")
	$FileDialog.add_filter("*.dtf", "DIISIS text file") # . Can be opened in plain text but denotes syntactic layout that permits re-import into DIISIS.

func _on_file_dialog_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	set_import_text(file.get_as_text())
	file.close()
	
	var modified_time := FileAccess.get_modified_time(path)
	if Pages.import_modified_times_by_path.has(path):
		%ImportAgainWarning.visible = Pages.import_modified_times_by_path.get(path) == modified_time
		#%ImportAgainWarning.text = "[color=#F7D468]A file from this path has already been imported once at %s.[/color]" % Time.get_date_string_from_unix_time(modified_time)
	else:
		%ImportAgainWarning.visible = false
	Pages.import_modified_times_by_path[path] = modified_time
	
	%ImportButton.grab_focus()

func _on_file_button_pressed() -> void:
	emit_signal("fd_opened")
	$FileDialog.popup()
	$FileDialog.call_deferred("grab_focus")

func _on_file_dialog_close_requested() -> void:
	$FileDialog.hide()
	emit_signal("fd_closed")

func _on_import_mode_option_pressed(index: int) -> void:
	match index:
		0: # update
			%ImportModeNotice0.visible = true
			%ImportModeNotice1.visible = false
		1: # override
			%ImportModeNotice0.visible = false
			%ImportModeNotice1.visible = true
	

func set_import_text(text:String):
	%ImportButton.disabled = text.is_empty()
	%ImportTextLabel.text = text

func _on_clipboard_button_pressed() -> void:
	set_import_text(DisplayServer.clipboard_get())


func _on_button_pressed() -> void:
	Pages.editor.set_importing_cover_visible(true)
	await get_tree().process_frame
	var payload := {}
	payload["import_mode"] = %ImportMode.get_selected_id()
	payload["capitalize"] = find_child("CapitalizeCheckBox").button_pressed
	payload["neaten_whitespace"] = find_child("NeatenWhitespaceCheckBox").button_pressed
	payload["fix_punctuation"] = find_child("FixPunctuationCheckBox").button_pressed
	TextToDiisis.ingest_pages(%ImportTextLabel.text, payload)
	
	#await get_tree().process_frame
	#
	#Pages.editor.step_through_pages()


func get_preferences() -> Dictionary:
	return {
		"mode" : %ImportMode.get_selected_id(),
	}
