@tool
extends Control
class_name Line

var line_type := DIISIS.LineType.Text
var is_head_editable := false
var indent_level := 0

signal move_line (child, dir)
signal insert_line (at)
signal move_to (child, idx)
signal delete_line

func init() -> void:
	find_child("Header").init()
	find_child("Conditionals").init()
	find_child("Facts").init()
	find_child("TextContent").init()
	find_child("InstructionContainer").init()
	set_line_type(Pages.editor.get_selected_line_type())
	await get_tree().process_frame
	set_head_editable(true)
	set_non_meta_parts_visible(true)

func set_page_view(view:DiisisEditor.PageView):
	var move_controls : Control = find_child("MoveControlsContainer")
	var move_controls_buttons : GridContainer = move_controls.find_child("MoveControlsButtonContainer")
	move_controls.visible = view != DiisisEditor.PageView.Minimal
	find_child("HeadVisibilityToggle").visible = view != DiisisEditor.PageView.Minimal
	if view == DiisisEditor.PageView.Full:
		move_controls_buttons.columns = 2
		move_controls.find_child("Spacer").visible = true
		move_controls_buttons.move_child(move_controls_buttons.find_child("InsertLineAbove"), 1)
	else:
		move_controls_buttons.columns = 5
		move_controls.find_child("Spacer").visible = false
		move_controls_buttons.move_child(move_controls_buttons.find_child("InsertLineAbove"), 0)

func set_indent_level(to:int):
	indent_level = to
	find_child("IndentContainer").custom_minimum_size.x = 60 * indent_level
	if line_type == DIISIS.LineType.Folder:# and indent_level > 0:
		find_child("IndentContainer").custom_minimum_size.x -= 60

func change_indent_level(by:int):
	set_indent_level(indent_level + by)

func get_folder_contents_visible() -> bool:
	if not line_type == DIISIS.LineType.Folder:
		push_warning(str("Trying to get folder visibility of non-folder line ", get_index()))
	return find_child("FolderContainer").get_folder_contents_visible()

## Returns the distance that the folder covers.
func get_folder_range_i() -> int:
	var range = get_folder_range_v()
	return range.y - range.x

## Returns the start (x) and end (y) indices of the folder.
func get_folder_range_v() -> Vector2:
	if not line_type == DIISIS.LineType.Folder:
		push_warning(str("Trying to get folder range of non-folder line ", get_index()))
		return Vector2.ZERO
	return Vector2(get_index(), get_index() + find_child("FolderContainer").get_included_count())

func change_folder_range(by:int):
	if not line_type == DIISIS.LineType.Folder:
		push_warning(str("Trying to change folder range of non-folder line ", get_index()))
		return
	find_child("FolderContainer").change_folder_range(by)

func set_line_move_controls_visible(value:bool):
	if value:
		find_child("MoveToIndexControls").modulate.a = 1.0
		find_child("MoveToIndexButton").mouse_filter = MOUSE_FILTER_STOP
		find_child("MoveToIndexSpinBox").mouse_filter = MOUSE_FILTER_STOP
	else:
		find_child("MoveToIndexControls").modulate.a = 0.0
		find_child("MoveToIndexButton").mouse_filter = MOUSE_FILTER_IGNORE
		find_child("MoveToIndexSpinBox").mouse_filter = MOUSE_FILTER_IGNORE

func set_line_type(value: int):
	line_type = value
	set_line_move_controls_visible(line_type != DIISIS.LineType.Folder)
	
	find_child("TextContent").visible = line_type == DIISIS.LineType.Text
	find_child("ChoiceContainer").visible = line_type == DIISIS.LineType.Choice
	find_child("InstructionContainer").visible = line_type == DIISIS.LineType.Instruction
	find_child("FolderContainer").visible = line_type == DIISIS.LineType.Folder
	
	if line_type == DIISIS.LineType.Folder:
		find_child("DeleteButton").tooltip_text = "Click to delete folder.\nShift + Click to delete folder + contents."

func move_choice_item_by_index(at_index:int, direction:int):
	if line_type != DIISIS.LineType.Choice:
		push_warning("trying to move choice item of nonchoice line")
		return
	find_child("ChoiceContainer").move_choice_item_by_index(at_index, direction)

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
	#data["meta.visible"] = find_child("VisibleToggle").button_pressed
	data["meta.is_head_editable"] = is_head_editable
	data["meta.line_index"] = get_index()
	data["meta.facts_visible"] = find_child("FactsVisibilityToggle").button_pressed
	data["meta.conditionals_visible"] = find_child("ConditionalsVisibilityToggle").button_pressed
	data["meta.indent_level"] = indent_level
	data["meta.selector"] = find_child("AddressSelectActionContainer").serialize()
	data["address"] = DiisisEditorUtil.get_address(self, DiisisEditorUtil.AddressDepth.Line)
	
	# content match
	match line_type:
		DIISIS.LineType.Text:
			data["content"] = find_child("TextContent").serialize()
		DIISIS.LineType.Choice:
			data["content"] = find_child("ChoiceContainer").serialize()
		DIISIS.LineType.Instruction:
			data["content"] = find_child("InstructionContainer").serialize()
		DIISIS.LineType.Folder:
			data["content"] = find_child("FolderContainer").serialize()
	
	return data

func deserialize(data: Dictionary):
	# line type
	set_line_type(data.get("line_type"))
	find_child("AddressSelectActionContainer").deserialize(data.get("meta.selector", {}))
	
	# header
	find_child("FactsVisibilityToggle").button_pressed = data.get("meta.facts_visible", false)
	find_child("ConditionalsVisibilityToggle").button_pressed = data.get("meta.conditionals_visible", false)
	
	find_child("Header").deserialize(data.get("header"))
	find_child("Facts").deserialize(data.get("facts", {}))
	find_child("Conditionals").deserialize(data.get("conditionals", {}))
	
	# content (based on line type)
	match line_type:
		DIISIS.LineType.Text:
			if data.get("content") is String:
				var compat_data = {}
				compat_data["content"] = data.get("content")
				find_child("TextContent").deserialize(compat_data)
			else:
				find_child("TextContent").deserialize(data.get("content"))
		DIISIS.LineType.Choice:
			find_child("ChoiceContainer").deserialize(data.get("content"))
		DIISIS.LineType.Instruction:
			find_child("InstructionContainer").deserialize(data.get("content"))
		DIISIS.LineType.Folder:
			find_child("FolderContainer").deserialize(data.get("content"))
			set_indent_level(data.get("meta.indent_level", 0))
	
	#set_non_meta_parts_visible(data.get("meta.visible", data.get("visible", true)))
	set_head_editable(data.get("meta.is_head_editable", false))

func _on_head_visibility_toggle_toggled(button_pressed: bool) -> void:
	set_head_editable(button_pressed)

func set_selected(value:bool):
	find_child("AddressSelectActionContainer").set_selected(value)

func _on_delete_pressed() -> void:
	request_delete()

func request_delete():
	emit_signal("delete_line", get_index())

func move(dir: int):
	emit_signal("move_line", self, dir)

func get_next_index() -> int:
	if get_index() == get_parent().get_child_count() - 1:
		return get_index()
	if line_type == DIISIS.LineType.Folder:
		return get_index() + get_folder_range_i() + 1
	return get_index() + 1

func update():
	var indent := ""
	for i in range(1, indent_level + 1):
		indent += ">"
	find_child("IndexLabel").text = str(get_index(), indent)
	set_head_editable(is_head_editable)
	find_child("MoveToIndexSpinBox").max_value = get_parent().get_child_count() - 1
	if line_type == DIISIS.LineType.Choice:
		find_child("ChoiceContainer").update()
	elif line_type == DIISIS.LineType.Text:
		find_child("TextContent").update()

func update_folder(max_folder_range):
	if line_type == DIISIS.LineType.Folder:
		find_child("FolderContainer").update(get_index(), max_folder_range)

func add_fact(fact_name: String, fact_value: bool):
	var facts = $PanelContainer/HBoxContainer/PanelContainer/VBoxContainer/Content/Facts
	facts.add_fact(fact_name, fact_value)

func add_conditional(fact_name: String, fact_value: bool):
	var facts = $PanelContainer/HBoxContainer/PanelContainer/VBoxContainer/Content/Conditionals
	facts.add_fact(fact_name, fact_value)

func delete_fact(fact_name:String):
	var facts = $PanelContainer/HBoxContainer/PanelContainer/VBoxContainer/Content/Facts
	facts.delete_fact(fact_name)

func delete_conditional(fact_name:String):
	var facts = $PanelContainer/HBoxContainer/PanelContainer/VBoxContainer/Content/Conditionals
	facts.delete_fact(fact_name)

func add_choice_item(at_index:int, choice_data:={}):
	if line_type != DIISIS.LineType.Choice:
		push_warning("Trying to add choice to nonchoice line")
		return
	find_child("ChoiceContainer").add_choice(at_index, choice_data)

func get_choice_item(at_index:int) -> ChoiceEdit:
	if line_type != DIISIS.LineType.Choice:
		push_warning("Trying to get choice item from non-choice line.")
		return null
	return find_child("ChoiceContainer").get_item(at_index)

func delete_choice_item(at_index:int):
	find_child("ChoiceContainer").get_child(at_index).queue_free()

func get_choice_item_count() -> int:
	return find_child("ChoiceContainer").get_choice_item_count()

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


func _on_insert_line_above_pressed() -> void:
	emit_signal("insert_line", get_index())


func _on_insert_line_below_pressed() -> void:
	emit_signal("insert_line", get_index() + 1)


func _on_move_to_index_button_pressed() -> void:
	emit_signal("move_to", self, find_child("MoveToIndexSpinBox").value)
