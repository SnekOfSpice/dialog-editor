@tool
extends Control

func fill():
	for button : CheckBox in find_child("LocaleContainer").get_children():
		button.queue_free()
	
	for locale in Pages.LOCALES:
		var button = CheckBox.new()
		button.text = locale
		button.button_pressed = locale in Pages.locales_to_export
		button.toggled.connect(on_locale_toggled.bind(locale))
		find_child("LocaleContainer").add_child(button)

func on_locale_toggled(button_pressed:bool, locale:String):
	if button_pressed:
		Pages.locales_to_export.append(locale)
	else:
		Pages.locales_to_export.erase(locale)
	
	for button : CheckBox in find_child("LocaleContainer").get_children():
		button.disabled = Pages.locales_to_export.size() <= 1 and button.button_pressed
