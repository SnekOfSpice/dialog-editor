extends Control


var _page = preload("res://src/page.tscn")


func load_page(number: int):
	if number < 0 or number > Pages.get_page_count():
		return
	



func add_empty_page():
	var p = find_child("Page")
	if not p:
		return
	p.queue_free()
	
	var page = _page.instantiate()
	page.number = Pages.get_page_count()
	


func _on_add_pressed() -> void:
	add_empty_page()
