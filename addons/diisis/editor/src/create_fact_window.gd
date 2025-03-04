@tool
extends Window

signal fact_created

func _on_about_to_popup() -> void:
	$Control.init()

func _on_close_requested() -> void:
	hide()

func _on_control_close() -> void:
	_on_close_requested()
	emit_signal("fact_created")
