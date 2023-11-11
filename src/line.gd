extends Control
class_name Line




var line_type := Data.LineType.Text
var is_head_editable := false

signal move_line (child, dir)
signal line_deleted

func _ready() -> void:
	set_line_type(Data.of("editor.selected_line_type"))
	set_head_editable(true)
	find_child("Facts").visible = false
	find_child("Conditionals").visible = false
	set_non_meta_parts_visible(true)
	update()

func set_line_type(value: int):
	line_type = value
	match line_type:
		Data.LineType.Text:
			pass
	
	find_child("TextContent").visible = line_type == Data.LineType.Text
	find_child("ChoiceContainer").visible = line_type == Data.LineType.Choice
	find_child("InstructionContainer").visible = line_type == Data.LineType.Instruction

func set_head_editable(value: bool):
	is_head_editable = value
	find_child("Header").visible = is_head_editable
	find_child("HeaderShort").visible = not is_head_editable
	find_child("HeaderShort").text = find_child("Header").short_form()
	
	find_child("HeadVisibilityToggle").button_pressed = is_head_editable


func serialize() -> Dictionary:
	var data = {}
	
	data["line_type"] = line_type
	data["header"] = find_child("Header").serialize()
	data["facts"] = find_child("Facts").serialize()
	data["conditionals"] = find_child("Conditionals").serialize()
	data["meta.visible"] = find_child("VisibleToggle").button_pressed
	data["meta.is_head_editable"] = is_head_editable
	data["meta.line_index"] = get_index()
	
	# content match
	match line_type:
		Data.LineType.Text:
			data["content"] = find_child("TextContent").serialize()
		Data.LineType.Choice:
			data["content"] = find_child("ChoiceContainer").serialize()
		Data.LineType.Instruction:
			data["content"] = find_child("InstructionContainer").serialize()
	
	return data

func deserialize(data: Dictionary):
	# line type
	set_line_type(data.get("line_type"))
	
	# header
	find_child("Header").deserialize(data.get("header"))
	find_child("Facts").deserialize(data.get("facts", {}))
	find_child("Conditionals").deserialize(data.get("conditionals", {}))
	
	# content (based on line type)
	match line_type:
		Data.LineType.Text:
			find_child("TextContent").deserialize(data.get("content"))
		Data.LineType.Choice:
			find_child("ChoiceContainer").deserialize(data.get("content"))
		Data.LineType.Instruction:
			find_child("InstructionContainer").deserialize(data.get("content"))
	
	set_non_meta_parts_visible(data.get("meta.visible", data.get("visible", true)))
	set_head_editable(data.get("meta.is_head_editable", false))
	
	
func _on_head_visibility_toggle_toggled(button_pressed: bool) -> void:
	set_head_editable(button_pressed)


func _on_delete_pressed() -> void:
	# I'm not 100% on this
	# but I think since page serialization steps over every child, when this doesn't exist anymore, it'll just won't be part of that serialization anymore
	emit_signal("line_deleted")
	queue_free()

func move(dir: int):
	emit_signal("move_line", self, dir)

func update():
	find_child("IndexLabel").text = str(get_index())
	set_head_editable(is_head_editable)

func _on_move_up_pressed() -> void:
	move(-1)


func _on_move_down_pressed() -> void:
	move(1)





func _on_facts_visibility_toggle_toggled(button_pressed: bool) -> void:
	find_child("Facts").visible = button_pressed


func _on_conditionals_visibility_toggle_toggled(button_pressed: bool) -> void:
	find_child("Conditionals").visible = button_pressed

func getNonMetaParts() -> Array:
	var parts := []
	for control in find_child("Controls").get_children():
		if control.name != "MetaControls" and control.name != "DeleteContainer":
			parts.append(control)
	
	parts.append(find_child("Content"))
	
	return parts


func set_non_meta_parts_visible(value: bool):
	find_child("VisibleToggle").button_pressed = value
	for p in getNonMetaParts():
		p.visible = value

func _on_lock_toggle_toggled(button_pressed: bool) -> void:
	pass # Replace with function body.


func _on_visible_toggle_toggled(button_pressed: bool) -> void:
	set_non_meta_parts_visible(button_pressed)
