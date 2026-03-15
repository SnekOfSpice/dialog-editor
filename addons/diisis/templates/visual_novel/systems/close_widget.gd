extends MarginContainer


signal close_requested

func _on_button_pressed() -> void:
	close_requested.emit()
