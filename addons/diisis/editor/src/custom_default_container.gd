
@tool
extends Control

var item_list : ItemList
var custom_container : GridContainer

var custom_data := {}

func init():
	item_list = find_child("ItemList")
	find_child("MethodSearch").text = ""
	item_list.clear()
	for method in Pages.get_all_instruction_names():
		item_list.add_item(method)
	custom_data = {
		"custom_method_defaults" : Pages.custom_method_defaults.duplicate(true),
		"custom_method_dropdown_limiters" : Pages.custom_method_dropdown_limiters.duplicate(true)
	}
	if item_list.item_count > 0:
		item_list.select(0)

func save_to_local_data():
	var data : Dictionary = find_child("DefaultArgumentItemContainer").serialize()
	var method_name = data.get("method")
	custom_data["custom_method_defaults"][method_name] = data.get("custom_method_defaults", {})
	custom_data["custom_method_dropdown_limiters"][method_name] = data.get("custom_method_dropdown_limiters", {})

func _on_item_list_item_selected(index: int) -> void:
	save_to_local_data()
	find_child("DefaultArgumentItemContainer").clear()
	find_child("DefaultArgumentItemContainer").init(
		item_list.get_item_text(index),
		custom_data.get("custom_method_defaults", {}),
		custom_data.get("custom_method_dropdown_limiters", {}),
		)
	await get_tree().process_frame
	find_child("FuncNameLabel").text = item_list.get_item_text(index)
	find_child("FuncNameLabel").visible = not find_child("FuncNameLabel").text.is_empty()
	
func serialize():
	return custom_data


func _on_method_search_text_changed(new_text: String) -> void:
	item_list.clear()
	for method : String in Pages.get_all_instruction_names():
		if new_text in method or new_text.is_empty():
			item_list.add_item(method)


func _on_open_script_button_pressed() -> void:
	DiisisEditorUtil.search_function(item_list.get_item_text(item_list.get_selected_items()[0]))


func _on_save_button_pressed() -> void:
	save_to_local_data()
	Pages.custom_method_defaults = custom_data.get("custom_method_defaults", {}).duplicate(true)
	Pages.custom_method_dropdown_limiters = custom_data.get("custom_method_dropdown_limiters", {}).duplicate(true)


func _on_func_name_label_item_rect_changed() -> void:
	find_child("FuncNameLabel").visible = not find_child("FuncNameLabel").text.is_empty()
