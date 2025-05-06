@tool
extends Node
class_name DiisisParserEvents
## A helper autoload that provides hooks into DIISIS.
##
## Connect your custom stuff to these events to react when DIISIS reaches new states, encounters issues, or generally does anything.
##
## @tutorial(GitHub wiki tutorial): https://github.com/SnekOfSpice/dialog-editor/wiki/Using-Event-Signals


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
##    "values": Array of size 2
## }
##[/codeblock]
signal new_header(
	header:Array[Dictionary]
)

## Emitted when a page is finished. Is emitted before [signal page_terminated].
signal page_finished(
	page_index: int
)

## Emitted when a new page is read.
signal read_new_page(
	number:int
)

## Emitted when a page is finished when it was set to terminate. Is emitted after [signal page_finished].
signal page_terminated(
	page_index: int
)

## Emitted when the text of [LineReader] changes.
## Emitts the the entire text, irregardless of [param visible_characters].
## [param lead_time] is the time until the text will start showing, in seconds.
signal body_label_text_changed(
	old_text: String,
	new_text: String,
	lead_time: float,
)

## Emitted at the start of each line chunk getting read. Contains all string positions
## that were marked with a [code]<strpos>[/code] tag.
signal notify_string_positions(
	positions: Array
)

## Emitted when a function is called by the [LineReader] that was marked with a [code]<call:>[/code] tag.
signal function_called(
	method_name: String,
	arguments: Array,
	at_index: int
)

signal comment(
	comment:String,
	at_index: int
)

## Emitted when [LineReader] has finished displaying an entire word to its text box. See [member LineReader.non_word_characters].
signal word_read(
	word: String
)

## Emitted whenever [LineReader] advances text enough for one or more new characters to be visible in [member LineReader.body_label].
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

## Emitted when [member LineReader.body_label] reaches a [param visible_ratio] of [code]1.0[/code].
## Not emitted if [member LineReader.text_speed] is equal to [constant LineReader.MAX_TEXT_SPEED].
signal body_label_filled()

## Emitted when [member LineReader.body_label.visible_characters] is different from its value in the previous frame.
## Not emitted if [member LineReader.text_speed] is equal to [constant LineReader.MAX_TEXT_SPEED].
signal body_label_visible_characters_changed(
	visible_characters:int
)

## Emitted when [member LineReader.body_label.visible_ratio] is different from its value in the previous frame.
## Not emitted if [member LineReader.text_speed] is equal to [constant LineReader.MAX_TEXT_SPEED].
signal body_label_visible_ratio_changed(
	visible_ratio:float
)

## Emitted when [method LineReader.request_go_back] fails. This can be because the trail of visited line indices is empty or because the line type of the would-be previous line is non-Text.
signal go_back_declined()

## Emitted when a new line is read because of a successful [method LineReader.request_go_back] call. [param page] and [param line] are the indices of the new line.[br]
## Note: Is not emitted when going back through chunks, such as when going back through individual lines inside of a single Text Line with dialog syntax.[br]
## 
## Going from displaying "More text!" to "Text!", this will emit:
## [codeblock]
## ---- Line ----
## []>narrator: Text!
## ---- Line ----
## []>narrator: More text!
## [/codeblock]
## 
## 
## Going from displaying "More text!" to "Text!", this will [b]not[/b] emit:
## [codeblock]
## ---- Line ----
## []>narrator: Text!
## []>narrator: More text!
## [/codeblock]
signal go_back_accepted(page:int, line:int)

signal read_new_line(line_index:int)

## Emitted when [LineReader] skips a line. A line is skipped when it's toggled off with the eye icon in the top left corner in DIISIS.
signal line_skipped()

## Emitted when [method LineReader.request_advance] successfully advances the [LineReader].
signal advanced()
