@tool
extends Control

signal request_close()

func fill():
	for c : InstructionEditItem in find_child("ItemContainer").get_children():
		c.queue_free()
	for template in Pages.instruction_templates:
		add_item(template)

func add_item(template_name:String):
	var item = load("res://addons/diisis/editor/src/instruction_edit_item.tscn").instantiate()
	find_child("ItemContainer").add_child(item)
	item.set_template(template_name)
	item.set_editing(template_name == "")

func get_full_templates():
	pass

func _on_search_filter_text_changed(new_text: String) -> void:
	for c : InstructionEditItem in find_child("ItemContainer").get_children():
		c.visible = c.get_raw_entered_text().contains(new_text) or find_child("SearchFilter").text.is_empty()


func _on_clear_search_button_pressed() -> void:
	find_child("SearchFilter").text = ""
	_on_search_filter_text_changed("")


func _on_add_button_pressed() -> void:
	add_item("")


func _on_save_close_button_pressed() -> void:
	emit_signal("request_close")
