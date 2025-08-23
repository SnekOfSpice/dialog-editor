@tool
extends Window

signal go_to(page_number:int)
var direct_swap_start := -1

func filter_items(search:String):
	if search.is_empty():
		for i in find_child("Items").get_children():
			i.visible = true
	else:
		for i in find_child("Items").get_children():
			i.visible = Pages.get_page_key(i.number).containsn(search)

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
		item.connect("go_to", on_item_go_to)
		item.init()
	
	find_child("SearchLineEdit").text = ""
	find_child("SearchLineEdit").grab_focus()
	filter_items("")

func direct_swap(page_clicked: int):
	if direct_swap_start == -1:
		direct_swap_start = page_clicked
		return
	
	swap_pages(direct_swap_start, page_clicked)
	direct_swap_start = -1

func on_item_go_to(number:int):
	emit_signal("go_to", number)
	hide()

func _on_about_to_popup() -> void:
	fill()


func _on_close_requested() -> void:
	hide()


func _on_search_line_edit_text_changed(new_text: String) -> void:
	filter_items(new_text)


func _on_reset_address_mode_pressed() -> void:	
	$ResetAddressModePopup.popup()
	$ResetAddressModePopup.grab_focus()
	$ResetAddressModePopup.position = size - $ResetAddressModePopup.size
	# idk shit's fucked lol
	size.x += 1
	size.x -= 1


func _on_reset_address_mode_popup_change_to_mode(mode: AddressModeButton.Mode) -> void:
	for item in find_child("Items").get_children():
		item.set_address_mode(mode)


func _on_v_id_pressed(id: int) -> void:
	match id:
		0:
			Pages.linearize_pages()
			fill()
