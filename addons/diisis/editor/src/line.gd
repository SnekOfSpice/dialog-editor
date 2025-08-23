@tool
extends Control
class_name Line

var line_type := DIISIS.LineType.Text
var indent_level := 0
var id : String

signal move_line (child, dir)
signal insert_line (at)
signal move_to (child, idx)
signal delete_line

func init() -> void:
	%GoToHighlight.self_modulate.a = 0
	grab_focus()
	find_child("Header").init()
	find_child("Conditionals").init()
	find_child("Facts").init()
	find_child("TextContent").init()
	find_child("InstructionContainer").init()
	find_child("ChoiceContainer").init()
	set_line_type(Pages.editor.get_selected_line_type())
	
	var control_button_height = max(find_child("MoveUp").size.y, find_child("InsertLineAbove").size.y)
	find_child("MoveUp").custom_minimum_size.y = control_button_height
	find_child("InsertLineAbove").custom_minimum_size.y = control_button_height
	find_child("MoveDown").custom_minimum_size.y = control_button_height
	find_child("InsertLineBelow").custom_minimum_size.y = control_button_height
	
	await get_tree().process_frame
	find_child("HeadVisibilityToggle").visible = not Pages.is_header_schema_empty()
	set_head_editable(Pages.is_header_schema_empty())
	
	DiisisEditorUtil.set_up_delete_modulate(self, find_child("DeleteButton"), _on_delete_button_mouse_exited)

func set_page_view(view:DiisisEditor.PageView):
	var move_controls : Control = find_child("MoveControlsContainer")
	var move_controls_buttons : GridContainer = move_controls.find_child("MoveControlsButtonContainer")
	move_controls.visible = view != DiisisEditor.PageView.Minimal
	#find_child("LoopbackReferenceLabel").visible = view == DiisisEditor.PageView.Full and not find_child("LoopbackReferenceLabel").text.is_empty()
	find_child("HeadVisibilityToggle").visible = view != DiisisEditor.PageView.Minimal
	find_child("HeadVisibilityToggle").visible = not Pages.is_header_schema_empty()
	if view == DiisisEditor.PageView.Full:
		move_controls_buttons.columns = 2
		#move_controls.find_child("Spacer").visible = true
		move_controls_buttons.move_child(move_controls_buttons.find_child("InsertLineAbove"), 1)
	else:
		move_controls_buttons.columns = 5
		#move_controls.find_child("Spacer").visible = false
		move_controls_buttons.move_child(move_controls_buttons.find_child("InsertLineAbove"), 0)

func set_indent_level(to:int):
	indent_level = to
	find_child("IndentContainer").custom_minimum_size.x = 60 * indent_level
	find_child("IndentTexture").self_modulate.a = 0.2 * indent_level
	find_child("IndentMargin").add_theme_constant_override("margin_left", 0)
	if line_type == DIISIS.LineType.Folder:# and indent_level > 0:
		find_child("IndentContainer").custom_minimum_size.x -= 60
		find_child("IndentMargin").add_theme_constant_override("margin_left", 60)

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

func set_line_type(value: int):
	line_type = value
	
	var tc : Node = find_child("TextContent")
	var cc : Node = find_child("ChoiceContainer")
	var ic : Node = find_child("InstructionContainer")
	var fc : Node = find_child("FolderContainer")
	tc.visible = line_type == DIISIS.LineType.Text
	tc.process_mode = Node.PROCESS_MODE_INHERIT if line_type == DIISIS.LineType.Text else Node.PROCESS_MODE_DISABLED
	cc.visible = line_type == DIISIS.LineType.Choice
	cc.process_mode = Node.PROCESS_MODE_INHERIT if line_type == DIISIS.LineType.Choice else Node.PROCESS_MODE_DISABLED
	ic.visible = line_type == DIISIS.LineType.Instruction
	ic.process_mode = Node.PROCESS_MODE_INHERIT if line_type == DIISIS.LineType.Instruction else Node.PROCESS_MODE_DISABLED
	fc.visible = line_type == DIISIS.LineType.Folder
	fc.process_mode = Node.PROCESS_MODE_INHERIT if line_type == DIISIS.LineType.Folder else Node.PROCESS_MODE_DISABLED
	find_child("InstructionContainer").visible = line_type == DIISIS.LineType.Instruction
	find_child("FolderContainer").visible = line_type == DIISIS.LineType.Folder
	find_child("SelectAllInRangeButton").visible = line_type == DIISIS.LineType.Folder
	
	if line_type == DIISIS.LineType.Folder:
		find_child("DeleteButton").tooltip_text = "Click to delete folder.\nShift + Click to delete folder + contents."

func move_choice_item_by_index(at_index:int, direction:int):
	if line_type != DIISIS.LineType.Choice:
		push_warning("trying to move choice item of nonchoice line")
		return
	find_child("ChoiceContainer").move_choice_item_by_index(at_index, direction)

func set_head_editable(value: bool):
	find_child("Header").set_editable(value)
	find_child("HeadVisibilityToggle").button_pressed = value

func set_skip(value:bool):
	modulate.a = 0.6 if value else 1
	find_child("SkipCheckBox").button_pressed = value
	
	if line_type == DIISIS.LineType.Folder:
		var page : Page = Pages.editor.get_current_page()
		var range := get_folder_range_v()
		for index in range(range.x + 1, range.y + 2):
			var line : Line = page.get_line(index)
			if line:
				line.set_skip_folder_override(value)

func set_skip_folder_override(value:bool):
	modulate.a = 0.6 if value or find_child("SkipCheckBox").button_pressed else 1

func get_is_head_editable():
	return find_child("Header").is_editable

func serialize() -> Dictionary:
	if not id:
		id = Pages.get_new_id()
	
	var data = {}
	
	data["line_type"] = int(line_type)
	data["header"] = find_child("Header").serialize()
	data["facts"] = find_child("Facts").serialize()
	data["conditionals"] = find_child("Conditionals").serialize()
	#data["meta.visible"] = find_child("VisibleToggle").button_pressed
	data["meta.is_head_editable"] = get_is_head_editable()
	data["meta.line_index"] = get_index()
	data["meta.facts_visible"] = find_child("FactsVisibilityToggle").button_pressed
	data["meta.conditionals_visible"] = find_child("ConditionalsVisibilityToggle").button_pressed
	data["meta.indent_level"] = int(indent_level)
	data["meta.selector"] = find_child("AddressSelectActionContainer").serialize()
	data["address"] = DiisisEditorUtil.get_address(self, DiisisEditorUtil.AddressDepth.Line)
	data["id"] = id
	data["skip"] = find_child("SkipCheckBox").button_pressed
	
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
	set_line_type(data.get("line_type", Pages.editor.get_selected_line_type()))
	find_child("AddressSelectActionContainer").deserialize(data.get("meta.selector", {}))
	
	# header
	find_child("HeadVisibilityToggle").visible = not Pages.is_header_schema_empty()
	find_child("FactsVisibilityToggle").button_pressed = data.get("meta.facts_visible", false)
	find_child("ConditionalsVisibilityToggle").button_pressed = data.get("meta.conditionals_visible", false)
	
	find_child("Header").deserialize(data.get("header", []))
	find_child("Facts").deserialize(data.get("facts", {}))
	find_child("Conditionals").deserialize(data.get("conditionals", {}))
	
	# content (based on line type)
	match line_type:
		DIISIS.LineType.Text:
			find_child("TextContent").deserialize(data.get("content", {}))
		DIISIS.LineType.Choice:
			var content : Dictionary = data.get("content", {})
			if Pages.editor.is_importing():
				var choice_order : Array = content.get("choice_order", [])
				if not choice_order.is_empty():
					content["choices"] = Pages.sort_choices(choice_order, content.get("choices"))
				
			find_child("ChoiceContainer").deserialize(content)
		DIISIS.LineType.Instruction:
			find_child("InstructionContainer").deserialize(data.get("content", {}))
		DIISIS.LineType.Folder:
			find_child("FolderContainer").deserialize(data.get("content", {}))
			set_indent_level(data.get("meta.indent_level", 0))
	
	#var a = data.get("meta.is_head_editable")
	#if not a:
		#a = false
	set_head_editable(data.get("meta.is_head_editable", false))
	id = data.get("id", Pages.get_new_id())
	set_skip(data.get("skip", false))

func get_choice_item_count() -> int:
	if line_type != DIISIS.LineType.Choice:
		return 0
	
	return find_child("ChoiceContainer").get_choice_item_count()

func _on_head_visibility_toggle_toggled(button_pressed: bool) -> void:
	set_head_editable(button_pressed)

func set_selected(value:bool):
	find_child("AddressSelectActionContainer").set_selected(value)

func _on_delete_pressed() -> void:
	request_delete()


func get_address() -> String:
	return DiisisEditorUtil.get_address(self, DiisisEditorUtil.AddressDepth.Line)

func request_delete():
	if Pages.editor.try_prompt_fact_deletion_confirmation(
		get_address(),
		delete_line.emit.bind(get_index())
	):
		return
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
	set_head_editable(get_is_head_editable())
	if line_type == DIISIS.LineType.Choice:
		find_child("ChoiceContainer").update()
	elif line_type == DIISIS.LineType.Text:
		find_child("TextContent").update()
	
	update_incoming_reference_label()

func update_incoming_reference_label():
	var cpn : int = Pages.editor.get_current_page_number()
	var index := get_index()
	var loopback_reference_count : int = Pages.get_loopback_references_to(cpn, index).size()
	var jump_reference_count : int = Pages.get_jump_references_to(cpn, index).size()
	var reference_text := str(
		str("LB->", loopback_reference_count, "\n") if loopback_reference_count > 0 else "",
		str("JP->", jump_reference_count) if jump_reference_count > 0 else "",
		)
	if not reference_text.is_empty():
		reference_text = str(
			"[hint=Click to view incoming references :3][url=kissyoursister]",
			reference_text,
			"[/url][/hint]"
		)
	find_child("LoopbackReferenceLabel").text = reference_text
	find_child("LoopbackReferenceLabel").visible = not reference_text.is_empty()

func update_folder(max_folder_range):
	if line_type == DIISIS.LineType.Folder:
		find_child("FolderContainer").update(get_index(), max_folder_range)

func add_fact(fact_name: String, fact_value):
	find_child("Facts").add_fact(fact_name, fact_value)

func add_conditional(fact_name: String, fact_value):
	find_child("Conditionals").add_fact(fact_name, fact_value, true)

func delete_fact(fact_name:String):
	find_child("Facts").delete_fact(fact_name)

func delete_conditional(fact_name:String):
	find_child("Conditionals").delete_fact(fact_name)

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

func _on_move_up_pressed() -> void:
	move(-1)

func _on_move_down_pressed() -> void:
	move(1)

func _on_facts_visibility_toggle_toggled(button_pressed: bool) -> void:
	find_child("Facts").visible = button_pressed


func _on_conditionals_visibility_toggle_toggled(button_pressed: bool) -> void:
	find_child("Conditionals").visible = button_pressed


func _on_insert_line_above_pressed() -> void:
	var insert_index := get_index()
	emit_signal("insert_line", insert_index)


func _on_insert_line_below_pressed() -> void:
	var insert_index := get_index() + 1
	emit_signal("insert_line", insert_index)


func _on_select_all_in_range_button_pressed():
	var range : int = get_folder_range_i()
	var index := get_index()
	for line : Line in Pages.editor.get_current_page().find_child("Lines").get_children():
		var line_index := line.get_index()
		line.set_selected(line_index >= index and line_index <= index + range)


func _on_text_content_drop_focus() -> void:
	#grab_click_focus()
	$PanelContainer.grab_focus()


func _on_loopback_reference_label_meta_clicked(meta: Variant) -> void:
	Pages.editor.view_incoming_references(Pages.editor.get_current_page_number(), get_index())


func _on_delete_button_mouse_exited() -> void:
	# can happen when we actually delete the thing
	if not is_instance_valid(find_child("SkipCheckBox")):
		return
	set_skip(find_child("SkipCheckBox").button_pressed)

func flash_highlight():
	DiisisEditorUtil.flash_highlight(%GoToHighlight)
