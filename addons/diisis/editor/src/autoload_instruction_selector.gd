@tool
extends Control


func init():
	for child in find_child("Buttons").get_children():
		child.queue_free()
	var autoload_names := Pages.get_autoload_names()
	autoload_names.erase("DIISIS")
	autoload_names.erase("DiisisEditorActions")
	autoload_names.erase("DiisisEditorUtil")
	autoload_names.erase("TextToDiisis")
	autoload_names.erase("Pages")
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
	Pages.callable_autoloads = result.duplicate(true)
