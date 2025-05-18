@tool
extends HBoxContainer
class_name DefaultArgumentItem

var method := ""
var arg := ""
var is_string := false

signal updated()

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
		edit.value_changed.connect(_emit_updated1)
	elif type in [TYPE_BOOL]:
		edit = CheckBox.new()
		edit.button_pressed = base_defaults.get(arg_name, true)
		edit.pressed.connect(emit_signal.bind("updated"))
	else:
		edit.text = str(full_defaults.get(arg_name, ""))
		edit.expand_to_text_length = true
		edit.custom_minimum_size.x = 240
		edit.placeholder_text = str(base_defaults.get(arg_name, ""))
		edit.text_changed.connect(_emit_updated1)
		edit.text_submitted.connect(_emit_updated1)
	find_child("Edit").add_child(edit)
	
	is_string = type == TYPE_STRING
	
	#prints("---------- initttttttttt", method_name, arg_name)
	var override = Pages.custom_method_defaults.get(method_name, {}).get(arg_name)
	set_use_custom_default(override != null)

func deserialize(value):
	#print("got ", value)
	set_custom_default(value)
	set_use_custom_default(value != null)

func _emit_updated1(_a):
	emit_signal("updated")

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

func get_value():
	var value_holder = find_child("Edit").get_child(0)
	if value_holder is LineEdit:
		return value_holder.text
	elif value_holder is SpinBox:
		return value_holder.value
	elif value_holder is Button:
		return value_holder.button_pressed
	return null

func is_using_custom_default() -> bool:
	return not find_child("AddButton").visible

func set_use_custom_default(value:bool):
	find_child("AddButton").visible = not value
	find_child("ValueContainer").visible = value
	emit_signal("updated")

func get_arg_name() -> String:
	return find_child("ArgNameLabel").text

func _on_use_default_check_box_toggled(toggled_on: bool) -> void:
	modulate.a = 1 if toggled_on else 0.6
	var value_holder = find_child("Edit").get_child(0)
	if value_holder is LineEdit:
		value_holder.editable = toggled_on
	elif value_holder is SpinBox:
		value_holder.editable = toggled_on
	elif value_holder is Button:
		value_holder.disabled = not toggled_on

func show_antenna(value:bool):
	find_child("HSeparator").visible = value
