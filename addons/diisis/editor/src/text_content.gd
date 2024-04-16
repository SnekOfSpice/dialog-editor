@tool
extends Control

var use_dialog_syntax := false
var active_actors := [] # list of character names
var active_actors_title := ""
var selected_actor_dropdown_index := 0

var control_sequences := ["lc", "ap", "mp", "var", "func"]
var control_sequence_hints := {
	"lc": "Line Clear: Clears all text of this line that came before this control sequence. Equivalent to starting another line.",
	"ap": "Auto Pause: Pauses the reading of text for a certain time frame set in the parser before continuing automatically.",
	"mp": "Manual Pause: Pauses the reading of text until the player clicks.",
	"var": "<var:var_name>\n\nEvaluate any variable (will get inserted as its String representation).",
	"func": "<func:func_name>\n<func:func_name,arg0,arg1>\n\nCall a function (It should return a String). Can take in arbitrary amounts of arguments, but the arguments must match the function signature of the respective func in the evaluator (obv).",
}

func init() -> void:
	find_child("DropDownForActors").clear()
	for title in Pages.dropdown_titles:
		find_child("DropDownForActors").add_item(title)
	find_child("DropDownForActors").select(find_child("DropDownForActors").get_selectable_item())
	set_use_dialog_syntax(true)
	set_page_view(Pages.editor.get_selected_page_view())
	
func serialize() -> Dictionary:
	var result := {}
	
	result["content"] = find_child("TextBox").text
	result["use_dialog_syntax"] = use_dialog_syntax
	result["active_actors"] = active_actors
	result["selected_actor_dropdown_index"] = selected_actor_dropdown_index
	result["active_actors_title"] = active_actors_title
	
	return result

func deserialize(data: Dictionary):
	find_child("TextBox").text = data.get("content")
	active_actors = data.get("active_actors", [])
	active_actors_title = data.get("active_actors_title", "")
	selected_actor_dropdown_index = data.get("selected_actor_dropdown_index", 0)
	set_use_dialog_syntax(data.get("use_dialog_syntax", false))
	

func set_page_view(view:DiisisEditor.PageView):
	find_child("DialogSyntaxContainer").visible = view != DiisisEditor.PageView.Minimal
	var tb : TextEdit = find_child("TextBox")
	match view:
		DiisisEditor.PageView.Full:
			tb.custom_minimum_size.y = 80
			tb.size_flags_vertical = Control.SIZE_EXPAND_FILL
			tb.scroll_fit_content_height = true
		DiisisEditor.PageView.Truncated:
			tb.custom_minimum_size.y = 25
			tb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			tb.scroll_fit_content_height = true
		DiisisEditor.PageView.Minimal:
			tb.custom_minimum_size.y = 25
			tb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			tb.scroll_fit_content_height = false


func _input(event: InputEvent) -> void:
	pass

func insert(control_sequence: String):
	var tb : TextEdit = find_child("TextBox")
	match control_sequence:
		"autopause":
			tb.insert_text_at_caret("<ap>")
		"manualpause":
			tb.insert_text_at_caret("<mp>")
		"lineclear":
			tb.insert_text_at_caret("<lc>")

func set_use_dialog_syntax(value: bool):
	use_dialog_syntax = value
	if use_dialog_syntax:
		find_child("DropDownForActors").select(selected_actor_dropdown_index)
	find_child("DialogSyntaxControls").visible = use_dialog_syntax
	find_child("UseDialogSyntaxButton").button_pressed = use_dialog_syntax
	fill_active_actors()
	

func _on_use_dialog_syntax_button_toggled(button_pressed: bool) -> void:
	set_use_dialog_syntax(button_pressed)
	
	if not use_dialog_syntax: return
	
#	for c in find_child("ActiveActorsContainer").get_children():
#		c.queue_free()
	
	# TODO active actor stuff
	


func _on_text_box_caret_changed() -> void:
	if find_child("TextBox").get_caret_column() == 0:
		var is_line_empty = find_child("TextBox").get_line(find_child("TextBox").get_caret_line()).is_empty()
		if use_dialog_syntax and is_line_empty:
			build_actor_hint()

func build_actor_hint():
	used_arguments.clear()
	entered_arguments = 0
	find_child("TextBox").insert_text_at_caret("[]>")
	find_child("DialogActorHint").build(active_actors)
	find_child("DialogActorHint").popup()
	position_hint_at_caret(find_child("DialogActorHint"))

func fill_active_actors():
	var title = find_child("DropDownForActors").get_item_text(find_child("DropDownForActors").get_selected_id())
	active_actors.clear()
	for v in Pages.dropdowns.get(title):
		active_actors.append(v)
	active_actors_title = title
	find_child("ActiveActorsLabel").text = str(active_actors)


func _on_drop_down_for_actors_item_selected(index: int) -> void:
	fill_active_actors()
	selected_actor_dropdown_index = index


func _on_text_box_focus_entered() -> void:
	if find_child("TextBox").text.is_empty() and use_dialog_syntax:
		build_actor_hint()


func _on_dialog_actor_hint_item_chosen(item_name) -> void:
	find_child("TextBox").insert_text_at_caret(str(item_name, ":"))
	if not Pages.dropdown_dialog_arguments.is_empty():
		find_child("TextBox").set_caret_column(find_child("TextBox").get_caret_column() - 1)
		find_child("DialogArgumentHint").popup()
		find_child("DialogArgumentHint").build(Pages.dropdown_dialog_arguments)
		position_hint_at_caret(find_child("DialogArgumentHint"))


func _on_text_box_text_changed() -> void:
	var tb: TextEdit = find_child("TextBox")
	var line_index = tb.get_caret_line()
	var col_index = tb.get_caret_column()
	var line = tb.get_line(line_index)
	var last_char : String
	if col_index > 0:
		last_char = line[col_index-1]
	else:
		last_char = ""
	
	if last_char == "<":
		find_child("ControlSequenceHint").build(control_sequences, control_sequence_hints)
		find_child("ControlSequenceHint").popup()
		position_hint_at_caret(find_child("ControlSequenceHint"))

func position_hint_at_caret(hint: Window):
	var caret_pos = (
			get_window().position +
			Vector2i(find_child("TextBox").global_position) +
			Vector2i(find_child("TextBox").get_caret_draw_pos())
			)
	caret_pos.x += 40
	hint.position = caret_pos


func _on_control_sequence_hint_item_chosen(item_name) -> void:
	if item_name == "var" or item_name == "func":
		find_child("TextBox").insert_text_at_caret(str(item_name, ":>"))
		find_child("TextBox").set_caret_column(find_child("TextBox").get_caret_column() - 1)
	else:
		find_child("TextBox").insert_text_at_caret(str(item_name, ">"))

func move_caret(amount: int):
	find_child("TextBox").set_caret_column(find_child("TextBox").get_caret_column() + amount)

var entered_arguments := 0
var used_arguments := []
func _on_dialog_argument_hint_item_chosen(item_name) -> void:
	if entered_arguments == 0:
		find_child("TextBox").insert_text_at_caret(str("{",item_name, "}"))
		move_caret(-1)
	elif entered_arguments > 0 and entered_arguments < Pages.dropdown_dialog_arguments.size():
		move_caret(1)
		find_child("TextBox").insert_text_at_caret(str(",", item_name))
	elif entered_arguments > 0:
		move_caret(1)
		find_child("TextBox").insert_text_at_caret(str(item_name))
	
	find_child("DialogArgumentValueHint").popup()
	find_child("DialogArgumentValueHint").build(Pages.dropdowns.get(item_name, []))
	position_hint_at_caret(find_child("DialogArgumentValueHint"))
	
	used_arguments.append(item_name)
	entered_arguments += 1


func _on_dialog_argument_value_hint_item_chosen(item_name) -> void:
	find_child("TextBox").insert_text_at_caret(str("|",item_name))
	move_caret(-1)
	if entered_arguments < Pages.dropdown_dialog_arguments.size():
		if used_arguments.size() >= Pages.dropdown_dialog_arguments.size():
			return
		var available_arguments := []
		for a in Pages.dropdown_dialog_arguments:
			if not used_arguments.has(a):
				available_arguments.append(a)
			find_child("DialogArgumentHint").popup()
			find_child("DialogArgumentHint").build(available_arguments)
			position_hint_at_caret(find_child("DialogArgumentHint"))

func type_hint_about_to_close():
	# move caret to end of line
	find_child("TextBox").set_caret_column(find_child("TextBox").get_line(find_child("TextBox").get_caret_line()).length())
