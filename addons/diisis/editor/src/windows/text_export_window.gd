@tool
extends Window


func _on_about_to_popup() -> void:
	$TextExportContainer.init()


func _on_close_requested() -> void:
	Pages.preferences_export = $TextExportContainer.get_preferences()
	hide()


func _on_text_export_container_fd_closed() -> void:
	always_on_top = true


func _on_text_export_container_fd_opened() -> void:
	always_on_top = false
