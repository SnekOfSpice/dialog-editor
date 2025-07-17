@tool
extends Control

@export var toggle_button : Button
var container : VBoxContainer

var is_editable := false

func init() -> void:
	visible = not Pages.is_header_schema_empty()
	container = $PropertyContainer
	load_defaults()
	
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)

func add_property(data: Dictionary):
	var p = preload("res://addons/diisis/editor/src/head_property_2.tscn").instantiate()
	container.add_child(p)
	p.init()
	p.deserialize(data)
	p.set_is_editing_default(false)

func load_defaults():
	for c in container.get_children():
		c.queue_free()
	
	for prop in Pages.head_defaults:
		add_property(prop)

func change_header(property, value):
	for c in container.get_children():
		if c.property_name == property:
			c.value = value
			c.update()

func serialize() -> Array:
	var result = []
	for c in container.get_children():
		result.append(c.serialize())
	return result

func deserialize(data: Array):
	for c in container.get_children():
		c.queue_free()
	
	visible = not Pages.is_header_schema_empty()
	
	for d in data:
		add_property(d)

func get_short_form() -> String:
	var result = ""
	for c in container.get_children():
		result += str(c.stringify_value(), "\n")
	result = result.trim_suffix("\n")
	return result

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			var editable : bool = not find_child("PropertyContainer").visible
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					set_editable(editable)
				#MOUSE_BUTTON_RIGHT:
					#for header in get_tree().get_nodes_in_group("diisis_header"):
						#header.set_editable(editable)

func set_editable(value:bool):
	is_editable = value
	find_child("PropertyContainer").visible = value
	find_child("HeaderShort").visible = not value
	find_child("HeaderShort").text = get_short_form()
	
	if toggle_button:
		toggle_button.set_pressed_no_signal(value)
