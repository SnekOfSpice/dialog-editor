extends Control


#var _default
var property_name := ""

var _old_property_name := ""
var _old_value
var editable_name := false

var value

var data_type := Pages.DataTypes._String

signal property_changed(property_name, value)
signal erase_property(property_name)
signal property_default_changed(property_name, old_property_name, new_default_value)

func serialize() -> Dictionary:
	var d = {}
	
	d["property_name"] = property_name
	d["value"] = value
	d["data_type"] = data_type
	
	return d

func deserialize(data: Dictionary):
	property_name = data.get("property_name")
	var defaults = Pages.get_defaults(property_name)
	#_default = defaults.get("value")
	value = data.get("value")
	if Pages.head_data_types.get(property_name):
		data_type = Pages.head_data_types.get(property_name)
	else:
		data_type = Pages.DataTypes._String
	
	update()
	
	if editable_name:
		_old_property_name = property_name
		_old_value = value
		find_child("OldDefaults").text = str("changing from: ", _old_property_name, "|", _old_value)
	
	
	find_child("DefaultChangingContainer").visible = editable_name
	find_child("HSeparator").visible = editable_name
	find_child("EditableNameContainer").visible = editable_name
	find_child("PropertyName").visible = not editable_name
	find_child("Controls").visible = not editable_name

func update():
	find_child("PropertyName").text = property_name
	find_child("DataTypeName").text = str("(^ ", Pages.DATA_TYPE_STRINGS.get(data_type), " ^)")
	find_child("PropertyNameEdit").text = property_name
	
	find_child("ValueLineEdit").text = str(value)
	#find_child("ValueLineEdit").placeholder_text = str(_default)

func _on_save_pressed() -> void:
	emit_signal("property_changed", property_name, find_child("ValueLineEdit").text)
	value = find_child("ValueLineEdit").text
	update()


func _on_save_new_defaults_button_pressed() -> void:
	save_new_defaults()
	
func save_new_defaults():
	emit_signal("property_default_changed", property_name, _old_property_name, find_child("ValueLineEdit").text)
	value = find_child("ValueLineEdit").text
	update()


func _on_delete_button_pressed() -> void:
	emit_signal("erase_property", property_name)
	queue_free()
