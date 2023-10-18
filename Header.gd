extends VBoxContainer


func _ready() -> void:
	load_defaults()

func add_property(data: Dictionary):
	var p = preload("res://src/head_property.tscn").instantiate()
	add_child(p)
	#p.property_name = prop
	#Pages.head_defaults.get(prop)
	
	p.deserialize(data)
	p.connect("property_changed", change_header)

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
	
	for d in data:
		add_property(d)

func short_form() -> String:
	var result = ""
	for c in get_children():
		result += str(c.value, ", ")
	result = result.trim_suffix(", ")
	return result
