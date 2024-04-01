@tool
extends VBoxContainer


func init() -> void:
	load_defaults()

func add_property(data: Dictionary):
	var p = preload("res://addons/diisis/editor/src/head_property_2.tscn").instantiate()
	add_child(p)
	p.init()
	
	p.deserialize(data)
	p.set_is_editing_default(false)
	#p.connect("property_changed", change_header)

func load_defaults():
	for c in get_children():
		c.queue_free()
	
	for prop in Pages.head_defaults:
		add_property(prop)

func change_header(property, value):
	for c in get_children():
		if c.property_name == property:
			c.value = value
			c.update()

func serialize() -> Array:
	var result = []
	for c in get_children():
		result.append(c.serialize())
	return result

func deserialize(data: Array):
	for c in get_children():
		c.queue_free()
	
	await get_tree().process_frame
	
	for d in data:
		add_property(d)

func short_form() -> String:
	var result = ""
	for c in get_children():
		result += str(c.stringify_value(), ", ")
	result = result.trim_suffix(", ")
	#prints("short form ", result, " from ", get_child_count(), " properties")
	return result
