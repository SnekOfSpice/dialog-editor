@icon("res://addons/diisis/parser/style/reader_icon_Zeichenfläche 1.svg")
@tool
extends Control
class_name LineReader

## Text speed at which text will be shown instantly instead of gradually revealed.
const MAX_TEXT_SPEED := 201


enum ChoiceButtonFocusMode {
	## The first [ChoiceButton] of [member choice_button_container] will receive focus upon build. Items can be navigated and selected with keyboard UI inputs. Mouse can still be used.
	Keyboard,
	## No [ChoiceButton] will receive focus. An option has to be clicked to be selected.
	None
}

## Determines how the name of the currently speaking actor is displayed. All options
## respect [member name_map] and [member name_colors].
enum NameStyle {
	## The name will be displayed in [member name_label].
	NameLabel,
	## The name will be inserted in front of the text with a dividing hyphen. [member name_label] will be hidden.
	Prepend,
}

## Find an extensive tutorial on how to set up your [LineReader] on GitHub!
## @tutorial(Quick Start Guide): https://github.com/SnekOfSpice/dialog-editor/wiki/Quick-Start-Guide-%E2%80%90-LineReader-&-Parser

@export_group("UX")
@export_subgroup("Text Behavior")
## Speed at which characters are shown, in characters/second. Set to [constant MAX_TEXT_SPEED] for instant text instead.
@export_range(1.0, MAX_TEXT_SPEED, 1.0) var text_speed := 60.0
## The delay that <ap> tags imply, in seconds.
@export var auto_pause_duration := 0.2
## Disables input-based calls of [method advance].
## Instead, when hitting the end of a line or <mp> tag, LineReader
## will wait [param auto_continue_delay] seconds until continuing automatically.
@export var auto_continue := false:
	set(value):
		auto_continue = value
		notify_property_list_changed()
## If [member auto_continue] is [code]true[/code], this is the time before the line reader automatically continues, in seconds.
@export_range(0.1, 60.0, 0.1) var auto_continue_delay := 0.2
var _auto_continue_duration:= auto_continue_delay
## If [code]0[/code], [param text_content] will be filled as far as possible.
## Breaks will be caused by <lc> tags, 
## a file with [param Pages.use_dialog_syntax] enabled, and a
## new [Line] of type [member DIISIS.LineType.Text] being read.[br]
## If set to more than [code]0[/code], the text will additionally be split to
## ensure it never runs more than that amount of lines. [br]
## [b]Note:[/b] Resizing the [param text_content] after a Line has started to be read will
## throw this alignment off.
@export var max_text_line_count:=0
## If [code]true[/code], shows [param text_container] when choices are presented.
@export var show_text_during_choices := true
## If [code]true[/code], shows [param text_container] when instructions are being executed.
@export var show_text_during_instructions := false
## If [code]true[/code], the LineReader will add a copy of its text to [member past_text_container] whenever the text of [member text_content] is reset.
@export var keep_past_lines := false:
	set(value):
		keep_past_lines = value
		notify_property_list_changed()
		update_configuration_warnings()
@export var past_text_container : VBoxContainer:
	get:
		return past_text_container
	set(value):
		past_text_container = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
var auto_advance := false

@export_group("Text Display")
## The name of the dropdown property used for keying names. Usually something like "character"
@export_subgroup("Names")
@export
var property_for_name := ""
## If the newly speaking actor name is in this array, the name label will be hidden alltogether.
@export
var blank_names : Array[String] = []
## A String:String Dictionary. The keys are the actor names set in the options of [member property_for_name].
## The respective value is the name to be displayed in the [member name_label] or [member text_content], depending on [member name_style].
@export var name_map := {}
## A String:Color Dictionary. The keys are the actor names set in the options of [member property_for_name].
## The respective value is the color modulation applied to [member name_label] or bbcode color tag inserted around the name in [member text_content], depending on [member name_style].
@export var name_colors := {}
@export var name_style : NameStyle = NameStyle.NameLabel
var visible_prepend_offset := 0
@export_subgroup("Text Content")
## A prefix to add to all strings that are displayed in [member text_content]. Respects bbcode such as [code][center][/code].
@export var text_content_prefix := ""
## A suffix to add to all strings that are displayed in [member text_content]. Respects bbcode such as [code][/center][/code].
@export var text_content_suffix := ""

@export_group("Mandatory References")
## The Control holding [member choice_option_container]. Should have its [code]mouse_filter[/code] set to [code]Stop[/code] and [b]FullRect Layout[/b].
@export var choice_container:PanelContainer:
	get:
		return choice_container
	set(value):
		choice_container = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

## The Control used for enumerating options when they are presented. Should be [HBoxContainer], [VBoxContainer], or [GridContainer].
@export
var choice_option_container:Control:
	get:
		return choice_option_container
	set(value):
		choice_option_container = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

## The [RichTextLabel] used to display text as it gets read out. [member RichTextLabel.bbcode_enabled] will be set to [param true] by the [LineReader].
@export var text_content: RichTextLabel:
	get:
		return text_content
	set(value):
		text_content = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

## Any [Control] that is a parent of both nodes used for; [member name_label] and [member text_content].
@export var text_container: Control:
	get:
		return text_container
	set(value):
		text_container = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

## A [class Label] or [class RichTextLabel] that displays a currently speaking character's name.
@export
var name_label: Control:
	get:
		return name_label
	set(value):
		name_label = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

## The Control holding [member name_label]. Has its visiblity toggled by [member blank_names]. May be the same Node as [member name_label].
@export
var name_container: Control:
	get:
		return name_container
	set(value):
		name_container = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

## Your custom handling of instructions defined in the dialog editor. Must extend [InstructionHandler].
@export
var instruction_handler: InstructionHandler:
	get:
		return instruction_handler
	set(value):
		instruction_handler = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

@export_group("Optional References")

## Node that has vars and funcs to evaluate in dynamic Strings. All functions within
## this node have to return a [String] (can be empty).
@export var inline_evaluator: Node

@export_group("Advanced UX")
@export_subgroup("Choices")
## If [code]false[/code], the [LineReader] can still be advanced with [method LineReader.advance], even if
## Choice Buttons are currently presented to the player.
@export var block_advance_during_choices:=true
#@export var give_focus_to_choice_button := false
@export var choice_button_focus_mode := ChoiceButtonFocusMode.None
## Button scene that gets instantiated as children of [member choice_option_container].[br]
## If left unassigned, will use a default button.[br]
## If overridden, it must inherit from [ChoiceButton].
@export var button_scene:ChoiceButton
@export var show_choice_title := false:
	set(value):
		show_choice_title = value
		notify_property_list_changed()
		update_configuration_warnings()
@export
var choice_title_label: Label:
	get:
		return choice_title_label
	set(value):
		choice_title_label = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

@export_subgroup("Input Prompt")
## If [code]true[/code], [LineReader] will fade in either [member prompt_unfinished] or [member prompt_finished] whenever the player can give input to advance.
## Both references have to be set, and cannot be the same node.
@export var show_input_prompt := false:
	set(value):
		show_input_prompt = value
		notify_property_list_changed()
		update_configuration_warnings()
## The delay until the target prompt ([member prompt_unfinished] or [member prompt_finished]) starts being faded in with [member input_prompt_lerp_weight].
@export_range(0.0, 10.0) var input_prompt_delay := 0.0
## The weight with which the [member modulate.a] of the target prompt ([member prompt_unfinished] or [member prompt_finished]) gets faded in. [code]1.0[/code] is instant.
@export_range(0.0, 1.0) var input_prompt_lerp_weight := 1.0
## The node that gets shown when the [LineReader] is awaiting input but is not at the end of the text yet. Usually because of [code]<mp>[/code] tags.
@export
var prompt_unfinished: Control:
	get:
		return prompt_unfinished
	set(value):
		prompt_unfinished = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
## The node that gets shown when advancing the [LineReader] will clear [LineReader.text_content].
@export
var prompt_finished: Control:
	get:
		return prompt_finished
	set(value):
		prompt_finished = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
var remaining_prompt_delay := input_prompt_delay

@export_group("Parser Event Configurations")
## List of characters that will not be part of the [code]read_word[/code] Parser event and instead be treated as spaces.
@export var non_word_characters := [
	".",
	",",
	"/",
	";",
	":",
	"_",
	"-",
	"?",
	"!",
	"~",
]

signal line_finished(line_index: int)
signal jump_to_page(page_index: int, target_line: int)
signal is_input_locked_changed(new_value: bool)

var line_data := {}
var line_type := 0
var line_index := 0
var remaining_auto_pause_duration := 0.0

var is_input_locked := false : set = set_is_input_locked
var showing_text := false
var using_dialog_syntax := false

var lead_time := 0.0
var next_pause_position_index := -1
var pause_positions := []
var pause_types := []
var call_strings := {}
var called_positions := []
var next_pause_type := 0
enum PauseTypes {Manual, Auto, EoL}
var dialog_lines := []
var dialog_actors := []
var dialog_line_index := 0
var is_last_actor_name_different := true

var line_chunks := []
var chunk_index := 0
var current_raw_name := ""
var current_choice_title := ""

var terminated := false

var started_word_buffer :=""
var characters_visible_so_far := ""

var last_visible_ratio := 0.0
var last_visible_characters := 0.0
var visibilities_before_interrupt := {}

var trimmable_strings := [" ", "\n", "<lc>", "<ap>", "<mp>",]

var reverse_next_instruction := false

signal line_reader_ready

func _validate_property(property: Dictionary):
	if not show_input_prompt:
		if property.name in ["input_prompt_delay", "input_prompt_lerp_weight", "prompt_finished", "prompt_unfinished"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	if not auto_continue:
		if property.name in ["auto_continue_delay"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	if not keep_past_lines:
		if property.name in ["past_text_container"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	if not show_choice_title:
		if property.name in ["choice_title_label"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR

func serialize() -> Dictionary:
	var result := {}
	
	result["line_data"] = line_data 
	result["line_index"] = line_index 
	result["line_type"] = line_type 
	result["remaining_auto_pause_duration"] = remaining_auto_pause_duration 
	result["is_input_locked"] = is_input_locked 
	result["showing_text"] = showing_text 
	result["using_dialog_syntax"] = using_dialog_syntax 
	result["next_pause_position_index"] = next_pause_position_index 
	result["pause_positions"] = pause_positions 
	result["pause_types"] = pause_types 
	result["next_pause_type"] = next_pause_type 
	result["dialog_lines"] = dialog_lines 
	result["dialog_actors"] = dialog_actors 
	result["dialog_line_index"] = dialog_line_index 
	result["line_chunks"] = line_chunks 
	result["chunk_index"] = chunk_index 
	result["terminated"] = terminated 
	result["text_content.text"] = text_content.text
	result["current_raw_name"] = current_raw_name
	result["is_last_actor_name_different"] = is_last_actor_name_different
	result["name_map"] = name_map
	result["called_positions"] = called_positions
	result["call_strings"] = call_strings
	result["current_choice_title"] = current_choice_title
	
	return result

func deserialize(data: Dictionary):
	if not data:
		return
	line_data = data.get("line_data", {})
	line_index = int(data.get("line_index", 0))
	line_type = int(data.get("line_type", DIISIS.LineType.Text))
	remaining_auto_pause_duration = data.get("remaining_auto_pause_duration")
	is_input_locked = data.get("is_input_locked")
	showing_text = data.get("showing_text")
	using_dialog_syntax = data.get("using_dialog_syntax")
	next_pause_position_index = int(data.get("next_pause_position_index"))
	pause_positions = data.get("pause_positions")
	pause_types = data.get("pause_types")
	next_pause_type = int(data.get("next_pause_type"))
	dialog_lines = data.get("dialog_lines")
	dialog_actors = data.get("dialog_actors")
	dialog_line_index = int(data.get("dialog_line_index"))
	line_chunks = data.get("line_chunks")
	chunk_index = int(data.get("chunk_index"))
	terminated = data.get("terminated")
	name_map = data.get("name_map", name_map)
	is_last_actor_name_different = data.get("is_last_actor_name_different", true)
	called_positions = data.get("called_positions", [])
	call_strings = data.get("call_strings", {})
	current_choice_title = data.get("current_choice_title", "")
	
	text_container.visible = can_text_container_be_visible()
	showing_text = line_type == DIISIS.LineType.Text
	choice_container.visible = line_type == DIISIS.LineType.Choice
	
	if line_type == DIISIS.LineType.Choice:
		var raw_content = line_data.get("content")
		var content = line_data.get("content").get("content")
		var choices = line_data.get("content").get("choices")
		var auto_switch : bool = raw_content.get("auto_switch")
		current_choice_title = raw_content.get("choice_title", "")

		build_choices(choices, auto_switch)
	
	update_name_label(data.get("current_raw_name", "" if blank_names.is_empty() else blank_names.front()))
	set_text_content_text(data.get("text_content.text", ""))
	

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	
	if not choice_container:
		warnings.append("Choice Container is null")
	if not choice_option_container:
		warnings.append("Choice Option Container is null")
	elif not (
			choice_option_container is HBoxContainer or 
			choice_option_container is VBoxContainer or 
			choice_option_container is GridContainer 
			):
			warnings.append("Choice Option Container is not HBoxContainer, VBoxContainer, or GridContainer")
	if not instruction_handler:
		warnings.append("Instruction Handler is null")
	if not text_content:
		warnings.append("Text Content is null")
	if not text_container:
		warnings.append("Text Container is null")
	if not name_label and name_style == NameStyle.NameLabel:
		warnings.append("Name Label is null")
	elif name_style == NameStyle.NameLabel and not (
			name_label is Label or  
			name_label is RichTextLabel
			):
			warnings.append("Name Label is not Label, or RichTextLabel")
	if not name_container and name_style == NameStyle.NameLabel:
		warnings.append("Name Container is null")
	if show_input_prompt and not prompt_unfinished:
		warnings.append("Prompt Unfinished is null")
	if show_input_prompt and not prompt_finished:
		warnings.append("Prompt Finished is null")
	if show_input_prompt and prompt_finished == prompt_unfinished and prompt_unfinished:
		warnings.append("Prompt Finished and Prompt Unfinished cannot be the same node.")
	if keep_past_lines and not past_text_container:
		warnings.append("Past Text Container is null")
	if show_choice_title and not choice_title_label:
		warnings.append("Choice Title Label is null")
	
	return warnings

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	Parser.connect("read_new_line", read_new_line)
	Parser.connect("page_terminated", close)
	
	ParserEvents.go_back_accepted.connect(lmao)
	
	ParserEvents.text_content_text_changed.connect(on_text_content_text_changed)
	ParserEvents.display_name_changed.connect(on_name_label_updated)
	
	Parser.open_connection(self)
	tree_exiting.connect(Parser.close_connection)
	
	remaining_auto_pause_duration = auto_pause_duration# * (1.0 + (1-(text_speed / (MAX_TEXT_SPEED - 1))))
	
	if not instruction_handler:
		push_error("No InsutrctionHandler as child of LineReader.")
		return
	
	instruction_handler.connect("set_input_lock", set_is_input_locked)
	instruction_handler.connect("instruction_wrapped_completed", instruction_completed)
	text_content.visible_ratio = 0
	text_content.bbcode_enabled = true
	text_content.text = ""
	name_label.text = ""
	
	if not show_input_prompt and prompt_unfinished:
		prompt_unfinished.modulate.a = 0
	if not show_input_prompt and prompt_finished:
		prompt_finished.modulate.a = 0
	
	emit_signal("line_reader_ready")

func lmao(a, b):
	reverse_next_instruction = true

## Gets the prefrences that are usually set by the user. Save this to disk and apply it again with [code]apply_preferences()[/code].
func get_preferences() -> Dictionary:
	var prefs = {}
	
	prefs["text_speed"] = text_speed
	prefs["auto_continue"] = auto_continue
	prefs["auto_continue_delay"] = auto_continue_delay
	
	return prefs

## Applies the preferences that are usually set by the user. Includes keys:\n[code]text_speed[/code] (float)\n[code]auto_continue[/code] (bool)\n[code]auto_continue_delay[/code] (float)
func apply_preferences(prefs:Dictionary):
	text_speed = prefs.get("text_speed", 60.0)
	auto_continue = prefs.get("auto_continue", false)
	auto_continue_delay = prefs.get("auto_continue_delay", 2.0)

## Advances the interpreting of lines from the input file if possible. Will push an appropriate warning if not possible.
func request_advance():
	if Parser.paused:
		push_warning("Cannot advance because Parser.paused is true.")
		return
	if is_input_locked:
		push_warning("Cannot advance because is_input_locked is true.")
		return
	if terminated:
		push_warning("Cannot advance because terminated is true.")
		return
	if auto_continue:
		push_warning("Cannot advance because auto_continue is true.")
		return
	if is_choice_presented() and block_advance_during_choices:
		push_warning("Cannot advance because is_choice_presented() and block_advance_during_choices is true.")
		return
	
	advance()

## Advances the reading of lines directly. Do not call this directly. Use [code]request_advance()[/code] instead.
func advance():
	if auto_continue:
		_auto_continue_duration = auto_continue_delay
	if showing_text:
		lead_time = 0.0
		if text_content.visible_ratio >= 1.0:
			if chunk_index >= line_chunks.size() - 1:
				if dialog_line_index >= dialog_lines.size() - 1:
					remaining_prompt_delay = input_prompt_delay
					emit_signal("line_finished", line_index)
				else:
					remaining_prompt_delay = input_prompt_delay
					set_dialog_line_index(dialog_line_index + 1)
			else:
				read_next_chunk()
		else:
			if next_pause_position_index < pause_positions.size():
				text_content.visible_characters = get_end_of_chunk_position() 
				if next_pause_type != PauseTypes.EoL:
					if next_pause_position_index < pause_positions.size() - 1:
						next_pause_position_index += 1
					find_next_pause()
					#remaining_auto_pause_duration = remaining_auto_pause_duration * (1.0 + (1-(text_speed / (MAX_TEXT_SPEED - 1))))
				remaining_prompt_delay = input_prompt_delay
	else:
		emit_signal("line_finished", line_index)

func go_back():
	if Parser.paused:
		push_warning("Cannot go back because Parser.paused is true.")
		return
	if is_input_locked:
		push_warning("Cannot go back because is_input_locked is true.")
		return
	if terminated:
		push_warning("Cannot go back because terminated is true.")
		return
	Parser.go_back()

## Pauses the Parser and hides all controls uif [param hide_controls] is [code]true[/code] (default). Useful for reacting to game events outside the line reader. [br]
## [b]Call [method continue_after_interrupt] afterwards to cleanly resume.[/b]
func interrupt(hide_controls:=true):
	ParserEvents.line_reader_interrupted.emit(self)
	Parser.set_paused(true)
	if hide_controls:
		for key in ["choice_container", "choice_option_container", "text_content", "text_container", "name_container", "name_label"]:
			visibilities_before_interrupt[key] = get(key).visible
			get(key).visible = false

## Call this after calling [method interrupt] to cleanly resume the reading of lines.[br]
## Takes in optional arguments to be passed to [Parser] upon continuing. If [param read_page] is [code]-1[/code] (default), the Parser will read exactly where it left off.
func continue_after_interrupt(read_page:=-1, read_line:=0):
	for key in ["choice_container", "choice_option_container", "text_content", "text_container", "name_container", "name_label"]:
		if not visibilities_before_interrupt.has(key):
			push_warning("Visibilities after interrupt have not been set")
		else:
			get(key).visible = visibilities_before_interrupt[key]
	
	if read_page != -1:
		Parser.read_page(read_page, read_line)
	Parser.set_paused(false)
	ParserEvents.line_reader_resumed_after_interrupt.emit(self)

func instruction_completed():
	emit_signal("line_finished", line_index)

func set_is_input_locked(value: bool):
	is_input_locked = value
	emit_signal("is_input_locked_changed", is_input_locked)

func close(_terminating_page):
	visible = false
	terminated = true

func read_new_line(new_line: Dictionary):
	line_data = new_line
	line_index = new_line.get("meta.line_index")
	line_type = int(line_data.get("line_type"))
	terminated = false
	ParserEvents.read_new_line.emit(line_index)
	
	var eval = evaluate_conditionals(line_data.get("conditionals"))
	var conditional_is_true = eval[0]
	var behavior = eval[1]
	
	var last_line_index:int
	if line_type == DIISIS.LineType.Folder:
		var range = line_data.get("content", {}).get("range", 0)
		last_line_index = line_index + range
	else:
		last_line_index = line_index
	
	if behavior == "Show" or behavior == "Enable":
		if not conditional_is_true:
			emit_signal("line_finished", last_line_index)
			return
	if behavior == "Hide" or behavior == "Disable":
		if conditional_is_true:
			emit_signal("line_finished", last_line_index)
			return
	
	handle_header(line_data.get("header"))
	
	var raw_content = line_data.get("content")
	var content = line_data.get("content").get("content")
	var content_address
	var choices
	if line_type == DIISIS.LineType.Choice:
		choices = line_data.get("content").get("choices")
	var content_name = line_data.get("content").get("name")
	
	for key in ["choice_container", "choice_option_container", "text_content", "text_container", "name_container", "name_label"]:
		get(key).visible = true
	text_container.visible = can_text_container_be_visible()
	showing_text = line_type == DIISIS.LineType.Text
	choice_container.visible = line_type == DIISIS.LineType.Choice
	
	# register facts
	var facts = line_data.get("facts", {}).get("fact_data_by_name", {})
	
	for f in facts.values():
		Parser.change_fact(f)
	
	if not show_input_prompt and prompt_unfinished:
		prompt_unfinished.modulate.a = 0
	if not show_input_prompt and prompt_finished:
		prompt_finished.modulate.a = 0
	
	match line_type:
		DIISIS.LineType.Text:
			var localized : String = Parser.replace_from_locale(line_data.get("address"), Parser.locale)
			if not localized.is_empty():
				content = localized
			if str(content).is_empty():
				emit_signal("line_finished", line_index)
				return
			
			if Parser.use_dialog_syntax:
				var lines = content.split("[]>")
				dialog_actors.clear()
				dialog_lines.clear()
				for l : String in lines:
					if l.is_empty():
						continue
					
					var actor_name = l.split(":")[0]
					dialog_actors.append(actor_name)
					var line : String = l.trim_prefix(str(actor_name, ":"))
					while line.begins_with(" "):
						line = line.trim_prefix(" ")
					dialog_lines.append(line)
			else:
				dialog_lines = [content]
				dialog_actors.clear()
				dialog_actors = [""]
			
			dialog_lines = replace_tags(dialog_lines)
			
			
			set_dialog_line_index(0)
		DIISIS.LineType.Choice:
			var auto_switch : bool = raw_content.get("auto_switch")
			current_choice_title = raw_content.get("choice_title")
			build_choices(choices, auto_switch)
		DIISIS.LineType.Instruction:
			if not instruction_handler:
				push_error("No InsutrctionHandler as child of LineReader.")
				return
			if not instruction_handler.has_method("execute"):
				push_error("InsutrctionHandler doesn't have execute method.")
				return
			
			var instruction_name: String
			var args: Array
			var delay_before: float
			var delay_after: float
			
			var instruction_content : Dictionary = line_data.get("content")
			if reverse_next_instruction and not instruction_content.get("meta.has_reverse"):
				reverse_next_instruction = false
				remaining_prompt_delay = input_prompt_delay
				return
			
			if not reverse_next_instruction:
				instruction_name = instruction_content.get("name")
			else:
				instruction_name = instruction_content.get("reverse_name", "")
			
			if (not reverse_next_instruction) or instruction_name.is_empty():
				args = instruction_content.get("line_reader.args")
				
				instruction_name = instruction_content.get("name")
				delay_before = new_line.get("content").get("delay_before")
				delay_after = new_line.get("content").get("delay_after")
			else:
				
				args = instruction_content.get("line_reader.reverse_args")
				delay_before = 0.0
				delay_after = 0.0
			
			if reverse_next_instruction:
				#instruction_handler.execute(instruction_name, args)
				#reverse_next_instruction = false
				remaining_prompt_delay = input_prompt_delay
				
				return
			instruction_handler._wrapper_execute(instruction_name, args, delay_before, delay_after)
		DIISIS.LineType.Folder:
			if not line_data.get("content", {}).get("meta.contents_visible", true):
				push_warning(str("Line ", line_index, " was an invisible folder. It will get read regardless."))
			emit_signal("line_finished", line_index)
	
	remaining_prompt_delay = input_prompt_delay
	
	reverse_next_instruction = false

func fit_to_max_line_count(lines: Array):
	if max_text_line_count <= 0:
		return
	
	var new_chunks := []
	var label : RichTextLabel = RichTextLabel.new()
	add_child(label)
	label.visible = false
	label.bbcode_enabled = true
	label.theme = text_content.get_theme()
	label.size = text_content.size
	
	var i := 0
	while i < lines.size():
		
		var line_height:=0
		var content_height := 0
		
		var name_prefix:String
		var name_length:int
		if name_style == NameStyle.Prepend:
			var display_name: String = name_map.get(dialog_actors[dialog_line_index], dialog_actors[dialog_line_index])
			display_name = display_name.substr(0, display_name.find("{"))
			var name_color :Color = name_colors.get(dialog_actors[dialog_line_index], Color.WHITE)
			name_prefix = str(
			"[color=", name_color.to_html(), "]",
			display_name, "[/color] - ")
			name_length = display_name.length() + 3
		elif name_style == NameStyle.NameLabel:
			name_prefix = ""
			name_length = 0
		
		var line:String = lines[i]
		label.text = line
		label.visible_characters = 1
		if line_height == 0:
			line_height = label.get_content_height()
		
		label.text = str(text_content_prefix, name_prefix, line, text_content_suffix)
		
		while content_height <= line_height * max_text_line_count:
			if label.text.is_empty():
				break
			label.visible_characters += 1
			content_height = label.get_content_height()
			if content_height > line_height * max_text_line_count:
				label.text = label.text.trim_prefix(name_prefix)
				label.visible_characters -= 1
				label.visible_characters -= name_length
				while label.text[label.visible_characters] != " ":
					label.visible_characters -= 1
				label.bbcode_enabled = false
				var bbcode_padding := 0
				var scan_index := 0
				while scan_index < label.visible_characters:
					scan_index += 1
					if label.text[scan_index] == "[":
						if label.text[scan_index-1] == "\\[":
							scan_index += 1
							continue
						var tag_end = label.text.find("]", scan_index)
						bbcode_padding += tag_end - scan_index + 2
				
				
				var fitting_raw_text := label.text.substr(0, label.visible_characters + bbcode_padding)
				line = line.trim_prefix(fitting_raw_text)
				label.text = line
				new_chunks.append(fitting_raw_text)
				label.bbcode_enabled = true
				content_height = 0
				label.visible_characters = 0
				continue
			
			if label.visible_ratio == 1.0:
				new_chunks.append(line)
				break
			
		i += 1
	line_chunks = new_chunks
	label.queue_free()


func get_end_of_chunk_position() -> int:
	if pause_positions.size() == 0:
		return text_content.text.length()
	elif pause_types[next_pause_position_index] == PauseTypes.EoL:
		return text_content.text.length()
	else:
		return pause_positions[next_pause_position_index] - 4 * next_pause_position_index# - prepend_offset

func _process(delta: float) -> void:
	# this is a @tool script so this prevents the console from getting flooded
	if Engine.is_editor_hint():
		return
	
	if Parser.paused:
		return
	
	update_input_prompt(delta)
	
	if lead_time > 0:
		lead_time -= delta
		return
	
	if next_pause_position_index < pause_positions.size() and next_pause_position_index != -1:
		find_next_pause()
	if text_content.visible_characters < get_end_of_chunk_position():
		if text_speed == MAX_TEXT_SPEED:
			text_content.visible_characters = get_end_of_chunk_position()
		else:
			var old_text_length : int = text_content.visible_characters
			text_content.visible_ratio += (float(text_speed) / text_content.get_parsed_text().length()) * delta
			# fast text speed can make it go over the end  of the chunk
			text_content.visible_characters = min(text_content.visible_characters, get_end_of_chunk_position())
			if old_text_length != text_content.visible_characters:
				ParserEvents.visible_characters_changed.emit(old_text_length, text_content.visible_characters)
	elif remaining_auto_pause_duration > 0 and next_pause_type == PauseTypes.Auto:
		var last_dur = remaining_auto_pause_duration
		remaining_auto_pause_duration -= delta
		if last_dur > 0 and remaining_auto_pause_duration <= 0:
			next_pause_position_index += 1
			find_next_pause()
			remaining_auto_pause_duration = auto_pause_duration# * (1.0 + (1-(text_speed / (MAX_TEXT_SPEED - 1))))
	
	
	
	var new_characters_visible_so_far = text_content.text.substr(0, text_content.visible_characters)
	var new_characters : String = new_characters_visible_so_far.trim_prefix(characters_visible_so_far)
	if " " in new_characters:
		var split_new_characters : Array = new_characters.split(" ")
		for s in split_new_characters:
			s = remove_symbols(s)
		started_word_buffer += split_new_characters[0]
		remove_spaces_and_send_word_read_event(remove_symbols(started_word_buffer))
		var i = 1
		while i < split_new_characters.size() - 1:
			remove_spaces_and_send_word_read_event(remove_symbols(split_new_characters[i]))
			i += 1
		started_word_buffer = split_new_characters.back()
	else:
		started_word_buffer += new_characters
		if text_content.text.ends_with(started_word_buffer):
			if not started_word_buffer.is_empty():
				remove_spaces_and_send_word_read_event(remove_symbols(started_word_buffer))
				started_word_buffer = ""
	characters_visible_so_far = new_characters_visible_so_far
	
	if text_speed < MAX_TEXT_SPEED:
		if last_visible_ratio < 1.0 and text_content.visible_ratio >= 1.0:
			ParserEvents.text_content_filled.emit()
		if last_visible_ratio != text_content.visible_ratio:
			ParserEvents.text_content_visible_ratio_changed.emit(text_content.visible_ratio)
		if last_visible_characters != text_content.visible_characters:
			ParserEvents.text_content_visible_characters_changed.emit(text_content.visible_characters)
	
	for call_position : int in call_strings:
		if (
			((not called_positions.has(call_position)) and last_visible_characters >= call_position) or
			(call_position >= last_visible_characters and call_position <= text_content.visible_characters) or
			text_content.visible_characters == -1
		):
			call_from_position(call_position)
	
	last_visible_ratio = text_content.visible_ratio
	last_visible_characters = text_content.visible_characters
	
	if last_visible_characters == -1 and auto_advance:
		advance()
		auto_advance = false
		return
	
	if auto_continue:
		if not line_type == DIISIS.LineType.Text:
			return
		if pause_types.is_empty() or next_pause_position_index < 0:
			return
		if pause_types[next_pause_position_index] == PauseTypes.Auto:
			# bug here
			return
#			remaining_auto_pause_duration -= delta
#			if remaining_auto_pause_duration > 0:
#				return
#			else:
#				remaining_auto_pause_duration = auto_pause_duration
#				advance()
#				return
#		prints("auto pause dir ", remaining_auto_pause_duration)
#		prints(
#			"vis", text_content.visible_characters, 
#			"pause at", pause_positions[next_pause_position_index] - 4 * next_pause_position_index,
#			"length", text_content.text.length()
#			)
		if text_content.visible_characters >= pause_positions[next_pause_position_index] - 4 * next_pause_position_index or text_content.visible_characters == -1:
			_auto_continue_duration -= delta
			if _auto_continue_duration <= 0.0:
				
				advance()

func remove_spaces_and_send_word_read_event(word: String):
	word = word.replace(" ", "")
	ParserEvents.word_read.emit(word)

func remove_symbols(from: String, symbols:=non_word_characters) -> String:
	var s = from
	
	for c in symbols:
		s = s.replace(c, " ")
	
	return s

func update_input_prompt(delta:float):
	if (not show_input_prompt) or auto_continue:
		if prompt_finished:
			prompt_finished.visible = false
		if prompt_unfinished:
			prompt_unfinished.visible = false
		return
	
	var prompt_visible: bool

	if text_content.visible_ratio >= 1.0:
		prompt_visible = true
	elif next_pause_position_index > pause_positions.size() and next_pause_position_index != -1:
		prompt_visible = true
	elif pause_positions.size() > 0 and next_pause_type == PauseTypes.Manual:
		if text_content.visible_characters == pause_positions[next_pause_position_index] - 4 * next_pause_position_index:
			prompt_visible = true
		else:
			prompt_visible = false
	else:
		prompt_visible = false
	
	if text_content.visible_characters < get_end_of_chunk_position():
		prompt_visible = false
		if text_content.visible_characters == -1:
			prompt_visible = true
	
	if is_input_locked:
		prompt_visible = false
	if not prompt_visible:
		prompt_unfinished.modulate.a = 0
		prompt_finished.modulate.a = 0
		return
	else:
		if remaining_prompt_delay > 0.0:
			remaining_prompt_delay -= delta
			return
	
	# Order of operations is important. since both prompts may be the same node, we want to ensure something is visible if appropriate.
	var target_prompt:Control
	if text_content.visible_ratio >= 1.0:
		target_prompt = prompt_finished
		prompt_unfinished.visible = false
		prompt_finished.visible = true
	else:
		target_prompt = prompt_unfinished
		prompt_finished.visible = false
		prompt_unfinished.visible = true
	
	target_prompt.modulate.a = lerp(target_prompt.modulate.a, 1.0, input_prompt_lerp_weight)


func start_showing_text():
	var content : String = dialog_lines[dialog_line_index]
	line_chunks = content.split("<lc>")
	chunk_index = -1
	fit_to_max_line_count(line_chunks)
	read_next_chunk()

func replace_tags(lines):
	if not inline_evaluator:
		push_warning("No InlineEvaluator has been set. Calls to <var:>, <func:>, <name:>, <call:>, and <fact:> won't be parsed.")
		return lines
	var i := 0
	var result := []
	while i < lines.size():
		var new_text:String = lines[i]
		var scan_index := 0
		var text_length := new_text.length()
		while scan_index < text_length:
			if new_text[scan_index] == "<":
				if new_text.find("<var:", scan_index) == scan_index:
					var local_scan_index := scan_index
					var control_to_replace := ""
					var var_name := ""
					var start_reading_var_name := false
					while new_text[local_scan_index] != ">":
						control_to_replace += new_text[local_scan_index]
						if start_reading_var_name:
							var_name += new_text[local_scan_index]
						if new_text[local_scan_index] == ":":
							start_reading_var_name = true
						local_scan_index += 1
					var_name = var_name.trim_suffix(">")
					control_to_replace += ">"
					new_text = new_text.replace(control_to_replace, str(inline_evaluator.get(var_name)))
				elif new_text.find("<func:", scan_index) == scan_index:
					var local_scan_index := scan_index
					var control_to_replace := ""
					var func_name := ""
					var start_reading_func_name := false
					while new_text[local_scan_index] != ">":
						if new_text[local_scan_index] == ",":
							start_reading_func_name = false
						control_to_replace += new_text[local_scan_index]
						if start_reading_func_name:
							func_name += new_text[local_scan_index]
						if new_text[local_scan_index] == ":":
							start_reading_func_name = true
						
						local_scan_index += 1
					#func_name = func_name.trim_suffix(">")
					control_to_replace += ">"
					
					var control_prepared_for_split = control_to_replace.trim_prefix(str("<func:", func_name))
					control_prepared_for_split = control_prepared_for_split.trim_suffix(">")
					var packed_func_args := control_prepared_for_split.split(",")
					var func_args = []
					for a in packed_func_args:
						if not a.is_empty():
							func_args.append(a)
					if inline_evaluator.has_method(func_name):
						new_text = new_text.replace(control_to_replace, str(inline_evaluator.callv(func_name, func_args)))
					else:
						push_warning(str(func_name, " doesn't exist in inline_evaluator."))
				elif new_text.find("<name:", scan_index) == scan_index:
					var local_scan_index := scan_index
					var control_to_replace := ""
					var name_key := ""
					var start_reading_name_key := false
					while new_text[local_scan_index] != ">":
						control_to_replace += new_text[local_scan_index]
						if start_reading_name_key:
							name_key += new_text[local_scan_index]
						if new_text[local_scan_index] == ":":
							start_reading_name_key = true
						local_scan_index += 1
					name_key = name_key.trim_suffix(">")
					control_to_replace += ">"
					new_text = new_text.replace(control_to_replace,name_map.get(name_key, name_key))
				elif new_text.find("<fact:", scan_index) == scan_index:
					var local_scan_index := scan_index
					var control_to_replace := ""
					var fact_name := ""
					var start_reading_var_name := false
					while new_text[local_scan_index] != ">":
						control_to_replace += new_text[local_scan_index]
						if start_reading_var_name:
							fact_name += new_text[local_scan_index]
						if new_text[local_scan_index] == ":":
							start_reading_var_name = true
						local_scan_index += 1
					fact_name = fact_name.trim_suffix(">")
					control_to_replace += ">"
					new_text = new_text.replace(control_to_replace, str(Parser.get_fact(fact_name)))
				
			
			text_length = new_text.length()
			scan_index += 1
		result.append(new_text)
		i += 1
	return result

# returns if it can go back
func _attempt_read_previous_chunk() -> bool:
	var chunk_failure := false
	var dialog_line_failure := false
	if chunk_index <= 0:
		chunk_failure = true
	
	if chunk_failure:
		if dialog_line_index <= 0:
			dialog_line_failure = true
		else:
			set_dialog_line_index(dialog_line_index - 1)
			return true
	else:
		chunk_index -= 2
		read_next_chunk()
		return true
	
	if chunk_failure and dialog_line_failure:
		return false
	

	
	return true

func read_next_chunk():
	remaining_prompt_delay = input_prompt_delay
	chunk_index += 1
	if text_speed == MAX_TEXT_SPEED:
		text_content.visible_ratio = 1.0
	else:
		text_content.visible_characters = visible_prepend_offset
	
	pause_positions.clear()
	pause_types.clear()
	call_strings.clear()
	called_positions.clear()
	
	var new_text : String = line_chunks[chunk_index]
	var begins_trimmable := begins_with_trimmable(new_text)
	while begins_trimmable:
		for t in trimmable_strings:
			new_text = new_text.trim_prefix(t)
		begins_trimmable = begins_with_trimmable(new_text)
		
	var ends_trimmable := ends_with_trimmable(new_text)
	while ends_trimmable:
		for t in trimmable_strings:
			new_text = new_text.trim_suffix(t)
		ends_trimmable = ends_with_trimmable(new_text)
	
	if new_text.contains("<advance>") and not new_text.ends_with("<advance>"):
		push_warning(str("Line chunk \"", new_text, "\" contains an <advance> tag that is not at the end of the chunk."))
	auto_advance = new_text.ends_with("<advance>")
	new_text = new_text.trim_suffix("<advance>")
	
	new_text = str(text_content_prefix, new_text, text_content_suffix)
	
	var bbcode_removed_text := new_text
	var tag_start_position = bbcode_removed_text.find("[")
	var last_tag_start_position = tag_start_position
	var tag_end_position = bbcode_removed_text.find("]", tag_start_position)
	while tag_start_position != -1 and tag_end_position != -1:
		if tag_start_position > 0:
			if bbcode_removed_text[tag_start_position - 1] == "\\":
				bbcode_removed_text = bbcode_removed_text.erase(tag_start_position - 1)
				last_tag_start_position = tag_start_position + 1
				tag_start_position = bbcode_removed_text.find("[", tag_start_position + 1)
				tag_end_position = bbcode_removed_text.find("]", tag_start_position + 1)
				continue
		bbcode_removed_text = bbcode_removed_text.erase(tag_start_position, tag_end_position - tag_start_position + 1)
		last_tag_start_position = tag_start_position
		tag_start_position = bbcode_removed_text.find("[", last_tag_start_position)
		tag_end_position = bbcode_removed_text.find("]", tag_start_position)
	
	var scan_index := 0
	var notify_positions := []
	var tag_buffer := 0
	var target_length := bbcode_removed_text.length()
	while scan_index < target_length:
		if bbcode_removed_text[scan_index] == "<":
			if bbcode_removed_text.find("<strpos>", scan_index) == scan_index:
				notify_positions.append(scan_index - tag_buffer)
				bbcode_removed_text = bbcode_removed_text.erase(scan_index, "<strpos>".length())
				scan_index = max(scan_index - "<strpos>".length(), 0)
				target_length -= "<strpos>".length()
				tag_buffer += "<strpos>".length()
			elif bbcode_removed_text.find("<mp>", scan_index) == scan_index:
				tag_buffer += 4
			elif bbcode_removed_text.find("<ap>", scan_index) == scan_index:
				tag_buffer += 4
			elif bbcode_removed_text.find("<call:", scan_index) == scan_index:
				var tag_length := bbcode_removed_text.find(">", scan_index) - scan_index + 1
				var tag_string := bbcode_removed_text.substr(scan_index, tag_length)
				bbcode_removed_text = bbcode_removed_text.erase(scan_index, tag_length)
				call_strings[scan_index] = tag_string
				scan_index = max(scan_index - tag_string.length(), 0)
				target_length -= tag_string.length()
				tag_buffer += tag_string.length()
			
		scan_index += 1
	
	scan_index = 0
	while scan_index < bbcode_removed_text.length():
		if bbcode_removed_text[scan_index] == "<":
			if bbcode_removed_text.find("<mp>", scan_index) == scan_index:
				if not pause_positions.has(scan_index):
					pause_positions.append(scan_index)
					pause_types.append(PauseTypes.Manual)
			elif bbcode_removed_text.find("<ap>", scan_index) == scan_index:
				if not pause_positions.has(scan_index):
					pause_positions.append(scan_index)
					pause_types.append(PauseTypes.Auto)
				
		scan_index += 1
	
	pause_positions.append(bbcode_removed_text.length()-1)
	pause_types.append(PauseTypes.EoL)
	
	next_pause_position_index = 0
	find_next_pause()
	
	var cleaned_text : String = new_text
	cleaned_text = cleaned_text.replace("<mp>", "")
	cleaned_text = cleaned_text.replace("<ap>", "")
	cleaned_text = cleaned_text.replace("<strpos>", "")
	cleaned_text = cleaned_text.replace("\\[", "[")
	for call : String in call_strings.values():
		cleaned_text = cleaned_text.replace(call, "")
	
	if is_last_actor_name_different:
		lead_time = Parser.text_lead_time_other_actor
	else:
		lead_time = Parser.text_lead_time_same_actor
	
	visible_prepend_offset = 0
	if name_style == NameStyle.Prepend:
		name_container.modulate.a = 0.0
		var display_name: String = name_map.get(current_raw_name, current_raw_name)
		var name_color :Color = name_colors.get(current_raw_name, Color.WHITE)
		cleaned_text = str(
			"[color=", name_color.to_html(), "]",
			display_name, "[/color] - ",
			cleaned_text
			)
		
		var name_prepend_length := 3 + display_name.length()
		visible_prepend_offset = name_prepend_length
		var first_tag_position = cleaned_text.find("[", pause_positions[0])
		var l := 0
		while l < pause_positions.size():
			pause_positions[l] = pause_positions[l] + name_prepend_length
			l += 1
	
	ParserEvents.notify_string_positions.emit(notify_positions)
	ParserEvents.text_content_text_changed.emit(text_content.text, cleaned_text, lead_time)
	set_text_content_text(cleaned_text)

func begins_with_trimmable(text:String) -> bool:
	for t in trimmable_strings:
		if text.begins_with(t):
			return true
	return false
func ends_with_trimmable(text:String) -> bool:
	for t in trimmable_strings:
		if text.ends_with(t):
			return true
	return false

func call_from_position(call_position: int):
	var text : String = call_strings.get(call_position)
	called_positions.append(call_position)
	text = text.trim_prefix("<call:")
	text = text.trim_suffix(">")
	var parts := text.split(",")
	var func_name = parts[0]
	parts.remove_at(0)
	inline_evaluator.callv(func_name, Array(parts))
	ParserEvents.function_called.emit(func_name, Array(parts), call_position)
	call_strings.erase(call_position)

func set_text_content_text(text: String):
	if keep_past_lines:
		var past_line = RichTextLabel.new()
		past_line.text = text_content.text
		past_text_container.add_child(past_line)
		past_line.custom_minimum_size.x = text_content.custom_minimum_size.x
		past_line.fit_content = true
		past_line.bbcode_enabled = true
	
	text_content.text = text
	text_content.visible_characters = visible_prepend_offset
	characters_visible_so_far = ""
	started_word_buffer = ""

func find_next_pause():
	if pause_types.size() > 0 and next_pause_position_index < pause_types.size():
		next_pause_type = pause_types[next_pause_position_index]

func get_actor_name(actor_key:String):
	return name_map.get(actor_key, "")

func set_actor_name(actor_key:String, actor_name:String):
	name_map[actor_key] = actor_name

func build_choices(choices, auto_switch:bool):
	for c in choice_option_container.get_children():
		c.queue_free()
	
	var built_choices : Array[Dictionary] = []
	for option in choices:
		var conditional_eval = evaluate_conditionals(option.get("conditionals"), option.get("choice_text.enabled_as_default"))
		var cond_true = conditional_eval[0]
		var cond_behavior = conditional_eval[1]
		var facts = option.get("facts").get("fact_data_by_name", {})
		
		if cond_true and auto_switch:
			for f in facts.values():
				Parser.change_fact(f)
			choice_pressed(true, option.get("target_page"), option.get("target_line"))
			break
		
		var enable_option := true
		var option_text := ""
		
		if (cond_true and cond_behavior == "Hide") or (not cond_true and cond_behavior == "Show"):
			if Parser.selected_choices.has(option.get("address", "")):
				if option.get("behavior_after_first_selection") == DIISIS.ChoiceBehaviorAfterSelection.Default:
					continue
			else:
				continue
		
		if (cond_true and cond_behavior == "Show") or (not cond_true and cond_behavior == "Hide"):
			enable_option = option.get("choice_text.enabled_as_default")
		
		if (cond_true and cond_behavior == "Enable") or (not cond_true and cond_behavior == "Disable"):
			enable_option = true
			
		if (cond_true and cond_behavior == "Disable") or (not cond_true and cond_behavior == "Enable"):
			enable_option = false
		
		if (
			option.get("behavior_after_first_selection") != DIISIS.ChoiceBehaviorAfterSelection.Default and
			Parser.selected_choices.has(option.get("address", ""))
			):
			match int(option.get("behavior_after_first_selection")):
				DIISIS.ChoiceBehaviorAfterSelection.Enabled:
					enable_option = true
				DIISIS.ChoiceBehaviorAfterSelection.Disabled:
					enable_option = false
				DIISIS.ChoiceBehaviorAfterSelection.Hidden:
					continue
		
		if enable_option:
			var localized : String = Parser.replace_from_locale(str(option.get("address", ""), "enabled"), Parser.locale)
			if not localized.is_empty():
				option_text = localized
			else:
				option_text = option.get("choice_text.enabled")
		else:
			var localized : String = Parser.replace_from_locale(str(option.get("address", ""), "disabled"), Parser.locale)
			if not localized.is_empty():
				option_text = localized
			else:
				option_text = option.get("choice_text.disabled")
		
		# give to option to signal
		var do_jump_page = option.get("do_jump_page", false)
		var target_page = option.get("target_page", 0)
		var target_line = option.get("target_line", 0)
		var loopback = option.get("loopback", false)
		var loopback_target_page = option.get("loopback_target_page", -1)
		var loopback_target_line = option.get("loopback_target_line", -1)
		
		
		
		var new_option:ChoiceButton
		if button_scene:
			new_option = button_scene.instantiate()
		else:
			new_option = preload("res://addons/diisis/parser/src/choice_option.tscn").instantiate()
		new_option.disabled = not enable_option
		new_option.text = option_text
		
		new_option.facts = facts
		new_option.do_jump_page = do_jump_page
		new_option.target_page = target_page
		new_option.target_line = target_line
		new_option.loopback = loopback
		new_option.loopback_target_page = loopback_target_page
		new_option.loopback_target_line = loopback_target_line
		new_option.address = option.get("address", "")
		
		new_option.connect("choice_pressed", choice_pressed)
		
		choice_option_container.add_child(new_option)
		built_choices.append({
			"button": new_option,
			"disabled": not enable_option,
			"option_text": option_text,
			"facts": facts,
			"do_jump_page": do_jump_page,
			"target_page": target_page,
			"target_line": target_line,
			"loopback" : loopback,
			"loopback_target_page" : loopback_target_page,
			"loopback_target_line" : loopback_target_line,
		})
		
		match choice_button_focus_mode:
			ChoiceButtonFocusMode.Keyboard:
				new_option.focus_mode = Control.FOCUS_ALL
				new_option.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ChoiceButtonFocusMode.None:
				new_option.focus_mode = Control.FOCUS_NONE
				new_option.mouse_filter = Control.MOUSE_FILTER_STOP
	if choice_option_container.get_child_count() > 0 and choice_button_focus_mode == ChoiceButtonFocusMode.Keyboard:
		choice_option_container.get_child(0).call_deferred("grab_focus")
	ParserEvents.choices_presented.emit(built_choices)
	
	if show_choice_title:
		if choice_title_label:
			choice_title_label.text = current_choice_title
		else:
			push_warning(str("Choice Title Label not set. Choice Title \"", current_choice_title,"\" will be ignored."))
	
	#if give_focus_to_choice_button or ChoiceButtonFocusMode.KeyboardOnly == choice_button_focus_mode:
		#if choice_option_container.get_child_count() > 0:
			#choice_option_container.get_child(0).grab_focus.call_deferred()
		#else:
			#push_warning("No choice to give focus to.")

func is_choice_presented():
	return (not choice_option_container.get_children().is_empty()) and choice_container.visible

func choice_pressed(do_jump_page, target_page, target_line):
	for c in choice_option_container.get_children():
		c.queue_free()
	if do_jump_page:
		emit_signal("jump_to_page", target_page, target_line)
		return
	emit_signal("line_finished", line_index)
	

## returns an array of size 2. index 0 is if the conditionals are satisfied. index 1 is the behavior if it's true
func evaluate_conditionals(conditionals, enabled_as_default := true) -> Array:
	var conditional_is_true := true
	var behavior = conditionals.get("behavior_key")
	var args = conditionals.get("operand_args")
	var facts_to_check : Dictionary = conditionals.get("facts", {}).get("fact_data_by_name", {})
	if facts_to_check.is_empty():
		var default_key = "Enable" if enabled_as_default else "Disable"
		return [true, default_key]
	
	
	var operand_key = conditionals.get("operand_key")
	var true_facts := []
	for fact in facts_to_check.values():
		var fact_name : String = fact.get("fact_name")
		var current_fact_value = Parser.facts.get(fact_name)
		if int(fact.get("data_type", 0)) == 0: # bool
			var fact_value = bool(fact.get("fact_value", true))
			if fact_value == current_fact_value:
				true_facts.append(fact_name)
		elif int(fact.get("data_type", 0)) == 1: # int
			var new_fact_value = int(fact.get("fact_value", 0))
			var comparator := int(fact.get("int_comparator", 0)) 
			match comparator:
				0: # eq
					if new_fact_value == current_fact_value:
						true_facts.append(fact_name)
				1: # uneq
					if new_fact_value != current_fact_value:
						true_facts.append(fact_name)
				2: # lt
					if new_fact_value > current_fact_value:
						true_facts.append(fact_name)
				3: # lte
					if new_fact_value >= current_fact_value:
						true_facts.append(fact_name)
				4: # gt
					if new_fact_value < current_fact_value:
						true_facts.append(fact_name)
				5: # gte
					if new_fact_value <= current_fact_value:
						true_facts.append(fact_name)
				
		
	match operand_key:
		"AND":
			conditional_is_true = true_facts.size() == facts_to_check.size()
		"OR":
			conditional_is_true = true_facts.size() > 0
		"nOrMore":
			conditional_is_true = true_facts.size() >= args[0]
		"nOrLess":
			conditional_is_true = true_facts.size() <= args[0]
		"betweenNMincl":
			conditional_is_true = true_facts.size() >= args[0] and true_facts.size() <= args[1]
	
	return [conditional_is_true, behavior]


func handle_header(header: Array):
	for prop in header:
		var data_type = prop.get("data_type")
		var property_name = prop.get("property_name")
		var values = prop.get("values")
		if data_type == Parser.DataTypes._DropDown:
			values = Parser.drop_down_values_to_string_array(values)
		
		if property_name == property_for_name:
			update_name_label(values[1])
	
	ParserEvents.new_header.emit(header)


func set_dialog_line_index(value: int):
	dialog_line_index = value
	
	if Parser.use_dialog_syntax:
		var raw_name : String = dialog_actors[dialog_line_index]
		var actor_name: String
		var dialog_line_arg_dict := {}
		if "{" in raw_name:
			actor_name = raw_name.split("{")[0]
			var dialog_line_args = raw_name.split("{")[1]
			dialog_line_args = dialog_line_args.trim_suffix("}")
			dialog_line_args = dialog_line_args.split(",")
			
			for arg in dialog_line_args:
				var arg_key = arg.split("|")[0]
				var arg_value = arg.split("|")[1]
				dialog_line_arg_dict[arg_key] = arg_value
		else:
			actor_name = raw_name
		
		update_name_label(actor_name)
		
		ParserEvents.dialog_line_args_passed.emit(actor_name, dialog_line_arg_dict)
	
	start_showing_text()

func update_name_label(actor_name: String):
	is_last_actor_name_different = actor_name != current_raw_name
	current_raw_name = actor_name
	
	var display_name: String = name_map.get(actor_name, actor_name)
	var name_color :Color = name_colors.get(actor_name, Color.WHITE)
	
	if name_style == NameStyle.NameLabel:
		name_label.text = display_name
		name_label.add_theme_color_override("font_color", name_color)
		
		if actor_name in blank_names:
			name_container.modulate.a = 0.0
		else:
			name_container.modulate.a = 1.0
	
	var name_visible:bool
	if name_style == NameStyle.NameLabel:
		name_visible = name_container.modulate.a > 0.0
	elif name_style == NameStyle.Prepend:
		name_visible = current_raw_name in blank_names
	ParserEvents.display_name_changed.emit(display_name, name_visible)
	ParserEvents.actor_name_changed.emit(actor_name, name_visible)


func can_text_container_be_visible() -> bool:
	if line_type == DIISIS.LineType.Text:
		return true
	if line_type == DIISIS.LineType.Choice:
		return show_text_during_choices
	if line_type == DIISIS.LineType.Instruction:
		return show_text_during_instructions
	return false


func _go_to_end_of_dialog_line():
	set_dialog_line_index(dialog_lines.size() - 1)
func _go_to_start_of_dialog_line():
	set_dialog_line_index(0)


var currently_speaking_name := ""
var currently_speaking_visible := true

func on_name_label_updated(
	actor_name: String,
	is_name_container_visible: bool
):
	currently_speaking_name = actor_name
	currently_speaking_visible = is_name_container_visible

var chunk_addresses_in_history := []

func get_chunk_address() -> String:
	return str(Parser.page_index, ".", line_index, ".", dialog_line_index, ".", chunk_index)

func on_text_content_text_changed(old_text: String,
	new_text: String,
	lead_time: float):
	if chunk_addresses_in_history.has(get_chunk_address()):
		return
	chunk_addresses_in_history.append(get_chunk_address())
	Parser.call_deferred("append_to_history", (str(str("[b]",currently_speaking_name, "[/b]: ") if currently_speaking_visible else "", new_text)))
