@tool
extends Control

var all_ids : Array

signal close()

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
	find_child("ContentLabel").text = Pages.get_text(id)

func set_already_exists(value:bool, colliding_id:=""):
	find_child("AlreadyExistsLabel").modulate.a = 1 if value else 0
	find_child("SaveButton").disabled = value
	
	if not colliding_id.is_empty():
		var data := Pages.get_text_id_address_and_type(colliding_id)
		var address = data[0]
		find_child("AlreadyExistsLabel").text = str(
			"ID \"",
			colliding_id
			, "\" already exists at Address [url=goto-", address, "]", address, "[/url]"
			
		)

func _on_content_label_item_rect_changed() -> void:
	DiisisEditorUtil.limit_scroll_container_height(
		find_child("ScrollContainer"),
		0.1,
	)


func _on_new_id_line_edit_text_changed(new_text: String) -> void:
	var exists : bool = Pages.does_text_id_exist(new_text) and new_text != find_child("IDLabel").text
	var id : String = new_text if exists else ""
	set_already_exists(exists, id)
	if exists:
		var data := Pages.get_text_id_address_and_type(new_text)
		find_child("TypeLabel").text = data[1]
		find_child("AddressLabel").text = str("[url=goto-", data[0], "]", data[0], "[/url]")


func _on_save_button_pressed() -> void:
	emit_signal("close")
	DiisisEditorActions.change_text_id(find_child("IDLabel").text, find_child("NewIDLineEdit").text)


func _on_discard_button_pressed() -> void:
	emit_signal("close")


func goto(meta:Variant):
	emit_signal("close")
	Pages.editor.goto_with_meta(meta)
