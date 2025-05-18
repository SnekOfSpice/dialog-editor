@tool
extends MarginContainer
class_name DropdownTypeSelector

const HEIGHT := 32 # used for spacing and visual stuff

signal updated()
signal updated_selection(item:DropdownTypeSelector)

var method := ""
var arg := ""

func init(method_name:String, arg_name:String):
	method = method_name
	arg = arg_name
	for button : Button in find_child("GridContainer").get_children():
		button.queue_free()
	for title in Pages.dropdown_titles:
		var button = CheckBox.new()
		button.text = title
		button.tooltip_text = "\n".join(Pages.dropdowns.get(title))
		button.pressed.connect(_on_pressed)
		find_child("GridContainer").add_child(button)

func _on_pressed():
	emit_signal("updated")
	emit_signal("updated_selection", self)

func serialize() -> Array:
	var selected := []
	for child : Button in find_child("GridContainer").get_children():
		if child.button_pressed and Pages.get_custom_method_arg_type(method, arg) == TYPE_STRING:
			selected.append(child.text)
	return selected

func deserialize(data:Array):
	for button : Button in find_child("GridContainer").get_children():
		button.button_pressed = data.has(button.text)
