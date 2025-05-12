@tool
extends HBoxContainer


func init(method_name:String, arg_name:String):
	find_child("ArgNameLabel").text = arg_name
	var base_defaults : Dictionary = Pages.get_custom_method_base_defaultsd(method_name)
	var full_defaults : Dictionary = Pages.get_custom_method_defaults(method_name)
	var types = Pages.get_custom_method_typesd(method_name)
	var type = types.get(arg_name)
	
	var edit = LineEdit.new()
	if type in [TYPE_INT, TYPE_FLOAT]:
		edit = SpinBox.new()
		edit.step = 1 if type == TYPE_INT else 0.01
		edit.min_value = int(-INF)
		edit.max_value = int(INF)
		edit.custom_minimum_size.x = 140
		edit.value = base_defaults.get(arg_name, 0)
	elif type in [TYPE_BOOL]:
		edit = CheckBox.new()
		edit.button_pressed = base_defaults.get(arg_name, true)
	else:
		edit.text = str(full_defaults.get(arg_name, ""))
		edit.expand_to_text_length = true
		edit.custom_minimum_size.x = 240
		edit.placeholder_text = str(base_defaults.get(arg_name, ""))
	find_child("Edit").add_child(edit)
	
	if type == TYPE_STRING:
		# TODO give ability to limit to dropdowns
		var selection = preload("res://addons/diisis/editor/src/dropdown_type_selection.tscn").instantiate()
		selection.init()
		selection.deserialize(Pages.custom_method_dropdown_limiters.get(method_name, {}))
		add_child(selection)
	
	deserialize(Pages.custom_method_defaults.get(method_name, {}))

func deserialize(data:Dictionary):
	print("AYO TODO HERE")

func serialize() -> Dictionary:
	return {
		"arg_name" = find_child("ArgNameLabel").text,
		"use_custom_default" = find_child("UseDefaultCheckBox").button_pressed,
		"custom_default" = find_child("Edit").get_child(0).value
	}

func _on_use_default_check_box_toggled(toggled_on: bool) -> void:
	modulate.a = 1 if toggled_on else 0.6
