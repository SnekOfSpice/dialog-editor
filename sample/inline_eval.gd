extends Node


func function_in_eval():
	return ""

func screenshake():
	if GameWorld.camera:
		GameWorld.camera.apply_shake()
	
	return ""
