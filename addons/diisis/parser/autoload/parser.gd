extends Node

## Set this to manually set any DIISIS-generated file to be used as source, irregardless of project.
@export_file("*.json") var source_file_override: String
## Number of entries the history will save. If set to [code]-1[/code] (default),
## the history is not limited. Otherwise, the latest history entry will be erased when 
## a new one is entered while at max length.
@export var max_history_length := -1
## Folder containing all l10n files (starting with "diisis_l10n_").
## [br]Leave empty to forego l10n.
@export_dir var localization_folder

@export_group("Choices")
## If [code]true[/code], will append the text of choice buttons to the history.
@export var append_choices_to_history := true
##A space will be inserted between this String and the text of the choice made.[br]
## If this is an empty string, no space will be inserted.
@export var choice_appendation_string := "Choice made:"

var page_data := {}
var use_dialog_syntax := true
var text_lead_time_same_actor := 0.0
var text_lead_time_other_actor := 0.0
var locales := {}
var default_locale := "en_US"
var locale := "en_US"
var dropdown_titles := []
var dropdowns := {}

var line_reader : LineReader = null
var paused := true

var page_index := 0
var line_index := 0
var lines := []

var facts := {}
var starting_facts := {}

var max_line_index_on_page := 0

const MAX_LINE_LENGTH := 10

enum DataTypes {_String, _DropDown, _Boolean}

signal read_new_line(line)
signal page_terminated(page_index: int)
signal page_finished(page_index: int)
signal read_new_page(page_index: int)

var currently_speaking_name := ""
var currently_speaking_visible := true
var history := []

var address_trail_index := -1
var address_trail := []

var last_modified_time = 0

func _get_live_source_path() -> String:
	var source_path:String
	if not source_file_override.is_empty():
		source_path = source_file_override
	else:
		source_path = DiisisEditorUtil.get_project_source_file_path()
		if source_path.is_empty():
			push_error("Parser could not find project source file. Either set Parser.source_file_override manually, or make sure that the DIISIS file has been saved at least once.")
			return ""
	return source_path

func _get_data() -> Dictionary:
	var file := FileAccess.open(_get_live_source_path(), FileAccess.READ)
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	return data.get("pages")
	

func _ready() -> void:
	var data = _get_data()
	
	last_modified_time = FileAccess.get_modified_time(_get_live_source_path())
	
	init(data)
	
	ParserEvents.display_name_changed.connect(on_name_label_updated)
	ParserEvents.text_content_text_changed.connect(on_text_content_text_changed)
	ParserEvents.choice_pressed.connect(on_choice_pressed)

func init(data:Dictionary):
	# all keys are now strings instead of ints
	var int_data := {}
	var loaded_data = data.get("page_data")
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

func _process(delta: float) -> void:
	# hot reload
	var modified_time = FileAccess.get_modified_time(_get_live_source_path())
	if modified_time != last_modified_time:
		init(_get_data())
		if not line_reader:
			last_modified_time = FileAccess.get_modified_time(_get_live_source_path())
			return
		# only read the current page.line index again if we're not currently paused or terminated
		# since this causes a page to be read again, we counteract double-adding int facts by first subtracting the same fact value
		# this isn't necessary for bools or ints with operator Set
		if not (paused or line_reader.terminated):
			var f : Dictionary = page_data.get(page_index).get("facts", {}).get("fact_data_by_name", {})
			var  page_bound_facts = f.duplicate(true)
			for fact : Dictionary in page_bound_facts.values():
				if fact.get("data_type", 0) == 1 and fact.get("int_operator", 0) == 1:
					fact["fact_value"] = -fact.get("fact_value", 0)
			for fact : Dictionary in page_bound_facts.values():
				if fact.get("data_type") != 1:
					continue
				change_fact(fact)
			
			read_page(page_index, line_index)
	last_modified_time = FileAccess.get_modified_time(_get_live_source_path())

## Call this one for a blank, new game.
func reset_and_start(start_page_index:=0):
	line_reader.terminated = false
	set_paused(false)
	reset_facts()
	read_page(start_page_index)
	history = []
	selected_choices = []

## Pauses the Parser. If [param suppress_event] is true, [signal ParserEvents.parser_paused_changed]
## won't be emitted.
func set_paused(value:bool, suppress_event:=false):
	paused = value
	if not suppress_event:
		ParserEvents.parser_paused_changed.emit(paused)

func replace_from_locale(address:String, locale:String) -> String:
	if not locales.has(locale):
		try_load_locale(locale)
	if not locales.has(locale):
		return ""
	return locales[locale][address]

func try_load_locale(locale:String):
	if not localization_folder:
		return
	
	var file := FileAccess.open(str(localization_folder, "/diisis_l10n_", locale, ".json"), FileAccess.READ)
	locales[locale] = JSON.parse_string(file.get_as_text())
	file.close()

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

func get_line_position_string() -> String:
	return str(page_index, ".", line_index)

func get_page_key(page_index:int):
	return page_data.get(page_index, {}).get("page_key", "")

func append_to_history(text:String):
	history.append(text)
	if max_history_length > -1:
		if history.size() > max_history_length:
			history.reverse()
			history.pop_back()
			history.reverse()

func on_text_content_text_changed(old_text: String,
	new_text: String,
	lead_time: float):
	call_deferred("append_to_history", (str(str("[b]",currently_speaking_name, "[/b]: ") if currently_speaking_visible else "", new_text)))

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

func on_name_label_updated(
	actor_name: String,
	is_name_container_visible: bool
):
	currently_speaking_name = actor_name
	currently_speaking_visible = is_name_container_visible

func build_history_string(separator_string:="\n") -> String:
	var result  := ""
	
	for s in history:
		result += s
		result += separator_string
	
	result = result.trim_suffix(separator_string)
	
	return result

func drop_down_values_to_string_array(values:=[0,0]) -> Array:
	var result = ["", ""]
	var title = dropdown_titles[values[0]]
	#var title_index = dropdown_titles.find(title)
	var value = dropdowns.get(title)[values[1]]
	result[0] = title
	result[1] = value
	return result

func read_page(number: int, starting_line_index := 0):
	if not page_data.keys().has(number):
		push_warning("number not in page data")
		return
	
	#emit_signal("read_new_page", number)
	ParserEvents.read_new_page.emit(number)
	page_index = number
	lines = page_data.get(page_index).get("lines")
	max_line_index_on_page = lines.size() - 1
	
	line_index = starting_line_index
	
	var page_bound_facts : Dictionary = page_data.get(page_index).get("facts", {}).get("fact_data_by_name", {})
	for fact in page_bound_facts.values():
		change_fact(fact)
	
	read_line(line_index)

func get_saved_game_progress(file_path: String) -> float:
	var file : FileAccess
	file = FileAccess.open(file_path, FileAccess.READ)
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	
	if not file:
		return 0.0
	
	# all keys are now strings instead of ints
	return float(data.get("Parser", {}).get("Parser.game_progress", 0.0))
 
func get_game_progress_from_file(savepath:String) -> float:
	var file = FileAccess.open(savepath, FileAccess.READ)
	if not file:
		push_warning(str("No file at ", savepath))
		return 0.0
	
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	data = data.get("Parser", {})
	return data.get("Parser.game_progress", 0.0)

func _get_game_progress(full_if_on_last_page:= true) -> float:
	var max_line_index_used_for_calc := 0
	var calc_lines = page_data.get(page_index).get("lines")
	max_line_index_used_for_calc = calc_lines.size() - 1
	var max_page_index :int= max(page_data.keys().size(), 1)
	var page_index_used_for_calc := page_index
	var line_index_used_for_calc := line_index
	

	if max_line_index_used_for_calc <= 0:
		return 0.0
	
	
	if max_page_index <= 0:
		return 0.0
	
	var page_progress = (int(page_index_used_for_calc) / float(max_page_index))
	var line_progress = float(line_index_used_for_calc) / float(max_line_index_used_for_calc)
	
	if full_if_on_last_page and page_index_used_for_calc == max_page_index:
		return 1.0
	
	return page_progress + (line_progress / float(max_page_index))

func get_previous_address_line_type() -> DIISIS.LineType:
	if address_trail_index <= 0 or address_trail.is_empty():
		push_warning("At the beginning.")
		return int(page_data.get(0).get("lines")[0].get("line_type"))
	var previous_address = address_trail[address_trail_index - 1]
	var parts = DiisisEditorUtil.get_split_address(previous_address)
	var prev_page = parts[0]
	var prev_line = parts[1]
	
	return int(page_data.get(prev_page).get("lines")[prev_line].get("line_type"))

func go_back():
	if get_previous_address_line_type() in [DIISIS.LineType.Choice, DIISIS.LineType.Folder, DIISIS.LineType.Instruction]:
		ParserEvents.go_back_declined.emit()
		push_warning("You cannot go further back.")
		return
	
	if address_trail_index <= 0 or address_trail.is_empty():
		ParserEvents.go_back_declined.emit()
		push_warning("You're at the beginning.")
		return
	
	address_trail_index -= 1
	var previous_address = address_trail[address_trail_index]
	var parts = DiisisEditorUtil.get_split_address(previous_address)
	var prev_page = parts[0]
	var prev_line = parts[1]
	ParserEvents.go_back_accepted.emit(prev_page, prev_line)
	if not address_trail.is_empty():
		address_trail.resize(address_trail_index)
	if prev_page == page_index:
		read_line(prev_line)
	else:
		read_page(prev_page, prev_line)
	address_trail_index = address_trail.size() - 1
	

func read_line(index: int):
	if lines.size() == 0:
		push_warning(str("No lines defined for page ", page_index))
		return
	line_index = index
	#prints("reading line", index, "trail is ", address_trail, " idx is", address_trail_index)
	address_trail_index += 1
	#if not address_trail.is_empty():
		#address_trail.resize(address_trail_index)
		
	var new_address := str(page_index, ".", line_index)
	#if address_trail.back() == new_address:
		#address_trail_index -= 1
	#else:
	address_trail.append(str(page_index, ".", line_index))
	emit_signal("read_new_line", lines[index])
	#prints("line has been read. trail is now", address_trail, "and idx", address_trail_index)
	

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
		var do_terminate = bool(page_data.get(page_index).get("terminate"))
		if do_terminate:
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



func open_connection(new_lr: LineReader):
	line_reader = new_lr
	line_reader.connect("line_finished", read_next_line)
	line_reader.connect("jump_to_page", read_page)
	

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
	result["Parser.line_reader"] = line_reader.serialize()
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
		line_reader.deserialize(line_reader_data)


func save_parser_state_to_file(file_path: String, additional_data:={}):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	var data_to_save := {}
	data_to_save["Parser"] = serialize()
	data_to_save["Custom"] = additional_data
	file.store_string(JSON.stringify(data_to_save, "\t"))
	file.close()

## returns any additional custom arguments that were passed during saving.
func load_parser_state_from_file(file_path: String, pause_after_load:=false) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning(str("No file at ", file_path))
		page_index = 0
		line_index = 0
		return {}
	
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	
	deserialize(data.get("Parser", {}))
	
	paused = pause_after_load
	
	return data.get("Custom", {})
