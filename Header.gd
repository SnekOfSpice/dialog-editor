extends VBoxContainer


func _ready() -> void:
	load_defaults()


func load_defaults():
	for c in get_children():
		c.queue_free()
	
	for prop in Pages.head_defaults:
		var p = preload("res://src/head_property.tscn").instantiate()
		add_child(p)
		p.property_name = prop
		p._default = Pages.head_defaults.get(prop)
		p.connect("property_changed", change_header)

func change_header(property, value):
	printt(property, value)

func serialize() -> Dictionary:
	return {}

func deserialize(data: Dictionary):
	prints("deserializing header ", data)
