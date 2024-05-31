@tool
extends Window


var old_header := []
var new_header := []

signal update

func fill():
	old_header = Pages.head_defaults.duplicate(true)
	new_header = Pages.head_defaults.duplicate(true)
	for c in find_child("HeadPropertyContainer").get_children():
		c.queue_free()
	
	for prop in Pages.head_defaults:
		var p = preload("res://addons/diisis/editor/src/head_property_2.tscn").instantiate()
		find_child("HeadPropertyContainer").add_child(p)
		p.init()
		p.deserialize(prop)
		p.set_is_editing_default(true)


func add_empty_property():
	var p = preload("res://addons/diisis/editor/src/head_property_2.tscn").instantiate()
	find_child("HeadPropertyContainer").add_child(p)
	p.init()
	var new_key = str("property", new_header.size())
	#var new_value = str("value", new_header.size())
	var start_data = {
		"property_name":new_key,
		"values": [str("value", find_child("HeadPropertyContainer").get_child_count()), null],
		"data_type": Pages.DataTypes._String
	}
	
	new_header.append(start_data)
	
	
	p.deserialize(start_data)
	p.set_is_editing_default(true)
	#p.connect("property_default_changed", change_header_default)
	#p.connect("erase_property", erase_property_from_temp)
	

func erase_property_from_temp(property):
	new_header.erase(property)


func save():
	new_header.resize(find_child("HeadPropertyContainer").get_children().size())
	var i = 0
	for c in find_child("HeadPropertyContainer").get_children():
		new_header[i] = c.serialize()
		i += 1
	Pages.apply_new_header_schema(new_header)
	
	emit_signal("update")


func _on_about_to_popup() -> void:
	fill()


func _on_close_requested() -> void:
	hide()


func _on_add_property_button_pressed() -> void:
	add_empty_property()


func _on_save_button_pressed() -> void:
	save()


func _on_save_close_button_pressed() -> void:
	save()
	hide()
