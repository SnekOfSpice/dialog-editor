@tool
extends Control
class_name ChoiceEdit

var jump_page_before_auto_switch := false
var deserialized_loopback_page := 0
var deserialized_loopback_line := 0
var deserialized_line_index := 0

var text_id_enabled : String
var text_id_disabled : String

signal move_choice_edit(choice_edit, direction)

enum EditingView{
	Editable,
	TextLabel,
	Invisible
}

func init() -> void:
	find_child("Conditionals").init()
	find_child("Facts").init()
	find_child("Conditionals").init()
	find_child("PageSelect").max_value = Pages.get_page_count() - 1
	
	var behavior_options_button : OptionButton = find_child("BehaviorAfterFirstSelectionButton")
	for option in DIISIS.ChoiceBehaviorAfterSelection:
		behavior_options_button.add_item(option)
	
	set_do_jump_page(false)
	set_loopback(false)
	set_page_view(Pages.editor.get_selected_page_view())
	
	find_child("TextLinesDisabled").visible = false
	
	DiisisEditorUtil.set_up_delete_modulate(self, find_child("DeleteButton"))

func deserialize(data:Dictionary):
	text_id_enabled = data.get("text_id_enabled", Pages.get_new_id())
	text_id_disabled = data.get("text_id_disabled", Pages.get_new_id())
	var jump_target_page : int = data.get("target_page", 0)
	var jump_target_line : int = data.get("target_line", 0)
	var loopback_target_page : int = data.get("loopback_target_page", 0)
	var loopback_target_line : int = data.get("loopback_target_line", 0)
	
	var jump_address_mode := data.get("jump_address_mode", AddressModeButton.Mode.Objectt)
	var loop_address_mode := data.get("loop_address_mode", AddressModeButton.Mode.Objectt)
	find_child("JumpPageContainer").find_child("AddressModeButton").set_mode(jump_address_mode)
	find_child("LoopbackContainer").find_child("AddressModeButton").set_mode(loop_address_mode)
	find_child("TextLinesDisabled").visible = data.get("meta.disabled_visible", false)
	find_child("TextLinesEnabled").visible = data.get("meta.enabled_visible", false)
	
	if find_child("PageSelect").max_value < jump_target_page:
		find_child("PageSelect").max_value = jump_target_page
	if find_child("LineSelect").max_value < jump_target_line:
		find_child("LineSelect").max_value = jump_target_line
	if find_child("LoopbackPageSelect").max_value < loopback_target_page:
		find_child("LoopbackPageSelect").max_value = loopback_target_page
	if find_child("LoopbackLineSelect").max_value < loopback_target_line:
		find_child("LoopbackLineSelect").max_value = loopback_target_line
	
	find_child("LineEditEnabled").text =  Pages.get_text(text_id_enabled, data.get("choice_text.enabled", ""))
	find_child("LineEditDisabled").text = Pages.get_text(text_id_disabled, data.get("choice_text.disabled", ""))
	
	

	deserialized_line_index = DiisisEditorUtil.get_split_address(DiisisEditorUtil.get_address(self, DiisisEditorUtil.AddressDepth.ChoiceItem))[1]
	deserialized_loopback_page = loopback_target_page
	deserialized_loopback_line = loopback_target_line
	find_child("PageSelect").value = jump_target_page
	find_child("LineSelect").value = jump_target_line
	find_child("LoopbackPageSelect").value = loopback_target_page
	find_child("LoopbackLineSelect").value = loopback_target_line
	
	find_child("Facts").deserialize(data.get("facts", {}))
	find_child("Conditionals").deserialize(data.get("conditionals", {}))
	find_child("DefaultApparenceSelectionButton").button_pressed = data.get("choice_text.enabled_as_default", true)
	_on_default_apparence_selection_button_toggled(find_child("DefaultApparenceSelectionButton").button_pressed)
	find_child("AddressSelectActionContainer").deserialize(data.get("meta.selector", {}))
	jump_page_before_auto_switch = data.get("meta.jump_page_before_auto_switch", false)
	
	find_child("BehaviorAfterFirstSelectionButton").select(data.get("behavior_after_first_selection", 0))
	
	if jump_page_before_auto_switch:
		set_do_jump_page(data.get("do_jump_page", false))
	else:
		set_do_jump_page(jump_page_before_auto_switch)
	set_loopback(data.get("loopback", false))
	
	update()

func serialize() -> Dictionary:
	if not text_id_enabled:
		text_id_enabled = Pages.get_new_id()
	if not text_id_disabled:
		text_id_disabled = Pages.get_new_id()
	
	var loopback : bool = find_child("LoopbackToggle").button_pressed
	var jump_page : bool = find_child("JumpPageToggle").button_pressed
	
	var jump_page_target_page : int = find_child("PageSelect").value
	var jump_page_target_line : int = find_child("LineSelect").value
	
	Pages.save_text(text_id_enabled, find_child("LineEditEnabled").text)
	Pages.save_text(text_id_disabled, find_child("LineEditDisabled").text)
	
	return {
		"text_id_enabled" : text_id_enabled,
		"text_id_disabled" : text_id_disabled,
		"meta.disabled_visible" : find_child("TextLinesDisabled").visible,
		"meta.enabled_visible" : find_child("TextLinesEnabled").visible,
		"choice_text.enabled_as_default": find_child("DefaultApparenceSelectionButton").button_pressed,
		"target_page": int(jump_page_target_page),
		"target_line": int(jump_page_target_line),
		"loopback_target_page": int(find_child("LoopbackPageSelect").value),
		"loopback_target_line": int(find_child("LoopbackLineSelect").value),
		"facts": find_child("Facts").serialize(),
		"conditionals": find_child("Conditionals").serialize(),
		"do_jump_page": jump_page,
		"loopback": loopback,
		"meta.selector" : find_child("AddressSelectActionContainer").serialize(),
		"meta.jump_page_before_auto_switch" : jump_page_before_auto_switch,
		"address" : get_address(),
		"behavior_after_first_selection": int(find_child("BehaviorAfterFirstSelectionButton").get_selected_id()),
		"jump_address_mode": int(find_child("JumpPageContainer").find_child("AddressModeButton").get_mode()),
		"loop_address_mode": int(find_child("LoopbackContainer").find_child("AddressModeButton").get_mode()),
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
	var default_enabled_texture : Button = find_child("DefaultEnabledTexture")
	var line_edit_enabled : LineEdit = find_child("LineEditEnabled")
	var default_disabled_texture : Button = find_child("DefaultDisabledTexture")
	var default_dropdown : CheckBox = find_child("DefaultApparenceSelectionButton")
	var line_edit_disabled : LineEdit = find_child("LineEditDisabled")
	var buttons : GridContainer = find_child("ItemMoveButtons")
	
	find_child("BehaviorContainer").visible = view != DiisisEditor.PageView.Minimal
	find_child("BehaviorAfterFirstLabel").visible = view == DiisisEditor.PageView.Full
	find_child("BehaviorAfterFirstSelectionButton").visible = view == DiisisEditor.PageView.Full
	find_child("LoopbackPanelContainer").visible = view != DiisisEditor.PageView.Minimal
	
	if view == DiisisEditor.PageView.Full:
		default_dropdown.visible = true
		line_edit_enabled.visible = true
		line_edit_disabled.visible = true
		default_enabled_texture.visible = true
		default_disabled_texture.visible = true
		buttons.columns = 1
		buttons.find_child("UpButton").size_flags_horizontal = Button.SIZE_EXPAND_FILL
		buttons.find_child("DownButton").size_flags_horizontal = Button.SIZE_EXPAND_FILL
		find_child("Movement").reparent(find_child("OptionContainer"))
	else:
		default_enabled_texture.visible = default_dropdown.button_pressed
		line_edit_enabled.visible = default_dropdown.button_pressed
		default_disabled_texture.visible = not default_dropdown.button_pressed
		line_edit_disabled.visible = not default_dropdown.button_pressed
		buttons.columns = 3
		buttons.find_child("UpButton").size_flags_horizontal = Button.SIZE_SHRINK_CENTER
		buttons.find_child("DownButton").size_flags_horizontal = Button.SIZE_SHRINK_CENTER
		find_child("Movement").reparent(find_child("BehaviorContainer"))
	find_child("MoveChoiceItemContainer").visible = view != DiisisEditor.PageView.Minimal
	
	

func _on_page_select_value_changed(value: float) -> void:
	update()

func update():
	var is_loop_obj : bool = find_child("LoopbackContainer").find_child("AddressModeButton").get_mode() == AddressModeButton.Mode.Objectt
	var is_jump_obj : bool = find_child("JumpPageContainer").find_child("AddressModeButton").get_mode() == AddressModeButton.Mode.Objectt
	var max_page_index : int = max(Pages.get_page_count() - 1, deserialized_loopback_page)
	var target_page := int(find_child("PageSelect").value)
	if is_jump_obj:
		target_page = min(target_page, max_page_index)
	var target_line := int(find_child("LineSelect").value)
	var max_line_index : int = max(Pages.get_line_count(target_page) - 1, deserialized_loopback_page)
	
	if is_jump_obj:
		find_child("PageSelect").max_value = max_page_index
		find_child("LineSelect").max_value = max_line_index
		find_child("PageSelect").value = target_page
	find_child("TargetStringLabel").text = DiisisEditorUtil.humanize_address(str(target_page, ".", target_line))
	
	if is_loop_obj:
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
	
	Pages.editor.get_current_page().update_incoming_references()

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

var _auto_switch := false
func set_auto_switch(value:bool):
	_auto_switch = value
	set_text_lines_visible(not value)
	find_child("JumpPageToggle").visible = not value
	find_child("BehaviorContainer").visible = not value
	find_child("Conditionals").set_behavior_container_visible(not value)
	if value:
		jump_page_before_auto_switch = find_child("JumpPageToggle").button_pressed
		set_do_jump_page(true)
	else:
		set_do_jump_page(jump_page_before_auto_switch)

func _on_delete_pressed() -> void:
	request_delete()

func request_delete():
	if Pages.editor.try_prompt_fact_deletion_confirmation(
		get_address(),
		delete_with_action
	):
		return
	delete_with_action()

func delete_with_action():
	var address = get_address()
	var undo_redo = Pages.editor.undo_redo
	undo_redo.create_action("Delete Choice Item")
	undo_redo.add_do_method(DiisisEditorActions.delete_choice_item.bind(address))
	undo_redo.add_undo_method(DiisisEditorActions.add_choice_item.bind(address))
	undo_redo.commit_action()

func set_do_jump_page(do: bool):
	find_child("JumpPageContainer").visible = do
	find_child("JumpPageToggle").button_pressed = do
	find_child("TargetStringLabel").modulate.a = 1 if do else 0
	if not _auto_switch:
		jump_page_before_auto_switch = do

func set_loopback(do:bool):
	find_child("LoopbackContainer").visible = do
	find_child("LoopbackToggle").button_pressed = do
	find_child("LoopbackTargetStringLabel").modulate.a = 1 if do else 0

func get_loopback_target_address() -> String:
	return str(
		int(find_child("LoopbackPageSelect").value),
		".",
		int(find_child("LoopbackLineSelect").value)
	)

func get_jump_target_address() -> String:
	return str(
		int(find_child("PageSelect").value),
		".",
		int(find_child("LineSelect").value)
	)


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
	Pages.editor.get_current_page().update_incoming_references()


func _on_jump_page_toggle_toggled(toggled_on: bool) -> void:
	set_do_jump_page(toggled_on)
	Pages.editor.get_current_page().update_incoming_references()


func update_default_text_warning():
	var label : Label = find_child("DefaultTextEmptyWarningLabel")
	if find_child("LineEditEnabled").text.is_empty() and find_child("DefaultApparenceSelectionButton").button_pressed:
		label.visible = true
	elif find_child("LineEditDisabled").text.is_empty() and not find_child("DefaultApparenceSelectionButton").button_pressed:
		label.visible = true
	else:
		label.visible = false
	


func _on_line_edit_enabled_text_changed(_new_text: String) -> void:
	update_default_text_warning()


func _on_line_edit_disabled_text_changed(_new_text: String) -> void:
	update_default_text_warning()





func _on_edit_enabled_id_button_pressed() -> void:
	Pages.editor.prompt_change_text_id(text_id_enabled)


func _on_edit_disabled_id_button_pressed() -> void:
	Pages.editor.prompt_change_text_id(text_id_disabled)

func _update_text_line_visibilities(event: InputEvent):
	var enabled : bool = find_child("DefaultApparenceSelectionButton").button_pressed
	var lines_disabled : Control = find_child("TextLinesDisabled")
	var lines_enabled : Control = find_child("TextLinesEnabled")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if enabled:
			lines_disabled.visible = not lines_disabled.visible
		else:
			lines_enabled.visible = not lines_enabled.visible

func _on_text_lines_enabled_gui_input(event: InputEvent) -> void:
	_update_text_line_visibilities(event)

func _on_text_lines_disabled_gui_input(event: InputEvent) -> void:
	_update_text_line_visibilities(event)

func _on_default_apparence_selection_button_toggled(toggled_on: bool) -> void:
	var both_visible = find_child("TextLinesEnabled").visible and find_child("TextLinesDisabled").visible
	update_default_text_warning()
	find_child("DefaultApparenceSelectionButton").text = "enabled" if toggled_on else "disabled"
	if not both_visible:
		find_child("TextLinesEnabled").visible = toggled_on
		find_child("TextLinesDisabled").visible = not toggled_on
	
	var text_lines : VBoxContainer = find_child("TextLines")
	if toggled_on:
		text_lines.move_child(text_lines.find_child("TextLinesEnabled"), 0)
	else:
		text_lines.move_child(text_lines.find_child("TextLinesDisabled"), 0)

# called by choice container
func set_editing_view(value:int):
	match value:
		EditingView.Editable:
			find_child("ChoiceEdit").visible = true
			find_child("ChoiceLabel").visible = false
		EditingView.TextLabel:
			find_child("ChoiceEdit").visible = false
			var label : RichTextLabel = find_child("ChoiceLabel")
			label.visible = true
			var text_enabled : String = find_child("LineEditEnabled").text
			var text_disabled : String = find_child("LineEditDisabled").text
			var enabled_first : bool = find_child("DefaultApparenceSelectionButton").button_pressed
			if enabled_first:
				label.text = DiisisEditorUtil.BBCODE_TRUE
				label.text += text_enabled if not text_enabled.is_empty() else "EMPTY DEFAULT"
				if not text_disabled.is_empty():
					label.text += str("\n[color=#ffffffbb]", DiisisEditorUtil.BBCODE_FALSE, text_disabled, "[/color]")
			else:
				label.text = DiisisEditorUtil.BBCODE_FALSE
				label.text += text_disabled if not text_disabled.is_empty() else "EMPTY DEFAULT"
				if not text_enabled.is_empty():
					label.text += str("\n[color=#ffffffbb]", DiisisEditorUtil.BBCODE_TRUE, text_enabled, "[/color]")
		EditingView.Invisible:
			find_child("ChoiceEdit").visible = false
			find_child("ChoiceLabel").visible = false
