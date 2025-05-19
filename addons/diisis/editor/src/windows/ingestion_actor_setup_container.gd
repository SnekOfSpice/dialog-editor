@tool
extends VBoxContainer

var text_edit : TextEdit

func init():
	text_edit = find_child("TextEdit")
	text_edit.text = Pages.ingestion_actor_declaration
	find_child("SaveButton").text = "save"
	find_child("HelpLabel").visible = false

func _on_text_edit_text_changed() -> void:
	var save_button : Button = find_child("SaveButton")
	save_button.text = str("save", " (*)" if text_edit.text != Pages.ingestion_actor_declaration else "")


func _on_reset_button_pressed() -> void:
	text_edit.text = Pages.ingestion_actor_declaration
	_on_text_edit_text_changed()


func _on_save_button_pressed() -> void:
	Pages.ingestion_actor_declaration = text_edit.text
	_on_text_edit_text_changed()


func _on_help_button_pressed() -> void:
	find_child("HelpLabel").visible = not find_child("HelpLabel").visible
