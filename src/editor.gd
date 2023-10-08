extends Control


var _page = preload("res://src/page.tscn")
var current_page: Page

var active_dir := ""

func _ready() -> void:
	add_empty_page()
	
	Pages.connect("pages_modified", update_controls)
	update_controls()

func load_page(number: int):
	if number < 0 or number > Pages.get_page_count():
		push_warning(str("page number ", number, " outside page count"))
		return
	
	for c in $Core/PageContainer.get_children():
		if not c is Page:
			push_warning(str("PageContainer has a child that's not a page: ", c))
			continue
		
		c.save()
		c.queue_free()
	
	prints("loading ", number)
	var page = _page.instantiate()
	get_node("Core/PageContainer").add_child(page)
	page.init(number)
	current_page = page
	
	update_controls()
	

func update_controls():
	if not current_page:
		return
	
	find_child("First").disabled = current_page.number <= 0
	find_child("Prev").disabled = current_page.number <= 0
	find_child("Next").disabled = current_page.number >= Pages.get_page_count() - 1
	find_child("Last").disabled = current_page.number >= Pages.get_page_count() - 1
	get_node("Core/PageControl/PageNav/PageCount/Current").text = str(current_page.number)
	get_node("Core/PageControl/PageNav/PageCount/Count").text = str(Pages.get_page_count() - 1)

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
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(Pages.page_data))
	file.close()
	active_dir = path


func _on_fd_open_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	
	active_dir = path
	
	# all keys are now strings instead of ints
	var int_data := {}
	for i in data.size():
		int_data[int(i)] = data.get(str(i))
	Pages.page_data = int_data
	load_page(0)



