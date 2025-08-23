@tool
extends Control


func init():
	find_child("AddressModeButtonPage").set_mode(Pages.default_address_mode_pages)
	
	for child in find_child("ToggleSettings").get_children():
		child.queue_free()
	for child in find_child("StringSettings").get_children():
		child.queue_free()
	var settings := Pages.TOGGLE_SETTINGS.duplicate(true)
	settings.sort()
	for setting : String in settings:
		var container = HBoxContainer.new()
		var button = CheckBox.new()
		button.toggled.connect(Pages.set_setting.bind(setting))
		var label = Label.new()
		label.text = Pages.TOGGLE_SETTINGS.get(setting)
		container.add_child(button)
		container.add_child(label)
		button.mouse_entered.connect(label.set.bind("visible", true))
		button.mouse_exited.connect(label.set.bind("visible", false))
		label.visible = false
		find_child("ToggleSettings").add_child(container)
		button.button_pressed = Pages.get(setting)
		button.text = setting.capitalize()
	
	for setting : String in Pages.STRING_SETTINGS.keys():
		var container = HBoxContainer.new()
		var label = Label.new()
		label.text = setting.capitalize()
		container.add_child(label)
		var edit := LineEdit.new()
		edit.placeholder_text = Pages.STRING_SETTINGS.get(setting)
		edit.text = Pages.get(setting)
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.text_changed.connect(Pages.set_setting.bind(setting))
		container.add_child(edit)
		var button = Button.new()
		button.text = "Reset"
		button.pressed.connect(edit.set.bind("text", ""))
		button.pressed.connect(Pages.set_setting.bind("", setting))
		container.add_child(button)
		find_child("StringSettings").add_child(container)
	
	$TabContainer.current_tab = 0


func _on_address_mode_button_page_mode_set(mode: AddressModeButton.Mode) -> void:
	Pages.default_address_mode_pages = mode
