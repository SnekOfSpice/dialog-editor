
@tool
extends Control

var item_list : ItemList
var custom_container : GridContainer

var custom_data := {}

func init():
	find_child("SaveButton").text = str("save")
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
	var changed := not custom_equals()
	find_child("SaveButton").text = str("save", " (*)" if changed else "")

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

func select_function(method:String):
	for idx in item_list.item_count:
		if item_list.get_item_text(idx) == method:
			item_list.select(idx)
			_on_item_list_item_selected(idx)

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

# doesnt really work but whatever
func custom_equals() -> bool:
	for topic in ["defaults", "dropdown_limiters"]:
		var defined : Dictionary = Pages.get(str("custom_method_", topic))
		var custom : Dictionary = custom_data.get(str("custom_method_", topic), {})
	
		if defined.size() != custom.size():
			return false
	
		for custom_key in custom.keys():
			if not custom_key in defined.keys():
				return false
		
		for key in custom.keys():
			var local_data : Dictionary = custom.get(key)
			var pages_data : Dictionary = defined.get(key)
			if local_data.size() != pages_data.size():
			
				return false
			
			for local_key in local_data.keys():
				if not local_key in pages_data.keys():
					return false
			
			for local_key in local_data.keys():
				var local_entry = local_data.get(local_key)
				var pages_entry = pages_data.get(local_key)
				if typeof(local_entry) != typeof(pages_entry):
					return false
				
				if local_entry is Array:
					if local_entry.size() != pages_entry.size():
						return false
					for entry in local_entry:
						if not entry in pages_entry:
							return false
				elif local_entry is Dictionary:
					for entry_key in local_entry.keys():
						if not pages_entry.has(entry_key):
							return false
						if pages_entry.get(entry_key) != local_entry.get(entry_key):
							return false
						
					for entry_key in pages_entry.keys():
						if not local_entry.has(entry_key):
							return false
						if pages_entry.get(entry_key) != local_entry.get(entry_key):
								return false
						
				else:
					# some simple data type
					if local_entry != pages_entry:
						return false
	
	return true
