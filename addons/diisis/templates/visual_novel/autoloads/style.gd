extends Control

const DEFAULT_LABEL_FONT_SIZE := 24
const DEFAULT_RTL_FONT_SIZE := 26
const DEFAULT_BUTTON_FONT_SIZE := 22
var button_to_label_size_difference := DEFAULT_BUTTON_FONT_SIZE - DEFAULT_LABEL_FONT_SIZE

var label_font_index := 0
const LABEL_FONTS := [
	"res://game/visuals/theme/fonts/justabit.ttf",
	"res://game/visuals/theme/fonts/open-dyslexic/OpenDyslexic-Regular.otf"
]

var rich_text_label_font_index := 0
const RICH_TEXT_LABEL_FONTS := [
	{
		"normal_font" : "res://game/visuals/theme/fonts/HelvetiPixel.ttf",
		"bold_font" : "res://game/visuals/theme/fonts/VSansSerif8bold.ttf",
		"bold_italics_font" : "res://game/visuals/theme/fonts/KHMenuItalic.ttf",
		"italics_font" : "res://game/visuals/theme/fonts/MinecraftItalic.ttf",
	},
	{
		"normal_font" : "res://game/visuals/theme/fonts/open-dyslexic/OpenDyslexic-Regular.otf",
		"bold_font" : "res://game/visuals/theme/fonts/open-dyslexic/OpenDyslexic-Bold.otf",
		"bold_italics_font" : "res://game/visuals/theme/fonts/open-dyslexic/OpenDyslexic-BoldItalic.otf",
		"italics_font" : "res://game/visuals/theme/fonts/open-dyslexic/OpenDyslexic-Italic.otf",
	}
]

var rich_text_label_font_size_index := 0
const RICH_TEXT_LABEL_FONT_SIZE_OFFSETS := [
	{
		"bold_font" : 0,
		"bold_italics_font" : -10,
		"italics_font" : 1,
	},
	{},
]

func adjust_font_size_tags(text:String) -> String:
	var tag_positions := []
	var index := text.find("[font_size=")
	while index != -1:
		tag_positions.append(index)
		if index >= text.length() - 1:
			break
		index = text.find("[font_size=", index + 1)
	
	var tag_offset := 0
	for tag_start : int in tag_positions:
		var tag_end := text.find("]", tag_start + tag_offset)
		if tag_end == -1:
			break
		var tag_length := tag_end - tag_start
		var tag := text.substr(tag_start + tag_offset, tag_length - tag_offset)
		var font_size := float(tag.split("=")[1])
		var ratio := get_rich_text_label_normal_font_size() / float(DEFAULT_RTL_FONT_SIZE)
		var new_tag := "[font_size=%s" % int(ratio * font_size)
		
		text = text.erase(tag_start + tag_offset, tag_length - tag_offset)
		text = text.insert(tag_start + tag_offset, new_tag)
		
		tag_offset += new_tag.length() - tag_length
	return text

func set_label_font(idx:int):
	label_font_index = idx
	var font = load(LABEL_FONTS[idx])
	theme.set_font("font", "Label", font)
	theme.set_font("font", "Button", font)
	theme.set_font("title_font", "PopupMenu", font)
	theme.set_font("font", "PopupMenu", font)
	_save_font_prefs()


func set_rich_text_label_font(idx:int):
	rich_text_label_font_index = idx
	var family : Dictionary = RICH_TEXT_LABEL_FONTS.get(idx)
	var normal_font = load(family.get("normal_font"))
	var bold_font = load(family.get("bold_font"))
	var bold_italics_font = load(family.get("bold_italics_font"))
	var italics_font = load(family.get("italics_font"))

	theme.set_font("normal_font", "RichTextLabel", normal_font)
	theme.set_font("bold_font", "RichTextLabel", bold_font)
	theme.set_font("bold_italics_font", "RichTextLabel", bold_italics_font)
	theme.set_font("italics_font", "RichTextLabel", italics_font)
	_save_font_prefs()

func set_label_font_size(value:int):
	theme.set_font_size("font_size", "Label", value)
	theme.set_font_size("font_size", "PopupMenu", value)
	theme.set_font_size("title_font_size", "PopupMenu", value)
	theme.set_font_size("font_size", "Button", value + button_to_label_size_difference)
	_save_font_prefs()

func set_rich_text_label_font_size(font_size:int):
	theme.set_font_size("normal_font_size", "RichTextLabel", font_size)
	theme.set_font_size("bold_font_size", "RichTextLabel", font_size + RICH_TEXT_LABEL_FONT_SIZE_OFFSETS.get(rich_text_label_font_index).get("bold_font", 0))
	theme.set_font_size("bold_italics_font_size", "RichTextLabel", font_size + RICH_TEXT_LABEL_FONT_SIZE_OFFSETS.get(rich_text_label_font_index).get("bold_italics_font", 0))
	theme.set_font_size("italics_font_size", "RichTextLabel", font_size + RICH_TEXT_LABEL_FONT_SIZE_OFFSETS.get(rich_text_label_font_index).get("italics_font", 0))
	_save_font_prefs()

func get_rich_text_label_normal_font_size() -> float:
	return theme.get_font_size("normal_font_size", "RichTextLabel")

func _save_font_prefs():
	var prefs := {}
	prefs["label_font"] = label_font_index
	prefs["label_font_size"] = theme.get_font_size("font_size", "Label")
	prefs["rich_text_label_font"] = rich_text_label_font_index
	prefs["rich_text_label_font_size"] = theme.get_font_size("normal_font_size", "RichTextLabel")
	Options.store_font_prefs(prefs)
