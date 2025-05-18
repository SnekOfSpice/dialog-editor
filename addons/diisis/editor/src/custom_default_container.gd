
@tool
extends Control

var item_list : ItemList
var values_container : VBoxContainer

var custom_defaults = {}
var custom_limiters = {}

func init():
	find_child("FuncNameLabel").text = ""
	find_child("FuncNameLabel").visible = false
	values_container = find_child("ValuesContainer")
	clear_values_container()
	find_child("SaveButton").text = str("save")
	item_list = find_child("ItemList")
	find_child("MethodSearch").text = ""
	item_list.clear()
	for method in Pages.get_all_instruction_names():
		item_list.add_item(method)
	print("xxxxxxxxxx")
	print(Pages.custom_method_defaults)
	print("xxxxxxxxxx")
	print(Pages.custom_method_dropdown_limiters)
	custom_defaults = Pages.custom_method_defaults.duplicate(true)
	custom_limiters = Pages.custom_method_dropdown_limiters.duplicate(true)
	print("DEFAULTS ---------\n",custom_defaults, "\nLIMITERS_______\n", custom_limiters)
	if item_list.item_count > 0:
		item_list.select(0)
	find_child("Fuck").text = str("DEFAULTS\n", custom_defaults, "\n\nLIMITERS\n", custom_limiters)

func save_to_local_data():
	var data : Dictionary = serialize_values_container()
	var method_name : String = data.get("method")
	if method_name.is_empty():
		return
	var default_data : Dictionary = data.get("custom_method_defaults", {})
	if not default_data.is_empty() and not method_name.is_empty():
		custom_defaults[method_name] = default_data
	else:
		custom_defaults.erase(method_name)
	var limiter_data : Dictionary = data.get("custom_method_dropdown_limiters", {})
	if not limiter_data.is_empty() and not method_name.is_empty():
		custom_limiters[method_name] = limiter_data
	else:
		limiter_data.erase(method_name)
	var changed := not custom_equals()
	find_child("SaveButton").text = str("save", " (*)" if changed else "")
	find_child("Fuck").text = str("DEFAULTS\n", custom_defaults, "\n\nLIMITERS\n", custom_limiters)

func _on_item_list_item_selected(index: int) -> void:
	save_to_local_data()
	#await get_tree().process_frame
	clear_values_container()
	#await get_tree().process_frame
	fill_values_container(item_list.get_item_text(index))
	#await get_tree().process_frame
	find_child("FuncNameLabel").text = item_list.get_item_text(index)
	find_child("FuncNameLabel").visible = not find_child("FuncNameLabel").text.is_empty()

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
	Pages.custom_method_defaults = custom_defaults.duplicate(true)
	Pages.custom_method_dropdown_limiters = custom_limiters.duplicate(true)
	find_child("SaveButton").text = "save"


func _on_func_name_label_item_rect_changed() -> void:
	find_child("FuncNameLabel").visible = not find_child("FuncNameLabel").text.is_empty()

func array_equals(a:Array, b:Array) -> bool:
	a.sort()
	b.sort()
	if a.size() != b.size():
		return false
	for i in a.size():
		var value_a = a[i]
		var value_b = b[i]
		if (value_a != value_b) or (typeof(value_a) != typeof(value_b)):
			if typeof(value_a) == TYPE_ARRAY and typeof(value_b) == TYPE_ARRAY:
				return array_equals(value_a, value_b)
			if typeof(value_a) == TYPE_DICTIONARY and typeof(value_b) == TYPE_DICTIONARY:
				return dictionary_equals(value_a, value_b)
			return false
	return true

func dictionary_equals(a:Dictionary, b:Dictionary) -> bool:
	#print("a-------------", a, "\nb------------", b)
	if a.size() != b.size():
		#print("AAAA\n", a.keys(), "\n", b.keys(), "-------------")
		return false
	for key in a.keys():
		if not b.keys().has(key):
			prints("BBBB", key)
			return false
	for key in a.keys():
		var value_a = a.get(key)
		var value_b = b.get(key)
		if (value_a != value_b) or (typeof(value_a) != typeof(value_b)):
			if typeof(value_a) == TYPE_ARRAY and typeof(value_b) == TYPE_ARRAY:
				print("CCC", array_equals(value_a, value_b))
				return array_equals(value_a, value_b)
			if typeof(value_a) == TYPE_DICTIONARY and typeof(value_b) == TYPE_DICTIONARY:
				return dictionary_equals(value_a, value_b)
			prints("DDDD", value_a, "|||", value_b, key)
			return false
	return true

func custom_equals() -> bool:
	var defined_defaults : Dictionary = Pages.custom_method_defaults
	var defined_limiters : Dictionary = Pages.custom_method_dropdown_limiters
	#print(
		#"defined_defaults ", defined_defaults, "\n",
		#"custom_defaults  ", custom_defaults, "\n",
		#"defined_limiters ", defined_limiters, "\n",
		#"custom_limiters  ", custom_limiters, "\n",
	#)
	return dictionary_equals(defined_defaults, custom_defaults) and dictionary_equals(defined_limiters, custom_limiters)


func _on_values_changed():
	save_to_local_data()

# defaults and limiters are duplicated to use the local data from the window
func fill_values_container(method_name:String):#, defaults:Dictionary, limiters:Dictionary):
	clear_values_container()
	#await get_tree().process_frame
	var created_things := []
	var has_string := false
	for arg_name in Pages.get_custom_method_arg_names(method_name):
		var row_container := HBoxContainer.new()
		var item : DefaultArgumentItem = preload("res://addons/diisis/editor/src/default_argument_item.tscn").instantiate()
		row_container.add_child(item)
		created_things.append(item)
		item.init(method_name, arg_name)
		item.deserialize(custom_defaults.get(method_name, {}).get(arg_name))
		
		if item.is_string:
			var selector : DropdownTypeSelector = preload("res://addons/diisis/editor/src/dropdown_type_selection.tscn").instantiate()
			row_container.add_child(selector)
			selector.init(method_name, arg_name)
			selector.deserialize(custom_limiters.get(method_name, {}).get(arg_name, []))
			created_things.append(selector)
			has_string = true
		
		values_container.add_child(row_container)
	
	#await get_tree().process_frame
	
	if get_child_count() == 0:
		var label = Label.new()
		label.text = "Method doesn't accept arguments"
		values_container.add_child(label)
	else:
		var label = Label.new()
		label.text = "Default Overrides"
		label.add_theme_color_override("font_color", Color.CORAL)
		values_container.add_child(label)
		values_container.move_child(label, 0)
		var limiter_head:Control
		if has_string:
			limiter_head = Label.new()
			limiter_head.text = "Limit String to dropdowns"
			limiter_head.add_theme_color_override("font_color", Color.CORAL)
		else:
			limiter_head = Control.new()
		values_container.add_child(limiter_head)
		values_container.move_child(limiter_head, 1)
	
	for item in created_things:
		item.updated.connect(_on_values_changed)

func serialize_values_container():
	var method_defaults := {}
	var method_limiters := {}
	var method_name = ""
	for row in values_container.get_children():
		if row is HBoxContainer:
			var arg_name:String
			var defaults = row.get_child(0)
			if defaults is DefaultArgumentItem:
				arg_name = defaults.get_arg_name()
				method_name = defaults.method
				if defaults.is_using_custom_default():
					method_defaults[arg_name] = defaults.get_value()
				print("found arg name ", arg_name)
			if row.get_child_count() <= 1:
				#method_limiters[arg_name] = []
				continue
			var limiters = row.get_child(1)
			if limiters is DropdownTypeSelector:
				var data : Array = limiters.serialize().duplicate(true)
				print("saving limiters ", data, " for ", arg_name, " of ", method_name)
				method_limiters[arg_name] = data
	return {
		"custom_method_defaults" : method_defaults,
		"method" : method_name,
		"custom_method_dropdown_limiters" : method_limiters,
	}

func clear_values_container():
	for child in values_container.get_children():
		child.queue_free()
	await get_tree().process_frame


func _on_item_list_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.echo:
			if event.keycode == KEY_UP:
				Pages.editor.notify("sorry")
				item_list.select(wrapi(item_list.get_selected_items()[0] + 1, 0, item_list.item_count - 1))
				#_on_item_list_item_selected(item_list.get_selected_items()[0])
			if event.keycode == KEY_DOWN:
				item_list.select(wrapi(item_list.get_selected_items()[0] - 1, 0, item_list.item_count - 1))
				#_on_item_list_item_selected(item_list.get_selected_items()[0])
