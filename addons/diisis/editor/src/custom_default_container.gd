
@tool
extends Control

var item_list : ItemList
var arg_container : VBoxContainer
var dropdown_container : VBoxContainer

var custom_defaults = {}
var custom_limiters = {}

func init():
	find_child("FuncNameLabel").text = ""
	find_child("FuncNameContainer").visible = false
	arg_container = find_child("ArgContainer")
	dropdown_container = find_child("DropdownContainer")
	clear_values_container()
	find_child("SaveButton").text = str("save")
	item_list = find_child("ItemList")
	find_child("MethodSearch").text = ""
	item_list.clear()
	for method in Pages.get_all_instruction_names():
		item_list.add_item(method)
	custom_defaults = Pages.custom_method_defaults.duplicate(true)
	custom_limiters = Pages.custom_method_dropdown_limiters.duplicate(true)
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
	clear_values_container()
	fill_values_container(item_list.get_item_text(index))
	find_child("FuncNameLabel").text = item_list.get_item_text(index)
	find_child("FuncNameContainer").visible = not find_child("FuncNameLabel").text.is_empty()

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


func _on_go_to_script_button_pressed() -> void:
	DiisisEditorUtil.search_function(item_list.get_item_text(item_list.get_selected_items()[0]))


func _on_save_button_pressed() -> void:
	save_to_local_data()
	Pages.custom_method_defaults = custom_defaults.duplicate(true)
	Pages.custom_method_dropdown_limiters = custom_limiters.duplicate(true)
	find_child("SaveButton").text = "save"


func _on_func_name_label_item_rect_changed() -> void:
	find_child("FuncNameContainer").visible = not find_child("FuncNameLabel").text.is_empty()

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
	if a.size() != b.size():
		return false
	for key in a.keys():
		if not b.keys().has(key):
			return false
	for key in a.keys():
		var value_a = a.get(key)
		var value_b = b.get(key)
		if (value_a != value_b) or (typeof(value_a) != typeof(value_b)):
			if typeof(value_a) == TYPE_ARRAY and typeof(value_b) == TYPE_ARRAY:
				return array_equals(value_a, value_b)
			if typeof(value_a) == TYPE_DICTIONARY and typeof(value_b) == TYPE_DICTIONARY:
				return dictionary_equals(value_a, value_b)
			return false
	return true

func custom_equals() -> bool:
	var defined_defaults : Dictionary = Pages.custom_method_defaults
	var defined_limiters : Dictionary = Pages.custom_method_dropdown_limiters
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
		var item : DefaultArgumentItem = preload("res://addons/diisis/editor/src/default_argument_item.tscn").instantiate()
		arg_container.add_child(item)
		created_things.append(item)
		item.init(method_name, arg_name)
		item.deserialize(custom_defaults.get(method_name, {}).get(arg_name))
		item.custom_minimum_size.y = DropdownTypeSelector.HEIGHT
		item.show_antenna(item.is_string)
		
		if item.is_string:
			var selector : DropdownTypeSelector = preload("res://addons/diisis/editor/src/dropdown_type_selection.tscn").instantiate()
			dropdown_container.add_child(selector)
			selector.init(method_name, arg_name)
			selector.deserialize(custom_limiters.get(method_name, {}).get(arg_name, []))
			created_things.append(selector)
			has_string = true
		else:
			var spacer = dropdown_container.add_spacer(false)
			spacer.custom_minimum_size.y = DropdownTypeSelector.HEIGHT
		
	await get_tree().process_frame
	
	if arg_container.get_child_count() == 0:
		var label = Label.new()
		label.text = "Method doesn't accept arguments"
		arg_container.add_child(label)
	else:
		var label = Label.new()
		label.text = "Default Overrides"
		label.add_theme_color_override("font_color", Color.CORAL)
		arg_container.add_child(label)
		arg_container.move_child(label, 0)
		var limiter_head:Control
		if has_string:
			limiter_head = Label.new()
			limiter_head.text = "Limit String to dropdowns"
			limiter_head.add_theme_color_override("font_color", Color.CORAL)
		else:
			limiter_head = Control.new()
		dropdown_container.add_child(limiter_head)
		dropdown_container.move_child(limiter_head, 0)
	
	# cant remember why but this needs to happen later (here) (not on instantiation)
	for item in created_things:
		if is_instance_valid(item):
			item.updated.connect(_on_values_changed)
			if item is DefaultArgumentItem:
				if item.is_string:
					item.text_updated.connect(validate_dropdown_defaults_from_arg)
			if item is DropdownTypeSelector:
				item.updated_selection.connect(validate_dropdown_defaults_from_dd)

func get_argument_items() -> Array:
	var result := []
	for item in arg_container.get_children():
		if item is DefaultArgumentItem and is_instance_valid(item):
			result.append(item)
	return result
func get_dropdown_items() -> Array:
	var result := []
	for item in dropdown_container.get_children():
		if item is DropdownTypeSelector and is_instance_valid(item):
			result.append(item)
	return result

func get_argument_item(arg:String) -> DefaultArgumentItem:
	for item in get_argument_items():
		if item.arg == arg:
			return item
	return null
func get_dropdown_item(arg:String) -> DropdownTypeSelector:
	for item in get_dropdown_items():
		if item.arg == arg:
			return item
	return null

func validate_dropdown_defaults_from_arg(arg:DefaultArgumentItem):
	validate_dropdown_defaults(arg, get_dropdown_item(arg.arg))
func validate_dropdown_defaults_from_dd(arg:DropdownTypeSelector):
	validate_dropdown_defaults(get_argument_item(arg.arg), arg)

func validate_dropdown_defaults(arg_item:DefaultArgumentItem, dropdown_item:DropdownTypeSelector):
	if arg_item.is_string:
		var has_limiters : bool = not dropdown_item.serialize().is_empty()
		var has_default : bool = arg_item.is_using_custom_default()
		var is_option_invalid : bool = not is_option_in_dropdowns(arg_item.get_value(), dropdown_item.serialize())
		arg_item.set_dropdown_error(
			has_default and has_limiters and is_option_invalid
		)

func is_option_in_dropdowns(query:String, dropdown_titles:Array) -> bool:
	var valid_strings := []
	for dd_name in dropdown_titles:
		valid_strings.append_array(Pages.dropdowns.get(dd_name))
		
	return query in valid_strings

func serialize_values_container():
	var method_defaults := {}
	var method_limiters := {}
	var method_name = ""
	for default in arg_container.get_children():
		var arg_name:String
		var default_index := 0
		if default is DefaultArgumentItem:
			default_index = default.get_index()
			arg_name = default.get_arg_name()
			method_name = default.method
			if default.is_using_custom_default():
				method_defaults[arg_name] = default.get_value()
		var limiters = dropdown_container.get_child(default_index)
		if limiters is DropdownTypeSelector:
			var data : Array = limiters.serialize().duplicate(true)
			#print("saving limiters ", data, " for ", arg_name, " of ", method_name)
			method_limiters[arg_name] = data
	return {
		"custom_method_defaults" : method_defaults,
		"method" : method_name,
		"custom_method_dropdown_limiters" : method_limiters,
	}

func clear_values_container():
	for child in arg_container.get_children():
		child.queue_free()
	for child in dropdown_container.get_children():
		child.queue_free()
	await get_tree().process_frame


func _on_item_list_gui_input(event: InputEvent) -> void:
	# for spaghetti code reasons, echo events go through the list too fast
	# which breaks the serialization in places while the GUI gets refreshed
	# so we just counteract it here
	if event is InputEventKey:
		if event.pressed and event.echo:
			if event.keycode == KEY_UP:
				Pages.editor.notify("sorry")
				item_list.select(wrapi(item_list.get_selected_items()[0] + 1, 0, item_list.item_count - 1))
				#_on_item_list_item_selected(item_list.get_selected_items()[0])
			if event.keycode == KEY_DOWN:
				item_list.select(wrapi(item_list.get_selected_items()[0] - 1, 0, item_list.item_count - 1))
				#_on_item_list_item_selected(item_list.get_selected_items()[0])
