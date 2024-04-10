@tool
extends Control
class_name DiisisEditor

const AUTO_SAVE_INTERVAL := 30000.0

var _page = preload("res://addons/diisis/editor/src/page.tscn")
var current_page: Page
var undo_redo = UndoRedo.new()

var active_dir := ""

func refresh(serialize_before_load:=true):
	var cpn:int
	if current_page:
		cpn = current_page.number
	else:
		cpn = 0
	if serialize_before_load:
		current_page.save()
	await get_tree().process_frame
	load_page(cpn, not serialize_before_load)

func init() -> void:
	print("init editor")
	Pages.connect("pages_modified", update_controls)
	Pages.editor = self
	
	#add_empty_page()
	request_add_page(0)
	
	
	update_controls()
	
	set_current_page_changeable(false)
	
	find_child("FDOpen").size = get_window().size * 0.75
	find_child("FDSave").size = get_window().size * 0.75
	find_child("MovePagePopup").size = get_window().size * 0.75
	find_child("FactsPopup").size = get_window().size * 0.75
	
	for c in get_tree().get_nodes_in_group("editor_popup_button"):
		c.init()
	
	$AutoSaveTimer.wait_time = AUTO_SAVE_INTERVAL
	$Core.visible = true
	$GraphView.visible = false
	undo_redo.clear_history()
	undo_redo.version_changed.connect(update_undo_redo_buttons)
	update_undo_redo_buttons()
	print("init editor successful")

func load_page(number: int, discard_without_saving:=false):
	await get_tree().process_frame
	number = clamp(number, 0, Pages.get_page_count() - 1)
	
	for c in $Core/PageContainer.get_children():
		if not c is Page:
			push_warning(str("PageContainer has a child that's not a page: ", c))
			continue
		
		if not discard_without_saving:
			c.save()
		c.queue_free()
	
	var page = _page.instantiate()
	$Core/PageContainer.add_child(page)
	page.init(number)
	current_page = page
	
	update_controls()
	
	$AutoSaveTimer.wait_time = AUTO_SAVE_INTERVAL
	await get_tree().process_frame

func _process(delta: float) -> void:
	find_child("AutosaveAnnounceLabel").visible = $AutoSaveTimer.time_left < 6.0
	find_child("AutosaveAnnounceLabel").text = str("Autosave in: ", floor($AutoSaveTimer.time_left))
	
	#if Input.is_action_just_pressed("f1"):
		#set_graph_view_visible(not $GraphView.visible)

func set_graph_view_visible(value:bool):
	$Core.visible = not value
	$GraphView.visible = value
	
func update_controls():
	if not current_page:
		return
	
	find_child("First").disabled = current_page.number <= 0
	find_child("Prev").disabled = current_page.number <= 0
	find_child("Next").disabled = current_page.number >= Pages.get_page_count() - 1
	find_child("Last").disabled = current_page.number >= Pages.get_page_count() - 1
	find_child("PageCountCurrent").text = str(current_page.number)
	find_child("PageCountMax").text = str(Pages.get_page_count() - 1)
	
	await get_tree().process_frame
	current_page.update()
	

func get_current_page_number() -> int:
	if not current_page:
		return 0
	
	return current_page.number




func _on_first_pressed() -> void:
	move_to_page(0, "Move to first page")


func _on_prev_pressed() -> void:
	move_to_page(current_page.number - 1, "Move to previous page")

func _on_next_pressed() -> void:
	move_to_page(current_page.number + 1, "Move to next page")

func _on_last_pressed() -> void:
	move_to_page(Pages.get_page_count() - 1, "Move to last page")

func _on_add_last_pressed() -> void:
	request_add_page(Pages.get_page_count())

func _on_delete_current_pressed() -> void:
	request_delete_page(get_current_page_number())

func request_delete_page(number:int):
	if Pages.get_page_count() <= 1:
		push_warning("you cannot delete the last page")
		return
	
	var a = get_current_page_number()
	undo_redo.create_action("Delete Page")
	if a == 0:
		undo_redo.add_do_method(DiisisEditorActions.load_page.bind(a + 1))
	else:
		undo_redo.add_do_method(DiisisEditorActions.load_page.bind(a - 1))
	undo_redo.add_do_method(DiisisEditorActions.delete_page.bind(a))
	undo_redo.add_undo_method(DiisisEditorActions.add_page.bind(a))
	undo_redo.add_undo_method(DiisisEditorActions.load_page.bind(a))
	undo_redo.commit_action()


func _on_add_after_pressed() -> void:
	request_add_page(get_current_page_number() + 1)
	

func request_add_page(at:int):
	undo_redo.create_action("Insert page")
	undo_redo.add_do_method(DiisisEditorActions.add_page.bind(at))
	undo_redo.add_do_method(DiisisEditorActions.change_page.bind(at))
	undo_redo.add_undo_method(DiisisEditorActions.change_page.bind(get_current_page_number()))
	undo_redo.add_undo_method(DiisisEditorActions.delete_page.bind(at))
	undo_redo.commit_action()


func _on_save_button_pressed() -> void:
	if active_dir != "":
		get_node("FDSave").current_dir = active_dir
	find_child("FDSave").popup()
	#find_child("FDSave").size = get_window().size - Vector2i(30, 80)

func _on_open_button_pressed() -> void:
	if active_dir != "":
		get_node("FDSave").current_dir = active_dir
	find_child("FDOpen").size = size
	find_child("FDOpen").popup()
	#find_child("FDOpen").size = get_window().size - Vector2i(30, 80)

func _on_fd_save_file_selected(path: String) -> void:
	if current_page:
		current_page.save()
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	var data_to_save = {
		"head_defaults" : Pages.head_defaults,
		"page_data" : Pages.page_data,
		"instruction_templates": Pages.instruction_templates,
		"facts": Pages.facts,
		"dropdowns": Pages.dropdowns,
		"dropdown_titles": Pages.dropdown_titles,
		"dropdown_dialog_arguments": Pages.dropdown_dialog_arguments,
	}
	file.store_string(JSON.stringify(data_to_save, "\t"))
	file.close()
	active_dir = path


func _on_fd_open_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	
	active_dir = path
	
	# all keys are now strings instead of ints
	var int_data = {}
	var page_data = data.get("page_data")
	for i in page_data.size():
		var where = int(page_data.get(str(i)).get("number"))
		int_data[where] = page_data.get(str(i)).duplicate()
	
	Pages.page_data.clear()
	Pages.page_data = int_data.duplicate()
	Pages.head_defaults = data.get("head_defaults", [])
	Pages.instruction_templates = data.get("instruction_templates", [])
	if data.get("facts") is Array:
		var compat_facts := {}
		for f in data.get("facts"):
			compat_facts[f] = true
		Pages.facts = compat_facts
	else:
		Pages.facts = data.get("facts", {})
	Pages.dropdowns = data.get("dropdowns", {})
	Pages.dropdown_titles = data.get("dropdown_titles", [])
	Pages.dropdown_dialog_arguments = data.get("dropdown_dialog_arguments", [])
	
	load_page(0, true)

func set_current_page_changeable(value:bool):
	find_child("PageCountSpinCounter").visible = value
	find_child("PageCountSpinCounter").max_value = Pages.get_page_count() - 1
	find_child("PageCountSpinCounter").get_line_edit().text = find_child("PageCountCurrent").text
	find_child("PageCountSpinCounter").apply()
	find_child("PageCountCurrent").visible = not value

func move_to_page(number:int, action_message:String):
	undo_redo.create_action(action_message)
	var cpn = current_page.number
	undo_redo.add_do_method(DiisisEditorActions.change_page.bind(number))
	undo_redo.add_undo_method(DiisisEditorActions.change_page.bind(cpn))
	undo_redo.commit_action()

func _on_change_page_button_pressed() -> void:
	if find_child("PageCountSpinCounter").visible:
		move_to_page(find_child("PageCountSpinCounter").value, "Jump to page")
	
	set_current_page_changeable(find_child("PageCountCurrent").visible)


func _on_add_line_button_pressed() -> void:
	undo_redo.create_action("Add Line")
	var line_count = current_page.get_line_count()
	undo_redo.add_do_method(DiisisEditorActions.add_line.bind(line_count))
	undo_redo.add_undo_method(DiisisEditorActions.delete_line.bind(line_count))
	undo_redo.commit_action()

func _on_edit_characters_button_pressed() -> void:
	current_page.save()
	$DropdownPopup.popup()


func _on_header_popup_update() -> void:
	await get_tree().process_frame
	current_page.update()

func _on_instruction_definition_timer_timeout() -> void:
	find_child("ErrorTextBox").text = Pages.get_all_invalid_instructions()

func _on_auto_save_timer_timeout() -> void:
	current_page.save()

func _on_instruction_popup_validate_saved_instructions() -> void:
	find_child("ErrorTextBox").text = Pages.get_all_invalid_instructions()

func update_undo_redo_buttons():
	find_child("UndoButton").disabled = not undo_redo.has_undo()
	find_child("RedoButton").disabled = not undo_redo.has_redo()

func _on_undo_button_pressed() -> void:
	undo_redo.undo()
	update_undo_redo_buttons()

func _on_redo_button_pressed() -> void:
	undo_redo.redo()
	update_undo_redo_buttons()
