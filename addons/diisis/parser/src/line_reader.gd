@icon("res://addons/diisis/parser/style/reader_icon_Zeichenfläche 1.svg")
@tool
extends Control
class_name LineReader
## The moist endoskeleton-wrapping articulations of runtime-side DIISIS <3
##
## Add it to your scene and hook up your own UI nodes to it. 
## Then handle input to call [method request_advance] and method [method request_go_back] to navigate
## through the dialog written in DIISIS!

## Text speed at which text will be shown instantly instead of gradually revealed.
const MAX_TEXT_SPEED := 201

## Determines how the name of the currently speaking actor is displayed. All options
## respect [member name_map] and [member name_colors].
enum NameStyle {
	## The name will be displayed in [member name_label].
	NameLabel,
	## The name will be inserted in front of the text with a sequence of optional spaces and characters (See [param prepend_separator] [param prefix_space] [param prefix_suffix]). [member name_label] will be hidden.
	Prepend,
}

## Find an extensive tutorial on how to set up your [LineReader] on GitHub!
## @tutorial(Quick Start Guide): https://github.com/SnekOfSpice/dialog-editor/wiki/LineReader-&-Parser
## @tutorial(Visual Novel Guide): https://github.com/SnekOfSpice/dialog-editor/wiki/Using-the-visual-novel-template

@export_group("Text")
@export_subgroup("Cadence")
## Speed at which characters are shown, in characters/second. Set to [constant MAX_TEXT_SPEED] for instant text instead.[br]
## If [member full_words] is [code]true[/code], will instead pause between words for [constant MAX_TEXT_SPEED] / [member text_speed] seconds.
@export_range(1.0, MAX_TEXT_SPEED, 1.0) var text_speed := 60.0
## Complete override of other text speed settings, including [member text_speed] and [code]<ts_*>[/code] tags.[br][br]
## Set to [code]-1[/code] (default) to disable.
@export_range(-1.0, MAX_TEXT_SPEED, 1.0) var custom_text_speed_override := -1.0
## If true, the text will be read one word at a time instead of character by character.
@export var full_words := false
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
## If [code]true[/code], shows [param text_container] when choices are presented.
@export_subgroup("Show Text During", "show_text_during")
## If [code]true[/code], shows [param text_container] when choices are being displayed.
@export var show_text_during_choices := true
## If [code]true[/code], shows [param text_container] when instructions are being executed.
@export var show_text_during_instructions := false
@export_subgroup("Past Lines")
## If [code]true[/code], the LineReader will add a copy of its text to [member past_lines_container] whenever the text of [member text_content] is reset.
@export var keep_past_lines := false:
	set(value):
		keep_past_lines = value
		notify_property_list_changed()
		update_configuration_warnings()
## [VBoxContainer] to which past text lines get added. See [member keep_past_lines].
@export var past_lines_container : VBoxContainer:
	get:
		return past_lines_container
	set(value):
		past_lines_container = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
## If [member keep_past_lines] is true, limits the number of lines saved to [member past_lines_container][br]
## Default of -1 means no upper limit.
@export var max_past_lines := -1
## If true, the displayed actor names will also be prepended to the text
## saved with [member keep_past_lines].
@export var preserve_name_in_past_lines := true
## [b]Optional[/b] [RichTextLabel] scene that gets used to deposit past lines saved by [member keep_past_lines]. By default, the [LineReader] will create a [RichTextLabel] by itself.
@export var past_line_label:PackedScene
var _auto_advance := false
var _last_raw_name := ""

@export_group("Name Display")
## The name of the dropdown property used for keying names. Usually something like "character"
## Name of the DropDown in DIISIS that gets used for dialog syntax. [br]
## ("character" in the demo)
@export var property_for_name := ""
## If the newly speaking actor name is in this array, the name label will be hidden alltogether.
@export var blank_names : Array[String] = []
## A String:String Dictionary. The keys are the actor names set in the options of [member property_for_name].
## The respective value is the name to be displayed in the [member name_label] or [member text_content], depending on [member name_style].
@export var name_map : Dictionary[String, String] = {}
## A String:Color Dictionary. The keys are the actor names set in the options of [member property_for_name].
## The respective value is the color modulation applied to [member name_label] or bbcode color tag inserted around the name in [member text_content], depending on [member name_style].
@export var name_colors : Dictionary[String, Color] = {}
## Style in which names get displayed. See [enum LineReader.NameStyle].
@export var name_style : NameStyle = NameStyle.NameLabel
var _visible_prepend_offset := 0

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

## Node that evaluates [code]<var:>[/code] and [code]<func:>[/code] tags.
## Any function called by one of these tags has to return a [String] (can be empty).
@export var inline_evaluator: Node

@export_group("Advanced Text Display")
@export_subgroup("Text Content", "text_content")
## If [code]0[/code], [param text_content] will be filled as far as possible.
## Breaks will be caused by <lc> tags, 
## a file with [param Pages.use_dialog_syntax] enabled, and a
## new [Line] of type [member DIISIS.LineType.Text] being read.[br]
## If set to more than [code]0[/code], the text will additionally be split to
## ensure it never runs more than that amount of lines. [br]
## [b]Note:[/b] Resizing the [param text_content] after a Line has started to be read will
## throw this alignment off.
@export_range(0, 1, 1.0, "or_greater") var text_content_max_lines := 0
## A prefix to add to all strings that are displayed in [member text_content]. Respects bbcode such as [code][center][/code].
@export var text_content_prefix := ""
## A suffix to add to all strings that are displayed in [member text_content]. Respects bbcode such as [code][/center][/code].
@export var text_content_suffix := ""
## Wraps all case-sensitive matches of individual words in custom defined wrappers. (Adds prefix and suffix)
## The dictionary key is the word to wrap. The value is the prefix and suffix for that word, separated by a space.[br]
## For example; [code]"DIISIS" : "[b] [/b]"[/code].
@export var text_content_word_wrappers : Dictionary[String, String]
@export_subgroup("Chatlog", "chatlog")
## If true, and dialog syntax is used (default in DIISIS), the text inside a Text Line will instead
## be formatted like a chatlog, where all speaking parts are concatonated and speaking names are tinted in the colors set in [member chatlog_name_colors].[br]
## [member text_speed] will still act as normal, though you probably want to use [constant LineReader.MAX_TEXT_SPEED]. [br][br]
## [s]I've been reading homestuck[/s]
@export var chatlog_enabled := false
## When [member chatlog_enabled] is true, instead these names will be used if set. If not, defaults to [member name_map.]
@export var chatlog_name_map : Dictionary[String, String] = {}
## Chatlog override for colors. Tints the names displayed when [member chatlog_enabled] is true. If not set, no tint is used.
@export var chatlog_name_colors : Dictionary[String, Color] = {}
## If set, the entire line is tinted in the appropriate color set in [member chatlog_name_colors]. If false, only the actor name is tinted.
@export var chatlog_tint_full_line := true

@export_group("Advanced UX")
@export_subgroup("Choices")
## If [code]false[/code], the [LineReader] can still be advanced with [method LineReader.advance], even if
## Choice Buttons are currently presented to the player.
@export var block_advance_during_choices := true
## Focuses the first button when choices are built to allow keyboard navigation in the UI.
@export var choice_button_keyboard_focus := true
## Hides all built choice buttons during choices. Instead, the LineReader
## must be advanced by calling [method LineReader.choice_pressed_virtual]. Useful if you want
## a custom override for how choices are selected beyond buttons.[br][br]
## See also, [signal ParserEvents.choices_presented].
@export var virtual_choices := false
var _built_virtual_choices := []
## [b]Optional[/b] button scene that gets instantiated as children of [member choice_option_container].[br]
## If left unassigned, will use a default button.[br]
## If overridden, it must inherit from [ChoiceButton].
@export var button_scene:PackedScene
## [Label] used to display the choice title. Invisible if the choice title is empty. Not setting it will result in the choice title not being shown.
@export var choice_title_label: Label

@export_subgroup("Input Prompt")
## If [code]true[/code], [LineReader] will fade in either [member prompt_unfinished] or [member prompt_finished] whenever the player can give input to advance.
## Both references have to be set, and [b]cannot be the same node[/b].
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
## The node that gets shown when advancing the [LineReader] will clear [member text_content].
@export
var prompt_finished: Control:
	get:
		return prompt_finished
	set(value):
		prompt_finished = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
var _remaining_prompt_delay := input_prompt_delay

@export_group("Internal Config")
@export_subgroup("Inline Name Separator Sequence", "inline_name_")
## [enum NameStyle.Prepend] and [param preserve_name_in_past_lines] use this.
@export var inline_name_separator := "-"
## Adds a space before [member inline_name_separator].
@export var inline_name_space_prefix := true
## Adds a space after [member inline_name_separator].
@export var inline_name_space_suffix := true
@export_subgroup("Parser Events")
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
@export_subgroup("Warn about nonadvance on", "warn_advance_on_")
## Emits a warning when the LineReader didn't advance after [method request_advance] was called because the Parser is paused.
@export var warn_advance_on_parser_paused := true
## Emits a warning when the LineReader didn't advance after [method request_advance] was called because [param is_input_locked] is true. Probably because of waiting for an instruction to be finished.
@export var warn_advance_on_input_locked := true
## Emits a warning when the LineReader didn't advance after [method request_advance] was called because the Parser is terminated.
@export var warn_advance_on_terminated := true
## Emits a warning when the LineReader didn't advance after [method request_advance] was called because [param auto_continue] is true.
@export var warn_advance_on_auto_continue := true
## Emits a warning when the LineReader didn't advance after [method request_advance] was called because choices are being presented and [param block_advance_during_choices] is true.
@export var warn_advance_on_choices_presented := true

signal line_finished(line_index: int)
signal jump_to_page(page_index: int, target_line: int)

var _line_data := {}
## [enum DIISISGlobal.LineType] that's currently being read.
var line_type := 0
## Line index that's currently being read of the current page.
var line_index := 0
var _remaining_auto_pause_duration := 0.0

## Tracks the state of the [LineReader] being input-locked.
## Usually because of instructions being executed.
var is_input_locked := false : set = set_is_input_locked
var _showing_text := false

var _lead_time := 0.0
var _next_pause_position_index := -1
var _pause_positions := []
var _pause_types := []
var _call_strings := {}
var _comments := {}
var _called_positions := []
var _handled_comments := []
var _next_pause_type := 0
enum _PauseTypes {Manual, Auto, EoL}
var _dialog_lines := []
var _dialog_actors := []
var _dialog_line_index := 0
var _is_last_actor_name_different := true
var _text_speed_by_character_index := []

var _line_chunks := []
var _chunk_index := 0
## Current actor key used in dialogue.
var current_raw_name := ""
## Currently displayed choice title.
var current_choice_title := ""

## State of the [LineReader]. If terminated, it's currently not active.
var terminated := false

var _started_word_buffer :=""
var _characters_visible_so_far := ""
var _full_word_timer := 0.0

var _last_visible_ratio := 0.0
var _last_visible_characters := 0
## @experimental
var visibilities_before_interrupt := {}

var _trimmable_strings := [" ", "\n", "<lc>", "<ap>", "<mp>", "\r"]

var _reverse_next_instruction := false
var _chunk_addresses_in_history := []

signal line_reader_ready

func _validate_property(property: Dictionary):
	if not show_input_prompt:
		if property.name in ["input_prompt_delay", "input_prompt_lerp_weight", "prompt_finished", "prompt_unfinished"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	if not auto_continue:
		if property.name in ["auto_continue_delay"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	if not keep_past_lines:
		if property.name in ["past_lines_container", "max_past_lines", "preserve_name_in_past_lines", "past_line_label"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR

## Generates a [Dictionary] contained the full state of [LineReader].[br]
## Used by [Parser] to call [method deserialize].
func serialize() -> Dictionary:
	var result := {}
	
	result["line_data"] = _line_data 
	result["line_index"] = line_index 
	result["line_type"] = line_type 
	result["remaining_auto_pause_duration"] = _remaining_auto_pause_duration 
	result["is_input_locked"] = is_input_locked 
	result["showing_text"] = _showing_text 
	result["next_pause_position_index"] = _next_pause_position_index 
	result["pause_positions"] = _pause_positions 
	result["pause_types"] = _pause_types 
	result["next_pause_type"] = _next_pause_type 
	result["dialog_lines"] = _dialog_lines 
	result["dialog_actors"] = _dialog_actors 
	result["dialog_line_index"] = _dialog_line_index 
	result["line_chunks"] = _line_chunks 
	result["chunk_index"] = _chunk_index 
	result["terminated"] = terminated 
	result["text_content.text"] = text_content.text
	result["current_raw_name"] = current_raw_name
	result["is_last_actor_name_different"] = _is_last_actor_name_different
	result["name_map"] = name_map
	result["chatlog_name_map"] = chatlog_name_map
	result["called_positions"] = _called_positions
	result["handled_comments"] = _handled_comments
	result["call_strings"] = _call_strings
	result["current_choice_title"] = current_choice_title
	result["text_speed_by_character_index"] = _text_speed_by_character_index
	result["max_past_lines"] = max_past_lines
	result["preserve_name_in_past_lines"] = preserve_name_in_past_lines
	result["_last_raw_name"] = _last_raw_name
	result["built_virtual_choices"] = _built_virtual_choices
	
	return result

## Restores the [LineReader] to whatever state was saved in [param data] using [method serialize].[br]
## Used by [Parser].
func deserialize(data: Dictionary):
	if not data:
		return
	_line_data = data.get("line_data", {})
	line_index = int(data.get("line_index", 0))
	line_type = int(data.get("line_type", DIISIS.LineType.Text))
	_remaining_auto_pause_duration = data.get("remaining_auto_pause_duration")
	is_input_locked = data.get("is_input_locked")
	_showing_text = data.get("showing_text")
	_next_pause_position_index = int(data.get("next_pause_position_index"))
	_pause_positions = data.get("pause_positions")
	_pause_types = data.get("pause_types")
	_next_pause_type = int(data.get("next_pause_type"))
	_dialog_lines = data.get("dialog_lines")
	_dialog_actors = data.get("dialog_actors")
	_dialog_line_index = int(data.get("dialog_line_index"))
	_line_chunks = data.get("line_chunks")
	_chunk_index = int(data.get("chunk_index"))
	terminated = data.get("terminated")
	_set_dict_to_str_str_dict("name_map", data.get("name_map", name_map))
	_set_dict_to_str_str_dict("chatlog_name_map", data.get("chatlog_name_map", chatlog_name_map))
	_is_last_actor_name_different = data.get("is_last_actor_name_different", true)
	_called_positions = data.get("called_positions", [])
	_handled_comments = data.get("handled_comments", [])
	_call_strings = data.get("call_strings", {})
	_set_choice_title_or_warn(data.get("current_choice_title", ""))
	_text_speed_by_character_index = data.get("text_speed_by_character_index", [])
	max_past_lines = data.get("max_past_lines", -1)
	preserve_name_in_past_lines = data.get("preserve_name_in_past_lines", true)
	_last_raw_name = data.get("_last_raw_name", "")
	
	text_container.visible = _can_text_container_be_visible()
	_showing_text = line_type == DIISIS.LineType.Text
	choice_container.visible = line_type == DIISIS.LineType.Choice
	
	if line_type == DIISIS.LineType.Choice:
		var raw_content = _line_data.get("content")
		var content = _line_data.get("content").get("content")
		var choices = _line_data.get("content").get("choices")
		var auto_switch : bool = raw_content.get("auto_switch")
		_set_choice_title_or_warn(Parser.get_text(raw_content.get("title_id", "")))

		_build_choices(choices, auto_switch)
	
	update_name_label(data.get("current_raw_name", "" if blank_names.is_empty() else blank_names.front()))
	_set_text_content_text(data.get("text_content.text", ""))

## typed dictionaries don't survive saving to json so we need this
func _set_dict_to_str_str_dict(target_variable: StringName, map: Dictionary):
	var target = get(target_variable)
	target.clear()
	for key in map.keys():
		target[key] = map.get(key)

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
	if keep_past_lines and not past_lines_container:
		warnings.append("Past Text Container is null")
	
	return warnings

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	Parser.connect("read_new_line", _read_new_line)
	Parser.connect("page_terminated", _close)
	ParserEvents.comment.connect(_on_comment)
	ParserEvents.go_back_accepted.connect(_on_go_back_accepted)
	
	ParserEvents.text_content_text_changed.connect(_on_text_content_text_changed)
	ParserEvents.display_name_changed.connect(_on_name_label_updated)
	
	Parser.open_connection(self)
	tree_exiting.connect(Parser.close_connection)
	
	_remaining_auto_pause_duration = auto_pause_duration# * (1.0 + (1-(text_speed / (MAX_TEXT_SPEED - 1))))
	
	if not instruction_handler:
		push_error("No InsutrctionHandler as child of LineReader.")
		return
	
	instruction_handler.connect("set_input_lock", set_is_input_locked)
	instruction_handler.connect("instruction_wrapped_completed", _on_instruction_handler_wrapped_completed)
	text_content.visible_ratio = 0
	text_content.bbcode_enabled = true
	text_content.text = ""
	name_label.text = ""
	
	if not show_input_prompt and prompt_unfinished:
		prompt_unfinished.modulate.a = 0
	if not show_input_prompt and prompt_finished:
		prompt_finished.modulate.a = 0
	
	emit_signal("line_reader_ready")

# nts this is where _lmao(a, b) lies RIP
func _on_go_back_accepted(_page_index:int, _line_index:int):
	_reverse_next_instruction = true

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
		if warn_advance_on_parser_paused:
			push_warning("Cannot advance because Parser.paused is true.")
		return
	if is_input_locked:
		if warn_advance_on_input_locked:
			push_warning("Cannot advance because is_input_locked is true.")
		return
	if terminated:
		if warn_advance_on_terminated:
			push_warning("Cannot advance because terminated is true.")
		return
	if auto_continue:
		if warn_advance_on_auto_continue:
			push_warning("Cannot advance because auto_continue is true.")
		return
	if _is_choice_presented() and block_advance_during_choices:
		if warn_advance_on_choices_presented:
			push_warning("Cannot advance because choices are presented and block_advance_during_choices is true.")
		return
	
	advance()

## Advances the reading of lines directly. Do not call this directly. Use [code]request_advance()[/code] instead.
func advance():
	_last_visible_characters = 0
	_last_visible_ratio = 0
	if auto_continue:
		_auto_continue_duration = auto_continue_delay
	if _showing_text:
		_lead_time = 0.0
		_full_word_timer = 0
		if text_content.visible_ratio >= 1.0:
			if _chunk_index >= _line_chunks.size() - 1:
				if _dialog_line_index >= _dialog_lines.size() - 1:
					_remaining_prompt_delay = input_prompt_delay
					emit_signal("line_finished", line_index)
				else:
					_remaining_prompt_delay = input_prompt_delay
					_set_dialog_line_index(_dialog_line_index + 1)
			else:
				_read_next_chunk()
		else:
			if _next_pause_position_index < _pause_positions.size():
				text_content.visible_characters = _get_end_of_chunk_position() 
				if _next_pause_type != _PauseTypes.EoL:
					if _next_pause_position_index < _pause_positions.size() - 1:
						_next_pause_position_index += 1
					_find_next_pause()
					#remaining_auto_pause_duration = remaining_auto_pause_duration * (1.0 + (1-(text_speed / (MAX_TEXT_SPEED - 1))))
				_remaining_prompt_delay = input_prompt_delay
	else:
		emit_signal("line_finished", line_index)
	
	ParserEvents.advanced.emit()

## Go back up the dialogue tree, if possible. Pushes an appropriate warning if it fails.
func request_go_back() -> void:
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
## @experimental
func interrupt(hide_controls := true):
	ParserEvents.line_reader_interrupted.emit(self)
	Parser.set_paused(true)
	if hide_controls:
		for key in ["choice_container", "choice_option_container", "text_content", "text_container", "name_container", "name_label"]:
			visibilities_before_interrupt[key] = get(key).visible
			get(key).visible = false

## Call this after calling [method interrupt] to cleanly resume the reading of lines.[br]
## Takes in optional arguments to be passed to [Parser] upon continuing. If [param read_page] is [code]-1[/code] (default), the Parser will read exactly where it left off.
## @experimental
func continue_after_interrupt(read_page := -1, read_line := 0):
	for key in ["choice_container", "choice_option_container", "text_content", "text_container", "name_container", "name_label"]:
		if not visibilities_before_interrupt.has(key):
			push_warning("Visibilities after interrupt have not been set")
		else:
			get(key).visible = visibilities_before_interrupt[key]
	
	if read_page != -1:
		Parser.read_page(read_page, read_line)
	Parser.set_paused(false)
	ParserEvents.line_reader_resumed_after_interrupt.emit(self)

func _on_instruction_handler_wrapped_completed():
	emit_signal("line_finished", line_index)

func set_is_input_locked(value: bool):
	is_input_locked = value

func _close(_terminating_page):
	visible = false
	terminated = true

func _read_new_line(new_line: Dictionary):
	_line_data = new_line
	var skip : bool = _line_data.get("skip", false)
	line_index = new_line.get("meta.line_index")
	line_type = int(_line_data.get("line_type"))
	terminated = false
	if not skip:
		ParserEvents.read_new_line.emit(line_index)
	
	var eval = evaluate_conditionals(_line_data.get("conditionals"))
	var conditional_is_true = eval[0]
	var behavior = eval[1]
	
	var last_line_index:int
	if line_type == DIISIS.LineType.Folder:
		var range = _line_data.get("content", {}).get("range", 0)
		last_line_index = line_index + range
	else:
		last_line_index = line_index
	
	if skip:
		emit_signal("line_finished", last_line_index)
		ParserEvents.line_skipped.emit()
		return
	
	if behavior == "Show" or behavior == "Enable":
		if not conditional_is_true:
			emit_signal("line_finished", last_line_index)
			return
	if behavior == "Hide" or behavior == "Disable":
		if conditional_is_true:
			emit_signal("line_finished", last_line_index)
			return
	
	_handle_header(_line_data.get("header"))
	
	var raw_content = _line_data.get("content")
	var content = _line_data.get("content").get("content")
	var content_address
	var choices
	if line_type == DIISIS.LineType.Choice:
		choices = _line_data.get("content").get("choices")
	if line_type == DIISIS.LineType.Text:
		content = Parser.get_text(raw_content.get("text_id"))
	var content_name = _line_data.get("content").get("name")
	
	for key in ["choice_container", "choice_option_container", "text_content", "text_container", "name_container", "name_label"]:
		get(key).visible = true
	text_container.visible = _can_text_container_be_visible()
	_showing_text = line_type == DIISIS.LineType.Text
	choice_container.visible = line_type == DIISIS.LineType.Choice
	
	# register facts
	var facts = _line_data.get("facts", {}).get("fact_data_by_name", {})
	
	for f in facts.values():
		Parser.change_fact(f)
	
	if not show_input_prompt and prompt_unfinished:
		prompt_unfinished.modulate.a = 0
	if not show_input_prompt and prompt_finished:
		prompt_finished.modulate.a = 0
	
	match line_type:
		DIISIS.LineType.Text:
			#var localized : String = Parser.replace_from_locale(_line_data.get("address"), Parser.locale)
			#if not localized.is_empty():
				#content = localized
			if str(content).is_empty():
				emit_signal("line_finished", line_index)
				return
			
			
			if Parser.use_dialog_syntax or chatlog_enabled:
				var lines = content.split("[]>")
				_dialog_actors.clear()
				_dialog_lines.clear()
				for l : String in lines:
					if l.is_empty():
						continue
					
					var actor_name = l.split(":")[0]
					_dialog_actors.append(actor_name)
					var line : String = l.trim_prefix(str(actor_name, ":"))
					line = trim_trimmables(line)
					if chatlog_enabled:
						actor_name = _trim_syntax_and_emit_dialog_line_args(actor_name)
						
						var actor_prefix := ""
						if not actor_name in blank_names:
							actor_prefix = chatlog_name_map.get(actor_name, name_map.get(actor_name, actor_name)) + ": "
						line = str(
							"[color=", chatlog_name_colors.get(actor_name, name_colors.get(actor_name, Color.WHITE)).to_html(), "]",
							actor_prefix,
							"[/color]" if not chatlog_tint_full_line else "",
							line,
							"[/color]" if chatlog_tint_full_line else "",
							)
					_dialog_lines.append(line)
				
				
				if chatlog_enabled:
					var chat_text := "\n".join(PackedStringArray(_dialog_lines))
					_dialog_lines.clear()
					_dialog_lines = [chat_text]
					_dialog_actors.clear()
					_dialog_actors = [""]
			else:
				_dialog_lines = [content]
				_dialog_actors.clear()
				_dialog_actors = [""]
			
			_dialog_lines = _replace_tags(_dialog_lines)
			_dialog_lines = _replace_control_sequences(_dialog_lines)
			
			_set_dialog_line_index(0)
		DIISIS.LineType.Choice:
			var auto_switch : bool = raw_content.get("auto_switch")
			_set_choice_title_or_warn(Parser.get_text(raw_content.get("title_id")))
			_build_choices(choices, auto_switch)
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
			
			var instruction_content : Dictionary = _line_data.get("content")
			if _reverse_next_instruction and not instruction_content.get("meta.has_reverse"):
				_reverse_next_instruction = false
				_remaining_prompt_delay = input_prompt_delay
				return
			
			if not _reverse_next_instruction:
				instruction_name = instruction_content.get("name")
			else:
				instruction_name = instruction_content.get("reverse_name", "")
			
			if (not _reverse_next_instruction) or instruction_name.is_empty():
				instruction_name = instruction_content.get("name")
				args = Parser.get_arg_array_from_instruction_string(instruction_content.get("meta.text"), instruction_name)
				delay_before = new_line.get("content").get("delay_before")
				delay_after = new_line.get("content").get("delay_after")
			else:
				
				args = Parser.get_arg_array_from_instruction_string(instruction_content.get("meta.reverse_text"), instruction_name)
				delay_before = 0.0
				delay_after = 0.0
			
			if _reverse_next_instruction:
				#instruction_handler.execute(instruction_name, args)
				#reverse_next_instruction = false
				_remaining_prompt_delay = input_prompt_delay
				
				return
			instruction_handler._wrapper_execute(instruction_name, args, delay_before, delay_after)
		DIISIS.LineType.Folder:
			if not _line_data.get("content", {}).get("meta.contents_visible", true):
				push_warning(str("Line ", line_index, " was an invisible folder. It will get read regardless."))
			emit_signal("line_finished", line_index)
	
	_remaining_prompt_delay = input_prompt_delay
	
	_reverse_next_instruction = false

func _fit_to_max_line_count(lines: Array):
	if text_content_max_lines <= 0:
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
			var display_name: String = name_map.get(_dialog_actors[_dialog_line_index], _dialog_actors[_dialog_line_index])
			display_name = display_name.substr(0, display_name.find("{"))
			var name_color :Color = name_colors.get(_dialog_actors[_dialog_line_index], Color.WHITE)
			name_prefix = str(
			"[color=", name_color.to_html(), "]",
			display_name, "[/color]", _get_prepend_separator_sequence())
			name_length = display_name.length() + _get_prepend_separator_sequence().length()
		elif name_style == NameStyle.NameLabel:
			name_prefix = ""
			name_length = 0
		
		var line:String = lines[i]
		label.text = line
		label.visible_characters = 1
		if line_height == 0:
			line_height = label.get_content_height()
		
		label.text = str(text_content_prefix, name_prefix, line, text_content_suffix)
		
		while content_height <= line_height * text_content_max_lines:
			if label.text.is_empty():
				break
			label.visible_characters += 1
			content_height = label.get_content_height()
			if content_height > line_height * text_content_max_lines:
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
	_line_chunks = new_chunks
	label.queue_free()

func _get_prepend_separator_sequence() -> String:
	return str(" " if inline_name_space_prefix else "", inline_name_separator, " " if inline_name_space_suffix else "")

func _get_end_of_chunk_position() -> int:
	if _pause_positions.size() == 0:
		return text_content.text.length()
	elif _pause_types[_next_pause_position_index] == _PauseTypes.EoL:
		return text_content.text.length()
	else:
		return _pause_positions[_next_pause_position_index] - 4 * _next_pause_position_index# - prepend_offset

func _get_current_text_speed() -> float:
	if custom_text_speed_override > 0:
		return custom_text_speed_override
	
	var current_text_speed := text_speed
	if text_content.visible_characters < _text_speed_by_character_index.size() and text_content.visible_characters != -1:
		var value = _text_speed_by_character_index[text_content.visible_characters]
		current_text_speed = value if value != -1 else text_speed
	
	return current_text_speed

func _process(delta: float) -> void:
	# this is a @tool script so this prevents the console from getting flooded
	if Engine.is_editor_hint():
		return
	
	if Parser.paused:
		return
	
	_update_input_prompt(delta)
	
	if _lead_time > 0:
		_lead_time -= delta
		return
	
	var current_text_speed := _get_current_text_speed()
	
	if _next_pause_position_index < _pause_positions.size() and _next_pause_position_index != -1:
		_find_next_pause()
	if text_content.visible_characters < _get_end_of_chunk_position():
		if current_text_speed == MAX_TEXT_SPEED:
			text_content.visible_characters = _get_end_of_chunk_position()
		else:
			var old_text_length : int = text_content.visible_characters
			if full_words:
				var next_space_position = text_content.text.find(" ", text_content.visible_characters + 1)
				if text_content.visible_ratio != 1:
					_full_word_timer -= delta
				if _full_word_timer <= 0 or old_text_length == 0:
					text_content.visible_characters = min(next_space_position, _get_end_of_chunk_position())
					_full_word_timer = (MAX_TEXT_SPEED / current_text_speed) * delta
			else:
				text_content.visible_ratio += (float(current_text_speed) / text_content.get_parsed_text().length()) * delta
			# fast text speed can make it go over the end  of the chunk
			text_content.visible_characters = min(text_content.visible_characters, _get_end_of_chunk_position())
			if old_text_length != text_content.visible_characters:
				ParserEvents.visible_characters_changed.emit(old_text_length, text_content.visible_characters)
	elif _remaining_auto_pause_duration > 0 and _next_pause_type == _PauseTypes.Auto:
		var last_dur = _remaining_auto_pause_duration
		_remaining_auto_pause_duration -= delta
		if last_dur > 0 and _remaining_auto_pause_duration <= 0:
			_next_pause_position_index += 1
			_find_next_pause()
			_remaining_auto_pause_duration = auto_pause_duration# * (1.0 + (1-(text_speed / (MAX_TEXT_SPEED - 1))))
	
	
	var new_characters_visible_so_far = text_content.text.substr(0, text_content.visible_characters)
	var new_characters : String = new_characters_visible_so_far.trim_prefix(_characters_visible_so_far)
	if " " in new_characters:
		var split_new_characters : Array = new_characters.split(" ")
		for s in split_new_characters:
			s = _remove_symbols(s)
		_started_word_buffer += split_new_characters[0]
		_remove_spaces_and_send_word_read_event(_remove_symbols(_started_word_buffer))
		var i = 1
		while i < split_new_characters.size() - 1:
			_remove_spaces_and_send_word_read_event(_remove_symbols(split_new_characters[i]))
			i += 1
		_started_word_buffer = split_new_characters.back()
	else:
		_started_word_buffer += new_characters
		if text_content.text.ends_with(_started_word_buffer):
			if not _started_word_buffer.is_empty():
				_remove_spaces_and_send_word_read_event(_remove_symbols(_started_word_buffer))
				_started_word_buffer = ""
	_characters_visible_so_far = new_characters_visible_so_far
	
	if current_text_speed < MAX_TEXT_SPEED:
		if _last_visible_ratio < 1.0 and text_content.visible_ratio >= 1.0:
			ParserEvents.text_content_filled.emit()
		if _last_visible_ratio != text_content.visible_ratio:
			ParserEvents.text_content_visible_ratio_changed.emit(text_content.visible_ratio)
		if _last_visible_characters != text_content.visible_characters:
			ParserEvents.text_content_visible_characters_changed.emit(text_content.visible_characters)
		
	for pos : int in _call_strings:
		if _can_handle_text_position(pos, "_called_positions"):
			_call_from_position(pos)
	for pos : int in _comments:
		if _can_handle_text_position(pos, "_handled_comments"):
			_emit_comment(pos)
	
	_last_visible_ratio = text_content.visible_ratio
	_last_visible_characters = text_content.visible_characters
	if text_content.get_parsed_text().length() == text_content.visible_characters:
		_last_visible_characters = -1
		_last_visible_ratio = 0
	
	if _last_visible_characters == -1 and _auto_advance:
		advance()
		_auto_advance = false
		return
	
	if auto_continue:
		if not line_type == DIISIS.LineType.Text:
			return
		if _pause_types.is_empty() or _next_pause_position_index < 0:
			return
		if _pause_types[_next_pause_position_index] == _PauseTypes.Auto:
			return
		if text_content.visible_characters >= _pause_positions[_next_pause_position_index] - 4 * _next_pause_position_index or text_content.visible_characters == -1:
			_auto_continue_duration -= delta
			if _auto_continue_duration <= 0.0:
				advance()

func _can_handle_text_position(pos: int, tracker_array:StringName) -> bool:
	return (
			((not get(tracker_array).has(pos)) and _last_visible_characters >= pos) or
			(pos >= _last_visible_characters and pos <= text_content.visible_characters) or
			text_content.visible_characters == -1
		)

func _remove_spaces_and_send_word_read_event(word: String):
	word = word.replace(" ", "")
	ParserEvents.word_read.emit(word)

func _remove_symbols(from: String, symbols:=non_word_characters) -> String:
	var s = from
	
	for c in symbols:
		s = s.replace(c, " ")
	
	return s

func _update_input_prompt(delta:float):
	if (not show_input_prompt) or auto_continue:
		if prompt_finished:
			prompt_finished.visible = false
		if prompt_unfinished:
			prompt_unfinished.visible = false
		return
	
	var prompt_visible: bool

	if text_content.visible_ratio >= 1.0:
		prompt_visible = true
	elif _next_pause_position_index > _pause_positions.size() and _next_pause_position_index != -1:
		prompt_visible = true
	elif _pause_positions.size() > 0 and _next_pause_type == _PauseTypes.Manual:
		if text_content.visible_characters == _pause_positions[_next_pause_position_index] - 4 * _next_pause_position_index:
			prompt_visible = true
		else:
			prompt_visible = false
	else:
		prompt_visible = false
	
	if text_content.visible_characters < _get_end_of_chunk_position():
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
		if _remaining_prompt_delay > 0.0:
			_remaining_prompt_delay -= delta
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

func _start_showing_text():
	var content : String = _dialog_lines[_dialog_line_index]
	_line_chunks = content.split("<lc>")
	_chunk_index = -1
	_fit_to_max_line_count(_line_chunks)
	_read_next_chunk()

func _replace_tags(lines:Array) -> Array:
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
						var call_result = inline_evaluator.callv(func_name, func_args)
						if not call_result is String:
							if call_result == null:
								call_result = ""
							else:
								push_warning(str(func_name, " was called but didn't return String. Hoping this looks good ^^"))
								call_result = str(call_result)
						new_text = new_text.replace(control_to_replace, call_result)
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

func _replace_control_sequences(lines:Array) -> Array:
	var result := []
	var i := 0
	while i < lines.size():
		var new_text:String = lines[i]
		new_text = new_text.replace("\\n", "\n")
		new_text = new_text.replace("\\t", "\t")
		result.append(new_text)
		i += 1
	return result

# returns if it can go back
func _attempt_read_previous_chunk() -> bool:
	var chunk_failure := false
	var dialog_line_failure := false
	if _chunk_index <= 0:
		chunk_failure = true
	
	if chunk_failure:
		if _dialog_line_index <= 0:
			dialog_line_failure = true
		else:
			_set_dialog_line_index(_dialog_line_index - 1)
			return true
	else:
		_chunk_index -= 2
		_read_next_chunk()
		return true
	
	if chunk_failure and dialog_line_failure:
		return false
	

	
	return true

func _read_next_chunk():
	_remaining_prompt_delay = input_prompt_delay
	_chunk_index += 1
	if text_speed == MAX_TEXT_SPEED:
		text_content.visible_ratio = 1.0
	else:
		text_content.visible_characters = _visible_prepend_offset
	
	_pause_positions.clear()
	_pause_types.clear()
	_call_strings.clear()
	_called_positions.clear()
	_handled_comments.clear()
	var text_speed_override := -1.0
	_text_speed_by_character_index.clear()
	
	var new_text : String = _line_chunks[_chunk_index]
	new_text = trim_trimmables(new_text)
	
	if new_text.contains("<advance>") and not new_text.ends_with("<advance>"):
		push_warning(str("Line chunk \"", new_text, "\" contains an <advance> tag that is not at the end of the chunk."))
	_auto_advance = new_text.ends_with("<advance>")
	new_text = new_text.trim_suffix("<advance>")
	
	new_text = str(text_content_prefix, new_text, text_content_suffix)
	
	for word in text_content_word_wrappers.keys():
		var wrapper : PackedStringArray = text_content_word_wrappers.get(word).split(" ")
		if wrapper.size() != 2:
			push_error(str("Word ", word, " has invalid wrapper!"))
			continue
		new_text = new_text.replace(word, str(wrapper[0], word, wrapper[1]))
	
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
	var text_speed_tags := []
	var tag_buffer := 0
	var target_length := bbcode_removed_text.length()
	while scan_index < target_length:
		var call_strings_at_index : Array = _call_strings.get(scan_index, [])
		var scan_index_calls := scan_index
		var comments_at_index : Array = _comments.get(scan_index, [])
		if bbcode_removed_text[scan_index] == "<":
			if bbcode_removed_text.find("<strpos>", scan_index) == scan_index:
				notify_positions.append(scan_index - tag_buffer)
				bbcode_removed_text = bbcode_removed_text.erase(scan_index, "<strpos>".length())
				scan_index = max(scan_index - "<strpos>".length(), -1) # -1 because at the end we add 1
				target_length -= "<strpos>".length()
				tag_buffer += "<strpos>".length()
			elif bbcode_removed_text.find("<comment:", scan_index) == scan_index:
				var tag_length := bbcode_removed_text.find(">", scan_index) - scan_index + 1
				var tag_string := bbcode_removed_text.substr(scan_index, tag_length)
				bbcode_removed_text = bbcode_removed_text.erase(scan_index, tag_length)
				comments_at_index.append(tag_string)
				scan_index = max(scan_index - tag_string.length(), -1) # -1 because at the end we add 1
				target_length -= tag_string.length()
				tag_buffer += tag_string.length()
			elif bbcode_removed_text.find("<mp>", scan_index) == scan_index:
				tag_buffer += 4
			elif bbcode_removed_text.find("<ap>", scan_index) == scan_index:
				tag_buffer += 4
			elif bbcode_removed_text.find("<call:", scan_index) == scan_index:
				var tag_length := bbcode_removed_text.find(">", scan_index) - scan_index + 1
				var tag_string := bbcode_removed_text.substr(scan_index, tag_length)
				bbcode_removed_text = bbcode_removed_text.erase(scan_index, tag_length)
				call_strings_at_index.append(tag_string)
				scan_index = max(scan_index - tag_string.length(), -1) # -1 because at the end we add 1
				target_length -= tag_string.length()
				tag_buffer += tag_string.length()
			elif bbcode_removed_text.find("<ts_", scan_index) == scan_index:
				var tag_length := bbcode_removed_text.find(">", scan_index) - scan_index + 1
				var tag_string := bbcode_removed_text.substr(scan_index, tag_length)
				if bbcode_removed_text.find("<ts_rel:", scan_index) == scan_index:
					var value := float(tag_string.trim_suffix(">").split(":")[1])
					text_speed_override = clamp(float(value) * text_speed, 1, MAX_TEXT_SPEED-1)
				elif bbcode_removed_text.find("<ts_abs:", scan_index) == scan_index:
					var value := float(tag_string.trim_suffix(">").split(":")[1])
					text_speed_override = clamp(float(value), 1, MAX_TEXT_SPEED-1)
				elif bbcode_removed_text.find("<ts_reset", scan_index) == scan_index:
					text_speed_override = -1
				bbcode_removed_text = bbcode_removed_text.erase(scan_index, tag_length)
				target_length -= tag_string.length()
				tag_buffer += tag_string.length()
				text_speed_tags.append(tag_string)
		
		
		_text_speed_by_character_index.append(text_speed_override)
		_text_speed_by_character_index[scan_index_calls] = text_speed_override
		if not call_strings_at_index.is_empty():
			_call_strings[scan_index_calls] = call_strings_at_index.duplicate()
		if not comments_at_index.is_empty():
			_comments[scan_index_calls] = comments_at_index.duplicate()
		scan_index += 1
		call_strings_at_index.clear()
		comments_at_index.clear()
	_text_speed_by_character_index.resize(target_length)
	scan_index = 0
	while scan_index < bbcode_removed_text.length():
		if bbcode_removed_text[scan_index] == "<":
			if bbcode_removed_text.find("<mp>", scan_index) == scan_index:
				if not _pause_positions.has(scan_index):
					_pause_positions.append(scan_index)
					_pause_types.append(_PauseTypes.Manual)
			elif bbcode_removed_text.find("<ap>", scan_index) == scan_index:
				if not _pause_positions.has(scan_index):
					_pause_positions.append(scan_index)
					_pause_types.append(_PauseTypes.Auto)
				
		scan_index += 1
	
	_pause_positions.append(bbcode_removed_text.length()-1)
	_pause_types.append(_PauseTypes.EoL)
	
	_next_pause_position_index = 0
	_find_next_pause()
	
	var cleaned_text : String = new_text
	cleaned_text = cleaned_text.replace("<mp>", "")
	cleaned_text = cleaned_text.replace("<ap>", "")
	cleaned_text = cleaned_text.replace("<strpos>", "")
	cleaned_text = cleaned_text.replace("\\[", "[")
	for call_array : Array in _call_strings.values():
		for call in call_array:
			cleaned_text = cleaned_text.replace(call, "")
	for comment_array : Array in _comments.values():
		for comment in comment_array:
			cleaned_text = cleaned_text.replace(comment, "")
	for tag : String in text_speed_tags:
		cleaned_text = cleaned_text.replace(tag, "")
	
	if _is_last_actor_name_different:
		_lead_time = Parser.text_lead_time_other_actor
	else:
		_lead_time = Parser.text_lead_time_same_actor
	
	_visible_prepend_offset = 0
	if name_style == NameStyle.Prepend:
		name_container.modulate.a = 0.0
		var display_name: String = name_map.get(current_raw_name, current_raw_name)
		var name_color :Color = name_colors.get(current_raw_name, Color.WHITE)
		if not current_raw_name in blank_names:
			cleaned_text = str(
				"[color=", name_color.to_html(), "]",
				display_name, "[/color]", _get_prepend_separator_sequence(),
				cleaned_text
				)
		
		var name_prepend_length := _get_prepend_separator_sequence().length() + display_name.length()
		if current_raw_name in blank_names:
			name_prepend_length = 0
		_visible_prepend_offset = name_prepend_length
		var first_tag_position = cleaned_text.find("[", _pause_positions[0])
		var l := 0
		while l < _pause_positions.size():
			_pause_positions[l] = _pause_positions[l] + name_prepend_length
			l += 1
	
	var old_text = text_content.text
	_set_text_content_text(cleaned_text)
	ParserEvents.text_content_text_changed.emit(old_text, cleaned_text, _lead_time)
	ParserEvents.notify_string_positions.emit(notify_positions)

func trim_trimmables(text:String) -> String:
	var begins_trimmable := _begins_with_trimmable(text)
	while begins_trimmable:
		for t in _trimmable_strings:
			text = text.trim_prefix(t)
		begins_trimmable = _begins_with_trimmable(text)
		
	var ends_trimmable := _ends_with_trimmable(text)
	while ends_trimmable:
		for t in _trimmable_strings:
			text = text.trim_suffix(t)
		ends_trimmable = _ends_with_trimmable(text)
	return text

func _begins_with_trimmable(text:String) -> bool:
	for t in _trimmable_strings:
		if text.begins_with(t):
			return true
	return false

func _ends_with_trimmable(text:String) -> bool:
	for t in _trimmable_strings:
		if text.ends_with(t):
			return true
	return false

func _call_from_position(call_position: int):
	var strings : Array = _call_strings.get(call_position)
	_called_positions.append(call_position)
	for text : String in strings:
		text = text.trim_prefix("<call:")
		text = text.trim_suffix(">")
		var parts := text.split(",")
		var func_name = parts[0]
		while func_name.begins_with(" "):
			func_name = func_name.trim_prefix(" ")
		while func_name.ends_with(" "):
			func_name = func_name.trim_suffix(" ")
		parts.remove_at(0)
		
		var args := []
		var i := 0
		var arg_names : Array = Parser.get_instruction_arg_names(func_name)
		var arg_types : Array = Parser.get_instruction_arg_types(func_name)
		for type in arg_types:
			var arg_string = parts[i]
			var default = Parser.get_instruction_arg_defaults(func_name).get(arg_names[i])
			if arg_string == "*" and default != null:
				arg_string = default
			args.append(Parser.str_to_typed(arg_string, type))
			
			i += 1
		
		inline_evaluator.callv(func_name, args)
		ParserEvents.function_called.emit(func_name, args, call_position)
	_call_strings.erase(call_position)

func _emit_comment(comment_position:int):
	if not _comments.has(comment_position):
		return
	var comments = _comments.get(comment_position)
	for text : String in comments:
		text = text.trim_prefix("<comment:")
		text = text.trim_suffix(">")
		while text.begins_with(" "):
			text = text.trim_prefix(" ")
		while text.ends_with(" "):
			text = text.trim_suffix(" ")
		
		ParserEvents.comment.emit(text, comment_position)
	_handled_comments.append(comment_position)
	_comments.erase(comment_position)

func _set_text_content_text(text: String):
	if keep_past_lines:
		if max_past_lines > -1:
			var child_count := past_lines_container.get_child_count()
			while child_count >= max_past_lines:
				past_lines_container.get_child(0).queue_free()
				child_count -= 1
		
		var past_line : RichTextLabel
		if past_line_label:
			var instance = past_line_label.instantiate()
			if instance is RichTextLabel:
				past_line = instance
			else:
				push_warning("past_line_label is not a RichTextLabel. Using default RichTextLabel.")

		if not past_line:
			past_line = RichTextLabel.new()
			past_line.custom_minimum_size.x = text_content.custom_minimum_size.x
			past_line.fit_content = true
			past_line.bbcode_enabled = true
		
		var past_text := ""
		if preserve_name_in_past_lines and not _last_raw_name in blank_names and not text_content.text.is_empty():
			if name_colors.has(_last_raw_name):
				var color : Color = name_colors.get(_last_raw_name)
				var code = color.to_html(false)
				past_text = str("[color=", code, "]", _get_actor_name(_last_raw_name), "[/color]", _get_prepend_separator_sequence())
			else:
				past_text = str(_get_actor_name(_last_raw_name), _get_prepend_separator_sequence())
		
		var text_content_to_save = text_content.text
		if name_style == NameStyle.Prepend and not current_raw_name in blank_names:
			text_content_to_save = text_content_to_save.erase(0, text_content_to_save.find(_get_prepend_separator_sequence()) + _get_prepend_separator_sequence().length())
		past_text += text_content_to_save
		past_line.text = past_text
		past_lines_container.add_child(past_line)
	
	text_content.text = text
	text_content.visible_characters = _visible_prepend_offset
	_characters_visible_so_far = ""
	_started_word_buffer = ""
	
	_last_raw_name = current_raw_name


## Sets [param text_content]. If [param keep_text] is [code]true[/code], the text from the previous [param text_content] will be transferred to the passed argument.
func set_text_content(new_text_content:RichTextLabel, keep_text := true):
	var switch_text:bool = text_content != new_text_content
	var old_text : String
	if switch_text and keep_text:
		old_text = text_content.text
	text_content = new_text_content
	if switch_text and keep_text:
		text_content.text = old_text

## Helper function that you can use to switch [param keep_past_lines] to true and transfer all data to the [param new_label]. [param new_label] becomes [param text_content].
func enable_past_lines(container: VBoxContainer, new_label:RichTextLabel, name_style := NameStyle.Prepend):
	keep_past_lines = true
	self.past_lines_container = container
	self.name_style = name_style
	set_text_content(new_label)
		

func _find_next_pause():
	if _pause_types.size() > 0 and _next_pause_position_index < _pause_types.size():
		_next_pause_type = _pause_types[_next_pause_position_index]

func _get_actor_name(actor_key:String):
	return name_map.get(actor_key, actor_key)

## Sets the value of key [param actor_key] in [member name_map] to [param actor_name].
func set_actor_name(actor_key:String, actor_name:String):
	name_map[actor_key] = actor_name

func _build_choices(choices, auto_switch:bool):
	for c in choice_option_container.get_children():
		c.queue_free()
	
	var built_choices : Array = []
	for option in choices:
		var conditional_eval = evaluate_conditionals(option.get("conditionals"), option.get("choice_text.enabled_as_default"))
		var cond_true = conditional_eval[0]
		var cond_behavior = conditional_eval[1]
		var facts = option.get("facts").get("fact_data_by_name", {})
		
		if cond_true and auto_switch:
			for f in facts.values():
				Parser.change_fact(f)
			_choice_pressed(true, option.get("target_page"), option.get("target_line"))
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
			option_text = Parser.get_text(option.get("text_id_enabled"))
		else:
			option_text = Parser.get_text(option.get("text_id_disabled"))
		
		# give to option to signal
		var do_jump_page = option.get("do_jump_page", false)
		var target_page = option.get("target_page", 0)
		var target_line = option.get("target_line", 0)
		var loopback = option.get("loopback", false)
		var loopback_target_page = option.get("loopback_target_page", -1)
		var loopback_target_line = option.get("loopback_target_line", -1)
		
		
		
		var new_option:ChoiceButton
		if button_scene:
			var instance = button_scene.instantiate()
			if instance is ChoiceButton:
				new_option = instance
			else:
				push_warning("button_scene is not a ChoiceButton. Falling back to default.")
		if not new_option:
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
		
		new_option.connect("choice_pressed", _choice_pressed)
		
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
		
		if choice_button_keyboard_focus:
			new_option.focus_mode = Control.FOCUS_ALL
	
	if choice_option_container.get_child_count() > 0 and choice_button_keyboard_focus:
		choice_option_container.get_child(0).call_deferred("grab_focus")
	
	ParserEvents.choices_presented.emit(built_choices)
	
	if virtual_choices:
		_built_virtual_choices = built_choices
		for c in choice_option_container.get_children():
			c.visible = false

func _set_choice_title_or_warn(title: String):
	current_choice_title = title
	if choice_title_label:
		choice_title_label.visible = not title.is_empty()
		choice_title_label.text = title
	elif not title.is_empty():
		push_warning(str("Choice Title Label not set. Choice Title \"", title,"\" will be not be displayed."))


func _is_choice_presented() -> bool:
	if virtual_choices:
		return not _built_virtual_choices.is_empty()
	return (not choice_option_container.get_children().is_empty()) and choice_container.visible

## [param index] is the index of the choice emitted in [signal ParserEvents.choices_presented].
func choice_pressed_virtual(index:int):
	var choice_data : Dictionary = _built_virtual_choices[index]
	var button : ChoiceButton = choice_data.get("button")
	button.on_pressed()

func _choice_pressed(do_jump_page: bool, target_page : int, target_line : int):
	_built_virtual_choices.clear()
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


func _handle_header(header: Array):
	var cleaned_header : Array[Dictionary] = []
	for prop in header:
		var data_type = prop.get("data_type")
		var property_name = prop.get("property_name")
		var values = prop.get("values")
		if data_type == Parser.DataTypes._DropDown:
			values = Parser.drop_down_values_to_string_array(values)
		
		if property_name == property_for_name:
			update_name_label(values[1])
		
		cleaned_header.append({
			"data_type" : data_type,
			"property_name" : property_name,
			"values" : values,
		})
	
	ParserEvents.new_header.emit(cleaned_header)


func _set_dialog_line_index(value: int):
	_dialog_line_index = value
	
	if Parser.use_dialog_syntax:
		var raw_name : String = _dialog_actors[_dialog_line_index]
		var actor_name: String = _trim_syntax_and_emit_dialog_line_args(raw_name)
		
		update_name_label(actor_name)
	
	_start_showing_text()

# returns actor name
func _trim_syntax_and_emit_dialog_line_args(raw_name:String) -> String:
	var dialog_line_arg_dict := {}
	var actor_name := raw_name
	if "{" in raw_name:
		actor_name = raw_name.split("{")[0]
		var dialog_line_args = raw_name.split("{")[1]
		dialog_line_args = dialog_line_args.trim_suffix("}")
		dialog_line_args = dialog_line_args.split(",")
		
		for arg in dialog_line_args:
			var arg_key = arg.split("|")[0]
			var arg_value = arg.split("|")[1]
			dialog_line_arg_dict[arg_key] = arg_value
		ParserEvents.dialog_line_args_passed.emit(actor_name, dialog_line_arg_dict)
	return actor_name

## Updates the [member name_label] for [param actor_name], including [member name_style],
## name color, name fetched from [member name_map], etc. Or hides it if [param actor_name]
## is part of [member blank_names]. [br]
## Uses the raw keys defined in DIISIS.
func update_name_label(actor_name: String):
	_is_last_actor_name_different = actor_name != current_raw_name
	current_raw_name = actor_name
	
	var display_name: String = name_map.get(actor_name, actor_name)
	var name_color :Color = name_colors.get(actor_name, Color.WHITE)
	
	if name_style == NameStyle.NameLabel:
		name_label.text = display_name
		name_label.add_theme_color_override("font_color", name_color)
		
		if actor_name in blank_names or chatlog_enabled:
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


func _can_text_container_be_visible() -> bool:
	if line_type == DIISIS.LineType.Text:
		return true
	if line_type == DIISIS.LineType.Choice:
		return show_text_during_choices
	if line_type == DIISIS.LineType.Instruction:
		return show_text_during_instructions
	return false


func _go_to_end_of_dialog_line():
	_set_dialog_line_index(_dialog_lines.size() - 1)
func _go_to_start_of_dialog_line():
	_set_dialog_line_index(0)


var _currently_speaking_name := ""
var _currently_speaking_visible := true

func _on_name_label_updated(
	actor_name: String,
	is_name_container_visible: bool
):
	_currently_speaking_name = actor_name
	_currently_speaking_visible = is_name_container_visible

func _get_chunk_address() -> String:
	return str(Parser.page_index, ".", line_index, ".", _dialog_line_index, ".", _chunk_index)

## Automation to append stuff to parser history
func _on_text_content_text_changed(old_text: String,
	new_text: String,
	lead_time: float):
	var chunk_address := _get_chunk_address()
	if _chunk_addresses_in_history.has(chunk_address):
		return
	_chunk_addresses_in_history.append(chunk_address)
	Parser.call_deferred("append_to_history", (str(str("[b]", _currently_speaking_name, "[/b]: ") if _currently_speaking_visible else "", new_text)))

func _on_comment(comment: String, pos : int):
	prints(str(Parser.get_address(), ":", pos), comment)
