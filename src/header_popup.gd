extends Window


var old_header := []
var new_header := []


func fill():
	print("fillin")
	old_header = Pages.head_defaults.duplicate(true)
	new_header = Pages.head_defaults.duplicate(true)
	for c in find_child("HeadPropertyContainer").get_children():
		c.queue_free()
	
	for prop in Pages.head_defaults:
		var p = preload("res://src/head_property.tscn").instantiate()
		find_child("HeadPropertyContainer").add_child(p)
#		var start_data = {
#			"property_name":prop,
#			"value": Pages.get_defaults(prop).get("value")
#		}
		p.editable_name = true
		p.deserialize(prop)
		p.connect("property_default_changed", change_header_default)
		p.connect("erase_property", erase_property_from_temp)


func add_empty_property():
	var p = preload("res://src/head_property.tscn").instantiate()
	find_child("HeadPropertyContainer").add_child(p)
	var new_key = str("custom", new_header.size())
	var new_value = str("value", new_header.size())
	var start_data = {
		"property_name":new_key,
		"value": new_value,
		"data_type": Pages.DataTypes._String
	}
	
	new_header.append(start_data)
	
	p.editable_name = true
	p.deserialize(start_data)
	p.connect("property_default_changed", change_header_default)
	p.connect("erase_property", erase_property_from_temp)
	

func erase_property_from_temp(property):
	new_header.erase(property)


func change_header_default(property_name, old_property_name, new_default_value):
	printt(property_name, old_property_name, new_default_value)

func save():
	#get_parent().current_page.deserialize(Pages.page_data.get(get_parent().current_page.number).get("lines"))
	Pages.apply_new_header_schema(new_header)


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