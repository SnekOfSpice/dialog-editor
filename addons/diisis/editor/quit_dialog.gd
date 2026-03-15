@tool
extends Window
class_name DiisisQuitDialog


signal confirmed(save:bool)

func set_text(text:String):
	%RichTextLabel.text = str("[center]", text, "[/center]")

func _on_cancel_button_pressed() -> void:
	hide()

func _on_quit_button_pressed() -> void:
	confirmed.emit(false)
	hide()

func _on_about_to_popup() -> void:
	#%QuitButton.visible = not DiisisEditorUtil.embedded
	#if %QuitButton.visible:
	%QuitButton.grab_focus()
	#else:
	#%CancelButton.grab_focus()
	# sometimes the dialoge will stretch reeeaaaaaly tall and I have no idea why so this brings it back
	var actual_size = size
	await get_tree().process_frame
	size = actual_size


func _on_save_button_pressed() -> void:
	confirmed.emit(true)
	hide()


func _on_visibility_changed() -> void:
	if not visible:
		queue_free()
