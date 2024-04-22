extends Node
class_name InstructionHandler

signal set_input_lock(value)
signal instruction_wrapped_completed()
## Emit this signal from within the node that inherits from [InstructionHandler] after return from
## [method InstructionHandler.execute] with [code]true[/code].
signal instruction_completed()
signal execute_instruction(args)


func wrapper_execute(instruction_name, args, delay_before := 0.0, delay_after := 0.0):
	emit_signal("set_input_lock", true)
	ParserEvents.instruction_started.emit(instruction_name, args, delay_before)
	
	if delay_before > 0.0:
		await get_tree().create_timer(delay_before).timeout
	
	ParserEvents.instruction_started_after_delay.emit(instruction_name, args, delay_before)
	emit_signal("execute_instruction", args)
	
	var await_excecution = execute(instruction_name, args)
	
	if await_excecution:
		await instruction_completed
	
	ParserEvents.instruction_completed.emit(instruction_name, args, delay_after)
	
	if delay_after > 0.0:
		await get_tree().create_timer(delay_after).timeout
	
	emit_signal("set_input_lock", false)
	emit_signal("instruction_wrapped_completed")
	ParserEvents.instruction_completed_after_delay.emit(instruction_name, args, delay_after)

func execute(instruction_name, args):
	pass
