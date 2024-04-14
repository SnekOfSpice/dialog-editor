@tool
extends Control

signal go_to(address:String)
signal request_refresh()

func set_current_page_count(value):
	find_child("CurrentPageLabel").text = str(value)

func set_page_count(value):
	find_child("PageCountLabel").text = str(value)

func _on_address_bar_text_changed(new_text: String) -> void:
	update(new_text)

func update(address:String):
	var address_exists:bool = Pages.does_address_exist(address)
	
	if address_exists:
		if $GridContainer/AddressBar.visible:
			var address_string := ""
			var parts := DiisisEditorUtil.get_split_address(address)
			address_string = str(Pages.get_page_key(parts[0]))
			if parts.size() > 1:
				address_string += str(" / ", Pages.get_line_type_str(parts[0], parts[1]))
			if parts.size() > 2:
				address_string += str(" / ", Pages.get_choice_text_shortened(parts[0], parts[1], parts[2]))
			# TODO: [page name or number if no name] / line type / choice text (concat)
			find_child("ErrorLabel").text = address_string
		else:
			find_child("ErrorLabel").text = "Go To"
	else:
		find_child("ErrorLabel").text = "Address does not exist."
	find_child("GoToButton").disabled = not address_exists


func _on_address_bar_text_submitted(new_text: String) -> void:
	if not Pages.does_address_exist(new_text):
		push_warning("Address does not exist.")
		return
	emit_signal("go_to", new_text)
	$GridContainer/AddressBar.visible = false


func _on_go_to_button_pressed() -> void:
	if $GridContainer/AddressBar.visible:
		emit_signal("go_to", $GridContainer/AddressBar.text)
	else:
		$GridContainer/AddressBar.visible = true
		update($GridContainer/AddressBar.text)
		find_child("CancelGoTo").visible = true
		emit_signal("request_refresh")


func _on_cancel_go_to_pressed() -> void:
	find_child("AddressBar").visible = false
	find_child("CancelGoTo").visible = false
	find_child("GoToButton").disabled = false
	find_child("ErrorLabel").text = str("Go To")
