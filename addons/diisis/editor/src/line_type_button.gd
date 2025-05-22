@tool
extends Button
class_name LineTypeButton


# tscn autoloads break enum exports, either use this workaround or autoload the gd script alone
# I'm using the workaround
# https://github.com/godotengine/godot/issues/73109#issuecomment-1714885562
@export var line_type := DIISIS.LineType.Text
