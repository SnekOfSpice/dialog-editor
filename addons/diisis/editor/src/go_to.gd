@tool
extends Control

signal go_to(address:String)
signal request_refresh()

var error_window_offset := Vector2(50, -32)

func set_current_page_count(value):
	find_child("CurrentPageLabel").text = str(value)

func set_page_count(value):
	find_child("PageCountLabel").text = str(value)

func _on_address_bar_text_changed(new_text: String) -> void:
	update(new_text)

func address_bar_has_focus() -> bool:
	return find_child("AddressBar").has_focus()

func update(address:String):
	var address_exists:bool = Pages.does_address_exist(address)
	if address_exists:
		if find_child("AddressBar").visible:
			find_child("ErrorLabelWindow").popup()
			find_child("ErrorLabel").text = DiisisEditorUtil.humanize_address(address)
		else:
			find_child("ErrorLabelWindow").hide()
	else:
		find_child("ErrorLabel").text = "Address does not exist."
		find_child("ErrorLabelWindow").popup()
	find_child("GoToButton").disabled = not address_exists


func _on_address_bar_text_submitted(new_text: String) -> void:
	if not Pages.does_address_exist(new_text):
		push_warning("Address does not exist.")
		return
	emit_signal("go_to", new_text)
	find_child("AddressBar").visible = false

# used by editor shortcut
func toggle_active():
	if find_child("AddressBar").visible:
		_on_cancel_go_to_pressed()
		await get_tree().process_frame
		find_child("ErrorLabelWindow").hide()
	else:
		_on_go_to_button_pressed()
		await get_tree().process_frame
		find_child("AddressBar").grab_focus()
		

func _on_go_to_button_pressed() -> void:
	if find_child("AddressBar").visible:
		emit_signal("go_to", find_child("AddressBar").text)
	else:
		find_child("AddressBar").visible = true
		find_child("AddressBar").text = str(Pages.editor.get_current_page_number())
		find_child("AddressBar").caret_column = 1
		
		update(find_child("AddressBar").text)
		find_child("AddressBar").grab_focus()
		find_child("CancelGoTo").visible = true
		emit_signal("request_refresh")
		

func _address_bar_grab_focus():
	find_child("AddressBar").grab_focus()

func _on_cancel_go_to_pressed() -> void:
	find_child("AddressBar").visible = false
	find_child("CancelGoTo").visible = false
	find_child("GoToButton").disabled = false
	find_child("ErrorLabelWindow").hide()


func _on_address_bar_focus_exited() -> void:
	find_child("ErrorLabelWindow").hide()


func _on_address_bar_focus_entered() -> void:
	find_child("ErrorLabelWindow").popup()


func _on_error_label_window_about_to_popup() -> void:
	find_child("ErrorLabelWindow").position = global_position + error_window_offset
