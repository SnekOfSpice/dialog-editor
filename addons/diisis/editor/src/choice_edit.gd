@tool
extends Control
class_name ChoiceEdit

var jump_page_before_auto_switch := false
var deserialized_loopback_page := 0
var deserialized_loopback_line := 0
var deserialized_line_index := 0

signal move_choice_edit(choice_edit, direction)

# Called when the node enters the scene tree for the first time.
func init() -> void:
	find_child("Conditionals").init()
	find_child("Facts").init()
	find_child("Conditionals").init()
	find_child("PageSelect").max_value = Pages.get_page_count() - 1
	#find_child("Facts").visible = false
	#find_child("Conditionals").visible = false
	
	var behavior_options_button : OptionButton = find_child("BehaviorAfterFirstSelectionButton")
	for option in DIISIS.ChoiceBehaviorAfterSelection:
		behavior_options_button.add_item(option)
	
	set_do_jump_page(false)
	set_loopback(false)
	set_page_view(Pages.editor.get_selected_page_view())

func deserialize(data:Dictionary):
	var jump_target_page : int = data.get("target_page", 0)
	var jump_target_line : int = data.get("target_line", 0)
	var loopback_target_page : int = data.get("loopback_target_page", 0)
	var loopback_target_line : int = data.get("loopback_target_line", 0)
	
	if find_child("PageSelect").max_value < jump_target_page:
		#print("target exeeds limit")
		find_child("PageSelect").max_value = jump_target_page
		#prints("limit is now ", find_child("PageSelect").max_value)
	if find_child("LineSelect").max_value < jump_target_line:
		#print("target exeeds limit l")
		find_child("LineSelect").max_value = jump_target_line
		#prints("llimit is now ", find_child("LineSelect").max_value)
	if find_child("LoopbackPageSelect").max_value < loopback_target_page:
		find_child("LoopbackPageSelect").max_value = loopback_target_page
	if find_child("LoopbackLineSelect").max_value < loopback_target_line:
		find_child("LoopbackLineSelect").max_value = loopback_target_line
	
	find_child("LineEditEnabled").text = data.get("choice_text.enabled", "choice label")
	find_child("LineEditDisabled").text = data.get("choice_text.disabled", "")
	
	find_child("JumpPageContainer").find_child("AddressModeButton").set_mode(data.get("jump_address_mode", AddressModeButton.Mode.Objectt))
	find_child("LoopbackContainer").find_child("AddressModeButton").set_mode(data.get("loop_address_mode", AddressModeButton.Mode.Objectt))
	
	

	deserialized_line_index = DiisisEditorUtil.get_split_address(DiisisEditorUtil.get_address(self, DiisisEditorUtil.AddressDepth.ChoiceItem))[1]
	deserialized_loopback_page = loopback_target_page
	deserialized_loopback_line = loopback_target_line
	find_child("PageSelect").value = jump_target_page
	find_child("LineSelect").value = jump_target_line
	find_child("LoopbackPageSelect").value = loopback_target_page
	find_child("LoopbackLineSelect").value = loopback_target_line
	
	find_child("Facts").deserialize(data.get("facts", {}))
	find_child("Conditionals").deserialize(data.get("conditionals", {}))
	if data.get("choice_text.enabled_as_default", true):
		find_child("DefaultApparenceSelectionButton").select(0)
	else:
		find_child("DefaultApparenceSelectionButton").select(1)
	find_child("AddressSelectActionContainer").deserialize(data.get("meta.selector", {}))
	jump_page_before_auto_switch = data.get("meta.jump_page_before_auto_switch", false)
	
	find_child("BehaviorAfterFirstSelectionButton").select(data.get("behavior_after_first_selection", 0))
	
	set_do_jump_page(data.get("do_jump_page", false))
	set_loopback(data.get("loopback", false))
	
	# this has to be done last. choice_container injects the data into this
	# but this function relies on jump_page_before_auto_switch to be set
	set_auto_switch(data.get("auto_switch", false))
	
	update()

func serialize() -> Dictionary:
	var loopback : bool = find_child("LoopbackToggle").button_pressed
	var jump_page : bool = find_child("JumpPageToggle").button_pressed
	
	var jump_page_target_page : int = find_child("PageSelect").value
	var jump_page_target_line : int = find_child("LineSelect").value
	
	# remove the loopback / jump page pointers
	if Pages.loopback_references_by_page.has(deserialized_loopback_page):
		if Pages.loopback_references_by_page.get(deserialized_loopback_page).has(deserialized_loopback_line):
			Pages.loopback_references_by_page[deserialized_loopback_page][deserialized_loopback_line].erase(get_address())
	# tbh idk if this also works if we don't save the deserialized value but I think it should
	if Pages.jump_page_references_by_page.has(jump_page_target_page):
		if Pages.jump_page_references_by_page.get(jump_page_target_page).has(jump_page_target_line):
			Pages.jump_page_references_by_page[jump_page_target_page][jump_page_target_line].erase(get_address())
	
	if loopback:
		var loopback_page :int= find_child("LoopbackPageSelect").value
		var loopback_line :int= find_child("LoopbackLineSelect").value
		if Pages.loopback_references_by_page.has(loopback_page):
			if Pages.loopback_references_by_page.get(loopback_page).has(loopback_line):
				Pages.loopback_references_by_page.get(loopback_page).get(loopback_line).append(get_address())
			else:
				Pages.loopback_references_by_page[loopback_page][loopback_line] = [get_address()]
		else:
			Pages.loopback_references_by_page[loopback_page] = {loopback_line : [get_address()]}
	
	if jump_page:
		if Pages.jump_page_references_by_page.has(jump_page_target_page):
			if Pages.jump_page_references_by_page.get(jump_page_target_page).has(jump_page_target_line):
				Pages.jump_page_references_by_page.get(jump_page_target_page).get(jump_page_target_line).append(get_address())
			else:
				Pages.jump_page_references_by_page[jump_page_target_page][jump_page_target_line] = [get_address()]
		else:
			Pages.jump_page_references_by_page[jump_page_target_page] = {jump_page_target_line : [get_address()]}
	
	
	return {
		"choice_text.enabled": find_child("LineEditEnabled").text,
		"choice_text.disabled": find_child("LineEditDisabled").text,
		"choice_text.enabled_as_default": find_child("DefaultApparenceSelectionButton").get_selected_id() == 0,
		"target_page": jump_page_target_page,
		"target_line": jump_page_target_line,
		"loopback_target_page": find_child("LoopbackPageSelect").value,
		"loopback_target_line": find_child("LoopbackLineSelect").value,
		"facts": find_child("Facts").serialize(),
		"conditionals": find_child("Conditionals").serialize(),
		"do_jump_page": jump_page,
		"loopback": loopback,
		"meta.selector" : find_child("AddressSelectActionContainer").serialize(),
		"meta.jump_page_before_auto_switch" : jump_page_before_auto_switch,
		"address" : get_address(),
		"behavior_after_first_selection": find_child("BehaviorAfterFirstSelectionButton").get_selected_id(),
		"jump_address_mode": find_child("JumpPageContainer").find_child("AddressModeButton").get_mode(),
		"loop_address_mode": find_child("LoopbackContainer").find_child("AddressModeButton").get_mode(),
	}

func update_fragile():
	var line_parent = get_parent()
	if not is_instance_valid(line_parent):
		return
	while not line_parent is Line:
		if not line_parent:
			return
		line_parent = line_parent.get_parent()
	var actual_line_type = line_parent.line_type
	if actual_line_type != DIISIS.LineType.Choice:
		# since lines never delete the different line type containers, there can be remnants of choice items at this line index from other pages during page loading
		# this ensures that we actually only get choices if the current line is actually still a choice
		return
	var address := get_address()
	var parts : Array = DiisisEditorUtil.get_split_address(address)
	var line : Dictionary = line_parent.serialize() #Pages.page_data.get(parts[0]).get("lines")[parts[1]]
	var line_type : int= line.get("line_type")
	if line_type != DIISIS.LineType.Choice:
		return
	
	await get_tree().process_frame
	var offset:int
	if line.get("meta.line_index") > deserialized_line_index:
		offset = Pages.local_line_insert_offset
	else:
		offset = 0
		
	var choices = Pages.page_data.get(parts[0]).get("lines")[line.get("meta.line_index") - offset].get("content").get("choices")
	if not choices: return
	var data = choices[parts[2]]
	deserialize(data)

func get_address() -> String:
	return DiisisEditorUtil.get_address(self, DiisisEditorUtil.AddressDepth.ChoiceItem)

# TODO: Add enabled / disabled icons
func set_page_view(view:DiisisEditor.PageView):
	var default_enabled_texture : TextureRect = find_child("DefaultEnabledTexture")
	var line_edit_enabled : LineEdit = find_child("LineEditEnabled")
	var default_disabled_texture : TextureRect = find_child("DefaultDisabledTexture")
	var default_dropdown : OptionButton = find_child("DefaultApparenceSelectionButton")
	var line_edit_disabled : LineEdit = find_child("LineEditDisabled")
	var buttons : GridContainer = find_child("ItemMoveButtons")
	
	find_child("BehaviorContainer").visible = view != DiisisEditor.PageView.Minimal
	find_child("BehaviorAfterFirstLabel").visible = view == DiisisEditor.PageView.Full
	find_child("BehaviorAfterFirstSelectionButton").visible = view == DiisisEditor.PageView.Full
	
	if view == DiisisEditor.PageView.Full:
		default_dropdown.visible = true
		line_edit_enabled.visible = true
		line_edit_disabled.visible = true
		default_enabled_texture.visible = true
		default_disabled_texture.visible = true
		buttons.columns = 1
		buttons.find_child("UpButton").size_flags_horizontal = Button.SIZE_EXPAND_FILL
		buttons.find_child("DownButton").size_flags_horizontal = Button.SIZE_EXPAND_FILL
	else:
		default_enabled_texture.visible = default_dropdown.get_selected_id() == 0
		line_edit_enabled.visible = default_dropdown.get_selected_id() == 0
		default_disabled_texture.visible = default_dropdown.get_selected_id() == 1
		line_edit_disabled.visible = default_dropdown.get_selected_id() == 1
		buttons.columns = 3
		buttons.find_child("UpButton").size_flags_horizontal = Button.SIZE_SHRINK_CENTER
		buttons.find_child("DownButton").size_flags_horizontal = Button.SIZE_SHRINK_CENTER
	
	find_child("MoveChoiceItemContainer").visible = view != DiisisEditor.PageView.Minimal
	
	

func _on_page_select_value_changed(value: float) -> void:
	update()

func update():
	var max_page_index : int = max(Pages.get_page_count() - 1, deserialized_loopback_page)
	var target_page := int(find_child("PageSelect").value)
	target_page = min(target_page, max_page_index)
	var target_line := int(find_child("LineSelect").value)
	var max_line_index : int = max(Pages.get_line_count(target_page) - 1, deserialized_loopback_line)
	
	#prints("updating, setting to", max_line_index, " was des w", deserialized_loopback_line)
	find_child("PageSelect").max_value = max_page_index
	find_child("LineSelect").max_value = max_line_index
	
	find_child("TargetStringLabel").text = DiisisEditorUtil.humanize_address(str(target_page, ".", target_line))
	#find_child("TargetStringLabel").tooltip = DiisisEditorUtil.humanize_address(str(target_page, ".", target_line))
	find_child("PageSelect").value = target_page
	
	find_child("LoopbackPageSelect").max_value = max_page_index
	find_child("LoopbackLineSelect").max_value = max_line_index
	var loopback_page := int(find_child("LoopbackPageSelect").value)
	var loopback_line := int(find_child("LoopbackLineSelect").value)
	
	find_child("LoopbackTargetStringLabel").text = DiisisEditorUtil.humanize_address(str(loopback_page, ".", loopback_line))
	
	find_child("IndexLabel").text = str(get_index())
	find_child("UpButton").disabled = get_index() <= 0
	find_child("DownButton").disabled = get_index() >= get_parent().get_child_count() - 1
	
	update_default_text_warning()
	
	if deserialized_loopback_line > find_child("LoopbackLineSelect").value:
		find_child("LoopbackLineSelect").value = deserialized_loopback_page
	if deserialized_loopback_page > find_child("LoopbackPageSelect").value:
		find_child("LoopbackPageSelect").value = deserialized_loopback_page

func set_selected(value:bool):
	find_child("AddressSelectActionContainer").set_selected(value)

func add_fact(fact_name: String, fact_value):
	find_child("Facts").add_fact(fact_name, fact_value)

func add_conditional(fact_name: String, fact_value: bool):
	find_child("Conditionals").add_fact(fact_name, fact_value, true)

func delete_fact(fact_name:String):
	find_child("Facts").delete_fact(fact_name)

func delete_conditional(fact_name:String):
	find_child("Conditionals").delete_fact(fact_name)

func set_text_lines_visible(value:bool):
	find_child("TextLines").visible = value
	
func set_auto_switch(value:bool):
	set_text_lines_visible(not value)
	find_child("JumpPageToggle").visible = not value
	find_child("Conditionals").set_behavior_container_visible(not value)
	if value:
		jump_page_before_auto_switch = find_child("JumpPageToggle").button_pressed
		set_do_jump_page(true)
	else:
		set_do_jump_page(jump_page_before_auto_switch)

func _on_delete_pressed() -> void:
	request_delete()

func request_delete():
	var address = DiisisEditorUtil.get_address(self, DiisisEditorUtil.AddressDepth.ChoiceItem)
	#var line_address = DiisisEditorUtil.truncate_address(address, DiisisEditorUtil.AddressDepth.Line)
	var undo_redo = Pages.editor.undo_redo
	undo_redo.create_action("Delete Choice Item")
	undo_redo.add_do_method(DiisisEditorActions.delete_choice_item.bind(address))
	undo_redo.add_undo_method(DiisisEditorActions.add_choice_item.bind(address))
	undo_redo.commit_action()

#func set_jump_page_toggle_visible(value:bool):
	#find_child("JumpPageToggle").visible = value

func set_do_jump_page(do: bool):
	find_child("JumpPageContainer").visible = do
	find_child("JumpPageToggle").button_pressed = do
	jump_page_before_auto_switch = do

func set_loopback(do:bool):
	find_child("LoopbackContainer").visible = do
	find_child("LoopbackToggle").button_pressed = do

func get_loopback_target_address() -> String:
	return str(find_child("LoopbackPageSelect").value, ".", find_child("LoopbackLineSelect").value)

func get_jump_target_address() -> String:
	return str(find_child("PageSelect").value, ".", find_child("LineSelect").value)


func _on_up_button_pressed() -> void:
	emit_signal("move_choice_edit", self, -1)


func _on_down_button_pressed() -> void:
	emit_signal("move_choice_edit", self, 1)


func _on_line_select_value_changed(value: float) -> void:
	update()


func _on_loopback_page_select_value_changed(value: float) -> void:
	update()


func _on_loopback_line_select_value_changed(value: float) -> void:
	update()



func _on_loopback_toggle_toggled(toggled_on: bool) -> void:
	set_loopback(toggled_on)


func _on_jump_page_toggle_toggled(toggled_on: bool) -> void:
	set_do_jump_page(toggled_on)


func _on_default_apparence_selection_button_item_selected(_index: int) -> void:
	update_default_text_warning()

func update_default_text_warning():
	var label : Label = find_child("DefaultTextEmptyWarningLabel")
	if find_child("LineEditEnabled").text.is_empty() and find_child("DefaultApparenceSelectionButton").get_selected_id() == 0:
		label.visible = true
	elif find_child("LineEditDisabled").text.is_empty() and find_child("DefaultApparenceSelectionButton").get_selected_id() == 1:
		label.visible = true
	else:
		label.visible = false
	


func _on_line_edit_enabled_text_changed(_new_text: String) -> void:
	update_default_text_warning()


func _on_line_edit_disabled_text_changed(_new_text: String) -> void:
	update_default_text_warning()
