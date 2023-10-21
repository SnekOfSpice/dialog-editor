extends Control


var _page = preload("res://src/page.tscn")
var current_page: Page

var active_dir := ""

var page_trail := []
var trail_idx := 0

func refresh():
	var cpn = current_page.number
	#Pages.page_data[cpn] = current_page.serialize()
	current_page.deserialize(Pages.page_data.get(cpn))

func _ready() -> void:
	add_empty_page()
	
	Pages.connect("pages_modified", update_controls)
	Pages.editor = self
	update_controls()
	
	set_current_page_changeable(false)
	
	find_child("FDOpen").size = get_window().size * 0.75
	find_child("FDSave").size = get_window().size * 0.75
	find_child("MovePagePopup").size = get_window().size * 0.75
	find_child("FactsPopup").size = get_window().size * 0.75
	

func load_page(number: int, initial_load:=false):
	number = clamp(number, 0, Pages.get_page_count() - 1)
#		push_warning(str("page number ", number, " outside page count"))
#		return
	
	
	# broken, do this later
#	if page_trail.size() > 1 and trail_idx < page_trail.size():
#		if page_trail[trail_idx + 1] != number:
#			# erase remaining trail
#			page_trail = page_trail.slice(0, trail_idx + 1)
#
#		set_trail_idx(page_trail.size() - 1)
	
	for c in $Core/PageContainer.get_children():
		if not c is Page:
			push_warning(str("PageContainer has a child that's not a page: ", c))
			continue
		
		if not initial_load:
			c.save()
		c.queue_free()
	
	prints("loading ", number)
	var page = _page.instantiate()
	$Core/PageContainer.add_child(page)
	page.init(number)
	current_page = page
	page_trail.append(number)
	
	update_controls()
	

func update_controls():
	if not current_page:
		return
	
	find_child("First").disabled = current_page.number <= 0
	find_child("Prev").disabled = current_page.number <= 0
	find_child("Next").disabled = current_page.number >= Pages.get_page_count() - 1
	find_child("Last").disabled = current_page.number >= Pages.get_page_count() - 1
	find_child("PageCountCurrent").text = str(current_page.number)
	find_child("PageCountMax").text = str(Pages.get_page_count() - 1)
	
	set_trail_idx(trail_idx)

func add_empty_page():
	var page_count = Pages.get_page_count()
	Pages.create_page(page_count)
	load_page(page_count)
	

func get_current_page_number() -> int:
	if not current_page:
		return 0
	
	return current_page.number




func _on_first_pressed() -> void:
	load_page(0)


func _on_prev_pressed() -> void:
	if current_page.number > 0:
		load_page(current_page.number - 1)

func _on_next_pressed() -> void:
	if current_page.number < Pages.get_page_count() - 1:
		load_page(current_page.number + 1)


func _on_last_pressed() -> void:
	load_page(Pages.get_page_count() - 1)


func _on_add_last_pressed() -> void:
	add_empty_page()

func _on_delete_current_pressed() -> void:
	if Pages.get_page_count() <= 1:
		push_warning("you cannot delete the last page")
		return
	
	var a = get_current_page_number()
	load_page(a - 1)
	Pages.delete_page(a)
	


func _on_add_after_pressed() -> void:
	var at = get_current_page_number() + 1
	if at >= Pages.get_page_count():
		add_empty_page()
		return
	Pages.insert_page(at)
	
	load_page(at)


func _on_save_button_pressed() -> void:
	if active_dir != "":
		get_node("FDSave").current_dir = active_dir
	find_child("FDSave").popup()
	#find_child("FDSave").size = get_window().size - Vector2i(30, 80)

func _on_open_button_pressed() -> void:
	if active_dir != "":
		get_node("FDSave").current_dir = active_dir
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
		"facts": Pages.facts
	}
	file.store_string(JSON.stringify(data_to_save))
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
	Pages.facts = data.get("facts", [])
	
	load_page(0, true)



func set_current_page_changeable(value:bool):
	find_child("PageCountSpinCounter").visible = value
	find_child("PageCountSpinCounter").max_value = Pages.get_page_count() - 1
	find_child("PageCountSpinCounter").get_line_edit().text = find_child("PageCountCurrent").text
	find_child("PageCountSpinCounter").apply()
	find_child("PageCountCurrent").visible = not value

func set_trail_idx(value: int):
	trail_idx = value
	
	find_child("LastVisited").disabled = trail_idx <= page_trail.size() or page_trail.is_empty()
	find_child("NextVisited").disabled = trail_idx > 0 or page_trail.is_empty()

func _on_change_page_button_pressed() -> void:
	
	
	if find_child("PageCountSpinCounter").visible:
		load_page(find_child("PageCountSpinCounter").value)
	
	set_current_page_changeable(find_child("PageCountCurrent").visible)


func _on_last_visited_pressed() -> void:
	#set_trail_idx(clamp(trail_idx - 1, 0, page_trail.size()))
	if page_trail.size() > 1: load_page(page_trail[trail_idx])


func _on_next_visited_pressed() -> void:
	set_trail_idx(clamp(trail_idx + 1, 0, page_trail.size()))
	if page_trail.size() > 1: load_page(page_trail[trail_idx])


func _on_edit_header_button_pressed() -> void:
	current_page.save()
	load_page(current_page.number)
	$HeaderPopup.popup()


func _on_edit_instruction_button_pressed() -> void:
	current_page.save()
	load_page(current_page.number)
	$InstructionPopup.popup()


func _on_move_pages_button_pressed() -> void:
	current_page.save()
	#load_page(current_page.number)
	$MovePagePopup.popup()


func _on_edit_facts_button_pressed() -> void:
	current_page.save()
	$FactsPopup.popup()
