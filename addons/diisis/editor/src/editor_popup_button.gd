@tool
extends Button

@export var popup:Window

func _ready() -> void:
	add_to_group("editor_popup_button")

func init():
	connect("pressed", open_popup)

func open_popup():
	if not popup:
		push_warning("No popup set.")
		return
	Pages.editor.refresh()
	popup.popup()
