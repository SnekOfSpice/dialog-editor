@tool
extends Control


var is_editing_default := false
var property_name := ""
var _old_property_name := ""
var values := [null, null]
var _old_values := [null, null]
var data_type :int= Pages.DataTypes._String
#var drop_down_title := ""

func init() -> void:
	find_child("DataTypeButton").init()
	find_child("DropDownButton").init()
	find_child("DropDownValueButton").init()

#func updated_header_default():
#	return {
#		"property_name": property_name,
#		"old_property_name": _old_property_name,
#		"new_default_values": values,
#	}

func update_drop_downs(select_dd:= 0, select_dd_value:= 0):
	find_child("DropDownButton").clear()
	find_child("DropDownValueButton").clear()
	for title in Pages.dropdown_titles:
		find_child("DropDownButton").add_item(title)
	
	if Pages.dropdown_titles.size() == 0:
		find_child("UndefinedDropDownsLabel").visible = true
		return
	
	if Pages.dropdowns.keys().size() == 0:
		find_child("UndefinedDropDownsLabel").visible = true
		return
	
	if Pages.dropdowns.get(Pages.dropdowns.keys()[0]).size() == 0:
		find_child("UndefinedDropDownsLabel").visible = true
		return
	find_child("UndefinedDropDownsLabel").visible = false
	find_child("DropDownButton").select(select_dd)
	
	for title in Pages.dropdowns.get(Pages.dropdown_titles[find_child("DropDownButton").get_selected_id()], []):
		find_child("DropDownValueButton").add_item(title)
	
	find_child("DropDownValueButton").select(select_dd_value)

func set_is_editing_default(value: bool):
	is_editing_default = value
	find_child("NameEditContainer").visible = is_editing_default
	find_child("PropertyNameLabel").visible = not is_editing_default
	find_child("DataTypeButton").visible = is_editing_default
	find_child("DataTypeLabelContainer").visible = not is_editing_default
	find_child("DeleteButton").visible = is_editing_default

func set_property_name(new_name: String):
	property_name = new_name
	find_child("PropertyNameEdit").text = property_name
	find_child("PropertyNameLabel").text = property_name

func set_data_type(new_type: int):
	data_type = new_type
	
	find_child("StringValueEdit").visible = data_type == Pages.DataTypes._String
	find_child("DropDownContainer").visible = data_type == Pages.DataTypes._DropDown
	find_child("BooleanButton").visible = data_type == Pages.DataTypes._Boolean
	
	find_child("DataTypeLabel").text = Pages.DATA_TYPE_STRINGS.get(data_type)
	find_child("DataTypeButton").select(data_type)
	
	if data_type != Pages.DataTypes._DropDown:
		find_child("UndefinedDropDownsLabel").visible = false
	
	if data_type == Pages.DataTypes._Boolean:
		if typeof(values[0]) == TYPE_BOOL:
			find_child("BooleanButton").text = str(values[0])
			find_child("BooleanButton").button_pressed = values[0]
		else:
			find_child("BooleanButton").text = "false"
			find_child("BooleanButton").button_pressed = false
	elif data_type == Pages.DataTypes._DropDown:
		if typeof(values[0]) == TYPE_FLOAT: values[0] = int(values[0])
		if typeof(values[1]) == TYPE_FLOAT: values[1] = int(values[1])
		if typeof(values[0]) != TYPE_INT: values[0] = 0
		if typeof(values[1]) != TYPE_INT: values[1] = 0
		update_drop_downs(values[0], values[1])

func serialize() -> Dictionary:
	var result := {}
	
	result["property_name"] = property_name
	result["values"] = values
	result["data_type"] = data_type
	
	return result

func deserialize(data: Dictionary):
	var killme = []
	for v in data.get("values"):
		killme.append(v)
	
	values = killme
	
	_old_values = values
	
	set_property_name(data.get("property_name", "property"))
	_old_property_name = property_name
	
	set_data_type(data.get("data_type", Pages.DataTypes._String))
	
	match data_type:
		Pages.DataTypes._String:
			find_child("StringValueEdit").text = str(values[0])
		Pages.DataTypes._DropDown:
			var first = int(killme[0]) if killme.front() != null else 0
			var second = int(killme[1]) if killme.back() != null else 0
			update_drop_downs(first, second)
		Pages.DataTypes._Boolean:
			var new_value = values[0]
			if values[0] is float or values[0] is bool or values[0] is int:
				new_value = bool(values[0])
			else:
				new_value = true
			find_child("BooleanButton").button_pressed = bool(new_value)



func _on_drop_down_value_button_item_selected(index: int) -> void:
	values[1] = index
	values = values.duplicate(true)


func _on_line_edit_text_changed(new_text: String) -> void:
	values[0] = new_text


func _on_data_type_button_item_selected(index: int) -> void:
	set_data_type(index)


func stringify_value() -> String:
	if data_type == Pages.DataTypes._DropDown:
		var title = Pages.dropdown_titles[values[0]]
		return str(
			title, "/", Pages.dropdowns.get(title)[values[1]]
		)
		return str(values.front(), "-", values.back())
	return str(values.front())


func _on_property_name_edit_text_changed(new_text: String) -> void:
	property_name = new_text


func _on_delete_button_pressed() -> void:
	queue_free()


func _on_boolean_button_pressed() -> void:
	values[0] = find_child("BooleanButton").button_pressed
	find_child("BooleanButton").text = str(values[0])


func _on_data_type_button_option_pressed(index: int) -> void:
	set_data_type(index)


func _on_drop_down_button_option_pressed(index: int) -> void:
	find_child("DropDownValueButton").clear()
	for value in Pages.dropdowns.get(Pages.dropdown_titles[index]):
		find_child("DropDownValueButton").add_item(value)
	
	values[0] = index
	values = values.duplicate(true)


func _on_drop_down_value_button_option_pressed(index: int) -> void:
	values[1] = index
	values = values.duplicate(true)
