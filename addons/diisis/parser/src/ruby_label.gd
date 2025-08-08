extends PanelContainer
class_name RubyLabel

var start_index : int
var end_index : int
var segment_index := 0



func _ready() -> void:
	%RubyLabel.visible_characters = 0

static func make(start_index: int, end_index: int, label_text:String) -> RubyLabel:
	var label := preload("res://addons/diisis/parser/src/ruby_label.tscn").instantiate()
	var llabel : RichTextLabel = label.find_child("RubyLabel")
	llabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.start_index = start_index
	label.end_index = end_index
	llabel.text = label_text
	llabel.custom_minimum_size = llabel.size
	llabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label

func handle_parent_visible_characters(index:int):
	if index == -1:
		index = end_index
	var ratio : float = clamp(float(index - start_index) / float(end_index - start_index), 0, 1)
	if stretch:
		custom_minimum_size.x = %RubyLabel.custom_minimum_size.x * ratio
	else:
		%RubyLabel.visible_ratio = ratio

## only needed by past lines
func set_visible_ratio(ratio:float):
	%RubyLabel.visible_ratio = ratio

func serialize() -> Dictionary:
	return {
		"start_index" : start_index,
		"end_index" : end_index,
		"position" : position,
		"text" : %RubyLabel.text,
		"visible_ratio" : %RubyLabel.visible_ratio,
	}

func set_font(font:Font):
	%RubyLabel.add_theme_font_override("normal_font", font)
func set_font_size(font_size:int):
	%RubyLabel.add_theme_font_size_override("normal_font_size", font_size)

func deserialize(data:Dictionary):
	for property : String in data.keys():
		call_deferred_thread_group("set", property, data.get(property))

var stretch := false
func set_stretch(value:bool):
	stretch = value
	clip_contents = stretch
	if stretch:
		%RubyLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
		%RubyLabel.visible_ratio = 1
	else:
		%RubyLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT



func get_text() -> String:
	return %RubyLabel.text
func get_size() -> Vector2:
	return %RubyLabel.size

func set_minimum_width(width:int):
	%RubyLabel.custom_minimum_size.x = width
func get_minimum_width() -> int:
	return %RubyLabel.custom_minimum_size.x

func set_height(height:int):
	custom_minimum_size.y = height
