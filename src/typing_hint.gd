extends Window

signal item_chosen(item_name)

var item_descriptions := {}
var selected_index := 0

func build(items: Array, hints := {}):
	find_child("ItemList").clear()
	for n in items:
		find_child("ItemList").add_item(n)
	
	if items.size() == 0:
		return
	
	item_descriptions = hints
	find_child("ItemList").call_deferred("grab_focus")
	find_child("ItemList").call_deferred("select", 0)
	selected_index = 0
	
	find_child("HintText").text = item_descriptions.get(find_child("ItemList").get_item_text(selected_index), "")
	find_child("HintTextContainer").visible = not find_child("HintText").text.is_empty()
	if find_child("HintText").text.is_empty():
		size.x = 485
	else:
		size.x = 485 * 2
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		emit_signal("close_requested")
	if event.is_action_pressed("ui_accept"):
		emit_signal("item_chosen", find_child("ItemList").get_item_text(selected_index))
		emit_signal("close_requested")

func _on_close_requested() -> void:
	hide()


func _on_item_list_item_selected(index: int) -> void:
	selected_index = index
	find_child("HintText").text = item_descriptions.get(find_child("ItemList").get_item_text(selected_index), "")
	find_child("HintTextContainer").visible = not find_child("HintText").text.is_empty()
	if find_child("HintText").text.is_empty():
		size.x = 485
	else:
		size.x = 485 * 2
