@tool
extends Window

signal validate_saved_instructions()

func _on_about_to_popup() -> void:
	find_child("InstructionEditContainer").fill()


func _on_close_requested() -> void:
	Pages.editor.refresh(false)
	emit_signal("validate_saved_instructions")
	hide()
