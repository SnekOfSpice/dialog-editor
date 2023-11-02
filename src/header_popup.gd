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
		var p = preload("res://src/head_property_2.tscn").instantiate()
		find_child("HeadPropertyContainer").add_child(p)
		
		p.deserialize(prop)
		p.set_is_editing_default(true)


func add_empty_property():
	var p = preload("res://src/head_property_2.tscn").instantiate()
	find_child("HeadPropertyContainer").add_child(p)
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


#func change_header_default(property_name, old_property_name, new_default_value):
#	#print("CHANGING HEADER DEFAULT ( NOT ACTUALLY )")
#	#printt(property_name, old_property_name, new_default_value)
#	# not working atm
#	# I think it is now?
#
#	for i in new_header.size():
#		if new_header[i].get("property_name") == old_property_name:
#			new_header[i] = {
#				"property_name" : property_name,
#				"values" : new_default_value,
#				"data_type":
#			}
#			break
	
	# trim excess
#	var overshoot = old_header.size() - new_header.size()
#	if overshoot > 0:
#
	#new_header[old_property_name] = new_default_value

func save():
	new_header.resize(find_child("HeadPropertyContainer").get_children().size())
	var i = 0
	for c in find_child("HeadPropertyContainer").get_children():
		new_header[i] = c.serialize()
		i += 1
#		var new_head = c.updated_header_default()
#		change_header_default(
#			new_head.get("property_name"),
#			new_head.get("old_property_name"),
#			new_head.get("new_default_values"),
#			)
	#get_parent().current_page.deserialize(Pages.page_data.get(get_parent().current_page.number).get("lines"))
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
