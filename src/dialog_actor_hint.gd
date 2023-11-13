extends Window

signal actor_chosen(actor_name)

func build(actor_names: Array):
	find_child("ItemList").clear()
	for n in actor_names:
		find_child("ItemList").add_item(n)
	
	if actor_names.size() == 0:
		return
	
	find_child("ItemList").call_deferred("grab_focus")
	find_child("ItemList").call_deferred("select", 0)
	selected_index = 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		emit_signal("close_requested")
	if event.is_action_pressed("ui_accept"):
		emit_signal("actor_chosen", find_child("ItemList").get_item_text(selected_index))
		emit_signal("close_requested")

func _on_close_requested() -> void:
	hide()


var selected_index := 0
func _on_item_list_item_selected(index: int) -> void:
	selected_index = index
