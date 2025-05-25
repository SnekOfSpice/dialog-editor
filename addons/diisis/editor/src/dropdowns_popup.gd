@tool
extends Window


func _on_about_to_popup() -> void:
	$Container.fill()

func _on_close_requested() -> void:
	hide()
