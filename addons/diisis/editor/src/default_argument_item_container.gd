@tool
extends Control

var method := ""

# defaults and limiters are duplicated to use the local data from the window
func init(method_name:String, defaults:Dictionary, limiters:Dictionary):
	method = method_name
	for arg_name in Pages.get_custom_method_arg_names(method_name):
		var item : DefaultArgumentItem = preload("res://addons/diisis/editor/src/default_argument_item.tscn").instantiate()
		add_child(item)
		item.init(
			method_name,
			arg_name)
		item.deserialize(defaults.get(method_name, {}))
		
		if item.is_string:
			var selector : DropdownTypeSelector = preload("res://addons/diisis/editor/src/dropdown_type_selection.tscn").instantiate()
			add_child(selector)
			selector.init(arg_name)
			selector.deserialize(limiters.get(method_name, {}))
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

func serialize() -> Dictionary:
	var method_defaults := {}
	for arg in get_children():
		if arg is DefaultArgumentItem:
			var arg_name = arg.arg
			var data : Dictionary = arg.serialize().duplicate(true)
			method_defaults[arg_name] = data
	
	var method_limiters := {}
	for arg in get_children():
		if arg is DropdownTypeSelector:
			var arg_name = arg.arg
			var data : Dictionary = arg.serialize().duplicate(true)
			method_limiters[arg_name] = data
	return {
		"custom_method_defaults" : method_defaults,
		"method" : method,
		"custom_method_dropdown_limiters" : method_limiters,
	}
