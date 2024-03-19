@tool
extends MarginContainer
class_name Facts

## Override this to hide the built-in visibility toggle button.
@export var visibility_toggle_button:Button

func init():
	set_visibility(false)
	if visibility_toggle_button:
		find_child("VisibilityToggleButton").visible = false
		visibility_toggle_button.connect("pressed", toggle_visibility)
	else:
		find_child("VisibilityToggleButton").connect("pressed", toggle_visibility)

func set_visibility(value:bool):
	if visibility_toggle_button:
		visibility_toggle_button.button_pressed = value
		visible = value
	else:
		find_child("Controls").visible = value
		find_child("FactsContainer").visible = value

func toggle_visibility():
	if visibility_toggle_button:
		set_visibility(not visible)
	else:
		set_visibility(not find_child("Controls").visible)

func serialize() -> Dictionary:
	var result := {}
	var facts := {}
	for fact in find_child("FactsContainer").get_children():
		facts[fact.get_fact_name()] = fact.get_fact_value()
	result["values"] = facts
	result["meta.visible"] = find_child("Controls").visible
	return result

func deserialize(data: Dictionary):
	for fact_name in data.get("values", {}).keys():
		add_fact(fact_name, data.get("values", {}).get(fact_name))
	set_visibility(data.get("meta.visible", false))

func add_fact(fact_name: String, fact_value: bool):
	var f = preload("res://addons/diisis/editor/src/fact_item.tscn").instantiate()
	find_child("FactsContainer").add_child(f)
	f.set_fact(fact_name, fact_value)

func _on_add_fact_button_pressed() -> void:
	add_fact(str("newfact", Pages.facts.keys().size()), true)
