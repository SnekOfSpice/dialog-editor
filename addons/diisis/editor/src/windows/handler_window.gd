@tool
extends Window


func _on_about_to_popup() -> void:
	$HandlerSetupContainer.init()

func select_function(method:String):
	$HandlerSetupContainer.select_function(method)

func _on_close_requested() -> void:
	var unsaved_tabs : Array = $HandlerSetupContainer.get_unsaved_change_tabs()
	if unsaved_tabs.size() > 0:
		always_on_top = false
		var popup = Pages.editor.popup_confirm_dialogue(
			str(
				"You have unsaved changes in ",
				", ".join(unsaved_tabs), "\nAre you sure you want to close the window and discard them?"
			),
			"Discard changes?",
			hide)
		popup.ok_button_text = "Discard Changes"
		popup.cancel_button_text = "Stay"
		return
	_on_close_dialog_confirmed()

func _on_close_dialog_canceled() -> void:
	$CloseDialog.hide()


func _on_close_dialog_confirmed() -> void:
	always_on_top = true
	hide()
