@icon("res://addons/diisis/parser/style/icon_line_reader.svg")
@tool
extends Node
class_name LineReader
## The moist endoskeleton-wrapping articulations of runtime-side DIISIS <3
##
## Add it to your scene and hook up your own UI nodes to it. 
## Then handle input to call [method request_advance] and method [method request_go_back] to navigate
## through the dialog written in DIISIS!

## Text speed at which text will be shown instantly instead of gradually revealed.
const MAX_TEXT_SPEED := 201
const UI_PROPERTIES := ["choice_container", "choice_list", "body_label", "text_container", "name_container", "name_label", "prompt_finished", "prompt_unfinished"]

## Determines how the name of the currently speaking actor is displayed. All options
## respect [member name_map] and [member color_map].
enum NameStyle {
	## The actor's name will be displayed in [member name_label].
	NameLabel,
	## The actor's name will be inserted in front of the text with a sequence of optional spaces and characters (See [param prepend_separator] [param prefix_space] [param prefix_suffix]). [member name_label] will be hidden.
	Prepend,
	## Actor name will not be shown. [member name_label] will be hidden.
	None,
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
@export_range(0, 1, 0.01, "or_greater","hide_slider") var auto_pause_duration := 0.2
## Disables input-based calls of [method advance].
## Instead, when hitting the end of a line or <mp> tag, LineReader
## will wait [param auto_continue_delay] seconds until continuing automatically.
@export var auto_continue := false:
	set(value):
		auto_continue = value
		notify_property_list_changed()
## If [member auto_continue] is [code]true[/code], this is the time before the line reader automatically continues, in seconds.
@export_range(0, 1, 0.01, "or_greater","hide_slider") var auto_continue_delay := 0.2
var _auto_continue_duration:= auto_continue_delay
## If [code]true[/code], shows [param text_container] when choices are presented.
@export_subgroup("Show Text During", "show_text_during")
## If [code]true[/code], shows [param text_container] when choices are being displayed.
@export var show_text_during_choices := true
##
@export var show_text_during_text := true
## If [code]true[/code], shows [param text_container] when instructions are being executed.
@export var show_text_during_instructions := false
@export_subgroup("Past Lines")
## If [code]true[/code], the LineReader will add a copy of its text to [member past_lines_container] whenever the text of [member body_label] is reset.
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
@export var actor_config : Dictionary[String, LineReaderActorConfig]
## If the newly speaking actor name is in this array, the name label will be hidden alltogether.
@export var blank_names : Array[String] = []
## A String:String Dictionary. The keys are the actor names set in the options of the Speaker Dropdown in DIISIS.
## The respective value is the name to be displayed in the [member name_label] or [member body_label], depending on [member name_style].
#@export var name_map : Dictionary[String, String] = {}
## A String:Color Dictionary. The keys are the actor names set in the options of the Speaker Dropdown in DIISIS.
## The respective value is the color modulation applied to [member name_label] or bbcode color tag inserted around the name in [member body_label], depending on [member name_style].
#@export var color_map : Dictionary[String, Color] = {}
## Style in which names get displayed. See [enum LineReader.NameStyle].
@export var name_style : NameStyle = NameStyle.NameLabel
var _prepend_length := 0

@export_group("Text References")
## A [Label] or [RichTextLabel] that displays a currently speaking character's name.
@export
var name_label: Control:
	get:
		return name_label
	set(value):
		name_label = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
## The [RichTextLabel] used to display text as it gets read out. [member RichTextLabel.bbcode_enabled] will be set to [param true] by the [LineReader].
@export var body_label: RichTextLabel:
	get:
		return body_label
	set(value):
		body_label = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
## The Control used for enumerating options when they are presented. Should be [HBoxContainer], [VBoxContainer], or [GridContainer].
## Any [Control] that is a parent of both nodes used for; [member name_label] and [member body_label].
@export var text_container: Control:
	get:
		return text_container
	set(value):
		text_container = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
## The Control holding [member name_label]. This is the control that actually gets its visibility toggled by [member blank_names] and other settings. Can be the same Node as [member name_label].
@export
var name_container: Control:
	get:
		return name_container
	set(value):
		name_container = value
		if Engine.is_editor_hint():
			update_configuration_warnings()


@export_group("Choice References", "choice_")
## [Label] used to display the choice title. Invisible if the choice title is empty. Not setting it will result in the choice title not being shown.
@export var choice_title_label: Label
## The Control holding [member choice_list].[br][br]
## I like setting using [code]mouse_filter[/code] [code]Stop[/code] and [b]FullRect Layout[/b].
@export var choice_container:PanelContainer:
	get:
		return choice_container
	set(value):
		choice_container = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
@export
## Container to which all choices get parented.
var choice_list:Control:
	get:
		return choice_list
	set(value):
		choice_list = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

@export_group("Advanced Text Display")
@export_subgroup("Body Label", "body_label")
## @experimental
## If [code]0[/code], [param body_label] will be filled as far as possible.
## Breaks will be caused by <lc> tags, 
## a file with [param Pages.use_dialog_syntax] enabled, and a
## new [Line] of type [member DIISIS.LineType.Text] being read.[br]
## If set to more than [code]0[/code], the text will additionally be split to
## ensure it never runs more than that amount of lines. [br]
## [b]Note:[/b] Resizing the [param body_label] after a Line has started to be read will
## throw this alignment off.[br]
## [b]Incompatible with [member chatlog_enabled]![/b]
@export_range(0, 1, 1.0, "or_greater") var body_label_max_lines := 0
## A prefix to add to all strings that are displayed in [member body_label]. Respects bbcode such as [code][center][/code].
@export var body_label_prefix := ""
## A suffix to add to all strings that are displayed in [member body_label]. Respects bbcode such as [code][/center][/code].
@export var body_label_suffix := ""
## Wraps all case-sensitive matches of individual words in custom defined wrappers. (Adds prefix and suffix)
## The dictionary key is the word to wrap. The value is the prefix and suffix for that word, separated by a space.[br]
## For example; [code]"DIISIS" : "[b] [/b]"[/code].
@export var body_label_word_wrappers : Dictionary[String, String]
## Prefix before the name.
@export var name_prefix : String
@export var name_suffix : String
## List of functions that get called with [method callv_custom] with the text of the [member body_label] as argument whenever that text gets set. (So referencing autoloads is also valid)
## Each call will replace the text as it gets passed along the array.
## This can be used to mangle the text in arbitrary ways before adding it to [member body_label], such as adding or replacing contents with your own custom text.
## [br][b]For example:[/b] [code]h3h3[/code] in [member body_label_function_funnel] will call [code]h3h3(text)[/code]. Giving [LineReader] the function with the name [code]h3h3[/code] will transform the text in interesting ways!
## [codeblock]
## func h3h3(text:String):
##     text = text.to_upper()
##     text = text.replace("E", "3")
##     text = text.replace("I", "1")
##     text = text.replace("A", "4")
##     return text
## [/codeblock]
@export var body_label_function_funnel : Array[String]
@export var body_label_tint_lines := false
@export_subgroup("Chatlog", "chatlog")
## If true, and dialog syntax is used (default in DIISIS), the text inside a Text Line will instead
## be formatted like a chatlog, where all speaking parts are concatonated and speaking names are tinted in the colors set in [member chatlog_color_map].[br]
## [member text_speed] will still act as normal, though you probably want to use [constant LineReader.MAX_TEXT_SPEED]. [br]
## [b]Incompatible with [member body_label_max_lines]![/b]
@export var chatlog_enabled := false
## Ignores [code][]>[/code] syntax and fuses all dialog lines of a single Text Line to one big chunk of text.
@export var chatlog_fuse_lines := true
## If set, the entire line is tinted in the appropriate color set in [member chatlog_color_map]. If false, only the actor name is tinted.
@export var chatlog_tint_full_line := true
## If set, the actor's prefix from [member body_label_prefix_by_actor] will also be prefixed to the chatlog.
@export var chatlog_include_body_label_actor_prefix := false
## If set, the actor's suffix from [member body_label_suffix_by_actor] will also be suffixed to the chatlog.
@export var chatlog_include_body_label_actor_suffix := false
@export var chatlog_line_prefix := "[code]"
@export var chatlog_line_suffix := "[/code]"

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
## [b]Optional[/b] button scene that gets instantiated as children of [member choice_list].[br]
## If left unassigned, will use a default button.[br]
## If overridden, it must inherit from [ChoiceButton].
@export var button_scene:PackedScene

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
## The node that gets shown when advancing the [LineReader] will clear [member body_label].
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
## [signal stop_accepting_advance] and [signal start_accepting_advance] will be fired synchronized with the
## internal state if true, since that blocks [method request_advance()].
## However, I needed it for UI once to emit this even when [param auto_continue] was true.
## So this is the option for that.
@export var include_auto_continue_in_accept_advance_signal := false
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
## Emits a warning when the LineReader didn't advance after [method request_advance] was called because [param is_executing] is true. Probably because of waiting for an instruction to be finished.
@export var warn_advance_on_executing := false
## Emits a warning when the LineReader didn't advance after [method request_advance] was called because the Parser is terminated.
@export var warn_advance_on_terminated := true
## Emits a warning when the LineReader didn't advance after [method request_advance] was called because [param auto_continue] is true.
@export var warn_advance_on_auto_continue := true
## Emits a warning when the LineReader didn't advance after [method request_advance] was called because [param awaiting_inline_call] is true.
@export var warn_advance_on_awaiting_inline_call := true
## Emits a warning when the LineReader didn't advance after [method request_advance] was called because choices are being presented and [param block_advance_during_choices] is true.
@export var warn_advance_on_choices_presented := true
@export_subgroup("Misc")
## Serializes and deserializes the [member visibility] property of all UI nodes [LineReader] references.
@export var persist_ui_visibilities := true
@export_group("Assist")
@export var warn_on_non_bool_function_return := true
#@export_tool_button("Get Map Diffs", "Popup") var get_map_diffs_action = get_map_diffs

signal line_finished(line_index: int)
signal jump_to_page(page_index: int, target_line: int)
signal start_accepting_advance()
signal stop_accepting_advance()
@onready var _is_advance_blocked := is_advance_blocked()

var _line_data := {}
## [enum DIISISGlobal.LineType] that's currently being read.
var line_type := 0
## Line index that's currently being read of the current page.
var line_index := 0
var _remaining_auto_pause_duration := 0.0

var _showing_text := false
var _text_delay := 0.0

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
#var _dialog_base_lines := [] # unchanged thing needed to rebuild on setting new config
var _full_prefix := ""
var _dialog_actors := []
var _dialog_line_index := 0
var _is_last_actor_name_different := true
var _text_speed_by_character_index := []

## Current actor key used in dialogue.
var current_raw_name := ""
## Currently displayed choice title.
var current_choice_title := ""
#
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
var _subaddresses_in_history := []

var _body_duplicate : RichTextLabel
var _body_duplicate_last_line : TextEdit

signal line_reader_ready

func _validate_property(property: Dictionary):
	if not show_input_prompt:
		if property.name in ["input_prompt_delay", "input_prompt_lerp_weight", "prompt_finished", "prompt_unfinished"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	#if not keep_past_lines:
		#if property.name in ["past_lines_container", "max_past_lines", "preserve_name_in_past_lines", "past_line_label"]:
			#property.usage = PROPERTY_USAGE_NO_EDITOR

## Generates a [Dictionary] contained the full state of [LineReader].[br]
## Used by [Parser] to call [method deserialize].
func serialize() -> Dictionary:
	var result := {}
	
	result["actors"] = actor_config.keys()
	result["awaiting_inline_call"] = awaiting_inline_call
	result["built_virtual_choices"] = _built_virtual_choices
	if body_label:
		result["body_label.text"] = body_label.text
	result["call_strings"] = _call_strings
	result["called_positions"] = _called_positions
	result["chatlog_enabled"] = chatlog_enabled
	result["chatlog_fuse_lines"] = chatlog_fuse_lines
	result["current_choice_title"] = current_choice_title
	result["current_raw_name"] = current_raw_name
	result["custom_text_speed_override"] = custom_text_speed_override
	result["dialog_actors"] = _dialog_actors 
	result["dialog_line_index"] = _dialog_line_index 
	result["dialog_lines"] = _dialog_lines 
	result["_full_prefix"] = _full_prefix 
	result["handled_comments"] = _handled_comments
	result["instruction_handler"] = serialize_instruction_handler_data() 
	result["is_last_actor_name_different"] = _is_last_actor_name_different
	result["_last_raw_name"] = _last_raw_name
	result["line_data"] = _line_data 
	result["line_index"] = line_index 
	result["line_type"] = line_type 
	result["max_past_lines"] = max_past_lines
	result["name_prefix"] = name_prefix
	result["name_suffix"] = name_suffix
	result["next_pause_position_index"] = _next_pause_position_index 
	result["next_pause_type"] = _next_pause_type 
	result["pause_positions"] = _pause_positions 
	result["pause_types"] = _pause_types
	result["preserve_name_in_past_lines"] = preserve_name_in_past_lines
	result["remaining_auto_pause_duration"] = _remaining_auto_pause_duration 
	result["showing_text"] = _showing_text 
	result["_subaddresses_in_history"] = _subaddresses_in_history 
	result["terminated"] = terminated
	result["_text_delay"] = _text_delay
	result["text_speed_by_character_index"] = _text_speed_by_character_index
	if persist_ui_visibilities:
		result["ui_visibilities"] = get_ui_visibilities()
	
	return result

## Restores the [LineReader] to whatever state was saved in [param data] using [method serialize].[br]
## Used by [Parser].
func deserialize(data: Dictionary):
	if not data:
		return
	for actor : String in data.get("actors", []):
		actor_config[actor] = null
	awaiting_inline_call = data.get("awaiting_inline_call", "")
	_built_virtual_choices = data.get("built_virtual_choices", {})
	_call_strings = data.get("call_strings", {})
	_called_positions = data.get("called_positions", [])
	chatlog_enabled = data.get("chatlog_enabled", chatlog_enabled)
	chatlog_fuse_lines = data.get("chatlog_fuse_lines", chatlog_fuse_lines)
	current_choice_title = data.get("current_choice_title", "")
	current_raw_name = data.get("current_raw_name", "")
	custom_text_speed_override = data.get("custom_text_speed_override", "")
	_dialog_actors = data.get("dialog_actors")
	_dialog_line_index = int(data.get("dialog_line_index"))
	_dialog_lines = data.get("dialog_lines")
	_full_prefix = data.get("_full_prefix", _full_prefix)
	_handled_comments = data.get("handled_comments", [])
	deserialize_instruction_handler_data(data.get("instruction_handler", {}))
	_is_last_actor_name_different = data.get("is_last_actor_name_different", true)
	_last_raw_name = data.get("_last_raw_name", "")
	_line_data = data.get("line_data", {})
	line_index = int(data.get("line_index", 0))
	line_type = int(data.get("line_type", DIISIS.LineType.Text))
	max_past_lines = data.get("max_past_lines", -1)
	_next_pause_position_index = int(data.get("next_pause_position_index"))
	_next_pause_type = int(data.get("next_pause_type"))
	name_prefix = data.get("name_prefix")
	name_suffix = data.get("name_suffix")
	_pause_positions = data.get("pause_positions")
	_pause_types = data.get("pause_types")
	preserve_name_in_past_lines = data.get("preserve_name_in_past_lines", preserve_name_in_past_lines)
	_remaining_auto_pause_duration = data.get("remaining_auto_pause_duration")
	_showing_text = data.get("showing_text")
	_subaddresses_in_history = data.get("_subaddresses_in_history")
	terminated = data.get("terminated")
	_text_delay = data.get("_text_delay", _text_delay)
	_text_speed_by_character_index = data.get("text_speed_by_character_index", [])
	
	_set_choice_title_or_warn(data.get("current_choice_title", ""))
	
	text_container.visible = _can_text_container_be_visible()
	_showing_text = line_type == DIISIS.LineType.Text
	if choice_container:
		choice_container.visible = line_type == DIISIS.LineType.Choice
	
	if persist_ui_visibilities:
		apply_ui_visibilities(data.get("ui_visibilities", {}))
	
	if line_type == DIISIS.LineType.Choice:
		var raw_content = _line_data.get("content")
		var content = _line_data.get("content").get("content")
		var choices = _line_data.get("content").get("choices")
		var auto_switch : bool = raw_content.get("auto_switch")
		_set_choice_title_or_warn(Parser.get_text(raw_content.get("title_id", "")))

		_build_choices(choices, auto_switch)
	
	update_name_label(data.get("current_raw_name", "" if blank_names.is_empty() else blank_names.front()))
	_set_body_label_text(data.get("body_label.text", ""))

## typed dictionaries don't survive saving to json so we need this
func _set_dict_to_str_str_dict(target_variable: StringName, map: Dictionary):
	var target = get(target_variable)
	target.clear()
	for key in map.keys():
		target[key] = map.get(key)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	
	if not (
			choice_list is HBoxContainer or 
			choice_list is VBoxContainer or 
			choice_list is GridContainer 
			) and choice_list != null:
			warnings.append("Choice Option Container is not HBoxContainer, VBoxContainer, or GridContainer")
	if not body_label:
		warnings.append("Body Label is null")
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
	
	ParserEvents.body_label_text_changed.connect(_on_body_label_text_changed)
	ParserEvents.display_name_changed.connect(_on_name_label_updated)
	
	Parser.open_connection(self)
	tree_exiting.connect(Parser.close_connection)
	
	_remaining_auto_pause_duration = auto_pause_duration
	_body_duplicate = RichTextLabel.new()
	_body_duplicate.focus_mode = Control.FOCUS_NONE
	_body_duplicate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body_duplicate.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	#_body_duplicate_last_line = TextEdit.new()
	#_body_duplicate_last_line.focus_mode = Control.FOCUS_NONE
	#_body_duplicate_last_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#_body_duplicate_last_line.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	
	#_body_duplicate.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	add_child(_body_duplicate)
	_body_duplicate.bbcode_enabled = true
	#add_child(_body_duplicate_last_line)
	
	if body_label:
		body_label.visible_ratio = 0
		body_label.bbcode_enabled = true
		body_label.text = ""
		set_body_label(body_label)
	if name_label:
		name_label.text = ""
	
	if not show_input_prompt and prompt_unfinished:
		prompt_unfinished.modulate.a = 0
	if not show_input_prompt and prompt_finished:
		prompt_finished.modulate.a = 0
	
	emit_signal("line_reader_ready")

# nts this is where _lmao(a, b) lies RIP
func _on_go_back_accepted(_page_index:int, _line_index:int, _dialine:int):
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
	text_speed = prefs.get("text_speed", text_speed)
	auto_continue = prefs.get("auto_continue", auto_continue)
	auto_continue_delay = prefs.get("auto_continue_delay", auto_continue_delay)

func is_advance_blocked(include_warnings:=false, include_auto_continue:=true) -> bool:
	if Engine.is_editor_hint():
		return false
	if Parser.paused:
		if warn_advance_on_parser_paused and include_warnings:
			push_warning("Cannot advance because Parser.paused is true.")
		return true
	if is_executing:
		if warn_advance_on_executing and include_warnings:
			push_warning("Cannot advance because is_executing is true.")
		return true
	if terminated:
		if warn_advance_on_terminated and include_warnings:
			push_warning("Cannot advance because terminated is true.")
		return true
	if auto_continue and include_auto_continue:
		if warn_advance_on_auto_continue and include_warnings:
			push_warning("Cannot advance because auto_continue is true.")
		return true
	if awaiting_inline_call:
		if warn_advance_on_awaiting_inline_call and include_warnings:
			push_warning("Cannot advance because awaiting_inline_call is true.")
		return true
	if _is_choice_presented() and block_advance_during_choices:
		if warn_advance_on_choices_presented and include_warnings:
			push_warning("Cannot advance because choices are presented and block_advance_during_choices is true.")
		return true
	return false

## Advances the interpreting of lines from the input file if possible. Will push an appropriate warning if not possible.
func request_advance():
	if is_advance_blocked(true):
		return
	
	advance()

## Advances the reading of lines directly. Do not call this directly. Use [code]request_advance()[/code] instead.
func advance():
	_full_prefix = ""
	_last_visible_characters = 0
	_last_visible_ratio = 0
	_text_delay = 0
	if auto_continue:
		_auto_continue_duration = auto_continue_delay
	if _showing_text:
		_lead_time = 0.0
		_full_word_timer = 0
		if body_label.visible_ratio >= 1.0:
			if _dialog_line_index >= _dialog_lines.size() - 1:
				_remaining_prompt_delay = input_prompt_delay
				emit_signal("line_finished", line_index)
			else:
				_remaining_prompt_delay = input_prompt_delay
				_set_dialog_line_index(_dialog_line_index + 1)
		else:
			if _next_pause_position_index < _pause_positions.size():
				body_label.visible_characters = _get_end_of_chunk_position() 
				if _next_pause_type != _PauseTypes.EoL:
					if _next_pause_position_index < _pause_positions.size() - 1:
						_next_pause_position_index += 1
					_find_next_pause()
				elif _auto_advance:
					_auto_advance = false
					advance()
				_remaining_prompt_delay = input_prompt_delay
	else:
		emit_signal("line_finished", line_index)
	
	ParserEvents.advanced.emit()

## Go back up the dialogue tree, if possible. Pushes an appropriate warning if it fails.
func request_go_back() -> void:
	if Parser.paused:
		push_warning("Cannot go back because Parser.paused is true.")
		return
	if is_executing:
		push_warning("Cannot go back because is_executing is true.")
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
		for key in UI_PROPERTIES:
			visibilities_before_interrupt[key] = get(key).visible
			get(key).visible = false

## Call this after calling [method interrupt] to cleanly resume the reading of lines.[br]
## Takes in optional arguments to be passed to [Parser] upon continuing. If [param read_page] is [code]-1[/code] (default), the Parser will read exactly where it left off.
## @experimental
func continue_after_interrupt(read_page := -1, read_line := 0):
	for key in UI_PROPERTIES:
		if not visibilities_before_interrupt.has(key):
			push_warning("Visibilities after interrupt have not been set")
		else:
			get(key).visible = visibilities_before_interrupt[key]
	
	if read_page != -1:
		Parser.read_page(read_page, read_line)
	Parser.set_paused(false)
	ParserEvents.line_reader_resumed_after_interrupt.emit(self)

func get_ui_visibilities() -> Dictionary:
	var result := {}
	for property in UI_PROPERTIES:
		if not get(property): continue
		result[property] = get(property).visible
	return result

func apply_ui_visibilities(data:Dictionary):
	for property in data.keys():
		var prop = get(property)
		if not prop: continue
		prop.set("visible", data.get(property))

func _on_instruction_wrapped_completed():
	emit_signal("line_finished", line_index)

func _close(_terminating_page):
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
	
	#for key in UI_PROPERTIES:
		#get(key).visible = get
	text_container.visible = _can_text_container_be_visible()
	_showing_text = line_type == DIISIS.LineType.Text
	if choice_container:
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
			if str(content).is_empty():
				emit_signal("line_finished", line_index)
				return
			
			if Parser.use_dialog_syntax:
				content = replace_lc_tags(content)
			
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
							actor_prefix = _get_actor_name(actor_name) + ": "
						
						var body_prefix : String = get_actor_config_property("body_label_prefix", actor_name, "")
						var body_suffix : String = get_actor_config_property("body_label_suffix", actor_name, "")
						if chatlog_enabled and not chatlog_include_body_label_actor_prefix:
							body_prefix = ""
						if chatlog_enabled and not chatlog_include_body_label_actor_suffix:
							body_suffix = ""
						
						var pair = _get_actor_color_prepend_tag_pair(actor_name)
						line = str(
							pair[0],
							actor_prefix,
							pair[1] if not chatlog_tint_full_line else "",
							body_prefix,
							line,
							body_suffix,
							pair[1] if chatlog_tint_full_line else "",
							)
						
						line = str(
							chatlog_line_prefix,
							line,
							chatlog_line_suffix,
						)
					_dialog_lines.append(line)
				
				
				if chatlog_enabled and chatlog_fuse_lines:
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
			_dialog_lines = _dialog_lines.duplicate(true)
			_set_dialog_line_index(0)
		DIISIS.LineType.Choice:
			var auto_switch : bool = raw_content.get("auto_switch")
			_set_choice_title_or_warn(Parser.get_text(raw_content.get("title_id")))
			_build_choices(choices, auto_switch)
		DIISIS.LineType.Instruction:
			
			var text : String
			var delay_before: float
			var delay_after: float
			
			var instruction_content : Dictionary = _line_data.get("content")
			if _reverse_next_instruction and not instruction_content.get("meta.has_reverse"):
				_reverse_next_instruction = false
				_remaining_prompt_delay = input_prompt_delay
				return
			
			if not _reverse_next_instruction:
				text = instruction_content.get("meta.text")
			else:
				text = instruction_content.get("meta.reverse_text", "")
			
			if (not _reverse_next_instruction) or text.is_empty():
				delay_before = new_line.get("content").get("delay_before")
				delay_after = new_line.get("content").get("delay_after")
			else:
				delay_before = 0.0
				delay_after = 0.0
			
			if _reverse_next_instruction:
				_remaining_prompt_delay = input_prompt_delay
				
				return
			_wrapper_execute(text, delay_before, delay_after)
		DIISIS.LineType.Folder:
			if not _line_data.get("content", {}).get("meta.contents_visible", true):
				push_warning(str("Line ", line_index, " was an invisible folder. It will get read regardless."))
			emit_signal("line_finished", line_index)
	
	_remaining_prompt_delay = input_prompt_delay
	
	_reverse_next_instruction = false

func replace_lc_tags(full_line_text:String) -> String:
	var lc_position := full_line_text.find("<lc>")
	while lc_position != -1:
		var context_start := full_line_text.rfind("[]>", lc_position)
		var actor : String
		if full_line_text.find("{", context_start) != -1:
			var context_end : int = min(
				full_line_text.find("{", context_start),
				full_line_text.find(":", context_start))
			actor = full_line_text.substr(context_start + 3, context_end - (context_start + 3))
		else:
			var context_end : int = full_line_text.find(":", context_start)
			actor = full_line_text.substr(context_start + 3, context_end - (context_start + 3))
		full_line_text = full_line_text.erase(lc_position, "<lc>".length())
		full_line_text = full_line_text.insert(lc_position, "\n[]>%s:" % actor)
		lc_position = full_line_text.find("<lc>")
	return full_line_text


func _get_prepend_separator_sequence() -> String:
	return str(" " if inline_name_space_prefix else "", inline_name_separator, " " if inline_name_space_suffix else "")

func _get_end_of_chunk_position() -> int:
	if _pause_positions.size() == 0:
		return body_label.text.length()
	elif _pause_types[_next_pause_position_index] == _PauseTypes.EoL:
		return body_label.text.length()
	else:
		return _pause_positions[_next_pause_position_index] - 4 * _next_pause_position_index# - prepend_offset

func _get_current_text_speed() -> float:
	if custom_text_speed_override > 0:
		return custom_text_speed_override
	
	var current_text_speed := text_speed
	if body_label.visible_characters < _text_speed_by_character_index.size() and body_label.visible_characters != -1:
		var value = _text_speed_by_character_index[body_label.visible_characters]
		current_text_speed = value if value != -1 else text_speed
	
	return current_text_speed

func _process(delta: float) -> void:
	# this is a @tool script so this prevents the console from getting flooded
	if Engine.is_editor_hint():
		return
	
	if Parser.paused:
		return
	
	_update_input_prompt(delta)
	var new_block := is_advance_blocked(false, include_auto_continue_in_accept_advance_signal)
	if _is_advance_blocked != new_block:
		if new_block:
			emit_signal("stop_accepting_advance")
		else:
			emit_signal("start_accepting_advance")
	_is_advance_blocked = new_block
	
	if is_executing:
		if delay_before > 0:
			delay_before -= delta
			return
		
		if not has_executed:
			ParserEvents.instruction_started_after_delay.emit(execution_text, delay_before)
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
		
		_on_instruction_wrapped_completed()
		ParserEvents.instruction_completed_after_delay.emit(execution_text, delay_after)
		
		is_executing = false
		return
	
	if _showing_text:
		if _text_delay > 0:
			_text_delay -= delta
			return
	
	
	var visible_characters_before_inline_call = body_label.visible_characters
	if awaiting_inline_call:
		return
	
	if _lead_time > 0:
		_lead_time -= delta
		return
	
	var current_text_speed := _get_current_text_speed()
	
	if _next_pause_position_index < _pause_positions.size() and _next_pause_position_index != -1:
		_find_next_pause()
	if body_label.visible_characters < _get_end_of_chunk_position():
		if current_text_speed == MAX_TEXT_SPEED:
			body_label.visible_characters = _get_end_of_chunk_position()
		else:
			var old_text_length : int = body_label.visible_characters
			if full_words:
				var next_space_position = body_label.text.find(" ", body_label.visible_characters + 1)
				if body_label.visible_ratio != 1:
					_full_word_timer -= delta
				if _full_word_timer <= 0 or old_text_length == 0:
					body_label.visible_characters = min(next_space_position, _get_end_of_chunk_position())
					_full_word_timer = (MAX_TEXT_SPEED / current_text_speed) * delta * 5.0 # avg word length whatever
			else:
				body_label.visible_ratio += (float(current_text_speed) / body_label.get_parsed_text().length()) * delta
			# fast text speed can make it go over the end  of the chunk
			body_label.visible_characters = min(body_label.visible_characters, _get_end_of_chunk_position())
			if old_text_length != body_label.visible_characters:
				ParserEvents.visible_characters_changed.emit(old_text_length, body_label.visible_characters)
	elif _remaining_auto_pause_duration > 0 and _next_pause_type == _PauseTypes.Auto:
		var last_dur = _remaining_auto_pause_duration
		_remaining_auto_pause_duration -= delta
		if last_dur > 0 and _remaining_auto_pause_duration <= 0:
			_next_pause_position_index += 1
			_find_next_pause()
			_remaining_auto_pause_duration = auto_pause_duration
	
	
	var new_characters_visible_so_far = body_label.text.substr(0, body_label.visible_characters)
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
		if body_label.text.ends_with(_started_word_buffer):
			if not _started_word_buffer.is_empty():
				_remove_spaces_and_send_word_read_event(_remove_symbols(_started_word_buffer))
				_started_word_buffer = ""
	_characters_visible_so_far = new_characters_visible_so_far
	
	if current_text_speed < MAX_TEXT_SPEED:
		if _last_visible_ratio < 1.0 and body_label.visible_ratio >= 1.0:
			ParserEvents.body_label_filled.emit()
		if _last_visible_ratio != body_label.visible_ratio:
			ParserEvents.body_label_visible_ratio_changed.emit(body_label.visible_ratio)
		if _last_visible_characters != body_label.visible_characters:
			ParserEvents.body_label_visible_characters_changed.emit(body_label.visible_characters)
		
	for pos : int in _call_strings:
		if _can_handle_text_position(pos, "_called_positions"):
			_call_from_position(pos)
	if awaiting_inline_call:
		body_label.visible_characters = visible_characters_before_inline_call
	for pos : int in _comments:
		if _can_handle_text_position(pos, "_handled_comments"):
			_emit_comment(pos)
	
	_last_visible_ratio = body_label.visible_ratio
	_last_visible_characters = body_label.visible_characters
	if body_label.get_parsed_text().length() == body_label.visible_characters:
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
		if body_label.visible_characters >= _pause_positions[_next_pause_position_index] - 4 * _next_pause_position_index or body_label.visible_characters == -1:
			_auto_continue_duration -= delta
			if _auto_continue_duration <= 0.0:
				advance()

func _can_handle_text_position(pos: int, tracker_array:StringName) -> bool:
	return (
			((not get(tracker_array).has(pos)) and _last_visible_characters >= pos) or
			(pos >= _last_visible_characters and pos <= body_label.visible_characters) or
			body_label.visible_characters == -1
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
	
	if show_input_prompt:
		if not prompt_unfinished:
			push_error("show_input_prompt is true but prompt_unfinished not set. Either disable show_input_prompt or set prompt_unfinished.")
			return
		if not prompt_finished:
			push_error("show_input_prompt is true but prompt_finished not set. Either disable show_input_prompt or set prompt_finished.")
			return
	
	var prompt_visible: bool

	if body_label.visible_ratio >= 1.0:
		prompt_visible = true
	elif _next_pause_position_index > _pause_positions.size() and _next_pause_position_index != -1:
		prompt_visible = true
	elif _pause_positions.size() > 0 and _next_pause_type == _PauseTypes.Manual:
		if body_label.visible_characters == _pause_positions[_next_pause_position_index] - 4 * _next_pause_position_index:
			prompt_visible = true
		else:
			prompt_visible = false
	else:
		prompt_visible = false
	
	if body_label.visible_characters < _get_end_of_chunk_position():
		prompt_visible = false
		if body_label.visible_characters == -1:
			prompt_visible = true
	
	if is_executing:
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
	if body_label.visible_ratio >= 1.0:
		target_prompt = prompt_finished
		prompt_unfinished.visible = false
		prompt_finished.visible = true
	else:
		target_prompt = prompt_unfinished
		prompt_finished.visible = false
		prompt_unfinished.visible = true
	
	target_prompt.modulate.a = lerp(target_prompt.modulate.a, 1.0, input_prompt_lerp_weight)

func _replace_tags(lines:Array) -> Array:
	for call in body_label_function_funnel:
		var i := 0
		while i < lines.size():
			var text : String = lines[i]
			lines[i] = str(callv_custom(call, [text]))
			i += 1
	
	var i := 0
	var result := []
	while i < lines.size():
		var new_text:String = lines[i]
		var scan_index := 0
		var text_length := new_text.length()
		while scan_index < text_length:
			if new_text[scan_index] == "<":
				var name_tag = new_text.find("<name:", scan_index) == scan_index
				var clname_tag = new_text.find("<clname:", scan_index) == scan_index
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
					new_text = new_text.replace(control_to_replace, str(get_property_from_self_or_autoload(var_name)))
				elif new_text.find("<func:", scan_index) == scan_index:
					var local_scan_index := scan_index + 6
					var func_text := ""
					while new_text[local_scan_index] != ">":
						func_text += new_text[local_scan_index]
						local_scan_index += 1
					new_text = new_text.replace(str("<func:", func_text, ">"), call_from_string(func_text, CallMode.Func))
				elif name_tag or clname_tag:
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
					if name_tag:
						new_text = new_text.replace(control_to_replace, _get_actor_name(name_key))
					elif clname_tag:
						new_text = new_text.replace(control_to_replace, _get_actor_name(name_key))
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
func _attempt_read_previous_dialine() -> bool:
	var dialog_line_failure := false
	if _dialog_line_index <= 0:
		dialog_line_failure = true
	else:
		_set_dialog_line_index(_dialog_line_index - 1)
		return true
	
	if dialog_line_failure:
		return false
	
	return true

# wrapper should be prefix or suffix
func _get_contextual_actor_body_wrapper(wrapper:String) -> String:
	if chatlog_enabled:
		if get(str("chatlog_include_body_label_actor_", wrapper)):
			return get_actor_config_property(str("body_label_", wrapper), current_raw_name, "")
	else:
		return get_actor_config_property(str("body_label_", wrapper), current_raw_name, "")
	return ""

func _insert_strings_in_current_dialine():
	var new_text : String = _dialog_lines[_dialog_line_index]
	new_text = trim_trimmables(new_text)
	var ends_with_advance := new_text.ends_with("<advance>")
	new_text = new_text.trim_suffix("<advance>")
	
	# prepend name
	if name_style == NameStyle.Prepend and (not current_raw_name in blank_names) and not chatlog_enabled:
		new_text = new_text.trim_prefix(_full_prefix) # when calling set_actor_config_property mid line, the previous prefix is still here so we need to clean it up
		
		var display_name: String = _get_actor_name(current_raw_name)
		
		var wrappers := _get_actor_color_prepend_tag_pair(current_raw_name)
		_full_prefix = str(
			name_prefix,
			get_actor_config_property("name_prefix", current_raw_name, ""),
			wrappers[0],
			display_name,
			wrappers[1],
			get_actor_config_property("name_suffix", current_raw_name, ""),
			name_suffix,
			_get_prepend_separator_sequence(),
		)
		new_text = str(
			_full_prefix,
			new_text
			)
		
		_prepend_length = _full_prefix.length()
	
	
	new_text = str(
		body_label_prefix,
		_get_contextual_actor_body_wrapper("prefix"),
		new_text,
		_get_contextual_actor_body_wrapper("suffix"),
		body_label_suffix,
		)
	
	for word in body_label_word_wrappers.keys():
		var wrapper : PackedStringArray = body_label_word_wrappers.get(word).split(" ")
		if wrapper.size() != 2:
			push_error(str("Word ", word, " has invalid wrapper!"))
			continue
		new_text = new_text.replace(word, str(wrapper[0], word, wrapper[1]))
	
	if ends_with_advance:
		new_text = str(new_text, "<advance>")
	
	_dialog_lines[_dialog_line_index] = new_text

func _handle_tags_and_start_reading():
	_remaining_prompt_delay = input_prompt_delay
	if text_speed == MAX_TEXT_SPEED:
		body_label.visible_ratio = 1.0
	else:
		body_label.visible_ratio = 0
		body_label.visible_characters = _prepend_length
	
	_pause_positions.clear()
	_pause_types.clear()
	_call_strings.clear()
	_called_positions.clear()
	_handled_comments.clear()
	var text_speed_override := -1.0
	_text_speed_by_character_index.clear()
	
	var new_text : String = _dialog_lines[_dialog_line_index]
	new_text = trim_trimmables(new_text)
	
	if new_text.contains("<advance>") and not new_text.ends_with("<advance>"):
		push_warning(str("Dialog line \"", new_text, "\" contains an <advance> tag that is not at the end of the line."))
	_auto_advance = new_text.ends_with("<advance>")
	new_text = new_text.trim_suffix("<advance>")
	
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
					text_speed_override = clamp(float(value) * text_speed, 1, MAX_TEXT_SPEED - 1)
				elif bbcode_removed_text.find("<ts_abs:", scan_index) == scan_index:
					var value := float(tag_string.trim_suffix(">").split(":")[1])
					text_speed_override = clamp(float(value), 1, MAX_TEXT_SPEED - 1)
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
	
	_prepend_length = 0
	if name_style == NameStyle.None:
		name_container.modulate.a = 0.0
	elif name_style == NameStyle.Prepend:
		name_container.modulate.a = 0.0
		
	
	if body_label_tint_lines and not chatlog_enabled:
		cleaned_text = str("[color=", _get_actor_color(current_raw_name).to_html(), "]", cleaned_text, "[/color]")
	
	var old_text = body_label.text
	_set_body_label_text(cleaned_text)
	ParserEvents.body_label_text_changed.emit(old_text, cleaned_text, _lead_time)
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


var awaiting_inline_call := ""

func _call_from_position(call_position: int):
	var strings : Array = _call_strings.get(call_position)
	_called_positions.append(call_position)
	var last_call := ""
	for text : String in strings:
		text = text.trim_prefix("<call:")
		text = text.trim_suffix(">")
		var result = call_from_string(text, CallMode.Call, call_position)
		if result is bool:
			if result:
				last_call = text
				if _get_current_text_speed() == MAX_TEXT_SPEED and call_position != 0:
					push_warning(
						str("You are calling ", text, " while text speed is MAX_TEXT_SPEED. The function ", text, " makes the LineReader await execution, so this may lead to unintended behavior.")
					)
	_call_strings.erase(call_position)
	awaiting_inline_call = last_call

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

func _set_body_label_text(text: String):
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
			past_line.custom_minimum_size.x = body_label.custom_minimum_size.x
			past_line.fit_content = true
			past_line.bbcode_enabled = true
			past_line.mouse_filter = Control.MOUSE_FILTER_PASS
		
		var past_text := ""
		# TODO this is kinda a hack and only properly worth with prepend name style because
		# if you switch target labels, it tracks the wrong last raw name
		# lonerdogmoment
		# but it works for now
		if not _last_raw_name in blank_names and not body_label.text.is_empty() and not chatlog_enabled and (name_style == NameStyle.NameLabel and preserve_name_in_past_lines):
			var actor_prefix := _wrap_in_color_tags_if_present(_last_raw_name)
			past_text = str(actor_prefix, _get_prepend_separator_sequence())
		
		if not preserve_name_in_past_lines and name_style == NameStyle.Prepend:
			push_warning("preserve_name_in_past_lines is false but name_style is set to Prepend. There will be a name in past lines.")
		
		var body_label_to_save = body_label.text
		
		past_text += body_label_to_save
		past_line.text = past_text
		past_lines_container.add_child(past_line)

	if body_label:
		body_label.text = text
		body_label.visible_ratio = 0
		body_label.visible_characters = _prepend_length
		_body_duplicate.text = body_label.text
		#_body_duplicate_last_line.text = body_label.get_parsed_text()
	_characters_visible_so_far = ""
	_started_word_buffer = ""
	
	_last_raw_name = current_raw_name

func get_body_label_text_draw_pos(index:int) -> Vector2:
	_body_duplicate.add_theme_font_override("normal_font", body_label.get_theme_font("normal_font", "RichTextLabel"))
	_body_duplicate.add_theme_font_size_override("normal_font_size", body_label.get_theme_font_size("normal_font_size", "RichTextLabel"))
	_body_duplicate.add_theme_stylebox_override("normal", body_label.get_theme_stylebox("normal", "RichTextLabel"))
	_body_duplicate.text = body_label.text
	_body_duplicate.custom_minimum_size = body_label.custom_minimum_size
	_body_duplicate.size = body_label.size
	
	if index == 0:
		_body_duplicate.visible_characters = -1
		return Vector2(0, _body_duplicate.get_content_height())
	if index >= body_label.get_parsed_text().length():
		push_warning("Index %s for get_body_label_text_draw_rect is out of bounds (%s)" % [index, _body_duplicate.text.length()])
		return Vector2.ZERO
	#prints("got index ", index, "got lenfth ", _body_duplicate.text.length())
	
	#_body_duplicate_last_line.text = body_label.get_parsed_text()
	
	var current_line := 0
	var line_sum := 0
	
	# take substr and the length of that
	# take left(index) substr for content height
	_body_duplicate.visible_characters = index
	
	var height : int = _body_duplicate.get_content_height() 
	
	# get target line
	_body_duplicate.visible_characters = -1
	var target_line : int = body_label.get_character_line(index)
	var target_line_range : Vector2i
	for i in _body_duplicate.get_line_count():
		var range = body_label.get_line_range(i)
		if index >= range.x and index <= range.y:
			target_line = i
			target_line_range = range
			break
	
	#print("line of ", index, " is ", target_line, target_line_range)
	var trailing_line = _body_duplicate.get_parsed_text().substr(target_line_range.x, target_line_range.y - target_line_range.x)
	#print(trailing_line)
	_body_duplicate.text = trailing_line
	var width : int = _body_duplicate.get_content_width()
	#print(line_start_index)
	# search to left / desc indices until the character line changes
	# ^^^^ TRY THIS I THINK I COOKED
	
	
	return Vector2(width, height)
	var label_height := _body_duplicate.get_content_height()
	_body_duplicate.text = _body_duplicate.text.left(index)
	# get last line for width
	_body_duplicate_last_line.text = _body_duplicate_last_line.text.left(index)
	var i := target_line
	while i > 0:
		_body_duplicate_last_line.remove_line_at(0)
		i -= 1
	print(_body_duplicate_last_line.text)
	body_label.get_theme_stylebox("normal", "RichTextLabel")
	# get the one line
	# create another label with just that line
	#_body_duplicate.text = target_line
	#var width = _body_duplicate.get_content_width()
	
	
	#return Vector2(width, _body_duplicate_line_height * target_line)
	# give it shrink left align
	# get its size
	#while current_line < target_line:
		#line_sum += body_label.get_colum
	##while line_sum < index:
		##body_label.get_character_line()
		##var line_sum_to_be = line_sum + _body_duplicate.get_line(current_line).length()
		##if index >= line_sum and index <= line_sum_to_be:
			##break
		##line_sum = line_sum_to_be
		##current_line += 1
	#_body_duplicate.get_character_line()
	#var column := index - line_sum
	#printt(current_line, column)
	#var dup_rect := _body_duplicate.get_rect_at_line_column(current_line, column)
	#dup_rect.position += Vector2i(body_label.position)
	#return dup_rect

## If showing text. Resets on successful [method request_advance] call.
func add_text_display_delay(duration:float):
	_text_delay += duration

func _wrap_in_color_tags_if_present(actor_name:String) -> String:
	var color : Color = _get_actor_color(_last_raw_name)
	if color != Color.TRANSPARENT:
		var code = color.to_html(false)
		return str("[color=", code, "]", _get_actor_name(_last_raw_name), "[/color]")
	else:
		return _get_actor_name(actor_name)

#var _body_duplicate_line_height : int
## Sets [param body_label]. If [param keep_text] is [code]true[/code], the text from the previous [param body_label] will be transferred to the passed argument.
func set_body_label(new_body_label:RichTextLabel, keep_text := true):
	_body_duplicate.theme = new_body_label.get_theme()
	#_body_duplicate.visible_characters = 1
	#if _body_duplicate_line_height == 0:
		#_body_duplicate_line_height = _body_duplicate.get_content_height()
	_body_duplicate.size = new_body_label.size
	if new_body_label == body_label:
		return
	var switch_text:bool = body_label != new_body_label
	var old_text : String
	if switch_text and keep_text and body_label:
		old_text = body_label.text
	body_label = new_body_label
	if switch_text and keep_text:
		body_label.text = old_text

func set_name_controls(label, container:=name_container, keep_text:=true):
	name_container = container
	var old_text = name_label.text
	name_label = label
	if keep_text:
		name_label.text = old_text
	

## Helper function that you can use to switch [param keep_past_lines] to true and transfer all data to the [param new_label]. [param new_label] becomes [param body_label].
func enable_keep_past_lines(container: VBoxContainer, keep_text := false, new_label:=body_label, new_name_style := name_style):
	keep_past_lines = true
	self.past_lines_container = container
	name_style = new_name_style
	set_body_label(new_label, keep_text)

func _find_next_pause():
	if _pause_types.size() > 0 and _next_pause_position_index < _pause_types.size():
		_next_pause_type = _pause_types[_next_pause_position_index]

func _get_full_prepend_name_prefix(actor:String) -> String:
	if name_style != NameStyle.Prepend:
		return ""
	return get_actor_config_property("name_prefix", actor) + _get_actor_name(actor) + _get_prepend_separator_sequence() + get_actor_config_property("name_suffix", actor)

func _get_actor_name(actor_key:String) -> String:
	if not actor_config.has(actor_key):
		return actor_key
	var display_name : String = get_actor_config_property(str("chatlog_" if chatlog_enabled else "", "name_display"), actor_key)
	if display_name.is_empty():
		display_name = get_actor_config_property("name_display", actor_key, actor_key)
	return display_name

func _get_actor_color(actor:String) -> Color:
	return _get_actor_color_config("color", actor)
func _get_actor_outline_color(actor:String) -> Color:
	return _get_actor_color_config("outline_color", actor)
func _get_actor_outline_size(actor:String) -> int:
	return get_actor_config_property("outline_size", actor, 0)

## Sensitive to chatlog_enabled. If blank, returns label or richtextlabel default color depending on name style
## base_property is either color or outline_color
func _get_actor_color_config(base_property:String, actor_key:String) -> Color:
	if actor_config.has(actor_key):
		var color : Color = (actor_config.get(actor_key) as LineReaderActorConfig).get(str("chatlog_" if chatlog_enabled else "", base_property))
		if color == Color.TRANSPARENT:
			color = (actor_config.get(actor_key) as LineReaderActorConfig).get(base_property)
		if color != Color.TRANSPARENT:
			return color
		
	if name_style == NameStyle.Prepend or chatlog_enabled: # prepend goes in body_label
		return body_label.get_theme_color("default_color", "RichTextLabel")
	else:
		return name_label.get_theme_color("font_color", "Label")
	

## returns array of size 2: prefix and suffix
func _get_actor_color_prepend_tag_pair(actor: String) -> Array:
	var color : Color = _get_actor_color_config("color", actor)
	var outline_color : Color = _get_actor_color_config("outline_color", actor)
	var outline_size : int = get_actor_config_property(str("chatlog_" if chatlog_enabled else "", "outline_size"), actor, 0)
	
	var prefix := str(
		"[color=", color.to_html(), "]",
		"[outline_color=", outline_color.to_html(), "]",
	)
	var suffix := "[/outline_color][/color]"
	
	# there's a bug where outline size 0 will throw an error that doesn't do anything
	if outline_size > 0:
		prefix += str("[outline_size=", outline_size, "]")
		suffix = str("[/outline_size]", suffix)
	
	return [prefix, suffix]

## Helper function derived from [method set_actor_config_property].
func set_actor_name(actor_key:String, actor_name:String):
	set_actor_config_property("name_display", actor_key, actor_name)
## Helper function derived from [method set_actor_config_property].
func set_actor_color(actor_key:String, color:Color):
	set_actor_config_property("color", actor_key, color)

## Helper function to set a color-based actor config with float values for RGB. See [method set_actor_config_property].
func set_actor_config_property_color(config_property:String, actor_key:String, r:float, g:float, b:float):
	var color = Color(r,g,b)
	set_actor_config_property(config_property, actor_key, color)

## Sets the passed property and updates the dialog line accordingly. See [LineReaderActorConfig].[br][br]
## [b]Note:[/b] Updating this mid-dialog line will have no effect if [member chatlog_enabled] is true.
func set_actor_config_property(config_property:String, actor_key:String, value):
	var previous_value
	if actor_config.has(actor_key):
		previous_value = get_actor_config_property(config_property, actor_key)
		(actor_config.get(actor_key) as LineReaderActorConfig).set(config_property, value)
	else:
		var new_config = LineReaderActorConfig.new()
		new_config.set(config_property, value)
		actor_config[actor_key] = new_config
	
	# update display string
	if previous_value != value:
		update_body_label()

func set_name_prefix(prefix : String, update := true):
	var old_prefix = name_prefix
	name_prefix = prefix
	if name_prefix != old_prefix and update:
		update_body_label()

func set_name_suffix(suffix : String, update := true):
	var old_suffix = name_suffix
	name_suffix = suffix
	if name_suffix != old_suffix and update:
		update_body_label()

func update_body_label():
	var visible_characters = body_label.visible_characters
	_set_dialog_line_index(_dialog_line_index)
	body_label.visible_characters = visible_characters

func get_actor_config_property(config_property:String, actor_key:String, default : Variant = null) -> Variant:
	if not actor_config.has(actor_key):
		return default
	return (actor_config.get(actor_key) as LineReaderActorConfig).get(config_property)

func _build_choices(choices, auto_switch:bool):
	if not choice_container:
		push_error("Tried to build choices when choice_container is null")
		return
	if not choice_list:
		push_error("Tried to build choices when choice_list is null")
		return
	
	for c in choice_list.get_children():
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
		
		choice_list.add_child(new_option)
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
	
	if choice_list.get_child_count() > 0 and choice_button_keyboard_focus:
		choice_list.get_child(0).call_deferred("grab_focus")
	
	ParserEvents.choices_presented.emit(built_choices)
	
	if virtual_choices:
		_built_virtual_choices = built_choices
		for c in choice_list.get_children():
			c.visible = false

func _set_choice_title_or_warn(title: String):
	current_choice_title = title
	if choice_title_label:
		choice_title_label.visible = not title.is_empty()
		choice_title_label.text = title
	elif not title.is_empty():
		push_warning(str("Choice Title Label not set. Choice Title \"", title,"\" will be not be displayed."))


func _is_choice_presented() -> bool:
	if (not choice_container) or (not choice_list):
		return false
	if virtual_choices:
		return not _built_virtual_choices.is_empty()
	return (not choice_list.get_children().is_empty()) and choice_container.visible

## [param index] is the index of the choice emitted in [signal ParserEvents.choices_presented].
func choice_pressed_virtual(index:int):
	var choice_data : Dictionary = _built_virtual_choices[index]
	var button : ChoiceButton = choice_data.get("button")
	button.on_pressed()

func _choice_pressed(do_jump_page: bool, target_page : int, target_line : int):
	_built_virtual_choices.clear()
	for c in choice_list.get_children():
		c.queue_free()
	if do_jump_page:
		emit_signal("jump_to_page", target_page, target_line)
		return
	emit_signal("line_finished", line_index)
	

## returns an array of size 2. index 0 is if the conditionals are satisfied. index 1 is the behavior if it's true
func evaluate_conditionals(conditionals, enabled_as_default := true) -> Array:
	var conditional_is_true := true
	var behavior = conditionals.get("behavior_key")
	var args : Array = conditionals.get("operand_args")
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
			if args[0] > args[1]:
				args.reverse()
			conditional_is_true = true_facts.size() >= args[0] and true_facts.size() <= args[1]
	
	return [conditional_is_true, behavior]


func _handle_header(header: Array):
	var header_data := {}
	for prop in header:
		var data_type = prop.get("data_type")
		var property_name = prop.get("property_name")
		var values : Array = prop.get("values")
		
		var actual_value
		match int(data_type):
			Pages.DataTypes._String:
				actual_value = str(values[0])
			Pages.DataTypes._DropDown:
				actual_value = Parser.get_dropdown_strings_from_header_values(values)
			Pages.DataTypes._Boolean:
				actual_value = bool(values[0])
		
		header_data[property_name] = actual_value
	
	ParserEvents.new_header.emit(header_data)


func _set_dialog_line_index(value: int):
	_dialog_line_index = value
	
	if Parser.use_dialog_syntax:
		var raw_name : String = _dialog_actors[_dialog_line_index]
		var actor_name: String = _trim_syntax_and_emit_dialog_line_args(raw_name)
		update_name_label(actor_name)
	
	_insert_strings_in_current_dialine()
	_handle_tags_and_start_reading()
	ParserEvents.start_new_dialine.emit(_dialog_line_index)

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
	ParserEvents.actor_name_about_to_change.emit(actor_name)
	_is_last_actor_name_different = actor_name != current_raw_name
	current_raw_name = actor_name
	
	var display_name : String = _get_actor_name(actor_name)
	var name_color : Color = _get_actor_color(actor_name)
	var name_outline_color : Color = _get_actor_outline_color(actor_name)
	var name_outline_size : int = _get_actor_outline_size(actor_name)
	
	if name_style == NameStyle.NameLabel:
		name_label.text = str(
			name_prefix,
			display_name,
			name_suffix
		)
		name_label.add_theme_color_override("font_color", name_color)
		name_label.add_theme_color_override("font_outline_color", name_color)
		name_label.add_theme_color_override("outline_size", name_color)
		
		if actor_name in blank_names or chatlog_enabled:
			name_container.modulate.a = 0.0
		else:
			name_container.modulate.a = 1.0
	
	var name_visible:bool
	if name_style == NameStyle.NameLabel:
		name_visible = name_container.modulate.a > 0.0
	elif name_style == NameStyle.Prepend:
		name_visible = current_raw_name in blank_names
	elif name_style == NameStyle.None:
		name_visible = false
	
	ParserEvents.display_name_changed.emit(display_name, name_visible)
	ParserEvents.actor_name_changed.emit(actor_name, name_visible)


func _can_text_container_be_visible() -> bool:
	if line_type == DIISIS.LineType.Text:
		return show_text_during_text or text_container.visible
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
	_currently_speaking_visible = is_name_container_visible and name_style == NameStyle.NameLabel

func get_subaddress() -> String:
	return str(Parser.page_index, ".", line_index, ".", _dialog_line_index)

## returns length 3 if text or length 2 if not text
func get_subaddress_arr(fill_with_zero := true) -> Array:
	var result := [Parser.page_index, line_index]
	if line_type == DIISIS.LineType.Text and Pages.use_dialog_syntax:
		result.append(_dialog_line_index)
	elif fill_with_zero:
		result.append(0)
	return result

## Automation to append stuff to parser history
func _on_body_label_text_changed(old_text: String,
	new_text: String,
	lead_time: float):
	var sub_address := get_subaddress()
	if _subaddresses_in_history.has(sub_address):
		return
	_subaddresses_in_history.append(sub_address)
	var name_prefix : String
	if _currently_speaking_name in blank_names:
		name_prefix = "    "
	elif _currently_speaking_visible:
		name_prefix = str("[b]", _get_full_prepend_name_prefix(_currently_speaking_name), "[/b]: ")
	else:
		name_prefix == ""
	Parser.call_deferred("append_to_history", (str(name_prefix, new_text)))

func _on_comment(comment: String, pos : int):
	prints(str(Parser.get_address(), ":", pos), comment)


#region InstructionHandler
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

func serialize_instruction_handler_data() -> Dictionary:
	return {
		"delay_before" : delay_before,
		"delay_after" : delay_after,
		"execution_text" : execution_text,
		"is_executing" : is_executing,
		"has_executed" : has_executed,
		"has_received_execute_callback" : has_received_execute_callback,
		"emitted_complete" : emitted_complete,
	}

func deserialize_instruction_handler_data(data: Dictionary):
	for key in data:
		set(key, data.get(key))

func finish_waiting_for_instruction():
	has_received_execute_callback = true
	
	if not emitted_complete and delay_after <= 0:
		ParserEvents.instruction_completed.emit(execution_text, delay_after)
		_on_instruction_wrapped_completed()
		ParserEvents.instruction_completed_after_delay.emit(execution_text, delay_after)
		is_executing = false
		emitted_complete = true

func _wrapper_execute(text : String, delay_before_seconds := 0.0, delay_after_seconds := 0.0):
	await get_tree().process_frame
	delay_after = delay_after_seconds
	delay_before = delay_before_seconds
	execution_text = text
	has_executed = false
	is_executing = true
	has_received_execute_callback = true
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
		result = get_tree().root.get_node(autoload).callv(func_name, args)
	else:
		result = callv(func_name, args)
	match call_mode:
		CallMode.Func:
			return str(result)
		CallMode.Call:
			ParserEvents.function_called.emit(func_name, args, call_position, result)
			return result

func callv_custom(method_name:String, argv):
	var autoload : String
	if "." in method_name:
		autoload = method_name.split(".")[0]
	var result
	if autoload:
		method_name = method_name.split(".")[1]
		result = get_tree().root.get_node(autoload).callv(method_name, argv)
	else:
		result = callv(method_name, argv)
	return result

func execute(instruction_text: String) -> bool:
	var instruction_name := instruction_text.split("(")[0]
	if (not has_method(instruction_name)) and (not "." in instruction_name):
		push_error(str("Function ", instruction_name, " not found in ", get_script().get_global_name(),"."))
		return false
	var result = call_from_string(instruction_text)
	if not result is bool:
		if warn_on_non_bool_function_return:
			push_warning(str("Function ", instruction_name, " in ", get_script().get_global_name(), " should return true or false."))
		return false
	return result

#endregion

## Returns an array of all actors that speak in this line. If [param empty_if_not_text] is true (default), the array will be empty if the current line isn't of type [enum DIISIS.LineType.Text].
func get_actor_names_in_line(empty_if_not_text:=true) -> Array:
	if empty_if_not_text:
		if line_type != DIISIS.LineType.Text:
			return []
	var result := []
	for actor in _dialog_actors:
		if not actor in result:
			result.append(actor)
	return result

func set_chatlog_enabled(value:bool):
	chatlog_enabled = value

func set_custom_text_speed_override(value:int):
	custom_text_speed_override = value

#func _fit_to_max_line_count(lines: Array):
	#if body_label_max_lines <= 0 or chatlog_enabled:
		#return
	#
	#var new_chunks := []
	#var label : RichTextLabel = RichTextLabel.new()
	#add_child(label)
	#label.visible = false
	#label.bbcode_enabled = true
	#label.theme = body_label.get_theme()
	#label.size = body_label.size
	#
	#var i := 0
	#while i < lines.size():
		#var line_height:=0
		#var content_height := 0
		#
		#var name_prefix:String
		#var name_length:int
		#if name_style == NameStyle.Prepend:
			#var actor_name = _dialog_actors[_dialog_line_index]
			#var display_name: String = name_map.get(_dialog_actors[_dialog_line_index], _dialog_actors[_dialog_line_index])
			#display_name = display_name.substr(0, display_name.find("{"))
			#name_prefix = str(_wrap_in_color_tags_if_present(actor_name), _get_prepend_separator_sequence())
			#name_length = display_name.length() + _get_prepend_separator_sequence().length()
		#elif name_style == NameStyle.NameLabel:
			#name_prefix = ""
			#name_length = 0
		#
		#var line:String = lines[i]
		#label.text = line
		#label.visible_characters = 1
		#if line_height == 0:
			#line_height = label.get_content_height()
		#
		#label.text = str(name_prefix,line,)
		#
		#while content_height <= line_height * body_label_max_lines:
			#if label.text.is_empty():
				#break
			#label.visible_characters += 1
			#content_height = label.get_content_height()
			#if content_height > line_height * body_label_max_lines:
				#label.text = label.text.trim_prefix(name_prefix)
				#label.visible_characters -= 1
				#label.visible_characters -= name_length
				#while label.text[label.visible_characters] != " ":
					#label.visible_characters -= 1
				#label.bbcode_enabled = false
				#var bbcode_padding := 0
				#var scan_index := 0
				#while scan_index < label.visible_characters:
					#scan_index += 1
					#if label.text[scan_index] == "[":
						#if label.text[scan_index-1] == "\\[":
							#scan_index += 1
							#continue
						#var tag_end = label.text.find("]", scan_index)
						#if label.text.length() >= scan_index + 3:
							#if (
								#label.text[scan_index + 1] == "i" and
								#label.text[scan_index + 2] == "m" and
								#label.text[scan_index + 3] == "g"):
									#tag_end = label.text.find("[/img]") + 5
							#elif (
								#label.text[scan_index + 1] == "u" and
								#label.text[scan_index + 2] == "r" and
								#label.text[scan_index + 3] == "l"):
									#tag_end = label.text.find("[/url]") + 5
						#bbcode_padding += tag_end - scan_index + 2
						#scan_index = tag_end
				#
				#
				#var fitting_raw_text := label.text.substr(0, label.visible_characters + bbcode_padding)
				#line = line.trim_prefix(fitting_raw_text)
				#label.text = line
				#new_chunks.append(fitting_raw_text)
				#label.bbcode_enabled = true
				#content_height = 0
				#label.visible_characters = 0
				#continue
			#
			#if label.visible_ratio == 1.0:
				#new_chunks.append(line)
				#break
			#
		#i += 1
	##_line_chunks = new_chunks
	#label.queue_free()
