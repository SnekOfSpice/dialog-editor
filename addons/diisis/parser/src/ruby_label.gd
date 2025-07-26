extends RichTextLabel
class_name RubyLabel

var start_index : int
var end_index : int

func _ready() -> void:
	visible_characters = 0

static func make(start_index: int, end_index: int, label_text:String) -> RubyLabel:
	var label = preload("res://addons/diisis/parser/src/ruby_label.tscn").instantiate()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.start_index = start_index
	label.end_index = end_index
	label.text = label_text
	label.custom_minimum_size = label.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label

func handle_parent_visible_characters(index:int):
	if index == -1:
		index = end_index
	visible_ratio = clamp(float(index - start_index) / float(end_index - start_index), 0, 1)


func serialize() -> Dictionary:
	return {
		"start_index" : start_index,
		"end_index" : end_index,
		"position" : position,
		"text" : text,
		"visible_ratio" : visible_ratio,
	}

func deserialize(data:Dictionary):
	for property : String in data.keys():
		call_deferred_thread_group("set", property, data.get(property))
