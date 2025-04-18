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

func _on_index_pressed(index: int) -> void:
	var target_value:bool
	match index:
		CAPITALIZE_INDEX:
			target_value = not is_capitalize_checked()
		WHITESPACE_INDEX:
			target_value = not is_whitespace_checked()
	for item in get_tree().get_nodes_in_group("diisis_ingest_menu"):
		match index:
			CAPITALIZE_INDEX:
				item.set_capitalize_checked(target_value)
			WHITESPACE_INDEX:
				item.set_whitespace_checked(target_value)
