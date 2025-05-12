@tool
extends Control


func init(method_name:String):

	
	for arg_name in Pages.get_custom_method_arg_names(method_name):
		# TODO get actual data from Pages.custom_method_defaults
		# TODO get actual data from Pages.custom_method_dropdown_limiters
		var item = preload("res://addons/diisis/editor/src/default_argument_item.tscn").instantiate()
		add_child(item)
		item.init(
			method_name,
			arg_name)
	
	await get_tree().process_frame
	
	if get_child_count() == 0:
		var label = Label.new()
		label.text = "Method doesn't accept arguments"
		add_child(label)

func clear():
	for child in get_children():
		child.queue_free()
