@icon("res://addons/diisis/parser/style/reader_icon_Zeichenfläche 1.svg")
@tool
extends Control
class_name LineReader

const MAX_TEXT_SPEED := 101

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
var auto_continue_duration:= auto_continue_delay
## If [code]0[/code], [param text_content] will be filled as far as possible.
## Breaks will be caused by <lc> tags, 
## a [TextContent] with [param TextContent.use_dialog_syntax] enabled, and a
## new [Line] of type [member DIISIS.LineType.Text] being read.[br]
## If set to more than [code]0[/code], the text will additionally be split to
## ensure it never runs more than that amount of lines. [br]
## [b]Note:[/b] Resizing the [param text_content] after a Line has started to be read will
## throw this alignment off.
@export var max_text_line_count:=0
@export var block_advance_during_choices:=true

@export_subgroup("Choices")
## If [code]true[/code], shows [param text_container] when choices are presented.
@export var show_text_during_choices := false
## Button scene that gets instantiated as children of [param choice_option_container].[br]
## If left unassigned, will use a default button.[br]
## If overridden, it must inherit from [class ChoiceButton].
@export var button_scene:ChoiceButton

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

@export_group("Name Setup")
## The name of the dropdown property used for keying names. Usually something like "character"
@export
var property_for_name := ""
## If set, this name will instead hide the name label alltogether.
@export
var name_for_blank_name := ""
@export var name_map := {}
@export var name_colors := {}

@export_group("Mandatory References")
## The Control holding [code]choice_option_container[/code]. Should have its [code]mouse_filter[/code] set to [code]Stop[/code] and [b]FullRect Layout[/b].
@export var choice_container:PanelContainer:
	get:
		return choice_container
	set(value):
		choice_container = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
## The Control used for enumerating options when they are presented. Should be HBoxContainer, VBoxContainer, or GridContainer.
@export
var choice_option_container:Control:
	get:
		return choice_option_container
	set(value):
		choice_option_container = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
## Your custom handling of instructions defined in the dialog editor.
@export
var instruction_handler: InstructionHandler:
	get:
		return instruction_handler
	set(value):
		instruction_handler = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
## Should have its visible characters / ratio set to 0 in the scene.
@export var text_content: RichTextLabel:
	get:
		return text_content
	set(value):
		text_content = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
## The Control holding ALL text; [code]name_label[/code] & [code]text_content[/code].
@export var text_container: Control:
	get:
		return text_container
	set(value):
		text_container = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
## A [code]Label[/code] that displays a currently speaking character's name.
@export
var name_label: Label:
	get:
		return name_label
	set(value):
		name_label = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
## The Control holding [code]name_label[/code]. Has its visiblity toggled by [code]name_for_blank_name[/code]. May be the same Node as [code]name_label[/code].
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


var next_pause_position_index := -1
var pause_positions := []
var pause_types := []
var next_pause_type := 0
enum PauseTypes {Manual, Auto, EoL}
var dialog_lines := []
var dialog_actors := []
var dialog_line_index := 0

var line_chunks := []
var chunk_index := 0
var current_raw_name := ""

var terminated := false

var started_word_buffer :=""
var characters_visible_so_far := ""

var last_visible_ratio := 0.0

signal line_reader_ready

func _validate_property(property: Dictionary):
	if not show_advance_available:
		if property.name in ["advance_available_delay", "advance_available_lerp_weight", "next_prompt_container"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	if not auto_continue:
		if property.name in ["auto_continue_delay"]:
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
	if data.get("name_map"):
		name_map = data.get("name_map")
	
	text_container.visible = line_type == DIISIS.LineType.Text or (line_type == DIISIS.LineType.Choice and show_text_during_choices)
	showing_text = line_type == DIISIS.LineType.Text
	choice_container.visible = line_type == DIISIS.LineType.Choice
	
	if line_type == DIISIS.LineType.Choice:
		var raw_content = line_data.get("content")
		var content = line_data.get("content").get("content")
		var choices = line_data.get("content").get("choices")
		var auto_switch : bool = raw_content.get("auto_switch")

		build_choices(choices, auto_switch)
		
	set_text_content_text(data.get("text_content.text", ""))
	update_name_label(data.get("current_raw_name", name_for_blank_name))

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
	if not name_label:
		warnings.append("Name Label is null")
	if not name_container:
		warnings.append("Name Container is null")
	if show_advance_available:
		warnings.append("Next Prompt Container is null")
	
	return warnings

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	Parser.connect("read_new_line", read_new_line)
	Parser.connect("page_terminated", close)
	
	Parser.open_connection(self)
	
	ParserEvents.fact_changed.connect(on_fact_change)
	remaining_auto_pause_duration = auto_pause_duration * (1.0 + (1-(text_speed / (MAX_TEXT_SPEED - 1))))
	
	if not instruction_handler:
		push_error("No InsutrctionHandler as child of LineReader.")
		return
	
	instruction_handler.connect("set_input_lock", set_is_input_locked)
	instruction_handler.connect("instruction_wrapped_completed", instruction_completed)
	text_content.visible_ratio = 0
	
	if not show_advance_available and next_prompt_container:
		next_prompt_container.modulate.a = 0
	
	emit_signal("line_reader_ready")

func on_fact_change(fact_name:String, old:bool, new:bool):
	printt(fact_name, old, new)

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
		auto_continue_duration = auto_continue_delay
	if showing_text:
		
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

func interrupt():
	pass

func continue_after_interrupt():
	pass

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
	var choices
	if line_type == DIISIS.LineType.Choice:
		choices = line_data.get("content").get("choices")
	var content_name = line_data.get("content").get("name") # wtf is this
	
	text_container.visible = line_type == DIISIS.LineType.Text or (line_type == DIISIS.LineType.Choice and show_text_during_choices)
	showing_text = line_type == DIISIS.LineType.Text
	choice_container.visible = line_type == DIISIS.LineType.Choice
	
	# register facts
	var facts = line_data.get("facts", {}).get("values", {})
	
	for f in facts.keys():
		Parser.change_fact(f, facts.get(f))
	
	match line_type:
		DIISIS.LineType.Text:
			using_dialog_syntax = line_data.get("content").get("use_dialog_syntax", false)
			if str(content).is_empty():
				emit_signal("line_finished", line_index)
				return
			if using_dialog_syntax:
				var lines = content.split("[]>")
				dialog_actors.clear()
				dialog_lines.clear()
				for l in lines:
					if l.is_empty():
						continue
					#var colon_pos = l.find(":")
					var actor_name = l.split(":")[0]
					dialog_actors.append(actor_name)
					var line : String = l.trim_prefix(str(actor_name, ":"))
					while line.begins_with(" "):
						line = line.trim_prefix(" ")
					dialog_lines.append(line)
			else:
				dialog_lines = [content]
				dialog_actors.clear()
			
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
			
			var instruction_name = content_name
			var args = {}
			
			# transform content to more friendly args
			for c in content:
				args[c.get("name")] = c.get("value")
			
			var delay_before = new_line.get("content").get("delay.before")
			var delay_after = new_line.get("content").get("delay.after")
			
			instruction_handler.wrapper_execute(instruction_name, args, delay_before, delay_after)
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
		return pause_positions[next_pause_position_index] - 4 * next_pause_position_index

func _process(delta: float) -> void:
	# this is a @tool script so this prevents the console from getting flooded
	if Engine.is_editor_hint():
		return
	
	if Parser.paused:
		return
	
	if next_pause_position_index < pause_positions.size() and next_pause_position_index != -1:
		find_next_pause()
	if text_content.visible_characters < get_end_of_chunk_position():
		if text_speed == MAX_TEXT_SPEED:
			text_content.visible_characters = get_end_of_chunk_position()
		else:
			text_content.visible_ratio += (float(text_speed) / text_content.text.length()) * delta
			# fast text speed can make it go over the end  of the chunk
			text_content.visible_characters = min(text_content.visible_characters, get_end_of_chunk_position())
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
	
	last_visible_ratio = text_content.visible_ratio
	
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
			auto_continue_duration -= delta
			if auto_continue_duration <= 0.0:
				
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
					new_text = new_text.replace(control_to_replace, str(inline_evaluator.callv(func_name, func_args)))
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
		text_content.visible_characters = 0
	
	pause_positions.clear()
	pause_types.clear()
	var new_text : String = line_chunks[chunk_index]
	
	while new_text.begins_with(" "):
		new_text = new_text.trim_prefix(" ")
	while new_text.begins_with("<lc>"):
		new_text = new_text.trim_prefix("<lc>")
	while new_text.begins_with("<ap>"):
		new_text = new_text.trim_prefix("<ap>")
	while new_text.begins_with("<mp>"):
		new_text = new_text.trim_prefix("<mp>")
	while new_text.ends_with(" "):
		new_text = new_text.trim_suffix(" ")
	while new_text.ends_with("<lc>"):
		new_text = new_text.trim_suffix("<lc>")
	while new_text.ends_with("<ap>"):
		new_text = new_text.trim_suffix("<ap>")
	while new_text.ends_with("<mp>"):
		new_text = new_text.trim_suffix("<mp>")
	
	
	var scan_index := 0
	pause_positions.clear()
	pause_types.clear()
	#scan_index = 0
	
	while scan_index < new_text.length():
		if new_text[scan_index] == "<":
			if new_text.find("<mp>", scan_index) == scan_index:
				if not pause_positions.has(scan_index):
					pause_positions.append(scan_index)
					pause_types.append(PauseTypes.Manual)
			elif new_text.find("<ap>", scan_index) == scan_index:
				if not pause_positions.has(scan_index):
					pause_positions.append(scan_index)
					pause_types.append(PauseTypes.Auto)
				
		scan_index += 1
	
	#pause_positions.erase(-1)
	pause_positions.append(new_text.length()-1)
	pause_types.append(PauseTypes.EoL)
	
	
	
	next_pause_position_index = 0
	find_next_pause()
	
	var cleaned_text : String = new_text
	var i = 0
	for pos in pause_positions:
		if pause_types[i] == PauseTypes.EoL:
			break
		
		cleaned_text = cleaned_text.erase(pos-(i*4), 4)
		i += 1
	
	ParserEvents.text_content_text_changed.emit(text_content.text, cleaned_text)
	set_text_content_text(cleaned_text)

func set_text_content_text(text: String):
	text_content.text = text
	text_content.visible_characters = 0
	characters_visible_so_far = ""
	started_word_buffer = ""

func find_next_pause():
	if pause_types.size() > 0 and next_pause_position_index < pause_types.size():
		next_pause_type = pause_types[next_pause_position_index]

func get_actor_name(actor_key:String):
	return name_map.get(actor_key, "")

func set_actor_name(actor_key:String, new_name:String):
	name_map[actor_key] = new_name

func build_choices(choices, auto_switch:bool):
	for c in choice_option_container.get_children():
		c.queue_free()
	
	var built_choices := []
	for option in choices:
		var conditional_eval = evaluate_conditionals(option.get("conditionals"), option.get("choice_text.enabled_as_default"))
		var cond_true = conditional_eval[0]
		var cond_behavior = conditional_eval[1]
		
		if cond_true and auto_switch:
			# untested for now
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
			option_text = option.get("choice_text.enabled")
		else:
			option_text = option.get("choice_text.disabled")
		
		# give to option to signal
		var facts = option.get("facts").get("values", {})
		var do_jump_page = option.get("do_jump_page")
		var target_page = option.get("target_page")
		
		var new_option = preload("res://addons/diisis/parser/src/choice_option.tscn").instantiate()
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
	ParserEvents.choices_presented.emit(built_choices)

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
	var facts_to_check = conditionals.get("facts").get("values")
	if facts_to_check.keys().size() == 0:
		var default_key = "Enable" if enabled_as_default else "Disable"
		return [true, default_key]
	
	
	var operand_key = conditionals.get("operand_key")
	var true_facts := []
	for fact in facts_to_check:
		if facts_to_check.get(fact) == Parser.facts.get(fact):
			true_facts.append(fact)
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
	if using_dialog_syntax:
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
	current_raw_name = actor_name
	var display_name: String = name_map.get(actor_name, actor_name)
	
	var name_color :Color = name_colors.get(actor_name, Color.WHITE)
	
	name_label.text = display_name
	name_label.add_theme_color_override("font_color", name_color)
	
	if actor_name == name_for_blank_name:
		name_container.modulate.a = 0.0
	else:
		name_container.modulate.a = 1.0
	
	ParserEvents.display_name_changed.emit(display_name, name_container.modulate.a > 0.0)
	ParserEvents.actor_name_changed.emit(actor_name, name_container.modulate.a > 0.0)

func _on_finished_button_pressed() -> void:
	emit_signal("line_finished", line_index)
