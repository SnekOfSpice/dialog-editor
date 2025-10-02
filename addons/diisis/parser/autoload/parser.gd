extends Node
## The beating heart of runtime-side DIISIS <3
##
## uwu

## Set this to manually set any DIISIS-generated file to be used as source, irregardless of project.
@export_file("*.json") var source_file_override: String
## Number of entries the history will save. If set to [code]-1[/code] (default),
## the history is not limited. Otherwise, the latest history entry will be erased when 
## a new one is entered while at max length.
@export var max_history_length := -1
## Folder containing all l10n files (starting with "diisis_l10n_").
## [br]Leave empty to forego l10n.
@export_file("*.json") var localization_file

@export_group("Choices")
## If [code]true[/code], will append the text of choice buttons to the history.
@export var append_choices_to_history := true
##A space will be inserted between this String and the text of the choice made.[br]
## If this is an empty string, no space will be inserted.
@export var choice_appendation_string := "Choice made:"

@export_group("Progress")
## When calling [method _get_game_progress], the Parser will assume that any terminating page means full progress (1.0).
## Mostly useful for visual novels and other linear stories that have few end points.
@export var full_progress_on_last_page := true

var page_data := {}
var text_data := {}
var use_dialog_syntax := true
var text_lead_time_same_actor := 0.0
var text_lead_time_other_actor := 0.0
var _default_locale := "en_US"
var locale := "en_US"
var l10n := {}
var dropdown_titles := []
var dropdowns := {}
var file_config := {}

var line_reader : LineReader = null
var paused := true

var page_index := 0
var line_index := 0
var lines := []

var facts := {}
var starting_facts := {}
var full_custom_method_defaults := {}

var max_line_index_on_page := 0

const MAX_LINE_LENGTH := 10

enum DataTypes {_String, _DropDown, _Boolean}

signal read_new_line(line)
signal page_terminated(page_index: int)
signal page_finished(page_index: int)
signal read_new_page(page_index: int)

var history := []

var address_trail_index := -1
var address_trail := []

var last_modified_time = 0

func _get_live_source_path(suppress_error:=false) -> String:
	var source_path:String
	if not source_file_override.is_empty():
		source_path = source_file_override
	else:
		source_path = DiisisEditorUtil.get_project_source_file_path()
		if source_path.is_empty():
			if not suppress_error:
				push_error("Parser could not find project source file. Either set Parser.source_file_override manually, or make sure that the DIISIS file has been saved at least once.")
			return ""
	# where did that \n come from???
	return source_path.trim_suffix("\n")

func _get_data() -> Dictionary:
	var file := FileAccess.open(ProjectSettings.get_setting("diisis/project/file/path"), FileAccess.READ)
	if not file:
		return {}
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	return data.get("pages")
	

func _ready() -> void:
	var data = _get_data()
	
	last_modified_time = FileAccess.get_modified_time(_get_live_source_path())
	
	init(data)
	
	if localization_file:
		var file := FileAccess.open(localization_file, FileAccess.READ)
		l10n = JSON.parse_string(file.get_as_text())
		file.close()
	
	ParserEvents.choice_pressed.connect(on_choice_pressed)

func init(data:Dictionary):
	# all keys are now strings instead of ints
	var int_data := {}
	var loaded_data = data.get("page_data", {})
	for i in loaded_data.size():
		var where = int(loaded_data.get(str(i)).get("number"))
		int_data[where] = loaded_data.get(str(i)).duplicate()
	
	page_data = int_data.duplicate()
	
	facts = data.get("facts", {})
	use_dialog_syntax = data.get("use_dialog_syntax", true)
	text_lead_time_same_actor = data.get("text_lead_time_same_actor", 0.0)
	text_lead_time_other_actor = data.get("text_lead_time_other_actor", 0.0)
	starting_facts = facts.duplicate(true)
	dropdown_titles = data.get("dropdown_titles", [])
	dropdowns = data.get("dropdowns", {})
	file_config = data.get("file_config", {})
	Pages.evaluator_paths = file_config.get("evaluator_paths", [])
	Pages.custom_method_defaults = file_config.get("custom_method_defaults", {})
	Pages.custom_method_dropdown_limiters = file_config.get("custom_method_dropdown_limiters", {})
	full_custom_method_defaults = data.get("full_custom_method_defaults", {})
	text_data = data.get("text_data", {})
	_default_locale = data.get("default_locale", "en_US")
	#locale = _default_locale

func get_custom_method_defaults(method_name:String) -> Dictionary:
	return full_custom_method_defaults.get(method_name, {})

func _process(delta: float) -> void:
	if not OS.has_feature("editor"):
		return
	var source_path := _get_live_source_path(true)
	var modified_time = FileAccess.get_modified_time(source_path)
	if modified_time != last_modified_time:
		while not FileAccess.file_exists(source_path):
			await get_tree().process_frame
		init(_get_data())
		read_page(page_index, line_index)
	last_modified_time = FileAccess.get_modified_time(source_path)

## Call this one for a blank, new game.
func reset_and_start(start_page_index := 0, start_line_index := 0):
	line_reader.terminated = false
	set_paused(false)
	reset_facts()
	read_page(start_page_index, start_line_index)
	history = []
	selected_choices = []

## Pauses the Parser. If [param suppress_event] is true, [signal ParserEvents.parser_paused_changed]
## won't be emitted.
func set_paused(value:bool, suppress_event:=false):
	paused = value
	if not suppress_event:
		ParserEvents.parser_paused_changed.emit(paused)


func get_fact(fact_name: String):
	if not facts.has(fact_name):
		push_error(str("Fact ", fact_name, " is not registered. Returning false."))
		return false
	return facts.get(fact_name)

func get_facts_of_value(b: bool) -> Array:
	var result := []
	for fact in facts:
		if facts.get(fact) == b:
			result.append(fact)
	return result

func get_address() -> String:
	return str(page_index, ".", line_index)

func get_page_key(page_index:int) -> String:
	return page_data.get(page_index, {}).get("page_key", "")

func get_page_count() -> int:
	return page_data.size()

func append_to_history(text:String):
	history.append(text)
	if max_history_length > -1:
		if history.size() > max_history_length:
			history.reverse()
			history.pop_back()
			history.reverse()


var loopback_target_page:=0
var loopback_target_line:=0
var loopback_trigger_page:=-1
var loopback_trigger_line:=-1

var selected_choices := []

func on_choice_pressed(
	do_jump_page:bool,
	target_page:int,
	target_line:int,
	set_loopback:bool,
	loopback_target_page:int,
	loopback_target_line:int,
	choice_text:String
):
	if append_choices_to_history:
		var prefix:String
		if not choice_appendation_string.is_empty():
			prefix = ""
		else:
			prefix = str(choice_appendation_string, " ")
		call_deferred("append_to_history", str(prefix, choice_text))



func build_history_string(separator_string:="\n", from:=0, to:=-1) -> String:
	var result  := ""
	
	var i := 0
	for s in history:
		if i < from:
			i += 1
			continue
		if to != -1 and i > to:
			i += 1
			continue
		result += s
		result += separator_string
		i += 1
	
	result = result.trim_suffix(separator_string)
	
	return result

func get_dropdown_strings_from_header_values(values:=[0,0]) -> Array:
	var result = ["", ""]
	var title = dropdown_titles[values[0]]
	var value = dropdowns.get(title)[values[1]]
	result[0] = title
	result[1] = value
	return result

func get_page_number(key:String) -> int:
	for data in page_data.values():
		if data.get("page_key", "") == key:
			return data.get("number")
	return -1

func read_page_by_key(key:String, starting_line_index := 0):
	var number = get_page_number(key)
	if number == -1:
		push_error(str("Couldn't find page with key \"", key, "\"."))
		return
	read_page(number, starting_line_index)

func read_page(starting_page_index: int, starting_line_index := 0):
	if not page_data.keys().has(starting_page_index):
		push_warning(str("number ", starting_page_index, " not in page data"))
		return
	
	if page_data.get(starting_page_index).get("skip", false):
		if is_terminating(starting_page_index):
			emit_signal("page_terminated", starting_page_index)
			return
		read_page(get_next(starting_page_index), starting_line_index)
		return
	
	set_paused(false)
	ParserEvents.read_new_page.emit(starting_page_index)
	page_index = starting_page_index
	lines = page_data.get(page_index).get("lines")
	max_line_index_on_page = lines.size() - 1
	page_id = page_data.get("id", "")
	line_index = starting_line_index
	
	var page_bound_facts : Dictionary = page_data.get(page_index).get("facts", {}).get("fact_data_by_name", {})
	for fact in page_bound_facts.values():
		change_fact(fact)
	
	read_line(line_index)

 
func get_game_progress(dir:String) -> float:
	var file_path = str("user://", dir, "/parser.json")
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning(str("No file at ", file_path))
		return 0.0
	
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	data = data.get("Parser", {})
	return data.get("Parser.game_progress", 0.0)

func _get_game_progress() -> float:
	var index_trails := []
	var handled_page_indices := []
	var page_count : int = max(page_data.size(), 1)
	var current_trail := []
	var current_handled_page := 0
	while handled_page_indices.size() < page_count:
		current_trail.append(current_handled_page)
		handled_page_indices.append(current_handled_page)
		var terminate : bool = page_data.get(current_handled_page).get("terminate", false)
		if terminate:
			index_trails.append(current_trail.duplicate(true))
			current_trail.clear()
			if handled_page_indices.size() >= page_count:
				break
			for i in page_count:
				if not i in handled_page_indices:
					current_handled_page = i
					break
		else:
			current_handled_page = page_data.get(current_handled_page).get("next")
	
	var trail : Array
	for t : Array in index_trails:
		if page_index in t:
			trail = t
			break
	
	if not trail:
		return 0.0
	
	var calc_lines = page_data.get(page_index).get("lines")
	var line_count_on_page : int = calc_lines.size() - 1
	var page_index_in_trail := trail.find(page_index)
	var trail_size := trail.size()

	if line_count_on_page <= 0:
		return 0.0
	
	var page_progress = (int(page_index_in_trail) / float(trail_size))
	var line_progress = float(line_index) / float(line_count_on_page)
	
	if full_progress_on_last_page and page_index_in_trail + 1 == trail_size:
		return 1.0
	
	var dialine_progress := 0.0
	if line_reader:
		if line_reader.line_type == DIISIS.LineType.Text and line_reader._dialog_lines.size() > 0:
			dialine_progress = float(line_reader._dialog_line_index) / float(line_reader._dialog_lines.size())
	
	return page_progress + (line_progress / float(trail_size)) + ((dialine_progress / float(line_count_on_page)) / float(trail_size))

func get_line_type(address:String) -> DIISIS.LineType:
	var parts = DiisisEditorUtil.get_split_address(address)
	var prev_page = parts[0]
	var prev_line = parts[1]
	
	return int(page_data.get(prev_page).get("lines")[prev_line].get("line_type"))

func get_line_content(address:String) -> Dictionary:
	var parts = DiisisEditorUtil.get_split_address(address)
	var prev_page = parts[0]
	var prev_line = parts[1]
	
	return page_data.get(prev_page).get("lines")[prev_line].get("content")

func get_text(id:String) -> String:
	if locale == _default_locale:
		return text_data.get(id, "")
	if l10n.has(id):
		var text : String = l10n.get(id, {}).get(locale, "")
		if not text.is_empty():
			return text
	return text_data.get(id, "")

func get_previous_address_line_type() -> DIISIS.LineType:
	if address_trail_index <= 0 or address_trail.is_empty():
		push_warning("At the beginning.")
		return int(page_data.get(0).get("lines")[0].get("line_type"))
	var previous_address = address_trail[address_trail_index - 1]
	var parts = DiisisEditorUtil.get_split_address(previous_address)
	var prev_page = parts[0]
	var prev_line = parts[1]
	
	return int(page_data.get(prev_page).get("lines")[prev_line].get("line_type"))

func get_line_type_by_address(address:String) -> DIISIS.LineType:
	var parts = DiisisEditorUtil.get_split_address(address)
	var prev_page = parts[0]
	var prev_line = parts[1]
	
	return int(page_data.get(prev_page).get("lines")[prev_line].get("line_type"))

enum RollbackDeclineReason {
	HIT_CHOICE = 1,
	HIT_FOLDER = 3,
	BEGINNING = 0,
}

func go_back():
	var trail_shift = -1
	var previous_line_type = get_previous_address_line_type()
	if previous_line_type in [DIISIS.LineType.Choice, DIISIS.LineType.Folder]:
		ParserEvents.go_back_declined.emit(previous_line_type)
		push_warning("You cannot go further back.")
		#return
		trail_shift = 0
	
	if address_trail_index < 0 or address_trail.is_empty():
		ParserEvents.go_back_declined.emit(RollbackDeclineReason.BEGINNING)
		push_warning("You're at the beginning.")
		#return
		trail_shift = 0
	
	
	if line_reader._attempt_read_previous_dialine() and line_reader.line_type == DIISIS.LineType.Text:
		var subaddr = line_reader.get_subaddress_arr()
		ParserEvents.go_back_accepted.emit(subaddr[0], subaddr[1], subaddr[2])
		return
	
	var instruction_stack := []
	var a := false
	while previous_line_type == DIISIS.LineType.Instruction:
		a = true
		# build instruction stack
		var address_content = get_line_content(address_trail[address_trail_index + trail_shift])
		instruction_stack.append(address_content)
		previous_line_type = get_line_type(address_trail[address_trail_index + trail_shift])
		trail_shift -= 1
		if address_trail_index + trail_shift < 0:
			a = false
			trail_shift = 0
			break
	if a: # cant remember what this fixed
		trail_shift += 1
	instruction_stack.pop_back()
	
	for instruction in instruction_stack:
		if not instruction.get("meta.has_reverse", false):
			continue
		var instr_text : String = instruction.get("meta.reverse_text", "")
		if instr_text.is_empty():
			instr_text = instruction.get("meta.text")
		line_reader._execute(instr_text)
	
	await get_tree().process_frame
	address_trail_index += trail_shift
	if address_trail_index >= address_trail.size():
		address_trail_index = address_trail.size() - 1
	var previous_address = address_trail[address_trail_index]
	var parts = DiisisEditorUtil.get_split_address(previous_address)
	var prev_page = parts[0]
	var prev_line = parts[1]
	if not get_line_type_by_address(previous_address) in [DIISIS.LineType.Choice, DIISIS.LineType.Folder]:
		# we need to preempt which dialine the linereader will be reading
		var dialine_about_to_read : int
		if trail_shift == 0:
			dialine_about_to_read = 0
		elif trail_shift != 0:
			var line_data : Array = page_data.get(prev_page).get("lines")
			var raw_content : Dictionary = line_data[prev_line].get("content")
			var content := get_text(raw_content.get("text_id"))
			dialine_about_to_read = content.count("[]>") + content.count("<lc>") -1
			
		ParserEvents.go_back_accepted.emit(prev_page, prev_line, dialine_about_to_read)
		if not address_trail.is_empty():
			address_trail.resize(address_trail_index)
		if prev_page == page_index:
			read_line(prev_line)
		else:
			read_page(prev_page, prev_line)
		if trail_shift == 0:
			line_reader._go_to_start_of_dialog_line()
		elif trail_shift != 0:
			line_reader._go_to_end_of_dialog_line()
		address_trail_index = address_trail.size() - 1

var page_id : String
var line_id : String

func read_line(index: int):
	if lines.size() == 0:
		push_warning(str("No lines defined for page ", page_index))
		read_page(get_next(page_index))
		return
	
	if index >= lines.size():
		push_warning(str("Index ", index, " is higher than the available lines - index will be set to 0"))
		index = 0
	
	line_index = index
	address_trail_index += 1

		
	var new_address := str(page_index, ".", line_index)

	address_trail.append(str(page_index, ".", line_index))
	
	var line_data : Dictionary = lines[index]
	line_id = line_data.get("id", "")
	emit_signal("read_new_line", line_data)
	

func read_next_line(finished_line_index: int):
	if loopback_trigger_page == page_index and loopback_trigger_line == finished_line_index:
		loopback_trigger_line = -1
		loopback_trigger_page = -1
		
		if page_index != loopback_target_page:
			read_page(loopback_target_page, loopback_target_line)
		else:
			read_line(loopback_target_line)
		return
		
		
	if finished_line_index >= max_line_index_on_page:
		if is_terminating(page_index):
			ParserEvents.page_finished.emit(page_index)
			ParserEvents.page_terminated.emit(page_index)
			emit_signal("page_terminated", page_index)
		else:
			var next = int(page_data.get(page_index).get("next"))
			if page_data.keys().has(next):
				emit_signal("page_finished", page_index)
				ParserEvents.page_finished.emit(page_index)
				read_page(next)
			else:
				emit_signal("page_terminated", page_index)
				ParserEvents.page_finished.emit(page_index)
				ParserEvents.page_terminated.emit(page_index)
				push_warning(str("tried to read non-existent page ", next, " after non-terminating page ", page_index))
		return
	
	read_line(finished_line_index + 1)

func is_terminating(page_index:int) -> bool:
	return bool(page_data.get(page_index).get("terminate"))

func get_next(page_index:int) -> int:
	if is_terminating(page_index):
		push_warning("%s terminates!" % page_index)
		return -1
	return int(page_data.get(page_index).get("next"))

func _open_connection(new_lr: LineReader):
	if is_instance_valid(line_reader):
		push_warning("Parser already had a LineReader connected to it. Not freeing the previous LineReader may have unintended consequences.")
	line_reader = new_lr
	line_reader.connect("line_finished", read_next_line)
	line_reader.connect("jump_to_page", read_page)

func _close_connection():
	line_reader.disconnect("line_finished", read_next_line)
	line_reader.disconnect("jump_to_page", read_page)
	line_reader = null

## Changes [param fact_name] to [param new_value]. If [param suppress_event] is [code]true[/code]
## [signal ParserEvents.fact_changed] won't be emitted.[br]
func change_fact(fact_item_data:Dictionary, suppress_event:=false):
	var fact_name : String = fact_item_data.get("fact_name", "")
	var old_value = facts.get(fact_name, false)
	var new_value
	
	if int(fact_item_data.get("data_type", 0)) == 0: # bool
		new_value = bool(fact_item_data.get("fact_value", true))
	elif int(fact_item_data.get("data_type", 0)) == 1: # int
		new_value = int(fact_item_data.get("fact_value", 0))
		if fact_item_data.get("int_operator", 0) == 0: # set
			new_value = int(fact_item_data.get("fact_value", 0))
		elif fact_item_data.get("int_operator", 0) == 1: # add
			new_value = int(old_value) + int(fact_item_data.get("fact_value", 0))
	
	facts[fact_name] = new_value
	if not suppress_event:
		ParserEvents.fact_changed.emit(fact_name, old_value, new_value)

func apply_facts(fact_values_by_name: Dictionary):
	for fact in fact_values_by_name:
		facts[fact] = fact_values_by_name.get(fact)

func reset_facts():
	apply_facts(starting_facts)

func serialize() -> Dictionary:
	var result := {}
	
	result["Parser.facts"] = facts
	result["Parser.use_dialog_syntax"] = use_dialog_syntax
	result["Parser.text_lead_time_other_actor"] = text_lead_time_other_actor
	result["Parser.text_lead_time_same_actor"] = text_lead_time_same_actor
	result["Parser.lines"] = lines
	result["Parser.max_line_index_on_page"] = max_line_index_on_page
	result["Parser.page_index"] = page_index
	result["Parser.line_index"] = line_index
	result["Parser.history"] = history
	result["Parser.line_reader"] = line_reader._serialize()
	result["Parser.game_progress"] = _get_game_progress()
	result["Parser.selected_choices"] = selected_choices
	result["address_trail"] = address_trail
	result["address_trail_index"] = address_trail_index
	
	return result

func deserialize(data: Dictionary):
	lines = data.get("Parser.lines")
	selected_choices = data.get("Parser.selected_choices")
	max_line_index_on_page = int(data.get("Parser.max_line_index_on_page"))
	
	address_trail_index = data.get("address_trail_index")
	address_trail = data.get("address_trail")
	
	page_index = int(data.get("Parser.page_index", 0))
	line_index = int(data.get("Parser.line_index", 0))
	apply_facts(data.get("Parser.facts", {}))
	history = data.get("Parser.history", [])
	var line_reader_data : Dictionary = data.get("Parser.line_reader", {})
	if line_reader_data.is_empty():
		read_page(page_index, line_index)
	else:
		line_reader._deserialize(line_reader_data)

## [param save_dir_name] can but doesn't have to start with "user://". It shouldn't but can end with "/". This function will clean it up.
func save_parser_state(save_dir_name: String, additional_data:={}):
	save_dir_name = save_dir_name.trim_prefix("user://")
	save_dir_name = save_dir_name.trim_suffix("/")
	var access = DirAccess.open("user://")
	var save_dir_path := str("user://", save_dir_name)
	if not access.dir_exists(save_dir_path):
		access.make_dir(save_dir_path)
	var file_path := str(save_dir_path, "/parser.json")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("File saving failed")
		push_error(FileAccess.get_open_error())
		return
	var data_to_save := {}
	data_to_save["Parser"] = serialize()
	data_to_save["Custom"] = additional_data
	
	file.store_string(JSON.stringify(data_to_save, "\t"))
	file.close()
	
	_save_actor_config(save_dir_path)

## returns any additional custom arguments that were passed during saving. [br]
## [param save_dir_name] can but doesn't have to start with "user://". It shouldn't but can end with "/". This function will clean it up.
func load_parser_state(save_dir_name: String, pause_after_load:=false) -> Dictionary:
	save_dir_name = save_dir_name.trim_prefix("user://")
	save_dir_name = save_dir_name.trim_suffix("/")
	var save_dir_path := str("user://", save_dir_name)
	var file_path := str(save_dir_path, "/parser.json")
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning(str("No file at ", file_path))
		page_index = 0
		line_index = 0
		return {}
	
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	
	_load_actor_config(save_dir_path)
	deserialize(data.get("Parser", {}))
	
	
	paused = pause_after_load
	
	return data.get("Custom", {})

func _str_to_typed(value:String, type:int):
	match type:
		TYPE_FLOAT:
			return float(value)
		TYPE_INT:
			return int(value)
		TYPE_BOOL:
			var cast : bool = true if value == "true" else false
			return cast
	return String(value)

## After you call a function from LineReader that returns [code]true[/code], [Parser] and [LineReader] will be in a suspended state, waiting to continue until this function is called.
## Call this from anywhere to continue reading the script when such a function is done.
## [br][i]Parser acceded control to the function, now it continues on its merry way![/i]
func function_acceded():
	if not line_reader:
		return
	ParserEvents.acceded.emit()
	if not line_reader.awaiting_inline_call.is_empty():
		line_reader.awaiting_inline_call = ""
		return
	line_reader.finish_waiting_for_instruction()


func get_next_line_data() -> Dictionary:
	return _get_next_line_data_custom(line_index, page_data.get(page_index, {}))

func _get_next_line_data_custom(from_line:int, local_page_data:Dictionary) -> Dictionary:
	var page_lines : Array = local_page_data.get("lines", [])
	if local_page_data.is_empty():
		return {}
	if from_line >= page_lines.size() - 1 and local_page_data.get("terminate"):
		return {}
	
	if from_line < page_lines.size() - 1:
		var next_line_index := from_line + 1
		var skip_line : bool = page_lines[next_line_index].get("skip")
		if not skip_line:
			return page_lines[next_line_index].duplicate(true)
		while skip_line:
			next_line_index += 1
			if next_line_index >= page_lines.size():
				break
			skip_line = page_lines[next_line_index].get("skip")
			if not skip_line:
				return page_lines[next_line_index].duplicate(true)
	var next_page_index : int = local_page_data.get("next", page_index + 1)
	var skip_page : bool = local_page_data.get("skip")
	var visited_pages := []
	var page_data_to_visit_next : Dictionary
	if not skip_page:
		page_data_to_visit_next = page_data.get(next_page_index)
	while skip_page:
		next_page_index = local_page_data.get("next", next_page_index + 1)
		if visited_pages.has(next_page_index):
			break
		visited_pages.append(next_page_index)
		if next_page_index >= page_data.size():
			break
		skip_page = page_data.get(next_page_index).get("skip")
		if not skip_page:
			break
	if page_lines.is_empty():
		page_data_to_visit_next = page_data.get(next_page_index)
	
	return _get_next_line_data_custom(0, page_data_to_visit_next)

func _ensure_actor_dir_exists(parent_dir : String):
	var access = DirAccess.open(parent_dir)
	var actor_dir := str(parent_dir, "/actors")
	if not access.dir_exists(actor_dir):
		access.make_dir(actor_dir)
	

func _save_actor_config(dir : String):
	_ensure_actor_dir_exists(dir)
	for actor in line_reader.actor_config.keys():
		var res_path := str(dir, "/actors/", actor, ".tres")
		ResourceSaver.save(line_reader.actor_config.get(actor), res_path)

func _load_actor_config(dir:String):
	_ensure_actor_dir_exists(dir)
	for actor in line_reader.actor_config.keys():
		var res_path := str(dir, "/actors/", actor, ".tres")
		var res = ResourceLoader.load(res_path)
		line_reader.actor_config[actor] = res
