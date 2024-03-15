@tool
extends Button


# tscn autoloads break enum exports, either use this workaround or autoload the gd script alone
# I'm using the workaround
# https://github.com/godotengine/godot/issues/73109#issuecomment-1714885562
@export var line_type := Data.LineType.Text

func _ready() -> void:
	Data.listen(self, "editor.selected_line_type")
	
	toggle_mode = true
	connect("pressed", set_selected)
	button_pressed = line_type == Data.LineType.Text


func set_selected():
	Data.apply("editor.selected_line_type", line_type)


func on_property_change(property: String, new_value, old_value):
	match property:
		"editor.selected_line_type":
			button_pressed = line_type == new_value
