@tool
extends Control

var all_ids : Array

func fill(id:String):
	find_child("IDLabel").text = id
	set_info(id)
	find_child("NewIDLineEdit").text = ""
	all_ids = Pages.text_data.keys()
	set_already_exists(false)

func set_info(id:String):
	var data := Pages.get_text_id_address_and_type(id)
	find_child("TypeLabel").text = data[1]
	find_child("AddressLabel").text = str("[url=goto-", data[0], "]", data[0], "[/url]")

func set_already_exists(value:bool):
	find_child("AlreadyExistsLabel").modulate.a = 1 if value else 0
	find_child("SaveButton").disabled = value

func _on_content_label_item_rect_changed() -> void:
	DiisisEditorUtil.limit_scroll_container_height(
		find_child("ScrollContainer"),
		0.25,
	)


func _on_new_id_line_edit_text_changed(new_text: String) -> void:
	var exists := Pages.does_text_id_exist(new_text)
	set_already_exists(exists)
	if exists:
		var data := Pages.get_text_id_address_and_type(new_text)
		find_child("TypeLabel").text = data[1]
		find_child("AddressLabel").text = str("[url=goto-", data[0], "]", data[0], "[/url]")


func _on_save_button_pressed() -> void:
	pass # Replace with function body.


func _on_discard_button_pressed() -> void:
	hide()
