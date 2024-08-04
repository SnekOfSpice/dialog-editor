@tool
extends Window


signal confirmed()
signal request_save()

func set_text(text:String):
	find_child("RichTextLabel").text = str("[center]", text)

func _on_cancel_button_pressed() -> void:
	hide()

func _on_quit_button_pressed() -> void:
	emit_signal("confirmed")

func _on_about_to_popup() -> void:
	find_child("QuitButton").grab_focus()
	# sometimes the dialoge will stretch reeeaaaaaly tall and I have no idea why so this brings it back
	var actual_size = size
	await get_tree().process_frame
	size = actual_size


func _on_save_button_pressed() -> void:
	emit_signal("request_save")
	emit_signal("confirmed")
