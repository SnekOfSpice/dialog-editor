@tool
extends Window

var direct_swap_start := -1

func swap_pages(page_a: int, page_b: int):
	var undo_redo = Pages.editor.undo_redo
	undo_redo.create_action("Move Pages")
	undo_redo.add_do_method(DiisisEditorActions.swap_pages.bind(page_a, page_b))
	undo_redo.add_undo_method(DiisisEditorActions.swap_pages.bind(page_b, page_a))
	undo_redo.commit_action()
	
	fill()


func fill():
	for i in find_child("Items").get_children():
		i.queue_free()
	
	for i in Pages.page_data.keys():
		var item = preload("res://addons/diisis/editor/src/move_page_item.tscn").instantiate()
		find_child("Items").add_child(item)
		item.set_number(i)
		item.connect("move_page", swap_pages)
		item.connect("on_direct_swap", direct_swap)

func direct_swap(page_clicked: int):
	if direct_swap_start == -1:
		direct_swap_start = page_clicked
		return
	
	swap_pages(direct_swap_start, page_clicked)
	direct_swap_start = -1

func _on_about_to_popup() -> void:
	fill()


func _on_close_requested() -> void:
	hide()
