extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	find_child("PageSelect").max_value = Pages.get_page_count() - 1
	find_child("Facts").visible = false
	find_child("Conditionals").visible = false


func deserialize(data:Dictionary):
	find_child("LineEdit").text = data.get("choice_text")
	find_child("PageSelect").value = data.get("target_page")
	find_child("Facts").deserialize(data.get("facts", {}))
	find_child("Conditionals").deserialize(data.get("conditionals", {}))
	
	update()

func serialize():
	return {
		"choice_text": find_child("LineEdit").text,
		"target_page": find_child("PageSelect").value,
		"facts": find_child("Facts").serialize(),
		"conditionals": find_child("Conditionals").serialize()
	}

func _on_page_select_value_changed(value: float) -> void:
	update()

func update():
	var default_target = int(find_child("PageSelect").value)
	default_target = min(default_target, Pages.get_page_count() - 1)
	
	find_child("PageKeyLabel").text = Pages.page_data.get(default_target).get("page_key")
	find_child("PageSelect").value = default_target


func _on_delete_pressed() -> void:
	queue_free()


func _on_facts_visibility_toggle_pressed() -> void:
	find_child("Facts").visible = not find_child("Facts").visible


func _on_conditional_visibility_toggle_pressed() -> void:
	find_child("Conditionals").visible = not find_child("Conditionals").visible
