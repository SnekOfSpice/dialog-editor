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
	$QuitDialog.popup()

func _on_quit_dialog_canceled() -> void:
	$QuitDialog.hide()

func _on_quit_dialog_confirmed() -> void:
	emit_signal("editor_closed")
	hide()
	queue_free()
