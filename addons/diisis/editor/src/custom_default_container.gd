@tool
extends Control

var item_list : ItemList
var custom_container : GridContainer

func init():
	item_list = find_child("ItemList")
	item_list.clear()
	for method in Pages.get_custom_methods():
		item_list.add_item(method)

func _on_item_list_item_selected(index: int) -> void:
	find_child("DefaultArgumentItemContainer").clear()
	find_child("DefaultArgumentItemContainer").init(item_list.get_item_text(index))
	
func serialize():
	pass
	# TODO


func _on_method_search_text_changed(new_text: String) -> void:
	item_list.clear()
	for method : String in Pages.get_custom_methods():
		if new_text in method or new_text.is_empty():
			item_list.add_item(method)
