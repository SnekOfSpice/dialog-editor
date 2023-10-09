extends Control
class_name Line




var line_type := Data.LineType.Text

func _ready() -> void:
	set_line_type(Data.of("editor.selected_line_type"))
	set_head_editable(false)

func set_line_type(value: int):
	line_type = value
	match line_type:
		Data.LineType.Text:
			pass
	
	find_child("TextContent").visible = line_type == Data.LineType.Text

func set_head_editable(value: bool):
	find_child("Header").visible = value


func serialize() -> Dictionary:
	var data = {}
	
	data["line_type"] = line_type
	data["header"] = find_child("Header").serialize()
	
	# content match
	data["content"] = find_child("TextContent").text
	
	return data

func deserialize(data: Dictionary):
	# line type
	set_line_type(data.get("line_type"))
	
	# header
	find_child("Header").deserialize(data.get("header"))
	
	# content (based on line type)
	match line_type:
		Data.LineType.Text:
			find_child("TextContent").text = data.get("content")
		Data.LineType.Choice:
			pass
		Data.LineType.Instruction:
			pass
	
	
func _on_head_visibility_toggle_toggled(button_pressed: bool) -> void:
	set_head_editable(button_pressed)


func _on_delete_pressed() -> void:
	# I'm not 100% on this
	# but I think since page serialization steps over every child, when this doesn't exist anymore, it'll just won't be part of that serialization anymore
	queue_free()
