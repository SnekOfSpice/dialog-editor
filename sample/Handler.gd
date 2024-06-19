extends InstructionHandler

var some_var = 3
var another_var:bool
var a_third_var := ""

@export var icon:Sprite2D

func function_one():
	return " hi "

func function_two():
	return ""

#func execute(instruction_name, args) -> bool:
	#match instruction_name:
		#"rotate_icon":
			#rotate_icon()
			#return true
		#"show_character":
			#prints("real code", args)
	#return false

func notbool():
	return 9

func yippie(some_arg):
	print(str(some_arg))
	return false

func rotate_icon():
	var t = get_tree().create_tween()
	t.tween_property(icon, "rotation_degrees", 360, 2.0)
	await t.finished
	instruction_completed.emit()
