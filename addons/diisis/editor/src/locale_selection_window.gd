@tool
extends Window


func _on_about_to_popup() -> void:
	$LocaleSelectionContainer.fill()


func _on_close_requested() -> void:
	hide()
