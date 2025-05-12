@tool
extends Control


func init():
	find_child("UseDialogSyntaxCheckBox").button_pressed = Pages.use_dialog_syntax
	find_child("LeadTimeSpinBoxSameActor").value = Pages.text_lead_time_same_actor
	find_child("LeadTimeSpinBoxOtherActor").value = Pages.text_lead_time_other_actor
	find_child("AddressModeButtonPage").set_mode(Pages.default_address_mode_pages)
	
	for child in find_child("ToggleSettings").get_children():
		child.queue_free()
	for child in find_child("StringSettings").get_children():
		child.queue_free()
	for setting : String in Pages.TOGGLE_SETTINGS.keys():
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
	
	find_child("ItemList").select(0)
	_on_item_list_item_selected(0)


func _on_item_list_item_selected(index: int) -> void:
	for c in find_child("ContentContainer").get_children():
		c.visible = c.get_index() == index

func _on_use_dialog_syntax_check_box_pressed():
	Pages.use_dialog_syntax = find_child("UseDialogSyntaxCheckBox").button_pressed


func _on_lead_time_spin_box_same_actor_value_changed(value):
	Pages.text_lead_time_same_actor = value


func _on_lead_time_spin_box_other_actor_value_changed(value):
	Pages.text_lead_time_other_actor = value


func _on_address_mode_button_page_mode_set(mode: AddressModeButton.Mode) -> void:
	Pages.default_address_mode_pages = mode



#func _on_save_on_play_check_box_toggled(toggled_on: bool) -> void:
	#Pages.save_on_play = toggled_on
#
#
#func _on_warn_on_fact_deletion_check_box_toggled(toggled_on: bool) -> void:
	#Pages.warn_on_fact_deletion = toggled_on
