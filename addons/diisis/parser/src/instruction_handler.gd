@icon("res://addons/diisis/parser/style/icon_instruction_handler.svg")
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

enum CallMode {
	Call,
	Func
}

var delay_before := 0.0
var delay_after := 0.0
var execution_text := ""
var is_executing := false
var has_executed := false
var has_received_execute_callback := false
var emitted_complete := false

func serialize() -> Dictionary:
	return {
		"delay_before" : delay_before,
		"delay_after" : delay_after,
		"execution_text" : execution_text,
		"is_executing" : is_executing,
		"has_executed" : has_executed,
		"has_received_execute_callback" : has_received_execute_callback,
		"emitted_complete" : emitted_complete,
	}

func deserialize(data: Dictionary):
	for key in data:
		set(key, data.get(key))

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	instruction_completed.connect(finish_waiting_for_instruction)

func finish_waiting_for_instruction():
	has_received_execute_callback = true
	
	if not emitted_complete and delay_after <= 0:
		ParserEvents.instruction_completed.emit(execution_text, delay_after)
	
		emit_signal("set_input_lock", false)
		emit_signal("instruction_wrapped_completed")
		ParserEvents.instruction_completed_after_delay.emit(execution_text, delay_after)
		
		is_executing = false
		emitted_complete = true

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
		ParserEvents.instruction_started_after_delay.emit(execution_text, delay_before)
		#emit_signal("execute_instruction", execution_args)
		has_executed = true
		has_received_execute_callback = not execute(execution_text)
	
	if not has_received_execute_callback:
		return
	
	if delay_after > 0:
		delay_after -= delta
		if delay_after <= 0:
			ParserEvents.instruction_completed.emit(execution_text, delay_after)
			emitted_complete = true
		return
	elif not emitted_complete:
		ParserEvents.instruction_completed.emit(execution_text, delay_after)
	
	emit_signal("set_input_lock", false)
	emit_signal("instruction_wrapped_completed")
	ParserEvents.instruction_completed_after_delay.emit(execution_text, delay_after)
	
	is_executing = false

func _wrapper_execute(text : String, delay_before_seconds := 0.0, delay_after_seconds := 0.0):
	await get_tree().process_frame
	delay_after = delay_after_seconds
	delay_before = delay_before_seconds
	execution_text = text
	has_executed = false
	is_executing = true
	has_received_execute_callback = true
	emit_signal("set_input_lock", true)
	ParserEvents.instruction_started.emit(execution_text, delay_before)
	emitted_complete = false

func get_property_from_self_or_autoload(property:String):
	var autoload : String
	if "." in property:
		autoload = property.split(".")[0]
	
	var result
	if autoload:
		property = property.split(".")[1]
		result = get_tree().root.get_node(autoload).get(property)
	else:
		result = get(property)
	
	return result

## Calls a function in itself with the signalute of [param text].[br]
## If [param call_mode] is Call, [signal ParserEvents.function_called] will be emitted. A [param call_position] of -1 means it was called by an instruction line. Positive integers are the text indices for inline calls using the [code]<call:>[/code] tag.[br][br]
## CallMode Func returns the string representation of the return value. This is used internally for [code]<func:>[/code] tags.
func call_from_string(text:String, call_mode := CallMode.Call, call_position := -1):
	var func_name = text.split("(")[0]
	var autoload : String
	if "." in func_name:
		autoload = func_name.split(".")[0]
	text = text.trim_prefix(str(func_name, "("))
	text = text.trim_suffix(")")
	var parts
	if text.is_empty():
		parts = []
	else:
		parts = text.split(",")
	
	var args := []
	var i := 0
	var arg_names : Array = Pages.get_custom_method_arg_names(func_name)
	var arg_types : Array = Pages.get_custom_method_types(func_name)
	for type in arg_types:
		if i >= parts.size():
			break
		var arg_string : String = parts[i]
		while arg_string.begins_with(" "):
			arg_string = arg_string.trim_prefix(" ")
		while arg_string.ends_with(" "):
			arg_string = arg_string.trim_suffix(" ")
		var default = Parser.get_custom_method_defaults(func_name).get(arg_names[i])
		if arg_string == "*" and default != null:
			arg_string = str(default)
		args.append(Parser.str_to_typed(arg_string, type))
		
		i += 1
	
	var result
	if autoload:
		func_name = func_name.split(".")[1]
		get_tree().root.get_node(autoload).callv(func_name, args)
	else:
		result = callv(func_name, args)
	match call_mode:
		CallMode.Func:
			return str(result)
		CallMode.Call:
			ParserEvents.function_called.emit(func_name, args, call_position)
			return result

func execute(instruction_text: String) -> bool:
	var instruction_name := instruction_text.split("(")[0]
	if (not has_method(instruction_name)) and (not "." in instruction_name):
		push_error(str("Function ", instruction_name, " not found in ", get_script().get_global_name(),"."))
		return false
	var result = call_from_string(instruction_text)
	if not result is bool:
		push_warning(str("Function ", instruction_name, " in ", get_script().get_global_name(), " should return true or false."))
		return false
	return result
