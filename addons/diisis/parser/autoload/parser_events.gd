@tool
extends Node
class_name DiisisParserEvents


## Emitted when a choice button has been pressed.
signal choice_pressed(
	do_jump_page:bool,
	target_page:int,
	target_line:int,
	set_loopback:bool,
	loopback_trigger_page:int,
	loopback_trigger_line:int,
	choice_text:String
)

## [param choices] is an [Array] where every item is
## [codeblock]
## {
##    "button": Button,
##    "disabled": bool,
##    "option_text": String,
##    "facts": Dictionary,
##    "do_jump_page": bool,
##    "target_page": int,
##    "target_line": int,
##}
## [/codeblock]
## [param facts] is a [Dictionary] where every key is a String representing a fact
## and the value of the fact if the choice is pressed.
signal choices_presented(
	choices:Array[Dictionary]
)

## [param actor_name] is the internal name of the actor.
signal dialog_line_args_passed(
	actor_name: String,
	dialog_line_args: Dictionary
)

## Emitted when a fact changes its value. During initialization, this will emit with [param old_value] being equal to [param new_value].
signal fact_changed(
	fact_name:String,
	old_value:bool,
	new_value:bool,
)

## Emitted when a new line of dialog is read. Passes the actual string that ends up in [member LineReader.name_label].[br]
## See [signal actor_name_changed].
signal display_name_changed(
	display_name:String,
	is_name_visible: bool
)

## Emitted when a new line of dialog is read. Passes the internal key of the actor.[br]
## This will be identical to the [param display_name] in [signal display_name_changed] if no name map override has been set.)[br]
## See [signal display_name_changed].
signal actor_name_changed(
	actor_name: String,
	is_name_visible: bool
)


## [param header] is an [Array] where every item is
## [codeblock]
## {
##    "data_type": int,
##    "property_name": String,
##    "values": Array of size 2}
##[/codeblock]
signal new_header(
	header:Array[Dictionary]
)

signal page_finished(
	page_index: int
)

signal read_new_page(
	number:int
)

signal page_terminated(
	page_index: int
)

## Emitted when the text of [LineReader] changes.
## Emitts the the entire text, irregardless of [param visible_characters].
## [param lead_time] is the time until the text will start showing, in seconds.
signal text_content_text_changed(
	old_text: String,
	new_text: String,
	lead_time: float,
)

## Emitted when [LineReader] has finished displaying an entire word to its text box.
signal word_read(
	word: String
)

## Emitted whenever [LineReader] advances text enough for one or more new characters to be visible in [member LineReader.text_content].
signal visible_characters_changed(
	old_amount:int,
	new_amount:int,
)

## Emitted when [InstructionHandler] receives an instruction.
## This will be on the same frame as [signal instruction_started_after_delay] if [param delay]
## is [code] 0.0[/code].
signal instruction_started(
	instruction_name : String,
	args : Array,
	delay : float,
)

## Emitted when [InstructionHandler] executes an instruction, [param delay] seconds after [signal instruction_started].
signal instruction_started_after_delay(
	instruction_name : String,
	args : Array,
	delay : float,
)

## Emitted when the instruction gets completed. Will be emitted on the same
## frame as [signal instruction_started] and [signal instruction_started_after_delay]
## if the instruction in question doesn't return [code]true[/code].[br]
##[param delay] is the time in seconds until [signal instruction_completed_after_delay] gets emitted.
signal instruction_completed(
	instruction_name : String,
	args : Array,
	delay : float,
)


## Emitted when the instruction gets completed, [param delay] seconds after [signal instruction_completed] is emitted.
## This will be on the same frame if [param delay] is [code]0.0[/code].
signal instruction_completed_after_delay(
	instruction_name : String,
	args : Array,
	delay : float,
)

## Emitted when the Parser is put into or out of pause with [method Parser.set_paused]. [param is_paused] is the new state.
signal parser_paused_changed(
	is_paused:bool
)

signal line_reader_interrupted(
	line_reader:LineReader
)

signal line_reader_resumed_after_interrupt(
	line_reader:LineReader
)

## Emitted when [member LineReader.text_content] reaches a [param visible_ratio] of [code]1.0[/code].
## Not emitted if [member LineReader.text_speed] is [LineReader.MAX_TEXT_SPEED].
signal text_content_filled()

signal text_content_visible_characters_changed(
	visible_characters:int
)
signal text_content_visible_ratio_changed(
	visible_ratio:float
)
