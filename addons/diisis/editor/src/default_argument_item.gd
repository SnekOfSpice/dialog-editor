@tool
extends HBoxContainer
class_name DefaultArgumentItem

var method := ""
var arg := ""
var is_string := false

signal update_custom_defaults()

func init(method_name:String, arg_name:String):
	method = method_name
	arg = arg_name
	find_child("ArgNameLabel").text = arg_name
	var base_defaults : Dictionary = Pages.get_custom_method_base_defaultsd(method_name)
	var full_defaults : Dictionary = Pages.get_custom_method_defaults(method_name)
	var types = Pages.get_custom_method_typesd(method_name)
	var type = types.get(arg_name)
	
	var edit = LineEdit.new()
	if type in [TYPE_INT, TYPE_FLOAT]:
		edit = SpinBox.new()
		edit.update_on_text_changed = true
		edit.step = 1 if type == TYPE_INT else 0.01
		edit.min_value = int(-99999)
		edit.max_value = int(999999)
		edit.custom_minimum_size.x = 140
		edit.value = base_defaults.get(arg_name, 0)
		#edit.value_changed.connect(_request_update_defaultsv)
	elif type in [TYPE_BOOL]:
		edit = CheckBox.new()
		edit.button_pressed = base_defaults.get(arg_name, true)
	else:
		edit.text = str(full_defaults.get(arg_name, ""))
		edit.expand_to_text_length = true
		edit.custom_minimum_size.x = 240
		edit.placeholder_text = str(base_defaults.get(arg_name, ""))
		#edit.text_changed.connect(_request_update_defaultsv)
	find_child("Edit").add_child(edit)
	
	is_string = type == TYPE_STRING
	
	#prints("---------- initttttttttt", method_name, arg_name)
	deserialize(Pages.custom_method_defaults.get(method_name, {}).get(arg_name, {}))

func deserialize(data:Dictionary):
	# for some reason this function gets called a second time from seemingly nowhere
	# and it passes all the defaults which obv fucks up the setter functions below
	# so we do this
	# lmfao
	# we pray that no one ever writes a function that has these three exact arguments as names
	if "".join(["arg_name", "use_custom_default", "custom_default"]) != "".join(data.keys()):
		return
	find_child("ArgNameLabel").text = data.get("arg_name", arg)
	set_custom_default(data.get("custom_default"))
	find_child("UseDefaultCheckBox").button_pressed = data.get("use_custom_default", false)
	_on_use_default_check_box_toggled(find_child("UseDefaultCheckBox").button_pressed)
	
func set_custom_default(value):
	if not value:
		return
	var value_holder = find_child("Edit").get_child(0)
	if not value_holder:
		return
	if value_holder is LineEdit:
		value_holder.text = value
	elif value_holder is SpinBox:
		value_holder.value = value
	elif value_holder is Button:
		value_holder.button_pressed = value

func get_custom_default():
	var value_holder = find_child("Edit").get_child(0)
	if value_holder is LineEdit:
		return value_holder.text
	elif value_holder is SpinBox:
		return value_holder.value
	elif value_holder is Button:
		return value_holder.button_pressed
	return null

func serialize() -> Dictionary:
	return {
		"arg_name" : find_child("ArgNameLabel").text,
		"use_custom_default" : find_child("UseDefaultCheckBox").button_pressed,
		"custom_default" : get_custom_default(),
	}

func _on_use_default_check_box_toggled(toggled_on: bool) -> void:
	modulate.a = 1 if toggled_on else 0.6
	var value_holder = find_child("Edit").get_child(0)
	if value_holder is LineEdit:
		value_holder.editable = toggled_on
	elif value_holder is SpinBox:
		value_holder.editable = toggled_on
	elif value_holder is Button:
		value_holder.disabled = not toggled_on
	#emit_signal("update_custom_defaults")

#func _request_update_defaultsv(_value):
	#emit_signal("update_custom_defaults")
#func _request_update_defaults():
	#emit_signal("update_custom_defaults")
