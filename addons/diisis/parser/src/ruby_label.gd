extends RichTextLabel
class_name RubyLabel

var start_index : int
var end_index : int

#func _ready() -> void:
	#visible_characters = 0

static func make(start_index: int, end_index: int, label_text:String) -> RubyLabel:
	var label = preload("res://addons/diisis/parser/src/ruby_label.tscn").instantiate()
	label.start_index = start_index
	label.end_index = end_index
	label.text = label_text
	return label

func set_text(new_text:String) -> void:
	text = new_text
	position -= size * 0.5

func handle_parent_visible_characters(index:int):
	visible_ratio = clamp((index - start_index) / end_index, 0, 1)
