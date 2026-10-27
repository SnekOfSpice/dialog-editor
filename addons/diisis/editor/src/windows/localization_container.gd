@tool
extends Control


signal fd_opened()
signal fd_closed()


func init():
	_apply_preferences()
	
	%CurrentFallbackLocaleLabel.text = "The current fallback locale is: [color=edc13eff]%s[/color]" % ProjectSettings.get_setting("internationalization/locale/fallback")


func _apply_preferences():
	var preferences : Dictionary = Pages.preferences_l10n
	%LocalesLineEdit.text = preferences.get("locales", "")
	%SeparateFilesCheckBox.set_pressed_no_signal(preferences.get("separate_files", %SeparateFilesCheckBox.button_pressed))
	%SplitDialinesCheckBox.set_pressed_no_signal(preferences.get("split_dialines", %SplitDialinesCheckBox.button_pressed))

func get_preferences() -> Dictionary:
	return {
		"locales" : %LocalesLineEdit.text,
		"separate_files" : %SeparateFilesCheckBox.button_pressed,
		"split_dialines" : %SplitDialinesCheckBox.button_pressed,
	}


func get_locales_from_line_edit() -> Array:
	return %LocalesLineEdit.text.split(",")


func _on_file_dialog_file_selected(path: String) -> void:
	Pages.save_csv(
		path,
		get_locales_from_line_edit(),
		%SeparateFilesCheckBox.button_pressed,
		%SplitDialinesCheckBox.button_pressed
	)
	var dir_path : String = path.substr(0, path.rfind("/"))
	Pages.editor.notify("Exported to [url=%s]%s[/url]!" % [dir_path, path], 10)


func _on_file_dialog_close_requested() -> void:
	$FileDialog.hide()
	emit_signal("fd_closed")


func _on_export_button_pressed() -> void:
	emit_signal("fd_opened")
	$FileDialog.popup()
	$FileDialog.call_deferred("grab_focus")
