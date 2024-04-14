@tool
extends Control

var addresses_by_index := {}
var details_by_address := {}

func display_results(search:String):
	var result = Pages.search_string(search)
	var item_list:ItemList = $VBoxContainer/HBoxContainer2/ItemList
	item_list.clear()
	var i = 0
	# this is duplicated for relevancy
	var keys := ["text", "choices", "facts"]
	
	for k : String in keys:
		if result.get(k).is_empty():
			continue
		i += 1
		item_list.add_item(str("-- ", k.capitalize(), " --"), null, false)
		for address in result.get(k):
			addresses_by_index[i] = address
			details_by_address[address] = result.get(k).get(address)
			item_list.add_item(address)
	

func _on_search_button_pressed() -> void:
	display_results($VBoxContainer/HBoxContainer/QueryTextEdit.text)

func _on_item_list_item_selected(index: int) -> void:
	var address = find_child("ItemList").get_item_text(index)
	$VBoxContainer/HBoxContainer2/ResultLabel.text = str(details_by_address.get(address))
