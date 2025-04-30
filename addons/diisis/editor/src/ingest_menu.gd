@tool
extends PopupMenu

const CAPITALIZE_INDEX := 3
const WHITESPACE_INDEX := 4

func is_capitalize_checked() -> bool:
	return is_item_checked(CAPITALIZE_INDEX)

func is_whitespace_checked() -> bool:
	return is_item_checked(WHITESPACE_INDEX)

func set_capitalize_checked(value: bool) -> void:
	set_item_checked(CAPITALIZE_INDEX, value)

func set_whitespace_checked(value: bool) -> void:
	set_item_checked(WHITESPACE_INDEX, value)

# used by file ingestion to figure out how to handle the text
func build_payload() -> Dictionary:
	return {
		"capitalize" : is_capitalize_checked(),
		"neaten_whitespace" : is_whitespace_checked()
	}

func _on_id_pressed(id: int) -> void:
	var target_value:bool
	match id:
		CAPITALIZE_INDEX:
			target_value = not is_capitalize_checked()
		WHITESPACE_INDEX:
			target_value = not is_whitespace_checked()
	for item in get_tree().get_nodes_in_group("diisis_ingest_menu"):
		match id:
			CAPITALIZE_INDEX:
				item.set_capitalize_checked(target_value)
			WHITESPACE_INDEX:
				item.set_whitespace_checked(target_value)
	if id == 6:
		Pages.editor.popup_confirm_dialogue(str(
			"For Lines -------------",
			"
			a: amber
			n: narrator

			CONTENT
			a: this line will be ingested and inserted into the text box!
			n: uwu
			n: uwuwuwu",
			"\n\nFor Pages --------------",
			"
			a: amber
			n: narrator
			END ACTORS

			CONTENT
			a: this first line will be ingested
			n: uwu
			n: uwuwuwu

			CONTENT
			n: This is a second line
			h: wow im not defined
			a: uuuuuuuuu

			PAGE

			CONTENT
			n: a second page
			n: waow"
		),
		"Ingestion Syntax",
		canvas_transform.get_origin())
