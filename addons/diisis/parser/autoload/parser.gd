extends Node
## The beating heart of runtime-side DIISIS <3
##
## uwu


const MAX_LINE_LENGTH := 10


signal line_started(line)
signal page_terminated(page_index: int)
signal page_finished(page_index: int)


enum RollbackDeclineReason {
	HIT_CHOICE = 1,
	HIT_FOLDER = 3,
	BEGINNING = 0,
}
## Enables dialine split detection. See the tooltip in DIISIS > File > Localization
## for more information.
enum DialineSplitDetection {
	## Parsed once iat [method full_initialize].
	## Makes it necessary to call [method full_initialize] again to apply
	## locale changes, and adds a bit of extra bake time to Parser startup.
	BAKED,
	## At runtime. Every call to [method get_text] dynamically fetches the correct text.
	## This makes locale changes (mostly) real-time, possibly leading to slight slowdowns at runtime.
	DYNAMIC,
	## Disables split detection from imported csv l10n files.
	## [Parser] will assume all l10n keys that end with [code]:0[/code] to denote
	## the start of a set of l10n keys that should be fused together.
	## If this is undesirable to you, e.g. because of a bespoke
	## text key naming convention, you can disable this behavior here.
	DISABLED,
}

## Set this to manually set any DIISIS-generated file to be used as source, irregardless of project.
@export_file("*.json") var source_file_override: String
## Number of entries the history will save. If set to [code]-1[/code] (default),
## the history is not limited. Otherwise, the latest history entry will be erased when 
## a new one is entered while at max length.
@export var max_history_length := -1
@export var dialine_split_detection := DialineSplitDetection.DYNAMIC

@export_group("Choices in History", "history_choices_")
## If [code]true[/code], will append the text of choice buttons to the history.
@export var history_choices_enabled := true
##When logging a choice to the history, a space will be inserted between this
## String and the text of the choice made.[br]
## If this is an empty string, no space will be inserted.
@export var history_choices_prefix := "Choice made:"

@export_group("Progress")
## When calling [method _get_game_progress], the Parser will assume that any terminating page means full progress (1.0).
## Mostly useful for visual novels and other linear stories that have few end points.
@export var full_progress_on_last_page := true
@export_subgroup("Block Rollback", "block_rollback_on_")
@export var block_rollback_on_choices := true
@export var block_rollback_on_folders := false

@export_group("Debug")
@export var startup_fact_payload : Array[ParserFactChange]

var page_data := {}
var text_data := {}
var use_dialog_syntax := true
var word_count := 0
var character_count := 0
var text_lead_time_same_actor := 0.0
var text_lead_time_other_actor := 0.0
var _default_locale := "en_US"
var locale := "en_US"
var l10n := {}
var stringkit_titles := []
var stringkits := {}
var file_config := {}
var regions := {}

var line_reader : LineReader = null
var paused := true

var page_index := 0
var line_index := 0
var lines := []
var page_id : String
var line_id : String
var terminated_line_index := -1
var terminated_page_index := -1

var facts := {}
var starting_facts := {}
var full_custom_method_defaults := {}

var max_line_index_on_page := 0


var history := []

var address_trail_index := -1
var address_trail := []

var _last_modified_time = 0
var _region_end : String

## dynamically built helper array to speed up some function calls
var page_keys := []


func _get_current_path(suppress_error := false) -> String:
	if source_file_override:
		return source_file_override
	if not last_data_fetch_path.is_empty():
		return last_data_fetch_path
	var project_path := String(ProjectSettings.get_setting("diisis/project/file/path"))
	if project_path.is_empty():
		if not suppress_error:
			push_error("Parser could not find project source file. Either set Parser.source_file_override manually, or make sure that the DIISIS file has been saved at least once.")
		return ""
	# where did that \n come from???
	return project_path.trim_suffix("\n")



var last_data_fetch_path := ""
func _get_data(path:String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	last_data_fetch_path = path
	file.close()
	return data.get("pages")
	

func _ready() -> void:
	full_initialize(ProjectSettings.get_setting("diisis/project/file/path"))
	
	ParserEvents.choice_pressed.connect(_on_choice_pressed)
	ParserEvents.rollback_declined.connect(_on_rollback_declined)


func _on_rollback_declined(reason : RollbackDeclineReason):
	match reason:
		RollbackDeclineReason.HIT_CHOICE:
			push_warning("Attempted rollback while block_rollback_on_choices was true.")
		RollbackDeclineReason.HIT_FOLDER:
			push_warning("Attempted rollback while block_rollback_on_folders was true.")
		RollbackDeclineReason.BEGINNING:
			push_warning("You're at the beginning.")


## Function that gets called automatically once when you run the game,
## using the [code]diisis/project/file/path[/code] property set in
## [ProjectSettings], which DIISIS handles automatically when you save a file.
## [br]Call this function with a path to a file at runtime to manually load a file.
## This is useful if your game is split across files.
func full_initialize(path : String):
	var data = _get_data(path)
	
	_last_modified_time = FileAccess.get_modified_time(_get_current_path())
	
	_initialize(data)
	_apply_debug_fact_payload()


func _initialize(data:Dictionary):
	# all keys are now strings instead of ints
	var int_data := {}
	var loaded_data = data.get("page_data", {})
	for i in loaded_data.size():
		var where = int(loaded_data.get(str(i)).get("number"))
		int_data[where] = loaded_data.get(str(i)).duplicate()
	
	page_data = int_data.duplicate()
	
	facts = data.get("facts", {})
	word_count = data.get("word_count", -1)
	character_count = data.get("character_count", -1)
	use_dialog_syntax = data.get("use_dialog_syntax", true)
	text_lead_time_same_actor = data.get("text_lead_time_same_actor", 0.0)
	text_lead_time_other_actor = data.get("text_lead_time_other_actor", 0.0)
	starting_facts = facts.duplicate(true)
	stringkit_titles = data.get("stringkit_titles", [])
	stringkits = data.get("stringkits", {})
	file_config = data.get("file_config", {})
	Pages.evaluator_paths = file_config.get("evaluator_paths", [])
	Pages.custom_method_defaults = file_config.get("custom_method_defaults", {})
	Pages.custom_method_stringkit_limiters = file_config.get("custom_method_stringkit_limiters", {})
	full_custom_method_defaults = data.get("full_custom_method_defaults", {})
	text_data = data.get("text_data", {})
	_default_locale = data.get("default_locale", "en_US")
	regions = data.get("regions", regions)
	#locale = _default_locale
	
	page_keys.clear()
	for pdata in page_data.values():
		page_keys.append(pdata.get("page_key", ""))
	
	# stitch text together
	if dialine_split_detection == DialineSplitDetection.BAKED:
		for id : String in text_data.keys():
			var translated : String = _get_stitched_dialines(id)
			if translated.is_empty():
				continue
			var translation := Translation.new()
			translation.add_message(id, translated)
			translation.locale = TranslationServer.get_locale()
			TranslationServer.add_translation(translation)

func get_custom_method_defaults(method_name:String) -> Dictionary:
	return full_custom_method_defaults.get(method_name, {})

func _process(delta: float) -> void:
	if not OS.has_feature("editor"):
		return
	
	# hot reload support
	var source_path := _get_current_path(true)
	var modified_time = FileAccess.get_modified_time(source_path)
	if modified_time != _last_modified_time:
		var current_address : String = address_trail[address_trail_index]
		var current_id : String = get_line_data(current_address).get("id")
		while not FileAccess.file_exists(source_path):
			await get_tree().process_frame
		var prev_vacts := facts.duplicate()
		_initialize(_get_data(last_data_fetch_path))
		apply_facts(prev_vacts)
		await get_tree().process_frame
		var target_indices := _get_hot_reload_position(current_id)
		
		read_page(target_indices.x, target_indices.y)
	_last_modified_time = FileAccess.get_modified_time(source_path)

# This is an internal function that implements project lookback
# returns the target page in x and target line in y
# set it to 0 in the project settings to reload in position
func _get_hot_reload_position(current_id : String) -> Vector2:
	var default := Vector2(page_index, line_index)
	if address_trail.is_empty():
		return default
	if address_trail_index < 0:
		return default
	var lookaround : int = abs(ProjectSettings.get_setting("diisis/runtime/hot_reload/lookaround", 0))
	if lookaround == 0:
		return default
	
	var sweep := 1
	var located_address := "%s.%s" % [page_index, line_index]
	while sweep <= lookaround:
		# look back
		var back_index := address_trail_index - sweep
		if back_index >= 0:
			var back_address : String = address_trail[back_index]
			var this_id : String = get_line_data(back_address).get("id")
			if this_id == current_id:
				located_address = back_address
				break
		
		# look ahead
		# this doesnÄt look ahead
		var front_address := "%s.%s" % [page_index, line_index + sweep]
		if has_address(front_address):
			var this_id : String = get_line_data(front_address).get("id")
			if this_id == current_id:
				located_address = front_address
				break
		
		
		sweep += 1
	
	var parts = DiisisEditorUtil.get_split_address(located_address)
	var page = parts[0]
	var line = parts[1]
	
	return Vector2(page, line)


func _apply_debug_fact_payload():
# ok so this is a horrible artifact from xxu
	# i couldnt get gradle to run without a debug export
	# but i dont want this to do shit on the android distributable
	# so here we are
	if OS.has_feature("debug") and (OS.has_feature("editor_hint") or OS.has_feature("editor_runtime")):
		for change : ParserFactChange in startup_fact_payload:
			change_fact_through_res(change)


## Call this one for a blank, new game.
func reset_and_start(start_page_index := 0, start_line_index := 0):
	line_reader.terminated = false
	set_paused(false)
	reset_facts()
	
	_apply_debug_fact_payload()
	
	read_page(start_page_index, start_line_index)
	history = []
	selected_choices = []
	presented_choices = []

## Pauses the Parser. If [param suppress_event] is true, [signal ParserEvents.pause_change]
## won't be emitted.
func set_paused(value:bool, suppress_event:=false):
	paused = value
	if not suppress_event:
		ParserEvents.pause_change.emit(paused)

## Returns the value of fact with name [param fact].
func get_fact(fact: String, suppress_error:=false) -> Variant:
	if not facts.has(fact):
		if not suppress_error:
			push_error("Fact is not registered. Returning null." % fact)
		return null
	return facts.get(fact)

## Typesafe version of [method get_fact] that returns a boolean. Throws a warning and returns false if the cached value isn't of type bool or doesn't exist.
func get_factb(fact: String) -> bool:
	var value := get_fact(fact, true)
	if value is bool:
		return value
	else:
		push_warning("Fact %s is not a boolean or doesn't exist. Returning false." % fact)
		return false

## Typesafe version of [method get_fact] that returns an integer. Throws a warning and returns 0 if the cached value isn't of type int or doesn't exist.
func get_facti(fact: String) -> int:
	var value := get_fact(fact, true)
	if value is int:
		return value
	else:
		push_warning("Fact %s is not an int or doesn't exist. Returning 0.")
		return 0

func get_facts_of_value(b: Variant) -> Array:
	var result := []
	for fact in facts:
		if facts.get(fact) == b:
			result.append(fact)
	return result


func set_factb(fact_name : String, value : bool, suppress_event := false) -> void:
	var change := ParserFactChange.new(
		fact_name,
		DIISISGlobal.FactDataType.BOOL,
		value
	)
	change_fact_through_res(change, suppress_event)
func set_facti(fact_name : String, value : int, suppress_event := false) -> void:
	var change := ParserFactChange.new(
		fact_name,
		DIISISGlobal.FactDataType.INT,
		value
	)
	change_fact_through_res(change, suppress_event)

func get_address() -> String:
	return str(page_index, ".", line_index)

func get_page_key(page:int) -> String:
	return page_keys[page]

func has_page_key(key:String) -> bool:
	return page_keys.has(key)

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
var presented_choices := []

func _on_choice_pressed(
	choice_data : Dictionary
):
	var choice_text : String = choice_data.get("text")
	if history_choices_enabled:
		var prefix:String
		if not history_choices_prefix.is_empty():
			prefix = ""
		else:
			prefix = str(history_choices_prefix, " ")
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


func get_page_number(key:String) -> int:
	return page_keys.find(key)


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
			page_terminated.emit(starting_page_index)
			return
		read_page(get_next(starting_page_index), starting_line_index)
		return
	
	set_paused(false)
	ParserEvents.page_started.emit(starting_page_index)
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

## [param containing] is the page index that has to be present in the trail
func get_page_trail(from_page : int, containing := -1) -> Array:
	var index_trails := []
	var handled_page_indices := []
	var page_count : int = max(page_data.size(), 1)
	var current_trail := []
	var current_handled_page := from_page
	while handled_page_indices.size() < page_count:
		current_trail.append(current_handled_page)
		handled_page_indices.append(current_handled_page)
		var page_terminates : bool = page_data.get(current_handled_page).get("terminate", false)
		if page_terminates:
			index_trails.append(current_trail.duplicate(true))
			current_trail.clear()
			if handled_page_indices.size() >= page_count:
				break
			
			# set current_handled_page to a new index we haven't started from yet.
			for i in page_count:
				if not i in handled_page_indices:
					current_handled_page = i
					break
		else:
			current_handled_page = page_data.get(current_handled_page).get("next")
	
	var required_page : int
	if containing == -1:
		required_page = from_page
	else:
		required_page = containing
	var trail : Array
	for t : Array in index_trails:
		if required_page in t:
			trail = t
			break
	
	if trail.is_empty() and not current_trail.is_empty():
		if containing == -1 or (containing != -1 and containing in current_trail):
			trail = current_trail
	
	if not trail:
		push_warning("Trail could not be built. Returning an empty array.")
		return []
	
	return trail



## Best used for kinetic VNs in combination with DIISIS' linearize option.
## [br]Nonlinear VNs get kinda nonsense values
func _get_game_progress() -> float:
	var trail : Array = get_page_trail(0, page_index)
	
	if trail.is_empty():
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
		if line_reader.line_type == DIISIS.LineType.TEXT and line_reader._dialog_lines.size() > 0:
			dialine_progress = float(line_reader._dialog_line_index) / float(line_reader._dialog_lines.size())
	
	return page_progress + (line_progress / float(trail_size)) + ((dialine_progress / float(line_count_on_page)) / float(trail_size))


func get_line_type(page : int, line : int) -> DIISIS.LineType:
	return get_line_type_by_address(str(page, ".", line))
	


func get_line_type_by_address(address:String) -> DIISIS.LineType:
	return int(get_line_data(address).get("line_type")) as DIISIS.LineType


func get_line_content(address:String) -> Dictionary:
	return get_line_data(address).get("content")


func has_address(address : String) -> bool:
	var parts = DiisisEditorUtil.get_split_address(address)
	var page = parts[0]
	var line = parts[1]
	return has_data(page, line)


func has_data(page : int, line : int) -> bool:
	if not page_data.has(page):
		return false
	
	var lines_on_page : Array = page_data.get(page).get("lines")
	return line >= 0 and line < lines_on_page.size()


func get_line_data(address:String) -> Dictionary:
	var parts = DiisisEditorUtil.get_split_address(address)
	var prev_page = parts[0]
	var prev_line = parts[1]
	
	return page_data.get(prev_page).get("lines")[prev_line]


func _get_stitched_dialines(id : String) -> String:
	var translated := ""
	var dialine_translation := tr(id + ":0")
	var has_dialine_split = dialine_translation != (id + ":0")
	if dialine_split_detection == DialineSplitDetection.DISABLED:
		has_dialine_split = false
	if has_dialine_split:
		var parts := []
		var i := 0
		while has_dialine_split:
			var dialine_key := (id + ":%s" % i)
			dialine_translation = tr(id + ":%s" % i)
			has_dialine_split = dialine_translation != dialine_key
			if not has_dialine_split or dialine_translation.is_empty():
				break
			i += 1
			parts.append(dialine_translation)
			
		translated = "[]>".join(parts)
		translated = str("[]>", translated)
	return translated


func get_text(id:String, keep_as_l10n_key := false) -> String:
	var translated := tr(id)
	if not _get_stitched_dialines(id).is_empty() and dialine_split_detection == DialineSplitDetection.DYNAMIC:
		translated = _get_stitched_dialines(id)
	
	if translated == id: # means we don't have a translation set up
		return text_data.get(id, "")
	if keep_as_l10n_key: # useful for choice labels etc
		return id
	return translated


func get_previous_address_line_type() -> DIISIS.LineType:
	if address_trail_index <= 0 or address_trail.is_empty():
		push_warning("At the beginning.")
		return int(page_data.get(0).get("lines")[0].get("line_type"))
	var previous_address = address_trail[address_trail_index - 1]
	var parts = DiisisEditorUtil.get_split_address(previous_address)
	var prev_page = parts[0]
	var prev_line = parts[1]
	
	return get_line_type_by_address(previous_address)


## Returns a dictionary with the following keys:
## [br] - [code]actors[/code]: An [Array] containing the keys of all speakers within this region.
## [br] - [code]region_end[/code]: An [String] of the address where this region ends. Is usually the exclusive end / start of the next region, except on the last region.
## [br][b]Note:[/b] Region baking needs to be enabled in the DIISIS editor for this to work. (File > Configure Regions)
func get_region() -> Dictionary:
	var address := get_address()
	for region_address in regions.keys():
		if not DiisisEditorUtil.is_address_before(address, region_address):
			var end_address : String = regions.get(region_address).get("region_end")
			if DiisisEditorUtil.is_address_before(address, end_address):
				return regions.get(region_address)
	return {}


## Returns all actors in the current region.
## See also [method get_region].
func get_region_actors() -> Array:
	return get_region().get("actors", [])


## Returns the end address of the current region.
## See also [method get_region].
func get_region_end() -> String:
	return get_region().get("region_end", "")





## returns the number of line indices to go back inside page_trail
## to reach the last text
## with blocking if we run into choices or folders if those flags are set
func _get_rollback() -> int:
	var lookback := 1
	var max_lookback := address_trail_index
	while lookback <= max_lookback:
		var line_type : DIISIS.LineType = get_line_type_by_address(address_trail[address_trail_index - lookback])
		
		if line_type == DIISIS.LineType.CHOICE and block_rollback_on_choices:
			ParserEvents.rollback_declined.emit(RollbackDeclineReason.HIT_CHOICE)
			return 0
		if line_type == DIISIS.LineType.FOLDER and block_rollback_on_folders:
			ParserEvents.rollback_declined.emit(RollbackDeclineReason.HIT_FOLDER)
			return 0
		if line_type == DIISIS.LineType.TEXT:
			return -lookback
		
		lookback += 1
	
	return 0
	

func rollback():
	var trail_shift = _get_rollback()
	
	if address_trail_index < 0 or address_trail.is_empty():
		ParserEvents.rollback_declined.emit(RollbackDeclineReason.BEGINNING)
		trail_shift = 0
	
	if line_reader._attempt_read_previous_dialine() and line_reader.line_type == DIISIS.LineType.TEXT:
		var subaddr = line_reader.get_subaddress_arr()
		ParserEvents.rollback_accepted.emit(subaddr[0], subaddr[1], subaddr[2])
		return
	
	var instruction_stack := []
	var instruction_finder := 0
	while instruction_finder > trail_shift:
		if address_trail_index + instruction_finder >= address_trail.size():
			break
		# build instruction stack
		var address_type = get_line_type_by_address(address_trail[address_trail_index + instruction_finder])
		if address_type == DIISIS.LineType.INSTRUCTION:
			var address_content = get_line_content(address_trail[address_trail_index + instruction_finder])
			instruction_stack.append(address_content)
		instruction_finder -= 1
	
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
		address_trail_index = max(address_trail.size() - 1, 0)
	var previous_address = address_trail[address_trail_index]
	var parts = DiisisEditorUtil.get_split_address(previous_address)
	var prev_page = parts[0]
	var prev_line = parts[1]
	
	var dialine_about_to_read : int
	if trail_shift == 0:
		dialine_about_to_read = 0
	elif trail_shift != 0:
		var line_data : Array = page_data.get(prev_page).get("lines")
		var raw_content : Dictionary = line_data[prev_line].get("content")
		var content := get_text(raw_content.get("text_id"))
		dialine_about_to_read = content.count("[]>") + content.count("<lc>") -1
		
		ParserEvents.rollback_accepted.emit(prev_page, prev_line, dialine_about_to_read)
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
	address_trail_index = max(address_trail.size() - 1, 0)
	address_trail.resize(address_trail_index + 1)


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
	
	terminated_line_index = -1
	terminated_page_index = -1
	
	var new_region_end = get_region_end()
	if new_region_end != _region_end:
		ParserEvents.region_changed.emit()
	_region_end = new_region_end
	
	var line_data : Dictionary = lines[index]
	line_id = line_data.get("id", "")
	emit_signal("line_started", line_data)
	

func read_next_line(finished_line_index: int):
	if page_index == terminated_page_index and finished_line_index == terminated_line_index:
		return
	
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
			terminate()
		else:
			var next = int(page_data.get(page_index).get("next"))
			if page_data.keys().has(next):
				emit_signal("page_finished", page_index)
				ParserEvents.page_finished.emit(page_index)
				read_page(next)
			else:
				terminate()
				push_warning(str("tried to read non-existent page ", next, " after non-terminating page ", page_index))
		return
	
	read_line(finished_line_index + 1)


## Call this to terminate early before the end of a page.
func terminate():
	if not is_active():
		return
	terminated_line_index = line_index
	terminated_page_index = page_index
	page_terminated.emit(page_index)
	ParserEvents.page_finished.emit(page_index)
	ParserEvents.page_terminated.emit(page_index)


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

## Helper function. 
## This is equivalent to calling [method change_fact] with a dictionary containing the fields of [ParserFactChange].
func change_fact_through_res(resource : ParserFactChange, suppress_event:=false):
	var data := {
			"fact_name" = resource.fact_name,
			"data_type" = int(resource.data_type),
			"fact_value" = resource.value
		}
	change_fact(data, suppress_event)
	

## Changes [param fact_name] to [param new_value]. If [param suppress_event] is [code]true[/code]
## [signal ParserEvents.fact_changed] won't be emitted.[br]
## See also [method change_fact_through_res].
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
	result["Parser.terminated_page_index"] = terminated_page_index
	result["Parser.terminated_line_index"] = terminated_line_index
	result["Parser.history"] = history
	result["Parser.line_reader"] = line_reader._serialize()
	result["Parser.game_progress"] = _get_game_progress()
	result["Parser.selected_choices"] = selected_choices
	result["Parser.presented_choices"] = presented_choices
	result["address_trail"] = address_trail
	result["address_trail_index"] = address_trail_index
	
	return result

func deserialize(data: Dictionary):
	lines = data.get("Parser.lines")
	selected_choices = data.get("Parser.selected_choices")
	presented_choices = data.get("Parser.presented_choices")
	max_line_index_on_page = int(data.get("Parser.max_line_index_on_page"))
	
	address_trail_index = data.get("address_trail_index")
	address_trail = data.get("address_trail")
	
	page_index = int(data.get("Parser.page_index", 0))
	line_index = int(data.get("Parser.line_index", 0))
	terminated_page_index = int(data.get("Parser.terminated_page_index", terminated_page_index))
	terminated_line_index = int(data.get("Parser.terminated_line_index", terminated_line_index))
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


func is_active() -> bool:
	if paused:
		return false
	if line_reader:
		if line_reader.terminated:
			return false
	if not line_reader:
		return false
	return true


func has_fact(fact_name : String) -> bool:
	return facts.has(fact_name)


func get_next_natural_line_address(
	from_page : int,
	from_line : int,
	for_type : DIISISGlobal.LineType = DIISISGlobal.LineType.TEXT) -> String:
	var trail := get_page_trail(from_page)
	for page : int in trail:
		for line in range(
			(from_line if page == from_page else 0),
			get_line_count(page)
		):
			var line_type : DIISIS.LineType = get_line_type(page, line)
			if line_type == for_type:
				return str(page, ".", line)
	
	push_warning("Couldn't find next natural line address from %s.%s" % [from_page, from_line])
	return str(from_page, ".", from_line)


func get_line_count(page : int) -> int:
	return page_data.get(page, {}).get("lines", []).size()
