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
		var time = int($Editor.time_since_last_save)
		var time_word = "second" if time == 1 else "seconds"
		text += str("You last saved ", time, " ", time_word, " ago.")
	$QuitDialog.dialog_text = text
	$QuitDialog.popup()

func _on_quit_dialog_canceled() -> void:
	$QuitDialog.hide()

func _on_quit_dialog_confirmed() -> void:
	emit_signal("editor_closed")
	hide()
	queue_free()
