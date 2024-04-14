@tool
extends Control

var addresses_by_index := {}
var details_by_address := {}

func display_results(search:String):
	var result = Pages.search_string(search)
	var item_list:ItemList = find_child("ItemList")
	item_list.clear()
	var i = 0
	# this is duplicated for relevancy
	var keys := ["text", "choices", "facts"]
	find_child("GoToButton").visible = false
	
	for k : String in keys:
		if result.get(k).is_empty():
			continue
		find_child("GoToButton").visible = true
		i += 1
		item_list.add_item(str("-- ", k.capitalize(), " --"), null, false)
		for address in result.get(k):
			addresses_by_index[i] = address
			details_by_address[address] = result.get(k).get(address)
			item_list.add_item(address)
	
	find_child("NoResultsLabel").visible = not find_child("GoToButton").visible
	

func _on_search_button_pressed() -> void:
	display_results(find_child("QueryTextEdit").text)

func _on_item_list_item_selected(index: int) -> void:
	var address = find_child("ItemList").get_item_text(index)
	find_child("ResultLabel").text = str(details_by_address.get(address))


func _on_go_to_button_pressed() -> void:
	var address = find_child("ItemList").get_item_text(find_child("ItemList").get_selected_items()[0])
	Pages.editor.request_go_to_address(address)
