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


func _on_file_id_pressed(id: int) -> void:
	match id:
		0:
			$FDExport.popup()
		1:
			$FDImport.popup()


func _on_fd_export_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	var data_to_save = []
	
	var container : VBoxContainer = find_child("ItemContainer")
	for item : InstructionEditItem in container.get_children():
		data_to_save.append(item.get_visible_text())
	
	file.store_string(JSON.stringify(data_to_save, "\t"))
	file.close()


func _on_fd_import_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	
	if not file:
		return
	
	var data : Array = JSON.parse_string(file.get_as_text())
	file.close()
	
	Pages.instruction_templates.clear()
	for text in data:
		Pages.add_template_from_string(text)
	fill()


func _on_fd_export_about_to_popup() -> void:
	$FDExport.size = get_window().size


func _on_fd_import_about_to_popup() -> void:
	$FDImport.size = get_window().size
