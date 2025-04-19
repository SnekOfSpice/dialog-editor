@tool
extends Control

var selecting_default := false
var selected_at_open := []

func fill():
	selected_at_open = Pages.locales_to_export.duplicate(true)
	find_child("DefaultLocaleLabel").text = Pages.default_locale
	for child in find_child("LocaleInitialContainer").get_children():
		child.queue_free()
	
	var handled_initials := []
	var sorted_locales = Pages.LOCALES.duplicate()
	sorted_locales.sort()
	for locale : String in sorted_locales:
		var initial = locale[0]
		if initial in handled_initials:
			continue
		var container : VBoxContainer = find_child("LocaleInitialContainer")
		var hbox = HBoxContainer.new()
		container.add_child(hbox)
		hbox.name = initial
		handled_initials.append(initial)
		
		var separator = HSeparator.new()
		container.add_child(separator)
		
		var label = Label.new()
		var separator2 = VSeparator.new()
		label.text = initial.capitalize()
		hbox.add_child(label)
		hbox.add_child(separator2)
	
	for locale in Pages.LOCALES:
		var button = CheckBox.new()
		button.name = locale
		button.text = locale
		button.button_pressed = locale in Pages.locales_to_export
		button.toggled.connect(on_locale_toggled.bind(locale))
		button.disabled = locale == Pages.default_locale
		
		var hbox : HBoxContainer = find_child("LocaleInitialContainer").get_node(locale[0])
		hbox.add_child(button)

func get_all_buttons() -> Array:
	var buttons := []
	for hbox in find_child("LocaleInitialContainer").get_children():
		for button in hbox.get_children():
			if button is CheckBox:
				buttons.append(button)
	return buttons

func get_locale_button(locale:String) -> CheckBox:
	for button in get_all_buttons():
		if button.text == locale:
			return button
	return null

func on_locale_toggled(button_pressed:bool, locale:String):
	if selecting_default:
		find_child("DefaultLocaleLabel").text = locale
		get_locale_button(Pages.default_locale).disabled = false
		Pages.default_locale = locale
		selecting_default = false
		get_locale_button(locale).button_pressed = true
		get_locale_button(locale).disabled = true
		return
	if button_pressed:
		Pages.locales_to_export.append(locale)
	else:
		Pages.locales_to_export.erase(locale)
	
	#for button : CheckBox in get_all_buttons():
		#button.disabled = Pages.locales_to_export.size() <= 1 and button.button_pressed

func set_selecting_default(value:bool):
	selecting_default = value
	if selecting_default:
		find_child("DefaultLocaleLabel").text = "Select a button or press again to cancel."
	else:
		find_child("DefaultLocaleLabel").text = Pages.default_locale

func _on_default_locale_selection_button_pressed() -> void:
	set_selecting_default(not selecting_default)


func select_all():
	for button in get_all_buttons():
		button.button_pressed = true

func deselect_all():
	for button in get_all_buttons():
		button.button_pressed = button.name == Pages.default_locale

func set_selected(locale:String, selected:bool):
	for button : CheckBox in get_all_buttons():
		if button.name == locale:
			button.button_pressed = selected

func _on_select_all_button_pressed() -> void:
	select_all()


func _on_deselect_all_button_pressed() -> void:
	deselect_all()


func _on_select_dominant_button_pressed() -> void:
	deselect_all()
	for locale in Pages.DOMINANT_LOCALES:
		set_selected(locale, true)


func _on_reset_button_pressed() -> void:
	deselect_all()
	for locale in selected_at_open:
		set_selected(locale, true)
