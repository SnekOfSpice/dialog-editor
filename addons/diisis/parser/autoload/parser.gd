extends Node


@export_file("*.json") var source_file
@export_file("*.json") var demo_file
#@export var source_path := ""
#@export var source_path_demo := ""
@export var show_demo := false
@export var max_history_length := -1

@export_group("Choices")
## If true, will append the text of choice buttons to the history.
@export var append_choices_to_history := true
##A space will be inserted between this String and the text of the choice made.
@export var choice_appendation_string := "Choice made:"

var page_data := {}
var dropdown_titles := []
var dropdowns := {}

var line_reader : LineReader = null
var paused := false

var page_index := 0
var line_index := 0
var lines := []

var facts := {}
var starting_facts := {}

var max_line_index_on_page := 0

const MAX_LINE_LENGTH := 10

enum DataTypes {_String, _Integer, _Float, _Array, _Dictionary, _DropDown, _Boolean}

signal read_new_line(line)
signal terminate_page(page_index: int)
signal page_finished(page_index: int)
signal read_new_page(page_index: int)

var currently_speaking_name := ""
var currently_speaking_visible := true
var history := []

func _ready() -> void:
	#var path = source_path_demo if show_demo else source_path
	var file : FileAccess
	if show_demo:
		file = FileAccess.open(demo_file, FileAccess.READ)
	else:
		file = FileAccess.open(source_file, FileAccess.READ)
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	
	
	# all keys are now strings instead of ints
	var int_data := {}
	var loaded_data = data.get("page_data")
	for i in loaded_data.size():
		var where = int(loaded_data.get(str(i)).get("number"))
		int_data[where] = loaded_data.get(str(i)).duplicate()
	
	page_data = int_data.duplicate()
	
	facts = data.get("facts")
	starting_facts = facts.duplicate(true)
	dropdown_titles = data.get("dropdown_titles")
	dropdowns = data.get("dropdowns")
	
	if show_demo:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	ParserEvents.listen(self, "name_label_updated")
	ParserEvents.listen(self, "text_content_text_changed")
	ParserEvents.listen(self, "choice_pressed")

## Call this one for a blank, new game.
func reset_and_start(start_page_index:=0):
	line_reader.terminated = false
	line_reader.visible = true
	paused = false
	reset_facts()
	read_page(start_page_index)
	history = []

func get_fact(fact_name: String) -> bool:
	return facts.get(fact_name, false)

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

func handle_event(event_name: String, event_args: Dictionary):
	match event_name:
		"name_label_updated":
			currently_speaking_name = event_args.get("actor_name")
			currently_speaking_visible = event_args.get("is_name_container_visible")
		"text_content_text_changed":
			var text = event_args.get("new_text")
			call_deferred("append_to_history", (str(str("[b]",currently_speaking_name, "[/b]: ") if currently_speaking_visible else "", text)))
		"choice_pressed":
			if append_choices_to_history:
				call_deferred("append_to_history", str(choice_appendation_string, " ", event_args.get("choice_text")))

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
	print(str("reading page ", number))
	if not page_data.keys().has(number):
		push_warning("number not in page data")
		return
	
	#emit_signal("read_new_page", number)
	ParserEvents.start("read_new_page", {"number":number})
	page_index = number
	lines = page_data.get(page_index).get("lines")
	max_line_index_on_page = lines.size() - 1
	
	line_index = starting_line_index
	
	var page_bound_facts : Dictionary = page_data.get(page_index).get("facts", {}).get("values", {})
	for fact in page_bound_facts:
		change_fact(fact, page_bound_facts.get(fact))
	
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
 
func get_game_progress(full_if_on_last_page:= true) -> float:
	var max_line_index_used_for_calc := 0
	var calc_lines = page_data.get(page_index).get("lines")
	max_line_index_used_for_calc = calc_lines.size() - 1
	var max_page_index :int= max(page_data.keys().size(), 1)
	var page_index_used_for_calc := page_index
	var line_index_used_for_calc := line_index
	
#	if FileAccess.file_exists(save_file_path):
#		var file = FileAccess.open(save_file_path, FileAccess.READ)
#
#		var data : Dictionary = JSON.parse_string(file.get_as_text())
#		file.close()
#
#		var parser_data = data.get("Parser", {})
#
#		page_index_used_for_calc = int(parser_data.get("Parser.page_index", 0))
#		line_index_used_for_calc = int(parser_data.get("Parser.line_index", 0))
	
	
	if max_line_index_used_for_calc <= 0:
		return 0.0
	
	
	if max_page_index <= 0:
		return 0.0
	
	var page_progress = (int(page_index_used_for_calc) / float(max_page_index))
	var line_progress = float(line_index_used_for_calc) / float(max_line_index_used_for_calc)
	
	if full_if_on_last_page and page_index_used_for_calc == max_page_index:
		return 1.0
	
	return page_progress + (line_progress / float(max_page_index))

func read_line(index: int):
	if lines.size() == 0:
		push_warning(str("No lines defined for page ", page_index))
		return
	line_index = index
	emit_signal("read_new_line", lines[index])
	

func read_next_line(finished_line_index: int):
	if finished_line_index >= max_line_index_on_page:
		var do_terminate = bool(page_data.get(page_index).get("terminate"))
		if do_terminate:
			ParserEvents.start("terminate_page", {"page_index": page_index})
			emit_signal("terminate_page", page_index)
		else:
			var next = int(page_data.get(page_index).get("next"))
			if page_data.keys().has(next):
				emit_signal("page_finished", page_index)
				ParserEvents.start("page_finished", {"page_index": page_index})
				read_page(next)
			else:
				emit_signal("terminate_page", page_index)
				ParserEvents.start("page_finished", {"page_index": page_index})
				ParserEvents.start("terminate_page", {"page_index": page_index})
				push_warning(str("tried to read non-existent page ", next, " after non-terminating page ", page_index))
		return
	read_line(finished_line_index + 1)



func open_connection(new_lr: LineReader):
	line_reader = new_lr
	line_reader.connect("line_finished", read_next_line)
	line_reader.connect("jump_to_page", read_page)
	

func change_fact(fact_name: String, new_value: bool):
	var e = {
		"old_value" : facts[fact_name],
		"fact_name": fact_name,
		"new_value": new_value
	}
	facts[fact_name] = new_value
	ParserEvents.start("fact_changed", e)

func apply_facts(f: Dictionary):
	for fact in f.keys():
		change_fact(fact, f.get(fact))

func reset_facts():
	for fact in starting_facts.keys():
		change_fact(fact, starting_facts.get(fact))

func serialize() -> Dictionary:
	var result := {}
	
	result["Parser.facts"] = facts
	result["Parser.lines"] = lines
	result["Parser.max_line_index_on_page"] = max_line_index_on_page
	result["Parser.page_index"] = page_index
	result["Parser.line_index"] = line_index
	result["Parser.history"] = history
	result["Parser.line_reader"] = line_reader.serialize()
	result["Parser.game_progress"] = get_game_progress()
	
	return result

func deserialize(data: Dictionary):
	lines = data.get("Parser.lines")
	max_line_index_on_page = int(data.get("Parser.max_line_index_on_page"))
	
	page_index = int(data.get("Parser.page_index", 0))
	line_index = int(data.get("Parser.line_index", 0))
	apply_facts(data.get("Parser.facts", {}))
	history = data.get("Parser.history", [])
	var line_reader_data = data.get("Parser.line_reader", {})
	if line_reader_data == {}:
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
