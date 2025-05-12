@tool
extends Control

var item_list : ItemList
var custom_container : GridContainer

func init():
	item_list = find_child("ItemList")
	custom_container = find_child("GridContainer")
	item_list.clear()
	for child in custom_container.get_children():
		child.queue_free()
	for method in Pages.get_custom_methods():
		item_list.add_item(method)

func _on_item_list_item_selected(index: int) -> void:
	for child in custom_container.get_children():
		child.queue_free()
	var method_name : String = item_list.get_item_text(index)
	var base_defaults : Dictionary = Pages.get_custom_method_base_defaultsd(method_name)
	var full_defaults : Dictionary = Pages.get_custom_method_defaults(method_name)
	
	for arg_name in Pages.get_custom_method_arg_names(method_name):
		
		var label = Label.new()
		label.text = arg_name
		custom_container.add_child(label)
		
		var hbox = HBoxContainer.new()
		var edit = LineEdit.new()
		edit.text = str(full_defaults.get(arg_name, ""))
		edit.placeholder_text = str(base_defaults.get(arg_name, ""))
		hbox.add_child(edit)
		
		custom_container.add_child(hbox)
		
		var type = Pages.get_custom_method_types(method_name).get(arg_name)
		if type == TYPE_STRING:
			# TODO give ability to limit to dropdowns
			var gc = GridContainer.new()
			gc.columns = 4
			for title in Pages.dropdown_titles:
				var check_box = CheckBox.new()
				check_box.text = title
				gc.add_child(check_box)
		else:
			var c = Control.new()
			custom_container.add_child(c)
	await get_tree().process_frame
	print(custom_container.get_child_count())
	if custom_container.get_child_count() == 0:
		var label = Label.new()
		label.text = "Method doesn't accept arguments"
		custom_container.add_child(label)
func serialize():
	pass
	# TODO


func _on_method_search_text_changed(new_text: String) -> void:
	for method : String in Pages.get_custom_methods():
		if new_text in method or new_text.is_empty():
			item_list.add_item(method)
