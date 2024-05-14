@tool
extends HBoxContainer


signal argument_pressed(label: String, pressed:bool)
signal syntax_pressed(label:String)

func init(text:String):
	find_child("SelectAsArgumentCheckbox").button_pressed = Pages.dropdown_dialog_arguments.has(text)
	find_child("SelectAsSyntaxCheckbox").button_pressed = Pages.dropdown_title_for_dialog_syntax == text
	find_child("Label").text = text

func _on_select_as_argument_checkbox_toggled(toggled_on: bool) -> void:
	emit_signal("argument_pressed", find_child("Label").text, toggled_on)


func _on_select_as_syntax_checkbox_toggled(toggled_on: bool) -> void:
	if toggled_on:
		emit_signal("syntax_pressed", find_child("Label").text)

func set_syntax_button_group(group:ButtonGroup):
	find_child("SelectAsSyntaxCheckbox").button_group = group
