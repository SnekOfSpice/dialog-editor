@tool
extends PopupMenu

const CAPITALIZE_INDEX := 3
const WHITESPACE_INDEX := 4

@export var page := false

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
		var line_content := str(
			"[color=#fd99f9]",
			"a: amber",
			"\nn: narrator\n",
			"[/color]",
			"\nCONTENT",
			"\na: this line will be ingested and inserted into the text box!",
			"\nn: with different speaking parts",
			"\nn: uwu")
		var page_content := str(
			"[color=#fd99f9]",
			"a: amber",
			"\nn: narrator",
			"[/color]",
			"\nEND ACTORS\n",
			"\nCONTENT",
			"\na: this first line will be ingested",
			"\nn: with different speaking parts",
			"\nn: uwu\n",
			"\nCONTENT",
			"\nn: This is a second line",
			"\nh: wow im not defined",
			"\na: uuuuuuuuu",
			"\n\nPAGE\n",
			"\nCONTENT",
			"\nn: a second page",
			"\nn: waow",
		)
		Pages.editor.popup_accept_dialogue(str(
			"At the top, declare the legend of [color=#fd99f9]actors[/color]. Separated by space.\n\n",
			"[b]Example For ", "Pages" if page else "Lines", ":[/b]",
			"\n\n",
			"[bgcolor=#0e0c10]",
			page_content if page else line_content,
			"[/bgcolor]",
		),
		"Ingestion Syntax",
		canvas_transform.get_origin())
