@tool
extends Control

var method := ""

func init(method_name:String):
	method = method_name
	for arg_name in Pages.get_custom_method_arg_names(method_name):
		# TODO get actual data from Pages.custom_method_defaults
		# TODO get actual data from Pages.custom_method_dropdown_limiters
		var item : DefaultArgumentItem = preload("res://addons/diisis/editor/src/default_argument_item.tscn").instantiate()
		add_child(item)
		item.update_custom_defaults.connect(_on_update_custom_defaults)
		item.init(
			method_name,
			arg_name)
		item.deserialize(Pages.custom_method_defaults.get(method_name, {}))
		
		if item.is_string:
			var selector : DropdownTypeSelector = preload("res://addons/diisis/editor/src/dropdown_type_selection.tscn").instantiate()
			add_child(selector)
			selector.init(arg_name)
			selector.deserialize(Pages.custom_method_dropdown_limiters.get(method_name, {}))
			selector.update_dropdown_limiters.connect(_on_update_dropdown_limiters)
		else:
			var c = Control.new()
			add_child(c)
	
	await get_tree().process_frame
	
	if get_child_count() == 0:
		var label = Label.new()
		label.text = "Method doesn't accept arguments"
		add_child(label)

func clear():
	for child in get_children():
		child.queue_free()

func _on_update_custom_defaults():
	var method_defaults := {}
	for arg in get_children():
		if arg is DefaultArgumentItem:
			var arg_name = arg.arg
			var data : Dictionary = arg.serialize().duplicate(true)
			method_defaults[arg_name] = data
	Pages.custom_method_defaults[method] = method_defaults

func _on_update_dropdown_limiters():
	var method_limiters := {}
	for arg in get_children():
		if arg is DropdownTypeSelector:
			var arg_name = arg.arg
			var data : Dictionary = arg.serialize().duplicate(true)
			method_limiters[arg_name] = data
	Pages.custom_method_dropdown_limiters[method] = method_limiters
	
