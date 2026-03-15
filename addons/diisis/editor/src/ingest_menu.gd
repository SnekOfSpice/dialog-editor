@tool
extends PopupMenu
class_name DiisisIngestMenu

# while we use ID in the signal, because of how tooltip initialization works
# we actualy need the index here
const CAPITALIZE_INDEX := 3
const WHITESPACE_INDEX := 4
const PUNCTUATION_INDEX := 5

@export var page := false

signal ingest_from_clipboard()
signal ingest_from_file()

func init():
	set_item_tooltip(CAPITALIZE_INDEX, Pages.TOOLTIP_CAPITALIZE)
	set_item_tooltip(WHITESPACE_INDEX, Pages.TOOLTIP_NEATEN_WHITESPACE)
	set_item_tooltip(PUNCTUATION_INDEX, Pages.TOOLTIP_FIX_PUNCTUATION)

func is_capitalize_checked() -> bool:
	return is_item_checked(CAPITALIZE_INDEX)

func is_whitespace_checked() -> bool:
	return is_item_checked(WHITESPACE_INDEX)

func is_punctuation_checked() -> bool:
	return is_item_checked(PUNCTUATION_INDEX)

func set_capitalize_checked(value: bool) -> void:
	set_item_checked(CAPITALIZE_INDEX, value)

func set_whitespace_checked(value: bool) -> void:
	set_item_checked(WHITESPACE_INDEX, value)

func set_punctuation_checked(value: bool) -> void:
	set_item_checked(PUNCTUATION_INDEX, value)

# used by file ingestion to figure out how to handle the text
func build_payload() -> Dictionary:
	return {
		"capitalize" : is_capitalize_checked(),
		"neaten_whitespace" : is_whitespace_checked(),
		"fix_punctuation" : is_punctuation_checked(),
	}

func _on_index_pressed(index: int) -> void:
	if index in [0, 1]:
		if not Pages.use_dialog_syntax:
			Pages.editor.notify("Text ingestion only makes sense with dialog syntax enabled.\nEnable it in File>Preferences>Dialog and try again.")
			return
		if index == 1:
			emit_signal("ingest_from_file")
		elif index == 0:
			emit_signal("ingest_from_clipboard")
	var target_value:bool
	match index:
		CAPITALIZE_INDEX:
			target_value = not is_capitalize_checked()
			set_capitalize_checked(target_value)
			Pages.ingest_is_capitalize_checked = target_value
		WHITESPACE_INDEX:
			target_value = not is_whitespace_checked()
			set_whitespace_checked(target_value)
			Pages.ingest_is_whitespace_checked = target_value
		PUNCTUATION_INDEX:
			target_value = not is_punctuation_checked()
			set_punctuation_checked(target_value)
			Pages.ingest_is_punctuation_checked = target_value
	if index == 7:
		Pages.editor.open_window_by_string("IngestionActorSetupWindow")
	if index == 8:
		popup_ingestion_help(page, canvas_transform.get_origin())

static func popup_ingestion_help(p_page:bool, at := Vector2.ZERO) -> RichTextAcceptDialog:
	var line_content := str(
		"[color=#fd99f9]",
		"a: amber",
		"\nn: narrator\n",
		"[/color]",
		"\nLINE",
		"\na: this line will be ingested and inserted into the text box!",
		"\nn: with different speaking parts",
		"\nn: uwu")
	var page_content := str(
		"[color=#fd99f9]",
		"a: amber",
		"\nn: narrator",
		"\nEND ACTORS[/color]\n",
		"\nLINE",
		"\na: this first line will be ingested",
		"\nn: with different speaking parts",
		"\nn: uwu\n",
		"\nLINE",
		"\nn: This is a second line",
		"\nh: wow im not defined",
		"\na: uuuuuuuuu",
		"\n\nPAGE\n",
		"\nLINE",
		"\nn: a second page",
		"\nn: waow",
	)
	return Pages.editor.popup_accept_dialogue(str(
		"At the top, declare the legend of [color=#fd99f9]actors[/color]. Separated by space. (If you omit the actors, [url=open-IngestionActorSetupWindow]Utility > Ingestion Actors[/url] will be used.)\n",
		"Colors are for emphasis.\n\n",
		"[b]Example For ", "Pages" if p_page else "Lines", ":[/b]",
		"\n\n",
		"[code][font_size=12]",
		page_content if p_page else line_content,
		"[/font_size][/code]",
	),
	"Ingestion Help",
	at)


func _on_visibility_changed() -> void:
	if visible:
		set_capitalize_checked(Pages.ingest_is_capitalize_checked)
		set_whitespace_checked(Pages.ingest_is_whitespace_checked)
		set_punctuation_checked(Pages.ingest_is_punctuation_checked)
