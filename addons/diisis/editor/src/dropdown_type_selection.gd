@tool
extends MarginContainer


func init():
	for button : Button in find_child("GridContainer").get_children():
		button.queue_free()
	for title in Pages.dropdown_titles:
		var button = CheckBox.new()
		button.text = title
		button.tooltip_text = "\n".join(Pages.dropdowns.get(title))
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
