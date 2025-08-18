@tool
extends Control

signal fd_opened
signal fd_closed

func init():
	%ImportMode.init()
	%ImportMode.select(0)
	%ImportTextLabel.text = ""

func _on_file_dialog_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	set_import_text(file.get_as_text())
	file.close()

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
	%ImportTextLabel.text = text

func _on_clipboard_button_pressed() -> void:
	set_import_text(DisplayServer.clipboard_get())


func _on_button_pressed() -> void:
	var payload := {}
	payload["import_mode"] = %ImportMode.get_selected_id()
	payload["capitalize"] = find_child("CapitalizeCheckBox").button_pressed
	payload["neaten_whitespace"] = find_child("NeatenWhitespaceCheckBox").button_pressed
	payload["fix_punctuation"] = find_child("FixPunctuationCheckBox").button_pressed
	TextToDiisis.ingest_pages(%ImportTextLabel.text, payload)
