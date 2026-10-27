@tool
extends Control

signal go_to(address:String)
signal request_refresh()

var error_window_offset := Vector2(50, -32)

func set_current_page_count(value):
	%CurrentPageLabel.text = str(value)

func set_page_count(value):
	%PageCountLabel.text = str(value)

func _on_address_bar_text_changed(new_text: String) -> void:
	update(new_text)

func address_bar_has_focus() -> bool:
	return %AddressBar.has_focus()

func update(address:String):
	var address_exists:bool = Pages.does_address_exist(address)
	if address_exists:
		if %AddressBar.visible:
			%ErrorLabelWindow.show()
			%ErrorLabel.text = DiisisEditorUtil.humanize_address(address)
		else:
			%ErrorLabelWindow.hide()
	else:
		%ErrorLabel.text = "Address does not exist."
		%ErrorLabelWindow.show()
	%GoToButton.disabled = not address_exists


func init():
	%ErrorLabelWindow.hide()
	

func _on_address_bar_text_submitted(new_text: String) -> void:
	if not Pages.does_address_exist(new_text):
		push_warning("Address does not exist.")
		return
	emit_signal("go_to", new_text)
	%AddressBar.visible = false
	%CancelGoTo.visible = false

# used by editor shortcut
func toggle_active():
	if %AddressBar.visible:
		_on_cancel_go_to_pressed()
		await get_tree().process_frame
		%ErrorLabelWindow.hide()
	else:
		_on_go_to_button_pressed()
		await get_tree().process_frame
		%AddressBar.grab_focus()
		

func _on_go_to_button_pressed() -> void:
	if %AddressBar.visible:
		go_to.emit(%AddressBar.text)
	else:
		%AddressBar.visible = true
		%AddressBar.text = str(Pages.editor.get_current_page_number())
		%AddressBar.caret_column = 1
		
		update(%AddressBar.text)
		%AddressBar.grab_focus()
		%CancelGoTo.visible = true
		await get_tree().process_frame # we need to wait a frame to ensure the bar has focus
		# so that the editor can give focus back after refreshing
		request_refresh.emit()
		

func address_bar_grab_focus():
	%AddressBar.grab_focus.call_deferred()


func _on_cancel_go_to_pressed() -> void:
	%AddressBar.visible = false
	%CancelGoTo.visible = false
	%GoToButton.disabled = false
	%ErrorLabelWindow.hide()


func _on_address_bar_focus_exited() -> void:
	%ErrorLabelWindow.hide()


func _on_address_bar_focus_entered() -> void:
	%ErrorLabelWindow.show()


func _on_address_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			_on_cancel_go_to_pressed()
