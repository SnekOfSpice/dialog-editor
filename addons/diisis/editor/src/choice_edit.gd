@tool
extends Control
class_name ChoiceEdit

var jump_page_before_auto_switch := false

signal move_choice_edit(choice_edit, direction)

# Called when the node enters the scene tree for the first time.
func init() -> void:
	find_child("Conditionals").init()
	find_child("Facts").init()
	find_child("Conditionals").init()
	find_child("PageSelect").max_value = Pages.get_page_count() - 1
	#find_child("Facts").visible = false
	#find_child("Conditionals").visible = false
	
	set_do_jump_page(false)
	set_page_view(Pages.editor.get_selected_page_view())

func deserialize(data:Dictionary):
	find_child("LineEditEnabled").text = data.get("choice_text.enabled", "choice label")
	find_child("LineEditDisabled").text = data.get("choice_text.disabled", "")
	find_child("PageSelect").value = data.get("target_page", 0)
	find_child("LineSelect").value = data.get("target_line", 0)
	find_child("Facts").deserialize(data.get("facts", {}))
	find_child("Conditionals").deserialize(data.get("conditionals", {}))
	find_child("DefaultButtonEnabled").button_pressed = data.get("choice_text.enabled_as_default", true)
	find_child("DefaultButtonDisabled").button_pressed = not data.get("choice_text.enabled_as_default", true)
	find_child("AddressSelectActionContainer").deserialize(data.get("meta.selector", {}))
	jump_page_before_auto_switch = data.get("meta.jump_page_before_auto_switch", false)
	
	set_do_jump_page(data.get("do_jump_page", false))
	update()

func serialize():
	return {
		"choice_text.enabled": find_child("LineEditEnabled").text,
		"choice_text.disabled": find_child("LineEditDisabled").text,
		"choice_text.enabled_as_default": find_child("DefaultButtonEnabled").button_pressed,
		"target_page": find_child("PageSelect").value,
		"target_line": find_child("LineSelect").value,
		"facts": find_child("Facts").serialize(),
		"conditionals": find_child("Conditionals").serialize(),
		"do_jump_page": find_child("JumpPageToggle").button_pressed,
		"meta.selector" : find_child("AddressSelectActionContainer").serialize(),
		"meta.jump_page_before_auto_switch" : jump_page_before_auto_switch,
		"address" : DiisisEditorUtil.get_address(self, DiisisEditorUtil.AddressDepth.ChoiceItem)
	}

func set_page_view(view:DiisisEditor.PageView):
	var default_enabled : CheckBox = find_child("DefaultButtonEnabled")
	var line_edit_enabled : LineEdit = find_child("LineEditEnabled")
	var default_disabled : CheckBox = find_child("DefaultButtonDisabled")
	var line_edit_disabled : LineEdit = find_child("LineEditDisabled")
	var buttons : GridContainer = find_child("ItemMoveButtons")
	
	if view == DiisisEditor.PageView.Full:
		default_enabled.visible = true
		line_edit_enabled.visible = true
		default_disabled.visible = true
		line_edit_disabled.visible = true
		buttons.columns = 1
		buttons.find_child("UpButton").size_flags_horizontal = Button.SIZE_EXPAND_FILL
		buttons.find_child("DownButton").size_flags_horizontal = Button.SIZE_EXPAND_FILL
	else:
		default_enabled.visible = default_enabled.button_pressed
		line_edit_enabled.visible = default_enabled.button_pressed
		default_disabled.visible = default_disabled.button_pressed
		line_edit_disabled.visible = default_disabled.button_pressed
		buttons.columns = 3
		buttons.find_child("UpButton").size_flags_horizontal = Button.SIZE_SHRINK_CENTER
		buttons.find_child("DownButton").size_flags_horizontal = Button.SIZE_SHRINK_CENTER
	
	find_child("MoveChoiceItemContainer").visible = view != DiisisEditor.PageView.Minimal
	
	

func _on_page_select_value_changed(value: float) -> void:
	update()

func update():
	var max_page_index : int = Pages.get_page_count() - 1
	var target_page = int(find_child("PageSelect").value)
	target_page = min(target_page, max_page_index)
	var target_line = int(find_child("LineSelect").value)
	var max_line_index : int = Pages.get_line_count(target_page) - 1
	
	find_child("PageSelect").max_value = max_page_index
	find_child("LineSelect").max_value = max_line_index
	
	find_child("TargetStringLabel").text = DiisisEditorUtil.humanize_address(str(target_page, ".", target_line))
	find_child("PageSelect").value = target_page
	
	find_child("IndexLabel").text = str(get_index())
	find_child("UpButton").disabled = get_index() <= 0
	find_child("DownButton").disabled = get_index() >= get_parent().get_child_count() - 1

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

#func _on_facts_visibility_toggle_pressed() -> void:
	#find_child("Facts").visible = not find_child("Facts").visible


#func _on_conditional_visibility_toggle_pressed() -> void:
	#find_child("Conditionals").visible = not find_child("Conditionals").visible


func _on_jump_page_toggle_pressed() -> void:
	set_do_jump_page(find_child("JumpPageToggle").button_pressed)


func _on_up_button_pressed() -> void:
	emit_signal("move_choice_edit", self, -1)


func _on_down_button_pressed() -> void:
	emit_signal("move_choice_edit", self, 1)


func _on_line_select_value_changed(value: float) -> void:
	update()
