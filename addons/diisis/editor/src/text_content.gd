@tool
extends Control
class_name TextContent

signal drop_focus()

const WORD_SEPARATORS :=  ["[", "]", "{", "}", ">", "<", ".", ",", "|", " ", "-", ":", ";", "#", "*", "+", "~", "'"]
const BBCODE_TAGS := ["b", "i", "u", "s", "img", "url", "font_size", "font", "rainbow", "pulse", "wave", "tornado", "shake", "fade", "code", "char", "center", "left", "right", "color", "bgcolor", "fgcolor", "outline_size", "outline_color"]

var active_actors := [] # list of character names
var active_actors_title := ""

var entered_arguments := 0
var used_arguments := []
var tags := []
var text_id : String
var last_character_after_caret : String

var text_box : CodeEdit

func get_text_before_caret(length:int):
	var line : String = text_box.get_line(text_box.get_caret_line())
	if text_box.get_caret_column() <= length:
		return line.substr(0, length)
	return line.substr(text_box.get_caret_column() - length, length)
	
func get_text_after_caret(length:int):
	var line : String = text_box.get_line(text_box.get_caret_line())
	if line.length() - text_box.get_caret_column() <= length:
		return line.substr(text_box.get_caret_column())
	return line.substr(text_box.get_caret_column(), length)

func init() -> void:
	text_box = find_child("TextBox")
	await get_tree().process_frame
	
	fill_active_actors()
	set_page_view(Pages.editor.get_selected_page_view())
	
	# these are  the symbols that need to wrap any position where code completion
	# should be able to be triggered /on both sides/
	var a : PackedStringArray = [">", "{", "<", "|", "}", ",", ":", "[", "]", "."]
	for actor in active_actors:
		a.append(actor[actor.length() - 1])
	text_box.code_completion_prefixes = a
	
	await get_tree().process_frame
	text_box.grab_focus()
	text_box.cancel_code_completion()
	
	find_child("Text Actions").add_submenu_node_item("Ingest Line", find_child("Import"))
	
func serialize() -> Dictionary:
	if not text_id:
		text_id = Pages.get_new_id()
	
	var result := {}
	
	result["text_id"] = text_id
	result["meta.validation_status"] = get_overall_compliance()
	if not get_function_calls().is_empty():
		result["meta.function_calls"] = get_function_calls()
	Pages.save_text(text_id, text_box.text)
	
	return result

func deserialize(data: Dictionary):
	text_id = data.get("text_id", Pages.get_new_id())
	text_box.text = Pages.get_text(text_id)
	if text_box.text.is_empty(): # compat
		text_box.text = data.get("content", "")
	active_actors = data.get("active_actors", [])
	active_actors_title = data.get("active_actors_title", "")
	fill_active_actors()

func set_page_view(view:DiisisEditor.PageView):
	find_child("DialogSyntaxContainer").visible = view == DiisisEditor.PageView.Full
	if not text_box:
		return
	match view:
		DiisisEditor.PageView.Full:
			text_box.custom_minimum_size.y = 100
			text_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
			text_box.scroll_fit_content_height = true
		DiisisEditor.PageView.Truncated:
			text_box.custom_minimum_size.y = 25
			text_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			text_box.scroll_fit_content_height = true
		DiisisEditor.PageView.Minimal:
			text_box.custom_minimum_size.y = 25
			text_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			text_box.scroll_fit_content_height = false


var caret_movement_to_do := 0
func _process(delta: float) -> void:
	if caret_movement_to_do != 0:
		move_caret(caret_movement_to_do)
		caret_movement_to_do = 0

func get_word_under_caret() -> String:
	var line := text_box.get_line(text_box.get_caret_line())
	var start_position := text_box.get_caret_column()
	var i := start_position-1
	var character_at_position := line[i]
	var word := ""
	while not (character_at_position in WORD_SEPARATORS) and i >= 0:
		character_at_position = line[i]
		if character_at_position in WORD_SEPARATORS:
			break
		word = character_at_position + word
		
		i -= 1
	i = start_position + 1
	while not (character_at_position in WORD_SEPARATORS) and i < line.length():
		character_at_position = line[i]
		if character_at_position in WORD_SEPARATORS:
			break
		word += character_at_position
		
		i += 1
	
	return word

func _find_position_under_caret(back_to_front:bool) -> int:
	var line := text_box.get_line(text_box.get_caret_line())
	var start_position := text_box.get_caret_column()
	var found_position:int
	if back_to_front:
		found_position = -1
	else:
		found_position = line.length()
	for separator in WORD_SEPARATORS:
		var separator_position:int
		if back_to_front:
			separator_position = line.rfind(separator, start_position)
			if separator_position > found_position:
				found_position = separator_position
		else:
			separator_position = line.find(separator, start_position)
			if separator_position < found_position and separator_position != -1:
				found_position = separator_position
	return found_position

func get_start_position_of_word_under_caret() -> int:
	return _find_position_under_caret(true)

func get_end_position_of_word_under_caret() -> int:
	return _find_position_under_caret(false)

func get_separator_character_before_word_under_caret() -> String:
	var line := text_box.get_line(text_box.get_caret_line())
	var pos := get_start_position_of_word_under_caret()
	if pos == -1:
		return ""
	return line[pos]

func get_separator_character_after_word_under_caret() -> String:
	var line := text_box.get_line(text_box.get_caret_line())
	var pos := get_end_position_of_word_under_caret()
	if pos == line.length():
		return ""
	return line[pos]

func is_current_line_empty():
	return text_box.get_line(text_box.get_caret_line()).is_empty()


# CRITICAL
# DON'T FORGET
# to make this work, also give the correct things to text_box.code_completion_prefixes on startup!
func _on_text_box_caret_changed() -> void:
	if text_box.get_caret_column() == 0:
		var is_line_empty = text_box.get_line(text_box.get_caret_line()).is_empty()
		if Pages.use_dialog_syntax and is_line_empty:
			prepare_line_for_text_insertion()
	
	
	var full_actor_before_caret := false
	for actor:String in active_actors:
		if is_text_before_caret(actor):
			full_actor_before_caret = true
			break
		
	if is_text_before_caret("[]>"):
		for actor in active_actors:
			text_box.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, actor, str(actor, ":"))

		text_box.update_code_completion_options(true)

	elif is_text_before_caret("{"):
		if Pages.dropdown_dialog_arguments.is_empty():
			Pages.editor.notify("No Dialog Arguments set.\nGo to Setup > Dropdowns to change this.")
		for actor in Pages.dropdown_dialog_arguments:
			text_box.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, actor, str(actor, "|}"))
		text_box.update_code_completion_options(true)
	elif get_text_before_caret(1) == "," and get_text_after_caret(1) == "}":
		var used_args = get_used_dialog_args_in_line()
		for arg in Pages.dropdown_dialog_arguments:
			if arg in used_args:
				continue
			text_box.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, arg, str(arg, "|"))
		text_box.update_code_completion_options(true)
	elif is_text_before_caret("<"):
		for a in DIISIS.control_sequences:
			text_box.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, a, str(a, ":" if (a in DIISIS.control_sequences_with_colon) else "", ">"))
		text_box.update_code_completion_options(true)
	elif get_text_before_caret(1) == "|":
		for a in Pages.dropdowns.get(Pages.auto_complete_context, []):
			text_box.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, a, a)
		text_box.update_code_completion_options(true)
	elif full_actor_before_caret and get_text_after_caret(1) == ":":
		text_box.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, "a", "a")
		text_box.update_code_completion_options(true)
	elif is_text_before_caret(":") and is_text_after_caret(">"):
		if is_text_before_caret("func:") or is_text_before_caret("call:"):
			for method in Pages.get_all_instruction_names():
				text_box.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, method, method)
		elif is_text_before_caret("var:"):
			for property in Pages.get_all_custom_properties():
				text_box.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, property, property)
		elif is_text_before_caret("fact:"):
			for fact in Pages.facts.keys():
				text_box.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, fact, fact)
		text_box.update_code_completion_options(true)
	elif is_text_before_caret("["):
		for tag in BBCODE_TAGS:
			var display_text:String
			var closing_tag = tag
			match tag:
				"b":
					display_text = "bold"
				"i":
					display_text = "italics"
				"u":
					display_text = "underline"
				"s":
					display_text = "strikethrough"
				"img":
					display_text = "image"
				"font_size":
					display_text = "font size"
				"rainbow":
					tag += " freq=1.0 sat=0.8 val=0.8 speed=1.0"
				"pulse":
					tag += " freq=1.0 color=#ffffff40 ease=-2.0"
				"wave":
					tag += " amp=50.0 freq=5.0 connected=1"
				"tornado":
					tag += " radius=10.0 freq=1.0 connected=1"
				"shake":
					tag += " rate=20.0 level=5 connected=1"
				"fade":
					tag += " start=4 length=14"
			if tag in ["url", "font_size", "font","char", "color", "bgcolor", "fgcolor", "outline_size", "outline_color"]:
				tag += "="
			if not display_text:
				display_text = closing_tag
			text_box.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, display_text, str(tag, "][/", closing_tag, "]"))
		text_box.update_code_completion_options(true)
		text_box.code_completion_prefixes
	elif is_text_before_caret("."):
		var found_autoload := ""
		var is_var : bool
		for autoload in Pages.callable_autoloads:
			if is_text_before_caret(str("<call:", autoload, ".")) or is_text_before_caret(str("<func:", autoload, ".")):
				found_autoload = autoload
				is_var = false
				break
			elif is_text_before_caret(str("<var:", autoload, ".")):
				found_autoload = autoload
				is_var = true
				break
		if not found_autoload.is_empty():
			var completions : Array
			var postfix := ""
			if is_var:
				completions = Pages.get_custom_autoload_properties(found_autoload)
			else:
				completions = Pages.get_custom_autoload_methods(found_autoload)
				postfix = "()"
			for method in completions:
				text_box.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, method, str(method, postfix))
			await get_tree().process_frame
			text_box.update_code_completion_options(true)
	
	update_tag_hint()
	last_character_after_caret = get_text_after_caret(1)

func update_tag_hint():
	index_all_tags()
	update_inline_tag_prompt()
	update_compliance_prompt()

func update():
	fill_active_actors()
	update_compliance_prompt()

func update_compliance_prompt():
	if not can_process():
		return
	var label : RichTextLabel =	find_child("CompliancesLabel")
	label.text = ""
	var compliances := get_compliances()
	var complaints := []
	for call in compliances.keys():
		if compliances.get(call) == "OK":
			continue
		var color := Color.ORANGE_RED
		var color_string = color.to_html(false)
		if not complaints.is_empty():
			color_string += "83"
		complaints.append(str("[color=", color_string, "]",
			"Invalid tag ", call, ": ", compliances.get(call),
			"[/color]"
			))
	label.text = " | ".join(complaints)
	label.visible = not label.text.is_empty()

func get_used_dialog_args_in_line() -> Array:
	var line : String = text_box.get_line(text_box.get_caret_line())
	if not line.begins_with("[]>"):
		return []
	if not line.contains("}:"):
		return []
	
	var beginning := line.split(":")[0]
	beginning = beginning.trim_prefix("[]>")
	for actor in active_actors:
		beginning = beginning.trim_prefix(actor)
	beginning = beginning.trim_prefix("{")
	beginning = beginning.trim_suffix("}")
	var arg_pairs := beginning.split(",")
	var args := []
	for pair in arg_pairs:
		if not pair.contains("|"):
			continue
		var arg_name = pair.split("|")[0]
		args.append(arg_name)
	
	return args

func prepare_line_for_text_insertion():
	if not text_box.get_selected_text().is_empty():
		return
	used_arguments.clear()
	entered_arguments = 0
	text_box.insert_text_at_caret("[]>")

func fill_active_actors():
	var title = Pages.dropdown_title_for_dialog_syntax
	active_actors.clear()
	for v in Pages.dropdowns.get(title, []):
		active_actors.append(v)
	active_actors_title = title


func _on_text_box_focus_entered() -> void:
	if text_box.text.is_empty() and Pages.use_dialog_syntax:
		prepare_line_for_text_insertion()


func _on_text_box_text_changed() -> void:
	update_tag_hint()
	
	if Pages.auto_complete_context in ["call", "func"]:
		for instr in Pages.get_all_instruction_names():
			if is_text_before_caret(str("<", Pages.auto_complete_context, ":", instr)) and is_text_after_caret(">") and not last_character_after_caret == ")":
				var prev_col := text_box.get_caret_column()
				text_box.insert_text_at_caret("()")
				await get_tree().process_frame
				text_box.set_caret_column(prev_col)
				caret_movement_to_do = 1
			elif is_text_before_caret(str("<", Pages.auto_complete_context, ":", instr, "()")):
				caret_movement_to_do = -1

	var line_index = text_box.get_caret_line()
	var col_index = text_box.get_caret_column()
	var last_char : String
	if col_index > 0:
		last_char = get_text_before_caret(1)
	else:
		last_char = ""

func move_caret(amount: int):
	text_box.set_caret_column(text_box.get_caret_column() + amount)

func is_text_before_caret(what:String):
	return get_text_before_caret(what.length()) == what

func is_text_after_caret(what:String):
	return get_text_after_caret(what.length()) == what

func _on_text_box_code_completion_requested() -> void:
	for arg_name in Pages.dropdown_dialog_arguments:
		if is_text_before_caret(str(arg_name, "|}")):
			Pages.auto_complete_context = arg_name
			caret_movement_to_do = -1
		elif is_text_before_caret(str(arg_name, "|")):
			Pages.auto_complete_context = arg_name
		elif is_text_after_caret("|"):
			caret_movement_to_do = 1

	for control in ["func", "name", "var", "fact", "call", "ts_rel", "ts_abs", "comment"]:
		if is_text_before_caret(str("<", control, ":>")):
			caret_movement_to_do = -1
			Pages.auto_complete_context = control
			break
	
	for tag in BBCODE_TAGS:
		if is_text_before_caret(str("=][/", tag, "]")):
			caret_movement_to_do = -str("][/", tag, "]").length()
			break
		elif is_text_before_caret(str("[/", tag, "]")):
			caret_movement_to_do = -str("[/", tag, "]").length()
			break
	
	update_tag_hint()


func _on_text_actions_id_pressed(id: int) -> void:
	match id:
		0:
			text_box.text = Pages.capitalize_sentence_beginnings(text_box.text)
		1:
			text_box.text = Pages.neaten_whitespace(text_box.text)
		3:
			if not text_id:
				text_id = Pages.get_new_id()
			Pages.editor.prompt_change_text_id(text_id)

func get_overall_compliance() -> String:
	for compliance : String in get_compliances().values():
		if compliance != "OK":
			return compliance
	return "OK"

func get_function_calls() -> Array:
	var result := []
	for tag_data : Dictionary in tags.duplicate(true):
		var tag : String = tag_data.get("tag")
		if tag.begins_with("<call:") or tag.begins_with("<func:"):
			var instruction := tag.split(":")[1]
			instruction = instruction.trim_suffix(">")
			result.append(instruction)
	return result

func get_compliances() -> Dictionary:
	var compliances := {}
	for instruction in get_function_calls():
		compliances[instruction] = Pages.get_method_validity(instruction)
	return compliances

func index_all_tags():
	tags.clear()
	for line_index in text_box.get_line_count():
		var line = text_box.get_line(line_index)
		var start := line.find("<")
		while start != -1:
			var end := line.find(">", start)
			if end == -1:
				break
			var tag = line.substr(start, end - start + 1)
			var data := {}
			data["start"] = start
			data["tag"] = tag
			data["end"] = end
			data["line_index"] = line_index
			tags.append(data)
			start = line.find("<", end)

func get_tag_under_caret() -> Dictionary:
	for tag : Dictionary in tags:
		if tag["line_index"] != text_box.get_caret_line():
			continue
		if tag["start"] < text_box.get_caret_column() and tag["end"] >= text_box.get_caret_column():
			return tag
	return {}

# this shit is hard-coded in length atm
# i.e. tags that access arg hint need to be 4 characters long OTL
func update_inline_tag_prompt():
	var data := get_tag_under_caret()
	if data.is_empty():
		Pages.editor.hide_arg_hint()
		return
	var tag = data["tag"]
	if is_text_before_caret(")"):
		Pages.editor.hide_arg_hint()
		return
	if tag.begins_with("<call") or tag.begins_with("<func"):
		var caret_column := text_box.get_caret_column()
		Pages.editor.request_arg_hint(text_box)
		tag = tag.erase(0, 6)
		tag = tag.trim_suffix(">")
		var instruction_name : String = tag.split("(")[0]
		var args = tag.trim_prefix(instruction_name)
		args = args.trim_prefix("(")
		args = args.trim_suffix(")")
		if caret_column > data["start"] and caret_column <= data["start"] + 6 + instruction_name.length():
			# INSTRUCTION NAME SECTION
			Pages.editor.hide_arg_hint()
		else:
			# ARG SECTION
			Pages.editor.build_arg_hint(instruction_name, args, caret_column - data["start"] - 6 - instruction_name.length())
	else:
		Pages.editor.hide_arg_hint()
		


func _on_text_box_item_rect_changed() -> void:
	if not text_box:
		text_box = find_child("TextBox")
	if not is_instance_valid(Pages.editor):
		return
	
	DiisisEditorUtil.limit_scroll_container_height(
		find_child("ScrollContainer"),
		0.5,
		find_child("ScrollHintTop"),
		find_child("ScrollHintBottom"),
	)


func set_text(text:String):
	text_box.text = text

func _on_import_id_pressed(id: int) -> void:
	match id:
		0: # file
			var address = DiisisEditorUtil.get_address(self, DiisisEditorUtil.AddressDepth.Line)
			Pages.editor.popup_ingest_file_dialog([
				address,
				find_child("Import").build_payload()]
				)
		1: # clipboard
			var text : String = TextToDiisis.format_text(DisplayServer.clipboard_get())
			if text.is_empty():
				return
			text_box.text = text
			if find_child("Import").is_capitalize_checked():
				text_box.text = Pages.capitalize_sentence_beginnings(text_box.text)
			if find_child("Import").is_whitespace_checked():
				text_box.text = Pages.neaten_whitespace(text_box.text)


func _on_text_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_command_or_control_pressed() and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			await get_tree().process_frame
			var tag : String = get_tag_under_caret().get("tag", "")
			if tag.begins_with("<call:") or tag.begins_with("<func:"):
				tag = tag.trim_prefix("<call:")
				tag = tag.trim_prefix("<func:")
				tag = tag.trim_suffix(">")
				if event.is_shift_pressed():
					Pages.editor.open_handler_window(tag.split("(")[0])
				else:
					DiisisEditorUtil.search_function(tag.split("(")[0])
			elif tag.begins_with("<var:"):
				tag = tag.trim_prefix("<var:")
				tag = tag.trim_suffix(">")
				DiisisEditorUtil.search_variable(tag)
			elif tag.begins_with("<fact:"):
				Pages.editor.open_window_by_string("FactsPopup")
			elif not tag.is_empty():
				OS.shell_open("https://github.com/SnekOfSpice/dialog-editor/wiki/Line-Type:-Text#other")
