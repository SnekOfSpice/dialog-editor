extends Node


func function_in_eval():
	print("calling a function")
	return ""

func screenshake():
	if GameWorld.camera:
		GameWorld.camera.apply_shake()
	
	return ""
