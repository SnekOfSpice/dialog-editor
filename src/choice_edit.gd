@tool
extends Control

var do_jump_page := false

# Called when the node enters the scene tree for the first time.
func init() -> void:
	find_child("Conditionals").init()
	find_child("PageSelect").max_value = Pages.get_page_count() - 1
	find_child("Facts").visible = false
	find_child("Conditionals").visible = false
	
	set_do_jump_page(false)


func deserialize(data:Dictionary):
	find_child("LineEditEnabled").text = data.get("choice_text.enabled", data.get("choice_text", ""))
	find_child("LineEditDisabled").text = data.get("choice_text.disabled", "")
	find_child("PageSelect").value = data.get("target_page")
	find_child("Facts").deserialize(data.get("facts", {}))
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

func set_text_lines_visible(value:bool):
	find_child("TextLines").visible = value

func _on_delete_pressed() -> void:
	queue_free()

func set_do_jump_page(do: bool):
	do_jump_page = do
	find_child("JumpPageContainer").visible = do_jump_page
	find_child("JumpPageToggle").button_pressed = do_jump_page

func _on_facts_visibility_toggle_pressed() -> void:
	find_child("Facts").visible = not find_child("Facts").visible


func _on_conditional_visibility_toggle_pressed() -> void:
	find_child("Conditionals").visible = not find_child("Conditionals").visible


func _on_jump_page_toggle_pressed() -> void:
	set_do_jump_page(find_child("JumpPageToggle").button_pressed)
