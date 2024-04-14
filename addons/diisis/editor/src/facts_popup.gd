@tool
extends Window

func _on_about_to_popup() -> void:
	$FactsPopupContent.fill()

func _on_close_requested() -> void:
	hide()
