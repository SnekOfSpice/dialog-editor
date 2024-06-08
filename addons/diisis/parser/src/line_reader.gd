@icon("res://addons/diisis/parser/style/reader_icon_Zeichenfläche 1.svg")
@tool
extends Control
class_name LineReader

const MAX_TEXT_SPEED := 201

#enum ChoiceButtonFocusMode {
	#KeyboardOnly,
	#MouseOnly,
	#All,
#}

enum NameStyle {
	NameLabel,
	Prepend,
}

## Find an extensive tutorial on how to set up your [LineReader] on GitHub!
## @tutorial(Quick Start Guide): https://github.com/SnekOfSpice/dialog-editor/wiki/Quick-Start-Guide-%E2%80%90-LineReader-&-Parser

@export_group("UX")
@export_subgroup("Text Behavior")
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
## Time before the line reader automatically continues, in seconds.
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
## If [code]true[/code], shows [param text_container] when choices are presented.
@export var show_text_during_instructions := false
@export var keep_past_lines := false:
	set(value):
		keep_past_lines = value
		notify_property_list_changed()
		update_configuration_warnings()
@export var past_text_continer : VBoxContainer:
	get:
		return past_text_continer
	set(value):
		past_text_continer = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

@export_subgroup("Choices")
## Button scene that gets instantiated as children of [member choice_option_container].[br]
## If left unassigned, will use a default button.[br]
## If overridden, it must inherit from [ChoiceButton].
@export var button_scene:ChoiceButton
## If [code]false[/code], the [LineReader] can still be advanced with [method LineReader.advance], even if
## Choice Buttons are currently presented to the player.
@export var block_advance_during_choices:=true
#@export var give_focus_to_choice_button := false
#@export var choice_button_focus_mode := ChoiceButtonFocusMode.MouseOnly

@export_subgroup("Advance")
@export var show_advance_available := false:
	set(value):
		show_advance_available = value
		notify_property_list_changed()
		update_configuration_warnings()
@export_range(0.0, 1.0) var advance_available_lerp_weight := 0.1
@export_range(0.0, 10.0) var advance_available_delay := 0.5
@export var next_prompt_container: Control
var remaining_advance_delay := advance_available_delay

@export_group("Names & Text Display")
## The name of the dropdown property used for keying names. Usually something like "character"
@export
var property_for_name := ""
## If set, this name will instead hide the name label alltogether.
@export
var name_for_blank_name := ""
@export var name_map := {}
@export var name_colors := {}
@export var name_style : NameStyle = NameStyle.NameLabel
var visible_prepend_offset := 0

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

## Your custom handling of instructions defined in the dialog editor. Must extend [InstructionHandler].
@export
var instruction_handler: InstructionHandler:
	get:
		return instruction_handler
	set(value):
		instruction_handler = value
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

## A [Label] that displays a currently speaking character's name.
@export
var name_label: Label:
	get:
		return name_label
	set(value):
		name_label = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

## The Control holding [member name_label]. Has its visiblity toggled by [member name_for_blank_name. May be the same Node as [member name_label].
@export
var name_container: Control:
	get:
		return name_container
	set(value):
		name_container = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

@export_group("Optional References")

## Node that has vars and funcs to evaluate in dynamic Strings. All functions within
## this node have to return a [String] (can be empty).
@export var inline_evaluator: Node


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
signal jump_to_page(page_index: int)
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
var next_pause_type := 0
enum PauseTypes {Manual, Auto, EoL}
var dialog_lines := []
var dialog_actors := []
var dialog_line_index := 0
var is_last_actor_name_different := true

var line_chunks := []
var chunk_index := 0
var current_raw_name := ""

var terminated := false

var started_word_buffer :=""
var characters_visible_so_far := ""

var last_visible_ratio := 0.0
var last_visible_characters := 0.0
var visibilities_before_interrupt := {}

signal line_reader_ready

func _validate_property(property: Dictionary):
	if not show_advance_available:
		if property.name in ["advance_available_delay", "advance_available_lerp_weight", "next_prompt_container"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	if not auto_continue:
		if property.name in ["auto_continue_delay"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	if not keep_past_lines:
		if property.name in ["past_text_continer"]:
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
	
	text_container.visible = can_text_container_be_visible()
	showing_text = line_type == DIISIS.LineType.Text
	choice_container.visible = line_type == DIISIS.LineType.Choice
	
	if line_type == DIISIS.LineType.Choice:
		var raw_content = line_data.get("content")
		var content = line_data.get("content").get("content")
		var choices = line_data.get("content").get("choices")
		var auto_switch : bool = raw_content.get("auto_switch")

		build_choices(choices, auto_switch)
	
	update_name_label(data.get("current_raw_name", name_for_blank_name))
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
	if not name_container and name_style == NameStyle.NameLabel:
		warnings.append("Name Container is null")
	if show_advance_available and not next_prompt_container:
		warnings.append("Next Prompt Container is null")
	if keep_past_lines and not past_text_continer:
		warnings.append("Past Text Container is null")
	
	return warnings

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	Parser.connect("read_new_line", read_new_line)
	Parser.connect("page_terminated", close)
	
	Parser.open_connection(self)
	
	remaining_auto_pause_duration = auto_pause_duration * (1.0 + (1-(text_speed / (MAX_TEXT_SPEED - 1))))
	
	if not instruction_handler:
		push_error("No InsutrctionHandler as child of LineReader.")
		return
	
	instruction_handler.connect("set_input_lock", set_is_input_locked)
	instruction_handler.connect("instruction_wrapped_completed", instruction_completed)
	text_content.visible_ratio = 0
	text_content.bbcode_enabled = true
	text_content.text = ""
	name_label.text = ""
	
	if not show_advance_available and next_prompt_container:
		next_prompt_container.modulate.a = 0
	
	emit_signal("line_reader_ready")

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
					emit_signal("line_finished", line_index)
				else:
					remaining_advance_delay = advance_available_delay
					set_dialog_line_index(dialog_line_index + 1)
					start_showing_text()
			else:
				remaining_advance_delay = advance_available_delay
				read_next_chunk()
		else:
			if next_pause_position_index < pause_positions.size():
				text_content.visible_characters = get_end_of_chunk_position() 
				if next_pause_type != PauseTypes.EoL:
					if next_pause_position_index < pause_positions.size() - 1:
						next_pause_position_index += 1
					find_next_pause()
					remaining_auto_pause_duration = remaining_auto_pause_duration * (1.0 + (1-(text_speed / (MAX_TEXT_SPEED - 1))))
					remaining_advance_delay = advance_available_delay
	else:
		emit_signal("line_finished", line_index)


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
			
			dialog_lines = replace_var_func_tags(dialog_lines)
			update_limit_line_count(dialog_lines)
			
			set_dialog_line_index(0)
			start_showing_text()
		DIISIS.LineType.Choice:
			var auto_switch : bool = raw_content.get("auto_switch")
			build_choices(choices, auto_switch)
		DIISIS.LineType.Instruction:
			if not instruction_handler:
				push_error("No InsutrctionHandler as child of LineReader.")
				return
			if not instruction_handler.has_method("execute"):
				push_error("InsutrctionHandler doesn't have execute method.")
				return
			
			var instruction_name : String = line_data.get("content").get("name")
			var args : Dictionary = line_data.get("content").get("line_reader.args")
			
			# transform content to more friendly args
			
			var delay_before = new_line.get("content").get("delay_before")
			var delay_after = new_line.get("content").get("delay_after")
			
			instruction_handler._wrapper_execute(instruction_name, args.get("args"), delay_before, delay_after)
		DIISIS.LineType.Folder:
			if not line_data.get("content", {}).get("meta.contents_visible", true):
				push_warning(str("Line ", line_index, " was an invisible folder. It will get read regardless."))
			emit_signal("line_finished", line_index)
			

func update_limit_line_count(lines: Array):
	if max_text_line_count <= 0:
		return
	var font : FontFile = text_content.get_theme_font("font", "RichTextLabel")
	var font_size : int = text_content.get_theme_font_size("font_size", "RichTextLabel")
	var label_width : float = text_content.size.x
	var new_actors := []
	var new_lines := []
	var i := 0
	while i < lines.size():
		var line:String = lines[i]
		var words := Array(line.split(" "))
		
		var subline : String = ""
		
		var line_height : int = font.get_string_size(str(lines), HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).y
		
		while not words.is_empty():
			var line_size : Vector2 = font.get_multiline_string_size(subline, HORIZONTAL_ALIGNMENT_CENTER, label_width, font_size)
			var next_word = ""
			while line_size.y <= line_height * max_text_line_count:
				next_word = words.pop_front() + " "
				line_size = font.get_multiline_string_size(subline + next_word, HORIZONTAL_ALIGNMENT_CENTER, label_width, font_size)
				
				if words.is_empty():
					if line_size.y <= line_height * max_text_line_count:
						subline += next_word
					else:
						subline = next_word
					new_lines.append(subline)
					new_actors.append(dialog_actors[i])
					subline = ""
					break
				
				if line_size.y > line_height * max_text_line_count:
					new_lines.append(subline)
					new_actors.append(dialog_actors[i])
					subline = next_word
					break
				
				subline += next_word
		i += 1
		
	dialog_lines = new_lines
	dialog_actors = new_actors

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
			text_content.visible_ratio += (float(text_speed) / text_content.text.length()) * delta
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
			remaining_auto_pause_duration = auto_pause_duration * (1.0 + (1-(text_speed / (MAX_TEXT_SPEED - 1))))
	
	if show_advance_available:
		if remaining_advance_delay <= 0.0:
			update_advance_available()
		else:
			remaining_advance_delay -= delta
	
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
	last_visible_ratio = text_content.visible_ratio
	last_visible_characters = text_content.visible_characters
	
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

func update_advance_available():
	var prompt_visible: bool
#	if next_pause_position_index != -1 and next_pause_position_index < pause_positions.size():
#		if (
#		next_pause_type == PauseTypes.Manual and 
#		text_content.visible_characters < 
#		pause_positions[next_pause_position_index] - 4 * next_pause_position_index
#		):
#			prompt_visible = true

	if text_content.visible_ratio >= 1.0:
		prompt_visible = true
	elif next_pause_position_index > pause_positions.size() and next_pause_position_index != -1:
		prompt_visible = true
	elif pause_positions.size() > 0 and next_pause_type == PauseTypes.Manual:
		if next_pause_position_index >= pause_positions.size() -1:
			prompt_visible = text_content.visible_ratio >= 1.0
		elif (text_content.visible_characters < 
		pause_positions[next_pause_position_index] - 4 * next_pause_position_index
		):

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
		next_prompt_container.modulate.a = 0
	else:
		next_prompt_container.modulate.a = lerp(next_prompt_container.modulate.a, 1.0, advance_available_lerp_weight)

func start_showing_text():
	var content : String = dialog_lines[dialog_line_index]
	line_chunks = content.split("<lc>")
	chunk_index = -1
	read_next_chunk()

func replace_var_func_tags(lines):
	if not inline_evaluator:
		push_warning("No InlineEvaluator has been set. Calls to <var:>, <func:>, and <name:> won't be parsed.")
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
				
			
			text_length = new_text.length()
			scan_index += 1
		result.append(new_text)
		i += 1
	return result


func read_next_chunk():
	chunk_index += 1
	if text_speed == MAX_TEXT_SPEED:
		text_content.visible_ratio = 1.0
	else:
		text_content.visible_characters = visible_prepend_offset
	
	pause_positions.clear()
	pause_types.clear()
	var new_text : String = line_chunks[chunk_index]
	while new_text.begins_with(" "):
		new_text = new_text.trim_prefix(" ")
	while new_text.begins_with("\n"):
		new_text = new_text.trim_prefix("\n")
	while new_text.begins_with("<lc>"):
		new_text = new_text.trim_prefix("<lc>")
	while new_text.begins_with("<ap>"):
		new_text = new_text.trim_prefix("<ap>")
	while new_text.begins_with("<mp>"):
		new_text = new_text.trim_prefix("<mp>")
	while new_text.ends_with(" "):
		new_text = new_text.trim_suffix(" ")
	while new_text.ends_with("\n"):
		new_text = new_text.trim_suffix("\n")
	while new_text.ends_with("<lc>"):
		new_text = new_text.trim_suffix("<lc>")
	while new_text.ends_with("<ap>"):
		new_text = new_text.trim_suffix("<ap>")
	while new_text.ends_with("<mp>"):
		new_text = new_text.trim_suffix("<mp>")
	
	
	var scan_index := 0
	pause_positions.clear()
	pause_types.clear()
	
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
	cleaned_text = cleaned_text.replace("\\[", "[")
	
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
		
	ParserEvents.text_content_text_changed.emit(text_content.text, cleaned_text, lead_time)
	set_text_content_text(cleaned_text)

func set_text_content_text(text: String):
	if keep_past_lines:
		var past_line = RichTextLabel.new()
		past_line.text = text_content.text
		past_text_continer.add_child(past_line)
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

func build_choices(choices, auto_switch:bool):
	for c in choice_option_container.get_children():
		c.queue_free()
	
	var built_choices := []
	for option in choices:
		var conditional_eval = evaluate_conditionals(option.get("conditionals"), option.get("choice_text.enabled_as_default"))
		var cond_true = conditional_eval[0]
		var cond_behavior = conditional_eval[1]
		var facts = option.get("facts").get("fact_data_by_name", {})
		
		if cond_true and auto_switch:
			for f in facts.values():
				Parser.change_fact(f)
			choice_pressed(true, option.get("target_page"))
			break
		
		var enable_option := true
		var option_text := ""
		
		if (cond_true and cond_behavior == "Hide") or (not cond_true and cond_behavior == "Show"):
			continue
		
		if (cond_true and cond_behavior == "Show") or (not cond_true and cond_behavior == "Hide"):
			enable_option = option.get("choice_text.enabled_as_default")
		
		if (cond_true and cond_behavior == "Enable") or (not cond_true and cond_behavior == "Disable"):
			enable_option = true
			
		if (cond_true and cond_behavior == "Disable") or (not cond_true and cond_behavior == "Enable"):
			enable_option = false
		
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
		var do_jump_page = option.get("do_jump_page")
		var target_page = option.get("target_page")
		
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
		
		new_option.connect("choice_pressed", choice_pressed)
		
		choice_option_container.add_child(new_option)
		built_choices.append({
			"button": new_option,
			"disabled": not enable_option,
			"option_text": option_text,
			"facts": facts,
			"do_jump_page": do_jump_page,
			"target_page": target_page,
		})
		
		#match choice_button_focus_mode:
			#ChoiceButtonFocusMode.All:
				#new_option.focus_mode = Control.FOCUS_ALL
				#new_option.mouse_filter = Control.MOUSE_FILTER_STOP
				#choice_option_container.mouse_filter = Control.MOUSE_FILTER_STOP
			#ChoiceButtonFocusMode.KeyboardOnly:
				#new_option.focus_mode = Control.FOCUS_ALL
				#new_option.mouse_filter = Control.MOUSE_FILTER_IGNORE
				#choice_option_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
			#ChoiceButtonFocusMode.MouseOnly:
				#if give_focus_to_choice_button:
					#new_option.focus_mode = Control.FOCUS_CLICK
				#else:
					#new_option.focus_mode = Control.FOCUS_NONE
				#new_option.mouse_filter = Control.MOUSE_FILTER_STOP
				#choice_option_container.mouse_filter = Control.MOUSE_FILTER_STOP
	ParserEvents.choices_presented.emit(built_choices)
	
	#if give_focus_to_choice_button or ChoiceButtonFocusMode.KeyboardOnly == choice_button_focus_mode:
		#if choice_option_container.get_child_count() > 0:
			#choice_option_container.get_child(0).grab_focus.call_deferred()
		#else:
			#push_warning("No choice to give focus to.")

func is_choice_presented():
	return not choice_option_container.get_children().is_empty()

func choice_pressed(do_jump_page, target_page):
	for c in choice_option_container.get_children():
		c.queue_free()
	if do_jump_page:
		emit_signal("jump_to_page", target_page)
		return
	emit_signal("line_finished", line_index)
	

## returns an array of size 2. index 0 is if the conditionals are satisfied. index 1 is the behavior if it's true
func evaluate_conditionals(conditionals, enabled_as_default := true) -> Array:
	var conditional_is_true := true
	var behavior = line_data.get("conditionals").get("behavior_key")
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

func update_name_label(actor_name: String):
	is_last_actor_name_different = actor_name != current_raw_name
	current_raw_name = actor_name
	
	var display_name: String = name_map.get(actor_name, actor_name)
	var name_color :Color = name_colors.get(actor_name, Color.WHITE)
	
	if name_style == NameStyle.NameLabel:
		name_label.text = display_name
		name_label.add_theme_color_override("font_color", name_color)
		
		if actor_name == name_for_blank_name:
			name_container.modulate.a = 0.0
		else:
			name_container.modulate.a = 1.0
	
	var name_visible:bool
	if name_style == NameStyle.NameLabel:
		name_visible = name_container.modulate.a > 0.0
	elif name_style == NameStyle.Prepend:
		name_visible = current_raw_name == name_for_blank_name
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



