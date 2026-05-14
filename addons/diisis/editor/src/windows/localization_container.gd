@tool
extends Control


signal fd_opened
signal fd_closed


func init():
	%LocalesLineEdit.text = Pages.preferences_l10n.get("locales", "")


func get_preferences() -> Dictionary:
	return {
		"locales" : %LocalesLineEdit.text
	}


func get_locales_from_line_edit() -> Array:
	return %LocalesLineEdit.text.split(",")


func _on_file_dialog_file_selected(path: String) -> void:
	Pages.save_csv(path, get_locales_from_line_edit())
	var dir_path : String = path.substr(0, path.rfind("/"))
	Pages.editor.notify("Exported to [url=%s]%s[/url]!" % [dir_path, path])


func _on_file_dialog_close_requested() -> void:
	$FileDialog.hide()
	emit_signal("fd_closed")


func _on_export_button_pressed() -> void:
	emit_signal("fd_opened")
	$FileDialog.popup()
	$FileDialog.call_deferred("grab_focus")
