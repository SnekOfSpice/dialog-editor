@tool
extends MarginContainer
class_name DropdownTypeSelector

var arg:String

signal update_dropdown_limiters()

func init(arg_name:String):
	arg = arg_name
	for button : Button in find_child("GridContainer").get_children():
		button.queue_free()
	for title in Pages.dropdown_titles:
		var button = CheckBox.new()
		button.text = title
		button.tooltip_text = "\n".join(Pages.dropdowns.get(title))
		button.pressed.connect(_on_dropdown_selector_button_pressed)
		find_child("GridContainer").add_child(button)

func serialize():
	var data := {}
	var selected := []
	for child : Button in find_child("GridContainer").get_children():
		if child.button_pressed:
			selected.append(child.text)
	data["selected"] = selected
	return data

func deserialize(data:Dictionary):
	for button : Button in find_child("GridContainer").get_children():
		button.button_pressed = data.get("selected", []).has(button.text)


func _on_dropdown_selector_button_pressed():
	emit_signal("update_dropdown_limiters")
