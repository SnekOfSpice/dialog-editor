extends TextureRect
class_name CGTexture

var start_pos : Vector2

func _ready() -> void:
	start_pos = position

func set_texture_offset(offset:Vector2):
	position = start_pos + offset
