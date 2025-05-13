@tool
extends Control


func init():
	for child in find_child("Buttons").get_children():
		child.queue_free()
	var autoload_names := []
	for property in ProjectSettings.get_property_list():
		var prop_name :String = property.get("name")
		if prop_name.begins_with("autoload/"):
			autoload_names.append(prop_name.trim_prefix("autoload/"))
	autoload_names.sort()
	for autoload in autoload_names:
		var button = CheckBox.new()
		button.text = autoload
		button.button_pressed = button.text in Pages.callable_autoloads
		find_child("Buttons").add_child(button)
		button.pressed.connect(save)

func save():
	var result := []
	for button : Button in find_child("Buttons").get_children():
		if button.button_pressed:
			result.append(button.text)
	print(result)
	Pages.callable_autoloads = result.duplicate(true)
