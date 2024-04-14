@tool
extends Control
class_name ChoiceEdit

var do_jump_page := false

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


func deserialize(data:Dictionary):
	find_child("LineEditEnabled").text = data.get("choice_text.enabled", "choice label")
	find_child("LineEditDisabled").text = data.get("choice_text.disabled", "")
	find_child("PageSelect").value = data.get("target_page", 0)
	find_child("Facts").deserialize(data.get("facts", {}).get("values", {}))
	find_child("Conditionals").deserialize(data.get("conditionals", {}))
	find_child("DefaultButtonEnabled").button_pressed = data.get("choice_text.enabled_as_default", true)
	find_child("DefaultButtonDisabled").button_pressed = not data.get("choice_text.enabled_as_default", true)
	
	set_do_jump_page(data.get("do_jump_page", false))
	
	update()

func serialize():
	return {
		"choice_text.enabled": find_child("LineEditEnabled").text,
		"choice_text.disabled": find_child("LineEditDisabled").text,
		"choice_text.enabled_as_default": find_child("DefaultButtonEnabled").button_pressed,
		"target_page": find_child("PageSelect").value,
		"facts": find_child("Facts").serialize(),
		"conditionals": find_child("Conditionals").serialize(),
		"do_jump_page": do_jump_page
	}

func _on_page_select_value_changed(value: float) -> void:
	update()

func update():
	var default_target = int(find_child("PageSelect").value)
	default_target = min(default_target, Pages.get_page_count() - 1)
	
	find_child("PageKeyLabel").text = Pages.page_data.get(default_target).get("page_key")
	find_child("PageSelect").value = default_target
	
	find_child("IndexLabel").text = str(get_index())
	find_child("UpButton").disabled = get_index() <= 0
	find_child("DownButton").disabled = get_index() >= get_parent().get_child_count() - 1

func add_fact(fact_name: String, fact_value: bool):
	var facts = $VBoxContainer2/HBoxContainer/Facts
	facts.add_fact(fact_name, fact_value)

func add_conditional(fact_name: String, fact_value: bool):
	var facts = $VBoxContainer2/HBoxContainer/Conditionals
	facts.add_fact(fact_name, fact_value)

func delete_fact(fact_name:String):
	var facts = $VBoxContainer2/HBoxContainer/Facts
	facts.delete_fact(fact_name)

func delete_conditional(fact_name:String):
	var facts = $VBoxContainer2/HBoxContainer/Conditionals
	facts.delete_fact(fact_name)

func set_text_lines_visible(value:bool):
	find_child("TextLines").visible = value

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
	do_jump_page = do
	find_child("JumpPageContainer").visible = do_jump_page
	find_child("JumpPageToggle").button_pressed = do_jump_page

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
