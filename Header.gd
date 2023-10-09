extends VBoxContainer


func _ready() -> void:
	load_defaults()

func add_property(data: Dictionary):
	var p = preload("res://src/head_property.tscn").instantiate()
	add_child(p)
	#p.property_name = prop
	#Pages.head_defaults.get(prop)
	
	p.deserlialize(data)
	p.connect("property_changed", change_header)

func load_defaults():
	for c in get_children():
		c.queue_free()
	
	for prop in Pages.head_defaults:
#		var start_data = {
#		"property_name":prop,
#		"value": Pages.get_defaults(prop).get("value")
#		}
	
		add_property(prop)

func change_header(property, value):
	printt(property, value)

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
