extends Control

var use_dialog_syntax := false
var active_actors := [] # list of character names
var active_actors_title := ""
var selected_actor_dropdown_index := 0

func _ready() -> void:
	find_child("DropDownForActors").clear()
	for title in Pages.dropdown_titles:
		find_child("DropDownForActors").add_item(title)
	find_child("DropDownForActors").select(find_child("DropDownForActors").get_selectable_item())
	set_use_dialog_syntax(false)
	
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

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ENTER:
			#if not use_dialog_syntax: return
			print("ENTER")

func _on_pause_auto_cont_pressed() -> void:
	insert("autopause")


func _on_pause_click_cont_pressed() -> void:
	insert("manualpause")

func _on_line_clear_pressed() -> void:
	insert("lineclear")

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
	find_child("TextBox").insert_text_at_caret("[]>")
	find_child("DialogActorHint").build(active_actors)
	find_child("DialogActorHint").popup()
	var caret_pos = (
		get_window().position +
		Vector2i(find_child("TextBox").global_position) +
		Vector2i(find_child("TextBox").get_caret_draw_pos())
		)
	caret_pos.x += 40
	find_child("DialogActorHint").position = caret_pos # - canvas_position

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
