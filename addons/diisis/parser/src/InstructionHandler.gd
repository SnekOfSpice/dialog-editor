@tool
extends Node
class_name InstructionHandler

signal set_input_lock(value)
signal instruction_wrapped_completed()
## Emit this signal from within the node that inherits from [InstructionHandler] after return from
## [method InstructionHandler.execute] with [code]true[/code].
signal instruction_completed()
signal execute_instruction(args)

var delay_before := 0.0
var delay_after := 0.0
var execution_name := ""
var execution_args := {}
var is_executing := false
var has_executed := false
var has_received_execute_callback := false

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
		return
	
	emit_signal("set_input_lock", false)
	emit_signal("instruction_wrapped_completed")
	ParserEvents.instruction_completed_after_delay.emit(execution_name, execution_args, delay_after)

	
	is_executing = false

func _wrapper_execute(instruction_name : String, args : Dictionary, delay_before_seconds := 0.0, delay_after_seconds := 0.0):
	delay_after = delay_after_seconds
	delay_before = delay_before_seconds
	execution_name = instruction_name
	execution_args = args
	has_executed = false
	is_executing = true
	has_received_execute_callback = true
	emit_signal("set_input_lock", true)
	ParserEvents.instruction_started.emit(instruction_name, args, delay_before)

## Should return [code]false[/code] by default. Return [code]true[/code] for any
## instructions to make the [InstructionHandler] wait for [signal InstructionHandler.instruction_completed]
## to be emitted. (Has to emitted manually.) This is useful for instructions that don't have an instant effect, such as a fade to black or other animations.[br]
## Note that you have to handle what happens inside those suspended calls yourself, including pausing the [Parser] and [method LineReader.interrupt].[br]
## Exaple of how to write a minimal script that inherits from [InstructionHandler] and uses all of its functionality:
## [codeblock]
## extends InstructionHandler
## @export var icon:Sprite2D
##
## func execute(instruction_name, args) -> bool:
##    match instruction_name:
##        "show_character":
##            # However you want to do this in your project is up to you.
##            GameStage.set_character_visible(
##                args.get("character_name"),
##                bool(args.get("value"))
##            )
##        "rotate_icon":
##            rotate_icon()
##            return true
##    return false
##
## func rotate_icon():
##   var t = get_tree().create_tween()
##   t.tween_property(icon, "rotation_degrees", 360, 2.0)
##   await t.finished
##   instruction_completed.emit()
## [/codeblock]
func execute(instruction_name, args) -> bool:
	return false
