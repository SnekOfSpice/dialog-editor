@tool
extends Window


func _on_about_to_popup() -> void:
	$TextImportContainer.init()


func _on_close_requested() -> void:
	Pages.preferences_import = $TextImportContainer.get_preferences()
	hide()


func _on_text_import_container_fd_closed() -> void:
	always_on_top = true


func _on_text_import_container_fd_opened() -> void:
	always_on_top = false
