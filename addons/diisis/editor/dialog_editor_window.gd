@tool
extends Window

signal editor_closed()

func _on_about_to_popup() -> void:
	find_child("Editor").init()
	get_viewport().get_camera_2d().offset = (size*0.5)

func _on_size_changed() -> void:
	if not get_viewport().get_camera_2d():
		return
	get_viewport().get_camera_2d().offset = (size*0.5)

func _on_close_requested() -> void:
	if $Editor.undo_redo.get_history_count() == 0:
		_on_quit_dialog_confirmed()
	var text := ""
	text += "Do you want to close DIISIS?\n"
	if $Editor.active_dir.is_empty() or not $Editor.has_saved:
		text += str("You have not saved since opening.")
	else:
		var seconds_since_last_save = int($Editor.time_since_last_save)
		var minutes_since_last_save := 0
		var hours_since_last_save := 0
		var last_system_save = $Editor.last_system_save
		
		var second_word:String
		var minute_word:String
		var hour_word:String
		
		
		if seconds_since_last_save >= 60:
			minutes_since_last_save = floor(seconds_since_last_save / 60.0)
			seconds_since_last_save -= 60 * minutes_since_last_save
			if minutes_since_last_save >= 60:
				hours_since_last_save = floor(minutes_since_last_save / 60.0)
				minutes_since_last_save -= 60 * hours_since_last_save
		
		second_word = "second" if seconds_since_last_save == 1 else "seconds"
		minute_word = "minute" if minutes_since_last_save == 1 else "minutes"
		hour_word = "hour" if hours_since_last_save == 1 else "hours"
		
		var system_str := str(last_system_save.get("hour"), ":", last_system_save.get("minute"), ":", last_system_save.get("second"))
		text += str("You last saved at ", system_str, ".\n")
		
		var ago_string:=""
		if hours_since_last_save > 0:
			ago_string += str(hours_since_last_save, " ", hour_word, ", ")
		if minutes_since_last_save > 0:
			ago_string += str(minutes_since_last_save, " ", minute_word, ", ")
		
		ago_string += str(seconds_since_last_save, " ", second_word)
		text += str("(", ago_string, " ago.)")
	$QuitDialog.dialog_text = text
	$QuitDialog.popup()

func _on_quit_dialog_canceled() -> void:
	$QuitDialog.hide()

func _on_quit_dialog_confirmed() -> void:
	emit_signal("editor_closed")
	hide()
	queue_free()
