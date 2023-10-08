extends Control


var _page = preload("res://src/page.tscn")
var current_page: Page

func _ready() -> void:
	add_empty_page()

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
	


func _on_add_pressed() -> void:
	add_empty_page()


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
