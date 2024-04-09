@tool
extends Control

signal go_to(address:String)



func set_current_page_count(value):
	find_child("CurrentPageLabel").text = str(value)

func set_page_count(value):
	find_child("PageCountLabel").text = str(value)

func _on_address_bar_text_changed(new_text: String) -> void:
	var address_exists:bool=Pages.does_address_exist($GridContainer/AddressBar.text)
	
	if address_exists:
		var address_string := ""
		# TODO: [page name or number if no name] / line type / choice text (concat)
		find_child("ErrorLabel").text = address_string
	else:
		find_child("ErrorLabel").text = str("Address does not exist.")
	$GridContainer/GoToButton.disabled = not address_exists


func _on_address_bar_text_submitted(new_text: String) -> void:
	if not Pages.does_address_exist($GridContainer/AddressBar.text):
		push_warning("Address does not exist.")
		return
	emit_signal("go_to", $GridContainer/AddressBar.text)
