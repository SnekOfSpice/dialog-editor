extends Node


func shake_camera(strength: float) -> void:
	if GameWorld.camera:
		GameWorld.camera.apply_shake(strength)
