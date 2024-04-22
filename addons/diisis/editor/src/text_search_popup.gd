@tool
extends Window

func _on_about_to_popup() -> void:
	$TextSearchContainer.init()

func _on_close_requested() -> void:
	hide()
