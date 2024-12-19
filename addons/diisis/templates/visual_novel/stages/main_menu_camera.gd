extends Camera2D




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not GameWorld.stage_root.screen.is_empty():
		position = Vector2(479, 271)
		return
	position = lerp(position, Vector2(479, 271) + get_local_mouse_position() * 0.02, 0.4)
