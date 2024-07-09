@tool
extends Node
class_name InstructionHandler

## A supplementary class to give more complex behaviors to [LineReader].
##
## All methods implemented in [InstructionHandler] should return [code]false[/code] by default. Return [code]true[/code] for any
## instructions to make the [InstructionHandler] wait for [signal InstructionHandler.instruction_completed]
## to be emitted. (Has to emitted manually.) This is useful for instructions that don't have an instant effect, such as a fade to black or other animations.[br]
## Note that you have to handle what happens inside those suspended calls yourself, including pausing the [Parser] and [method LineReader.interrupt].[br]
## Supported data types for arguments are [b]String, float, and bool only.[b][br]
## Exaple of how to write a minimal script that inherits from [InstructionHandler] and uses all of its functionality:
## 
## [codeblock]
## extends InstructionHandler
##
## # This will instantly position something.
## func position_character(character_name:String, character_position:int):
##    # However you want to do this in your project is up to you.
##    GameStage.set_character_position(
##    character_name,
##    character_position))
##    return false
##
## # This implementation returns true, so the LineReader will wait until you tell it to continue.
## # Make a callback to emit the instruction_completed signal of this node from the code that handles the movement.
## # Maybe it has some lerp that takes some time!
## func do_delayed():
##    # Give self as an argument to make the callback easier.
##    GameStage.call_some_lerp(self, 2.0)
##    return true
## [/codeblock]

signal set_input_lock(value)
signal instruction_wrapped_completed()
## Emit this signal from within the node that inherits from [InstructionHandler] after return from
## [method InstructionHandler.execute] with [code]true[/code].
signal instruction_completed()
signal execute_instruction(args)

var delay_before := 0.0
var delay_after := 0.0
var execution_name := ""
var execution_args := []
var is_executing := false
var has_executed := false
var has_received_execute_callback := false
var emitted_complete := false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	instruction_completed.connect(set.bind("has_received_execute_callback", true))

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if Parser.paused:
		return
	
	if not is_executing:
		return
	
	if delay_before > 0:
		delay_before -= delta
		return
	
	if not has_executed:
		ParserEvents.instruction_started_after_delay.emit(execution_name, execution_args, delay_before)
		emit_signal("execute_instruction", execution_args)
		has_executed = true
		has_received_execute_callback = not execute(execution_name, execution_args)
	
	if not has_received_execute_callback:
		return
	
	if delay_after > 0:
		delay_after -= delta
		if delay_after <= 0:
			ParserEvents.instruction_completed.emit(execution_name, execution_args, delay_after)
			emitted_complete = true
		return
	elif not emitted_complete:
		ParserEvents.instruction_completed.emit(execution_name, execution_args, delay_after)
	
	emit_signal("set_input_lock", false)
	emit_signal("instruction_wrapped_completed")
	ParserEvents.instruction_completed_after_delay.emit(execution_name, execution_args, delay_after)

	
	is_executing = false

func _wrapper_execute(instruction_name : String, args : Array, delay_before_seconds := 0.0, delay_after_seconds := 0.0):
	await get_tree().process_frame
	delay_after = delay_after_seconds
	delay_before = delay_before_seconds
	execution_name = instruction_name
	execution_args = args
	has_executed = false
	is_executing = true
	has_received_execute_callback = true
	emit_signal("set_input_lock", true)
	ParserEvents.instruction_started.emit(instruction_name, args, delay_before)
	emitted_complete = false


func execute(instruction_name:String, args:Array) -> bool:
	if not has_method(instruction_name):
		push_error(str("Function ", instruction_name, " not found in ", get_script().get_global_name(),"."))
		return false
	var result = callv(instruction_name, args)
	if not result is bool:
		push_error(str("Function ", instruction_name, " in ", get_script().get_global_name(), " should return true or false."))
		return false
	return result
